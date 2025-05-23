import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/dropped_item.dart';
import '../services/score_calculator.dart';
import '../widgets/score_display.dart';
import '../models/design.dart';
import 'package:hive/hive.dart';
import '../screens/design_detail_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final TextEditingController _searchController = TextEditingController();
  final List<DroppedItem> _droppedItems = [];
  final ScreenshotController _screenshotController = ScreenshotController();
  final GlobalKey _canvasKey = GlobalKey();

  LatLng _mapCenter = const LatLng(48.137154, 11.576124);
  Marker? _selectedMarker;
  bool _mapLocked = false;
  double? _pollutionScore;
  double? _happinessScore;
  String? _searchedAddress;

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    _searchedAddress = query;
    final apiKey = dotenv.env['google_nerv'];
    if (apiKey == null || apiKey.isEmpty) {
      _showMessage("Google Maps API key not found.");
      return;
    }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(query)}&components=country:DE|locality:München&key=$apiKey',
    );

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK' &&
          data['results'] != null &&
          data['results'].isNotEmpty) {
        final loc = data['results'][0]['geometry']['location'];
        final position = LatLng(loc['lat'], loc['lng']);
        _confirmStreetSelection(position);
      } else {
        _showMessage(
          "Adresse nicht gefunden. Versuche es erneut mit einer genaueren Eingabe.",
        );
      }
    } catch (e) {
      _showMessage("Fehler bei der Adresssuche: ${e.toString()}");
    }
  }

  Future<void> _confirmStreetSelection(LatLng position) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Adresse bestätigen'),
            content: const Text(
              'Möchtest du diese Straße sperren und bearbeiten?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Nein'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ja'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final controller = await _mapController.future;
      await controller.animateCamera(CameraUpdate.newLatLngZoom(position, 19));

      setState(() {
        _mapCenter = position;
        _selectedMarker = Marker(
          markerId: const MarkerId('selected'),
          position: position,
        );
        _mapLocked = true;
      });

      _updateScores();
    }
  }

  void _handleDrop(Offset globalOffset, String imagePath, String type) {
    final box = _canvasKey.currentContext!.findRenderObject() as RenderBox;
    final localPos = box.globalToLocal(globalOffset);
    final width = box.size.width;
    final inStreet = localPos.dx >= width * 0.25 && localPos.dx <= width * 0.75;

    if (!inStreet) {
      _showMessage("Bitte nur innerhalb der Straße ablegen.");
      return;
    }

    setState(() {
      _droppedItems.add(
        DroppedItem(position: localPos, imagePath: imagePath, type: type),
      );
    });

    _updateScores();
  }

  void _updateScores() {
    final score = ScoreCalculator(
      treeCount:
          _droppedItems
              .where((i) => ['tree', 'flower', 'plant'].contains(i.type))
              .length,
      greenModuleCount: _droppedItems.where((i) => i.type == 'charger').length,
      pollutingModuleCount: 1,
      amenityCount:
          _droppedItems
              .where(
                (i) => ['pedestrians', 'bench', 'barbecue'].contains(i.type),
              )
              .length,
      greenTransportCount:
          _droppedItems
              .where((i) => ['bike_lane', 'bus_stop'].contains(i.type))
              .length,
    );

    setState(() {
      _happinessScore = score.calculateHappinessScore().toDouble();
      _pollutionScore = 100 - _happinessScore!;
    });
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _publishDesign() async {
    final Uint8List? imageBytes = await _screenshotController.capture();
    if (imageBytes == null) {
      _showMessage("⚠️ Failed to capture screenshot.");
      return;
    }

    String prompt =
        'A realistic street view of $_searchedAddress with the following features: ';
    final Set<String> addedElements =
        _droppedItems.map((item) => item.type).toSet();
    prompt += addedElements.join(', ');

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/images/generations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${dotenv.env['OPENAI_API_KEY'] ?? ''}',
      },
      body: jsonEncode({
        'model': 'dall-e-3',
        'prompt': prompt,
        'n': 1,
        'size': '1024x1024',
        'response_format': 'b64_json',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final b64Image = data['data'][0]['b64_json'];

      if (b64Image == null || b64Image.toString().isEmpty) {
        _showMessage("⚠️ No image returned from the API.");
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => DesignDetailScreen(
                base64Image: b64Image,
                happinessScore: _happinessScore ?? 50,
                pollutionScore: _pollutionScore ?? 50,
              ),
        ),
      );
    }
  }

  Widget _buildTool(String type, String icon, String label, String classType) {
    final imagePath = 'assets/icons/$icon.png';
    final widget = Column(
      children: [
        Image.asset(imagePath, width: 40, height: 40),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );

    final bgColor = () {
      switch (classType) {
        case 'green':
          return Colors.green[800];
        case 'mobility':
          return Colors.blue[700];
        case 'social':
          return const Color.fromARGB(255, 122, 3, 173);
        default:
          return Colors.grey[700];
      }
    }();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Draggable<_DragPayload>(
        data: _DragPayload(imagePath, type),
        feedback: Material(color: Colors.transparent, child: widget),
        childWhenDragging: Opacity(opacity: 0.4, child: widget),
        child: Padding(padding: const EdgeInsets.all(8), child: widget),
      ),
    );
  }

  Widget _buildSidebarTools() {
    return Container(
      width: 100,
      color: Colors.black,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              '🌿 Green',
              style: TextStyle(color: Colors.greenAccent, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildTool('tree', 'tree', 'Tree', 'green'),
            _buildTool('charger', 'charger', 'Charger', 'green'),
            _buildTool('flower', 'flower', 'Flower', 'green'),
            _buildTool('plant', 'plant', 'Plant', 'green'),
            const SizedBox(height: 16),
            const Text(
              '👥 Social',
              style: TextStyle(color: Colors.pinkAccent, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildTool('barbecue', 'barbecue', 'Barbecue', 'social'),
            _buildTool('bench', 'bench', 'Bench', 'social'),
            const SizedBox(height: 16),
            const Text(
              '🚲 Mobility',
              style: TextStyle(color: Colors.lightBlueAccent, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildTool('pedestrians', 'pedestrians', 'People', 'mobility'),
            _buildTool('bike_lane', 'bike_lane', 'Bike', 'mobility'),
            _buildTool('bus_stop', 'bus_stop', 'Bus', 'mobility'),
          ],
        ),
      ),
    );
  }

  void _showToolPalette() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTool('tree', 'tree', 'Tree', 'green'),
                  _buildTool('charger', 'charger', 'Charger', 'green'),
                  _buildTool('flower', 'flower', 'Flower', 'green'),
                  _buildTool('plant', 'plant', 'Plant', 'green'),
                  _buildTool('barbecue', 'barbecue', 'Barbecue', 'social'),
                  _buildTool('bench', 'bench', 'Bench', 'social'),
                  _buildTool(
                    'pedestrians',
                    'pedestrians',
                    'People',
                    'mobility',
                  ),
                  _buildTool('bike_lane', 'bike_lane', 'Bike', 'mobility'),
                  _buildTool('bus_stop', 'bus_stop', 'Bus', 'mobility'),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildMapArea() {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final streetBounds = Rect.fromLTWH(width * 0.25, 0, width * 0.5, height);

    return Screenshot(
      controller: _screenshotController,
      child: Stack(
        key: _canvasKey,
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _mapCenter, zoom: 14),
            onMapCreated: (c) => _mapController.complete(c),
            myLocationEnabled: true,
            zoomControlsEnabled: !_mapLocked,
            scrollGesturesEnabled: !_mapLocked,
            zoomGesturesEnabled: !_mapLocked,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            markers: _selectedMarker != null ? {_selectedMarker!} : {},
          ),
          Positioned.fromRect(
            rect: streetBounds,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  border: Border.all(color: Colors.green.shade700, width: 2),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              child: DragTarget<_DragPayload>(
                builder: (_, __, ___) => const SizedBox.expand(),
                onAcceptWithDetails:
                    (details) => _handleDrop(
                      details.offset,
                      details.data.imagePath,
                      details.data.type,
                    ),
              ),
            ),
          ),
          ..._droppedItems.map(
            (item) => Positioned(
              left: item.position.dx - 24,
              top: item.position.dy - 24,
              child: Image.asset(item.imagePath, width: 48, height: 48),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  ImpactScoreDisplay(
                    pollution: _pollutionScore ?? 80,
                    happiness: _happinessScore ?? 20,
                    costScore: _droppedItems.length.toDouble(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('StreetAI-ability'),
        backgroundColor: const Color(0xFFCEFF00),
        actions:
            isMobile
                ? null
                : [
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/'),
                    child: const Text('Home'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/community'),
                    child: const Text('Community Designs'),
                  ),
                  TextButton(onPressed: () {}, child: const Text('Sign in')),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/about'),
                    child: const Text('About'),
                  ),
                ],
      ),
      drawer:
          isMobile
              ? Drawer(
                child: ListView(
                  children: [
                    const DrawerHeader(child: Text("StreetAI-ability")),
                    ListTile(
                      title: const Text('Home'),
                      onTap: () => Navigator.pushNamed(context, '/'),
                    ),
                    ListTile(
                      title: const Text('Community Designs'),
                      onTap: () => Navigator.pushNamed(context, '/community'),
                    ),
                    ListTile(title: const Text('Sign in'), onTap: () {}),
                    ListTile(
                      title: const Text('About'),
                      onTap: () => Navigator.pushNamed(context, '/about'),
                    ),
                  ],
                ),
              )
              : null,
      body: Row(
        children: [
          if (!isMobile) _buildSidebarTools(),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _searchLocation(),
                    decoration: InputDecoration(
                      hintText: 'Enter street name...',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _searchLocation,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Expanded(child: _buildMapArea()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton:
          isMobile
              ? FloatingActionButton(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                onPressed: _showToolPalette,
                child: const Icon(Icons.build),
              )
              : Padding(
                padding: const EdgeInsets.only(bottom: 24, right: 24),
                child: ElevatedButton(
                  onPressed: _publishDesign,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Publish Your Design'),
                ),
              ),
      bottomNavigationBar:
          isMobile
              ? Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton(
                  onPressed: _publishDesign,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Publish Your Design'),
                ),
              )
              : null,
    );
  }
}

class _DragPayload {
  final String imagePath;
  final String type;

  _DragPayload(this.imagePath, this.type);
}

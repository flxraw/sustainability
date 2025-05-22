// main_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:screenshot/screenshot.dart';

import '../models/dropped_item.dart';
import '../services/score_calculator.dart';
import '../widgets/score_display.dart';
import 'design_detail_screen.dart';

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

    final apiKey = dotenv.env['google_nerv']!;
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(query)}&region=de&key=$apiKey',
    );
    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (data['status'] == 'OK') {
      final loc = data['results'][0]['geometry']['location'];
      final position = LatLng(loc['lat'], loc['lng']);
      _confirmStreetSelection(position);
    } else {
      _showMessage("Adresse nicht gefunden.");
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

  Future<void> _publishDesign() async {
    final Uint8List? imageBytes = await _screenshotController.capture();
    if (imageBytes == null) {
      _showMessage("Failed to capture image.");
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
        'Authorization': 'Bearer ${dotenv.env['OPENAI_API_KEY']}',
      },
      body: jsonEncode({
        'model': 'dall-e-3',
        'prompt': prompt,
        'n': 1,
        'size': '1024x1024',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final imageUrl = data['data'][0]['url'];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DesignDetailScreen(imageUrl: imageUrl),
        ),
      );
    } else {
      _showMessage(
        'Failed to generate image. Status code: ${response.statusCode}',
      );
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
      treeCount: _droppedItems.where((i) => i.type == 'tree').length,
      greenModuleCount: _droppedItems.where((i) => i.type == 'charger').length,
      pollutingModuleCount: 1,
      amenityCount: _droppedItems.where((i) => i.type == 'pedestrians').length,
      greenTransportCount:
          _droppedItems
              .where((i) => i.type == 'bike_lane' || i.type == 'bus_stop')
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

  Widget _buildTool(String type, String icon, String label, String classType) {
    final imagePath = 'assets/icons/$icon.png';
    final widget = Column(
      children: [
        Image.asset(imagePath, width: 40, height: 40),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );

    final bgColor =
        classType == 'green'
            ? Colors.green[800]
            : classType == 'mobility'
            ? Colors.blue[700]
            : Colors.purple[700];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: const Color(0xFFCEFF00),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      children: [
                        TextSpan(text: 'StreetAI-'),
                        TextSpan(
                          text: 'ability\n',
                          style: TextStyle(fontSize: 48),
                        ),
                        TextSpan(
                          text: 'Design your street of tomorrow',
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/'),
                      child: const Text('Home'),
                    ),
                    TextButton(
                      onPressed:
                          () => Navigator.pushNamed(context, '/community'),
                      child: const Text('Community Designs'),
                    ),
                    TextButton(onPressed: () {}, child: const Text('Sign in')),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/about'),
                      child: const Text('About'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // Sidebar
                Container(
                  width: 80,
                  color: Colors.black,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTool('tree', 'Tree', 'Tree', 'green'),
                      _buildTool('charger', 'Charger', 'Charger', 'green'),
                      _buildTool(
                        'pedestrians',
                        'Pedestrians',
                        'People',
                        'mobility',
                      ),
                      _buildTool('bike_lane', 'Bike lane', 'Bike', 'mobility'),
                      _buildTool('bus_stop', 'Bus stop', 'Bus', 'mobility'),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final height = constraints.maxHeight;
                      final streetBounds = Rect.fromLTWH(
                        width * 0.25,
                        0,
                        width * 0.5,
                        height,
                      );

                      return Stack(
                        key: _canvasKey,
                        children: [
                          Screenshot(
                            controller: _screenshotController,
                            child: Stack(
                              children: [
                                GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: _mapCenter,
                                    zoom: 14,
                                  ),
                                  onMapCreated:
                                      (c) => _mapController.complete(c),
                                  myLocationEnabled: true,
                                  zoomControlsEnabled: !_mapLocked,
                                  scrollGesturesEnabled: !_mapLocked,
                                  zoomGesturesEnabled: !_mapLocked,
                                  rotateGesturesEnabled: !_mapLocked,
                                  markers:
                                      _selectedMarker != null
                                          ? {_selectedMarker!}
                                          : {},
                                ),
                                Positioned.fromRect(
                                  rect: streetBounds,
                                  child: IgnorePointer(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        border: Border.all(
                                          color: Colors.green.shade700,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: DragTarget<_DragPayload>(
                                    builder:
                                        (_, __, ___) => const SizedBox.expand(),
                                    onAcceptWithDetails:
                                        (details) => _handleDrop(
                                          details.offset,
                                          details.data.imagePath,
                                          details.data.type,
                                        ),
                                  ),
                                ),
                                ..._droppedItems.map(
                                  (item) => Positioned(
                                    left: item.position.dx - 24,
                                    top: item.position.dy - 24,
                                    child: Image.asset(
                                      item.imagePath,
                                      width: 48,
                                      height: 48,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 16,
                            left: 24,
                            right: 300,
                            child: TextField(
                              controller: _searchController,
                              onSubmitted: (_) => _searchLocation(),
                              style: const TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                hintText: 'Straßenname eingeben...',
                                hintStyle: const TextStyle(
                                  color: Colors.black54,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.search,
                                    color: Colors.black,
                                  ),
                                  onPressed: _searchLocation,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
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
                                  const Text(
                                    'Impact Scores',
                                    style: TextStyle(color: Colors.white),
                                  ),
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
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () {
                    setState(() => _droppedItems.clear());
                    _updateScores();
                  },
                  child: const Text('Reset Elements'),
                ),
                ElevatedButton(
                  onPressed: _publishDesign,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Publish Your Design'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DragPayload {
  final String imagePath;
  final String type;

  _DragPayload(this.imagePath, this.type);
}

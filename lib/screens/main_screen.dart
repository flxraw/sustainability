import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/dropped_item.dart';
import '../services/score_calculator.dart';
import '../services/dalle.dart';
import '../widgets/draggable_icon.dart';
import '../widgets/header_button.dart';
import '../widgets/score_display.dart';
import 'dart:convert';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final TextEditingController _searchController = TextEditingController();
  final List<DroppedItem> _droppedItems = [];

  LatLng _mapCenter = const LatLng(48.137154, 11.576124);
  Marker? _selectedMarker;
  bool _mapLocked = false;
  double? _pollutionScore;
  double? _happinessScore;

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final apiKey = dotenv.env['google_nerv']!;
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(query)}&key=$apiKey',
    );
    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (data['status'] == 'OK') {
      final loc = data['results'][0]['geometry']['location'];
      final position = LatLng(loc['lat'], loc['lng']);
      _confirmStreetSelection(position);
    } else {
      _showMessage("Location not found.");
    }
  }

  Future<void> _confirmStreetSelection(LatLng position) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Confirm Address'),
            content: const Text('Do you want to lock this street for editing?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final controller = await _mapController.future;
      await controller.animateCamera(CameraUpdate.newLatLngZoom(position, 18));

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

  void _handleDrop(Offset offset, Icon icon, String type) {
    final box = context.findRenderObject() as RenderBox;
    final localPos = box.globalToLocal(offset);
    final width = box.size.width;
    final inStreet = localPos.dx >= width * 0.25 && localPos.dx <= width * 0.75;

    if (!inStreet) {
      _showMessage("Drop only allowed on street.");
      return;
    }

    setState(() {
      _droppedItems.add(
        DroppedItem(position: localPos, icon: icon, type: type),
      );
    });

    _updateScores();
  }

  void _updateScores() {
    final score = ScoreCalculator(
      treeCount: _droppedItems.where((i) => i.type == 'tree').length,
      greenModuleCount:
          _droppedItems.where((i) => i.type == 'ev_station').length,
      pollutingModuleCount: 1,
      amenityCount:
          _droppedItems.where((i) => i.type == 'pedestrian_zone').length,
      greenTransportCount:
          _droppedItems
              .where((i) => i.type == 'bike_lane' || i.type == 'bus')
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // HEADER
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
                    HeaderButton(text: 'Design Your Street'),
                    HeaderButton(text: 'Community Designs'),
                    HeaderButton(text: 'Sign in'),
                    HeaderButton(text: 'About'),
                  ],
                ),
              ],
            ),
          ),

          // BODY
          Expanded(
            child: Row(
              children: [
                // SIDEBAR
                Container(
                  width: 260,
                  color: Colors.black,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transformation Element',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTool(
                        'bus',
                        Icons.directions_bus,
                        'MCube\nAutonomous Bus',
                      ),
                      _buildTool(
                        'bike_lane',
                        Icons.directions_bike,
                        'Bike Lane',
                      ),
                      _buildTool(
                        'ev_station',
                        Icons.ev_station,
                        'EV Charging Station',
                      ),
                      _buildTool(
                        'pedestrian_zone',
                        Icons.directions_walk,
                        'Pedestrian Zone',
                      ),
                    ],
                  ),
                ),

                // MAP + CANVAS
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
                        children: [
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _mapCenter,
                              zoom: 14,
                            ),
                            onMapCreated: (c) => _mapController.complete(c),
                            myLocationEnabled: true,
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
                              builder: (_, __, ___) => Container(),
                              onAcceptWithDetails:
                                  (details) => _handleDrop(
                                    details.offset,
                                    details.data.icon,
                                    details.data.type,
                                  ),
                            ),
                          ),
                          ..._droppedItems.map(
                            (item) => Positioned(
                              left: item.position.dx - 24,
                              top: item.position.dy - 24,
                              child: item.icon,
                            ),
                          ),
                          Positioned(
                            top: 16,
                            left: 24,
                            right: 300,
                            child: TextField(
                              controller: _searchController,
                              onSubmitted: (_) => _searchLocation(),
                              decoration: InputDecoration(
                                hintText: 'Enter street address',
                                filled: true,
                                fillColor: Colors.black,
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
                          Positioned(
                            top: 16,
                            right: 16,
                            child: ImpactScoreDisplay(
                              pollution: _pollutionScore ?? 80,
                              happiness: _happinessScore ?? 20,
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

          // BOTTOM BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => setState(() => _droppedItems.clear()),
                      child: const Text('Reset Elements'),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {},
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

  Widget _buildTool(String type, IconData icon, String label) {
    return Draggable<_DragPayload>(
      data: _DragPayload(Icon(icon, size: 40, color: Colors.limeAccent), type),
      feedback: Material(
        color: Colors.transparent,
        child: Icon(icon, size: 40, color: Colors.limeAccent),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: ListTile(
          leading: Icon(icon, color: Colors.limeAccent),
          title: Text(label),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.limeAccent),
        title: Text(label),
      ),
    );
  }
}

class _DragPayload {
  final Icon icon;
  final String type;

  _DragPayload(this.icon, this.type);
}

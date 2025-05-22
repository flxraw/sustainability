import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'dalle.dart';
import 'score.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(const StreetAIbilityApp());
}

class StreetAIbilityApp extends StatelessWidget {
  const StreetAIbilityApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StreetAIbility',
      theme: ThemeData.light(useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const StreetEditorScreen(),
    );
  }
}

class DroppedItem {
  final Offset position;
  final Icon icon;
  final String type;

  DroppedItem({required this.position, required this.icon, required this.type});
}

class StreetEditorScreen extends StatefulWidget {
  const StreetEditorScreen({super.key});
  @override
  State<StreetEditorScreen> createState() => _StreetEditorScreenState();
}

class _StreetEditorScreenState extends State<StreetEditorScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Completer<GoogleMapController> _mapController = Completer();
  final List<DroppedItem> _droppedItems = [];
  LatLng _mapCenter = const LatLng(48.137154, 11.576124);
  Marker? _selectedMarker;
  bool _mapLocked = false;
  int? _pollutionScore;
  int? _happinessScore;

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

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
            content: const Text('Do you want to lock this street?'),
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
        _mapLocked = true;
        _selectedMarker = Marker(
          markerId: const MarkerId('selected'),
          position: position,
        );
      });

      _updateScores();
    }
  }

  void _updateScores() async {
    final tree = _countItems('tree');
    final planter = _countItems('planter');
    final amenity = _countItems('bbq') + _countItems('bench');
    final transport = _countItems('bike') + _countItems('bus');

    final score = ScoreCalculator(
      treeCount: tree,
      greenModuleCount: planter,
      pollutingModuleCount: 1,
      amenityCount: amenity,
      greenTransportCount: transport,
    );

    try {
      final air = await score.calculatePollutionScore(
        _mapCenter.latitude,
        _mapCenter.longitude,
      );
      final happy = score.calculateHappinessScore();
      setState(() {
        _pollutionScore = air;
        _happinessScore = happy;
      });
    } catch (e) {
      _showMessage('Failed to update scores.');
    }
  }

  int _countItems(String type) =>
      _droppedItems.where((e) => e.type == type).length;

  void _handleDrop(Offset pos, Icon icon, String type) {
    final box = context.findRenderObject() as RenderBox;
    final localPos = box.globalToLocal(pos);
    final width = box.size.width;
    final inStreet = localPos.dx >= width * 0.25 && localPos.dx <= width * 0.75;
    if (!inStreet) {
      _showMessage('Drop inside street area only.');
      return;
    }

    setState(
      () => _droppedItems.add(
        DroppedItem(position: localPos, icon: icon, type: type),
      ),
    );
    _updateScores();
  }

  Future<void> _exportDesign() async {
    if (_selectedMarker == null) {
      _showMessage('No street selected.');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final imageBytes = await _fetchStreetImage(_mapCenter);
    if (imageBytes == null) {
      Navigator.pop(context);
      _showMessage('Street image unavailable.');
      return;
    }

    final composite = await _overlayIcons(imageBytes);
    final dalle = DalleService(authToken: dotenv.env['open_nerv']!);
    final imageUrl = await dalle.processImageFromBytes(
      imageBytes: composite,
      promptText:
          'Redesigned urban street with green, mobility, and social features.',
      tempDirPath: Directory.systemTemp.path,
    );

    Navigator.pop(context);

    if (imageUrl != null) {
      _promptSave(imageUrl);
    } else {
      _showMessage('DALL·E generation failed.');
    }
  }

  Future<Uint8List?> _fetchStreetImage(LatLng location) async {
    final apiKey = dotenv.env['google_nerv']!;
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/streetview?size=600x400&location=${location.latitude},${location.longitude}&key=$apiKey',
    );
    final res = await http.get(url);
    return res.statusCode == 200 ? res.bodyBytes : null;
  }

  Future<Uint8List> _overlayIcons(Uint8List baseBytes) async {
    final codec = await ui.instantiateImageCodec(baseBytes);
    final frame = await codec.getNextFrame();
    final baseImage = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..drawImage(baseImage, Offset.zero, Paint());

    for (final item in _droppedItems) {
      final iconImage = await _iconToImage(item.icon);
      canvas.drawImage(iconImage, item.position, Paint());
    }

    final finalImage = await recorder.endRecording().toImage(
      baseImage.width,
      baseImage.height,
    );
    final data = await finalImage.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<ui.Image> _iconToImage(Icon icon) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.icon!.codePoint),
        style: TextStyle(
          fontSize: icon.size ?? 24,
          fontFamily: icon.icon?.fontFamily,
          color: icon.color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    painter.paint(canvas, Offset.zero);
    return await recorder.endRecording().toImage(
      painter.width.ceil(),
      painter.height.ceil(),
    );
  }

  Future<void> _promptSave(String url) async {
    final nameCtrl = TextEditingController();
    final authorCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Save Your Design'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Design Name'),
                ),
                TextField(
                  controller: authorCtrl,
                  decoration: const InputDecoration(labelText: 'Author'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final design = {
        'name': nameCtrl.text,
        'author': authorCtrl.text,
        'pollutionScore': _pollutionScore ?? 0,
        'happinessScore': _happinessScore ?? 0,
        'imageUrl': url,
      };

      final storage = await SharedPreferences.getInstance();
      final designs = storage.getStringList('community_designs') ?? [];
      designs.add(jsonEncode(design));
      await storage.setStringList('community_designs', designs);
      _showMessage('Design saved successfully.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StreetAIbility'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportDesign,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _searchLocation(),
              decoration: InputDecoration(
                hintText: 'Search for a street...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchLocation,
                ),
              ),
            ),
          ),
          if (_pollutionScore != null && _happinessScore != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text('💨 $_pollutionScore    🧘 $_happinessScore'),
            ),
          Expanded(
            child: Row(
              children: [
                _buildSidebar(),
                Expanded(
                  flex: 3,
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
                            onMapCreated:
                                (controller) =>
                                    _mapController.complete(controller),
                            myLocationEnabled: true,
                            scrollGesturesEnabled: !_mapLocked,
                            zoomGesturesEnabled: !_mapLocked,
                            rotateGesturesEnabled: !_mapLocked,
                            tiltGesturesEnabled: !_mapLocked,
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
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 200,
      color: Colors.grey[100],
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: const [
          _DraggableIcon(
            icon: Icon(Icons.park, size: 40, color: Colors.green),
            label: 'Trees',
            type: 'tree',
          ),
          _DraggableIcon(
            icon: Icon(Icons.grass, size: 40, color: Colors.green),
            label: 'Planter',
            type: 'planter',
          ),
          _DraggableIcon(
            icon: Icon(Icons.directions_bike, size: 40, color: Colors.blue),
            label: 'Bike',
            type: 'bike',
          ),
          _DraggableIcon(
            icon: Icon(Icons.bus_alert, size: 40, color: Colors.grey),
            label: 'Bus',
            type: 'bus',
          ),
          _DraggableIcon(
            icon: Icon(Icons.outdoor_grill, size: 40, color: Colors.red),
            label: 'BBQ',
            type: 'bbq',
          ),
          _DraggableIcon(
            icon: Icon(Icons.event_seat, size: 40, color: Colors.brown),
            label: 'Bench',
            type: 'bench',
          ),
        ],
      ),
    );
  }
}

class _DragPayload {
  final Icon icon;
  final String type;
  _DragPayload(this.icon, this.type);
}

class _DraggableIcon extends StatelessWidget {
  final Icon icon;
  final String label;
  final String type;

  const _DraggableIcon({
    required this.icon,
    required this.label,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<_DragPayload>(
      data: _DragPayload(icon, type),
      feedback: Material(color: Colors.transparent, child: icon),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: ListTile(leading: icon, title: Text(label)),
      ),
      child: ListTile(leading: icon, title: Text(label)),
    );
  }
}

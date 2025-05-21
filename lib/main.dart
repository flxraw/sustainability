import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;

import 'dalle.dart';
import 'score.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  if (kIsWeb) {
    final mapKey = dotenv.env['google_nerv'];
    if (mapKey != null) {
      html.window.localStorage['MAP_CREDENTIAL'] = mapKey;
    } else {
      debugPrint("⚠️ 'google_nerv' not found in .env");
    }
  }

  runApp(const StreetAIbilityApp());
}

class StreetAIbilityApp extends StatelessWidget {
  const StreetAIbilityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StreetAIbility',
      theme: ThemeData.light(useMaterial3: true),
      home: const StreetEditorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DroppedItem {
  final Offset position;
  final Icon icon;

  DroppedItem({required this.position, required this.icon});
}

class StreetEditorScreen extends StatefulWidget {
  const StreetEditorScreen({super.key});

  @override
  State<StreetEditorScreen> createState() => _StreetEditorScreenState();
}

class _StreetEditorScreenState extends State<StreetEditorScreen> {
  String? _generatedImageUrl;
  final List<DroppedItem> _droppedItems = [];
  final Completer<GoogleMapController> _mapController = Completer();
  final Set<Marker> _markers = {};
  LatLng _initialPosition = const LatLng(48.137154, 11.576124);
  bool _isMapLocked = false;
  int? _pollutionScore;
  int? _happinessScore;

  Future<void> _generateImage() async {
    const prompt = 'Urban street with trees, no cars, seating and bike lanes';
    final dalle = DalleService(authToken: dotenv.env['open_nerv']!);
    final imageUrl = await dalle.generateImage(prompt);
    if (imageUrl != null) {
      setState(() => _generatedImageUrl = imageUrl);
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("Generated Image"),
              content:
                  kIsWeb
                      ? const Text("Open in new tab.")
                      : Image.network(imageUrl),
              actions: [
                if (kIsWeb)
                  TextButton(
                    onPressed: () => html.window.open(imageUrl, '_blank'),
                    child: const Text("Open"),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Close"),
                ),
              ],
            ),
      );
    }
  }

  Future<void> exportDesign() async {
    if (_markers.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No location selected.')));
      return;
    }

    final location = _markers.first.position;
    final streetViewImage = await fetchStreetImage(location);
    if (streetViewImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Street image could not be loaded.')),
      );
      return;
    }

    final compositeImage = await overlayIconsOnImage(
      streetViewImage,
      _droppedItems,
    );
    final dalle = DalleService(authToken: dotenv.env['open_nerv']!);
    final tempDir = Directory.systemTemp;

    final resultUrl = await dalle.processImageFromBytes(
      imageBytes: compositeImage,
      promptText: 'Refined urban street design with enhancements',
      tempDirPath: tempDir.path,
    );

    if (resultUrl != null) {
      setState(() => _generatedImageUrl = resultUrl);
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("Exported Design"),
              content:
                  kIsWeb
                      ? const Text("Open in new tab.")
                      : Image.network(resultUrl),
              actions: [
                if (kIsWeb)
                  TextButton(
                    onPressed: () => html.window.open(resultUrl, '_blank'),
                    child: const Text("Open"),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Close"),
                ),
              ],
            ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Image processing failed.')));
    }
  }

  Future<Uint8List?> fetchStreetImage(LatLng location) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/streetview'
      '?size=600x400'
      '&location=${location.latitude},${location.longitude}'
      '&key=${dotenv.env['google_nerv']}',
    );
    final response = await http.get(url);
    return response.statusCode == 200 ? response.bodyBytes : null;
  }

  Future<Uint8List> overlayIconsOnImage(
    Uint8List baseImageBytes,
    List<DroppedItem> items,
  ) async {
    final codec = await ui.instantiateImageCodec(baseImageBytes);
    final frame = await codec.getNextFrame();
    final baseImage = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();
    canvas.drawImage(baseImage, Offset.zero, paint);

    for (var item in items) {
      final iconImage = await iconToImage(item.icon);
      canvas.drawImage(iconImage, item.position, paint);
    }

    final picture = recorder.endRecording();
    final resultImage = await picture.toImage(
      baseImage.width,
      baseImage.height,
    );
    final byteData = await resultImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }

  Future<ui.Image> iconToImage(Icon icon) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = TextPainter(
      text: TextSpan(
        text:
            icon.icon != null ? String.fromCharCode(icon.icon!.codePoint) : '',
        style: TextStyle(
          fontSize: icon.size ?? 24,
          fontFamily: icon.icon?.fontFamily,
          package: icon.icon?.fontPackage,
          color: icon.color ?? Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    painter.paint(canvas, Offset.zero);
    final picture = recorder.endRecording();
    return await picture.toImage(painter.width.ceil(), painter.height.ceil());
  }

  void _handleDrop(Offset pos, Icon icon) {
    setState(() {
      _droppedItems.add(DroppedItem(position: pos, icon: icon));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StreetAIbility'),
        actions: [
          IconButton(icon: const Icon(Icons.image), onPressed: _generateImage),
          IconButton(icon: const Icon(Icons.download), onPressed: exportDesign),
        ],
      ),
      body: Column(
        children: [
          if (_pollutionScore != null && _happinessScore != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text(
                    'Pollution Score: $_pollutionScore',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    'Happiness Score: $_happinessScore',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildSidebar()),
                Expanded(flex: 3, child: _buildMapEditor()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('Tools', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        DraggableIconItem(
          icon: Icon(Icons.directions_bike, size: 48, color: Colors.blue),
          label: 'Bike Lane',
        ),
        DraggableIconItem(
          icon: Icon(Icons.park, size: 48, color: Colors.green),
          label: 'Street Trees',
        ),
      ],
    );
  }

  Widget _buildMapEditor() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 14,
              ),
              onMapCreated: (controller) => _mapController.complete(controller),
              markers: _markers,
              myLocationEnabled: true,
              scrollGesturesEnabled: !_isMapLocked,
              zoomGesturesEnabled: !_isMapLocked,
              rotateGesturesEnabled: !_isMapLocked,
              tiltGesturesEnabled: !_isMapLocked,
              onTap: (position) async {
                setState(() {
                  _markers.clear();
                  _markers.add(
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: position,
                    ),
                  );
                });

                final calculator = ScoreCalculator(
                  treeCount:
                      _droppedItems
                          .where((item) => item.icon.icon == Icons.park)
                          .length,
                  greenModuleCount:
                      _droppedItems
                          .where(
                            (item) => item.icon.icon == Icons.directions_bike,
                          )
                          .length,
                  pollutingModuleCount: 1,
                  amenityCount: 2,
                  greenTransportCount: 1,
                );

                try {
                  final pollution = await calculator.calculatePollutionScore(
                    position.latitude,
                    position.longitude,
                  );
                  final happiness = calculator.calculateHappinessScore();

                  setState(() {
                    _pollutionScore = pollution;
                    _happinessScore = happiness;
                  });
                } catch (e) {
                  debugPrint('Error calculating scores: $e');
                }
              },
            ),
            Positioned.fill(
              child: DragTarget<Icon>(
                builder: (context, _, __) => Container(),
                onAcceptWithDetails: (details) {
                  final pos = (context.findRenderObject() as RenderBox)
                      .globalToLocal(details.offset);
                  _handleDrop(pos, details.data);
                },
              ),
            ),
            for (var item in _droppedItems)
              Positioned(
                left: item.position.dx - 24,
                top: item.position.dy - 24,
                child: item.icon,
              ),
          ],
        );
      },
    );
  }
}

class DraggableIconItem extends StatelessWidget {
  final Icon icon;
  final String label;

  const DraggableIconItem({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Draggable<Icon>(
      data: icon,
      feedback: Material(color: Colors.transparent, child: icon),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: ListTile(leading: icon, title: Text(label)),
      ),
      child: ListTile(leading: icon, title: Text(label)),
    );
  }
}

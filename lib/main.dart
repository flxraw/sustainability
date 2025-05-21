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

class DroppedItem {
  final Offset position;
  final Icon icon;

  DroppedItem({required this.position, required this.icon});
}

class CommunityDesign {
  final String name;
  final String author;
  final int pollutionScore;
  final int happinessScore;
  final String imageUrl;

  CommunityDesign({
    required this.name,
    required this.author,
    required this.pollutionScore,
    required this.happinessScore,
    required this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'author': author,
    'pollutionScore': pollutionScore,
    'happinessScore': happinessScore,
    'imageUrl': imageUrl,
  };

  static CommunityDesign fromJson(Map<String, dynamic> json) => CommunityDesign(
    name: json['name'],
    author: json['author'],
    pollutionScore: json['pollutionScore'],
    happinessScore: json['happinessScore'],
    imageUrl: json['imageUrl'],
  );
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
      routes: {'/community': (context) => const CommunityDesignsScreen()},
    );
  }
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
  bool _isMapInitialized = false;
  int? _pollutionScore;
  int? _happinessScore;

  Future<void> exportDesign() async {
    if (_markers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No street selected to export.')),
      );
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
      promptText:
          'A redesigned urban street with trees, bike lanes, and community spaces.',
      tempDirPath: tempDir.path,
    );

    if (resultUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ DALL·E failed to generate an image.')),
      );
      return;
    }

    setState(() => _generatedImageUrl = resultUrl);

    final nameController = TextEditingController();
    final authorController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Save Your Design'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Design Name'),
                ),
                TextField(
                  controller: authorController,
                  decoration: const InputDecoration(labelText: 'Your Name'),
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

    if (saved == true) {
      final design = CommunityDesign(
        name: nameController.text,
        author: authorController.text,
        pollutionScore: _pollutionScore ?? 0,
        happinessScore: _happinessScore ?? 0,
        imageUrl: resultUrl,
      );

      final storage = html.window.localStorage;
      final key = 'community_designs';
      final raw = storage[key];
      final designs =
          raw != null ? List<Map<String, dynamic>>.from(jsonDecode(raw)) : [];
      designs.add(design.toJson());
      storage[key] = jsonEncode(designs);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Design exported and saved!')),
      );
    }
  }

  Future<Uint8List?> fetchStreetImage(LatLng location) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/streetview'
      '?size=600x400&location=${location.latitude},${location.longitude}'
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
        text: String.fromCharCode(icon.icon!.codePoint),
        style: TextStyle(
          fontSize: icon.size ?? 24,
          fontFamily: icon.icon?.fontFamily,
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
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final double streetZoneLeft = size.width * 0.25;
    final double streetZoneRight = size.width * 0.75;
    if (pos.dx >= streetZoneLeft && pos.dx <= streetZoneRight) {
      setState(() => _droppedItems.add(DroppedItem(position: pos, icon: icon)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '❌ Please drop icons within the highlighted street area.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StreetAIbility'),
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: exportDesign),
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () => Navigator.pushNamed(context, '/community'),
          ),
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
        Text(
          'Green',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        SizedBox(height: 8),
        DraggableIconItem(
          icon: Icon(Icons.park, size: 48, color: Colors.green),
          label: 'Street Trees',
        ),
        DraggableIconItem(
          icon: Icon(Icons.grass, size: 48, color: Colors.green),
          label: 'Planters',
        ),
        SizedBox(height: 24),
        Text(
          'Mobility',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        SizedBox(height: 8),
        DraggableIconItem(
          icon: Icon(Icons.directions_bike, size: 48, color: Colors.blue),
          label: 'Bike Lane',
        ),
        DraggableIconItem(
          icon: Icon(Icons.bus_alert, size: 48, color: Colors.blueGrey),
          label: 'Bus Stop',
        ),
        SizedBox(height: 24),
        Text(
          'Social',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        SizedBox(height: 8),
        DraggableIconItem(
          icon: Icon(Icons.outdoor_grill, size: 48, color: Colors.redAccent),
          label: 'BBQ',
        ),
        DraggableIconItem(
          icon: Icon(Icons.event_seat, size: 48, color: Colors.brown),
          label: 'Bench',
        ),
      ],
    );
  }

  Widget _buildMapEditor() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final zoneLeft = width * 0.25;
        final zoneRight = width * 0.75;

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 14,
              ),
              onMapCreated: (controller) {
                _mapController.complete(controller);
                setState(() => _isMapInitialized = true);
              },
              markers: _markers,
              myLocationEnabled: true,
              scrollGesturesEnabled: !_isMapLocked,
              zoomGesturesEnabled: !_isMapLocked,
              rotateGesturesEnabled: !_isMapLocked,
              tiltGesturesEnabled: !_isMapLocked,
              onTap: (position) async {
                if (!_isMapInitialized) return;
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text("Confirm Street Location"),
                        content: const Text(
                          "Do you want to lock this location as your street?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("No"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Yes"),
                          ),
                        ],
                      ),
                );
                if (confirmed != true) return;

                final controller = await _mapController.future;
                controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: position,
                      zoom: 18,
                      tilt: 0,
                      bearing: 0,
                    ),
                  ),
                );

                setState(() {
                  _markers.clear();
                  _markers.add(
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: position,
                    ),
                  );
                  _isMapLocked = true;
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
            Positioned(
              left: zoneLeft,
              top: 0,
              width: zoneRight - zoneLeft,
              height: height,
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

class CommunityDesignsScreen extends StatelessWidget {
  const CommunityDesignsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final raw = html.window.localStorage['community_designs'];
    final List<CommunityDesign> designs =
        raw != null
            ? (jsonDecode(raw) as List)
                .map((e) => CommunityDesign.fromJson(e))
                .toList()
            : [];

    designs.sort(
      (a, b) => (b.happinessScore + b.pollutionScore).compareTo(
        a.happinessScore + a.pollutionScore,
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Community Designs')),
      body: ListView.builder(
        itemCount: designs.length,
        itemBuilder: (context, index) {
          final design = designs[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Image.network(
                design.imageUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
              title: Text(design.name),
              subtitle: Text(
                'By ${design.author} — 🧘 ${design.happinessScore} 💨 ${design.pollutionScore}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Share Design',
                onPressed: () {
                  final link = design.imageUrl;
                  _shareDesign(context, link);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _shareDesign(BuildContext context, String url) {
    html.window.navigator.clipboard
        ?.writeText(url)
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🔗 Link copied to clipboard!')),
          );
        })
        .catchError((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚠️ Could not copy link.')),
          );
        });
  }
}

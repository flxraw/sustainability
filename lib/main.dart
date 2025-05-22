import 'dart:ui' as ui;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:html' as html;
import 'dalle.dart';

void main() {
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
  final TextEditingController _searchController = TextEditingController();
  final Completer<GoogleMapController> _mapController = Completer();
  final Set<Marker> _markers = {};
  LatLng _initialPosition = const LatLng(48.137154, 11.576124);
  bool _isMapLocked = false;

  Future<void> _generateImage() async {
    const prompt =
        'Eine städtische Straße, umgestaltet mit Bäumen links und rechts, ohne Autos, mit einer Sitzecke mit Grill links und einem Fahrradweg rechts, 2-spurig';

    final dalle = DalleService(apiKey: 'api-key-dalle');
    final imageUrl = await dalle.generateImage(prompt);

    setState(() {
      _generatedImageUrl = imageUrl;
    });

    if (imageUrl != null) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("Generiertes Bild"),
              content:
                  kIsWeb
                      ? const Text(
                        "Das Bild kann im neuen Tab geöffnet werden.",
                      )
                      : Image.network(imageUrl),
              actions: [
                if (kIsWeb)
                  TextButton(
                    onPressed: () => html.window.open(imageUrl, '_blank'),
                    child: const Text("Im neuen Tab öffnen"),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Schließen"),
                ),
              ],
            ),
      );
    }
  }

  Future<void> _searchLocation() async {
    final address = _searchController.text.trim();
    if (address.isEmpty) return;

    final apiKey = 'api-key';
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final location = result['geometry']['location'];
          final formattedAddress = result['formatted_address'];
          final latLng = LatLng(location['lat'], location['lng']);

          final isConfirmed = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Confirm Location'),
                  content: Text(
                    'Is this the correct address?\n\n$formattedAddress',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Yes'),
                    ),
                  ],
                ),
          );

          if (isConfirmed == true) {
            setState(() {
              _markers.clear();
              _markers.add(
                Marker(
                  markerId: const MarkerId('searched'),
                  position: latLng,
                  infoWindow: InfoWindow(title: formattedAddress),
                ),
              );
              _isMapLocked = true;
            });

            final controller = await _mapController.future;
            await controller.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: latLng, zoom: 18, bearing: 90),
              ),
            );
          }
        } else {
          _showNotFound();
        }
      } else {
        _showNotFound();
      }
    } catch (_) {
      _showNotFound();
    }
  }

  void _showNotFound() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Address not found.')));
  }

  void _handleDrop(Offset position, Icon icon) {
    setState(() {
      _droppedItems.add(DroppedItem(position: position, icon: icon));
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Design Your Street',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 20),
              TextButton(
                onPressed: () {},
                child: const Text('Community Designs'),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.image),
              tooltip: 'Generate DALL·E Image',
              onPressed: _generateImage,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTabCard()),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _buildMapCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildScoreCard()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: const [
          TabBar(
            labelColor: Colors.black,
            indicatorColor: Colors.black,
            tabs: [Tab(text: 'Mobility'), Tab(text: 'Green')],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: MobilityList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Your Street Canvas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search a street in Google Maps',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _searchLocation,
                      child: const Text('Search'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _initialPosition,
                        zoom: 14,
                      ),
                      onMapCreated: (controller) {
                        _mapController.complete(controller);
                      },
                      markers: _markers,
                      scrollGesturesEnabled: !_isMapLocked,
                      zoomGesturesEnabled: !_isMapLocked,
                      rotateGesturesEnabled: !_isMapLocked,
                      tiltGesturesEnabled: !_isMapLocked,
                      myLocationEnabled: true,
                      zoomControlsEnabled: false,
                    ),
                    Positioned.fill(
                      child: DragTarget<Icon>(
                        builder:
                            (context, _, __) =>
                                CustomPaint(painter: GridPainter(spacing: 20)),
                        onAcceptWithDetails: (details) {
                          final localPosition = (context.findRenderObject()
                                  as RenderBox)
                              .globalToLocal(details.offset);
                          _handleDrop(localPosition, details.data);
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
            ),
          ),
          if (_generatedImageUrl != null && !kIsWeb)
            Container(
              height: 200,
              padding: const EdgeInsets.all(8),
              child: Image.network(_generatedImageUrl!, fit: BoxFit.cover),
            ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Impact Scores',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 24),
            Text('Pollution'),
            LinearProgressIndicator(value: 0.8),
            SizedBox(height: 16),
            Text('Happiness'),
            LinearProgressIndicator(value: 0.2),
          ],
        ),
      ),
    );
  }
}

class MobilityList extends StatelessWidget {
  const MobilityList({super.key});

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      children: [
        ListView(
          children: const [
            DraggableIconItem(
              icon: Icon(Icons.directions_bike, size: 48, color: Colors.blue),
              label: 'Bike Lane',
            ),
          ],
        ),
        ListView(
          children: const [
            DraggableIconItem(
              icon: Icon(Icons.park, size: 48, color: Colors.green),
              label: 'Street Trees',
            ),
            DraggableIconItem(
              icon: Icon(Icons.outdoor_grill, size: 48, color: Colors.brown),
              label: 'BBQ & Seating Area',
            ),
          ],
        ),
      ],
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

class GridPainter extends CustomPainter {
  final double spacing;

  GridPainter({required this.spacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color.fromRGBO(0, 0, 0, 0.1)
          ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

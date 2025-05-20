import 'package:flutter/material.dart';

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

class StreetEditorScreen extends StatelessWidget {
  const StreetEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
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
                child: const Text('Design Your Street', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 20),
              TextButton(
                onPressed: () {},
                child: const Text('Community Designs'),
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Transformation Elements
              Expanded(
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: Colors.black,
                        indicatorColor: Colors.black,
                        tabs: [
                          Tab(text: 'Mobility'),
                          Tab(text: 'Green'),
                          Tab(text: 'Infrastructure'),
                        ],
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: MobilityList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Your Street Canvas
              Expanded(
                flex: 2,
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Your Street Canvas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Enter street address in Munich',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(onPressed: () {}, child: const Text('Search')),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text('Or upload your own street image:'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text('Datei auswählen'),
                        ),
                        const Text('Keine Datei ausgewählt', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Impact Scores
              Expanded(
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Impact Scores', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 24),
                        const Text('Pollution'),
                        LinearProgressIndicator(value: 0.8),
                        const SizedBox(height: 16),
                        const Text('Happiness'),
                        LinearProgressIndicator(value: 0.2),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MobilityList extends StatelessWidget {
  const MobilityList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        ListTile(
          leading: Icon(Icons.directions_bus),
          title: Text('MCube Autonomous Bus'),
          subtitle: Text('Self-driving electric mini-buses...'),
        ),
        ListTile(
          leading: Icon(Icons.directions_bike),
          title: Text('Bike Lane'),
          subtitle: Text('Protected cycling infrastructure...'),
        ),
        ListTile(
          leading: Icon(Icons.ev_station),
          title: Text('EV Charging Station'),
          subtitle: Text('Electric vehicle charging...'),
        ),
        ListTile(
          leading: Icon(Icons.directions_walk),
          title: Text('Pedestrian Zone'),
          subtitle: Text('Car-free areas prioritizing walking...'),
        ),
      ],
    );
  }
}

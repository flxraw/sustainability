import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.black,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'StreetAI-ability',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFCEFF00),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Rethink your street',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D0D0D), Color(0xFF1C1C1C)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Redesign Your Street For a\nSustainable Future',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFCEFF00),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Transform your neighbourhood with our interactive design tool. Add greenery, sustainable transportation, and urban elements.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/main'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCEFF00),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        child: const Text('Design Your Street'),
                      ),
                      OutlinedButton(
                        onPressed:
                            () => Navigator.pushNamed(context, '/community'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFCEFF00)),
                        ),
                        child: const Text('Community Designs'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'How It Works',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),

            // Steps
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: const [
                  _StepBox(
                    step: '1',
                    title: 'Upload Your Street',
                    description:
                        'Upload an image of your street or choose from our gallery.',
                  ),
                  _StepBox(
                    step: '2',
                    title: 'Design & Transform',
                    description:
                        'Drag and drop sustainable elements onto your street.',
                  ),
                  _StepBox(
                    step: '3',
                    title: 'Share & Inspire',
                    description:
                        'Publish and inspire others with your design vision.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Impact Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              color: Colors.grey[50],
              child: Column(
                children: [
                  const Text(
                    'Make a Real Impact',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'StreetAIability isn\'t just a tool – it\'s a platform for change. Your designs could inspire real-world improvements in Munich.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: const [
                      _ImpactCard(
                        title: '🌿 Environmental Benefits',
                        items: [
                          'Reduced carbon emissions',
                          'Improved air quality',
                          'Less noise pollution',
                        ],
                      ),
                      _ImpactCard(
                        title: '💬 Social Benefits',
                        items: [
                          'More community spaces',
                          'Safer streets for all',
                          'Better accessibility and mobility',
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBox extends StatelessWidget {
  final String step;
  final String title;
  final String description;

  const _StepBox({
    required this.step,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFCEFF00),
            child: Text(step, style: const TextStyle(color: Colors.black)),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  final String title;
  final List<String> items;

  const _ImpactCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  Expanded(
                    child: Text(item, style: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

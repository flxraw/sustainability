import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Logo
            Container(
              color: Colors.black,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'StreetAI-ability',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFCEFF00),
                          ),
                        ),
                        TextSpan(
                          text: '\nRethink your street',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
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
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 32, color: Colors.white),
                      children: [
                        TextSpan(text: 'Redesign '),
                        TextSpan(
                          text: 'Your Street',
                          style: TextStyle(
                            color: Color(0xFFCEFF00),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: ' For a\n'),
                        TextSpan(
                          text: 'Sustainable Future',
                          style: TextStyle(
                            color: Color(0xFFCEFF00),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Transform your neighborhood with our interactive design tool. Add greenery, sustainable transportation, and urban elements to create a cleaner, happier urban environment.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/main');
                        },
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
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/community');
                        },
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

            // How It Works
            const Text(
              'How It Works',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _StepBox(
                  step: '1',
                  title: 'Upload Your Street',
                  description:
                      'Upload an image of your street or select from our gallery of Munich locations.',
                ),
                SizedBox(width: 16),
                _StepBox(
                  step: '2',
                  title: 'Design & Transform',
                  description:
                      'Drag and drop sustainable elements to redesign your street according to your vision.',
                ),
                SizedBox(width: 16),
                _StepBox(
                  step: '3',
                  title: 'Share & Inspire',
                  description:
                      'Publish your design, view impact metrics, and inspire others with your vision.',
                ),
              ],
            ),

            const SizedBox(height: 48),

            // Impact Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              color: Colors.grey[50],
              child: Column(
                children: [
                  const Text(
                    'Make a Real Impact',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'StreeAIability isn\'t just a design tool – it\'s a platform for real change. The most popular designs could be considered for implementation in Munich.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      _ImpactCard(
                        title: '🌿 Environmental Benefits',
                        items: [
                          'Reduced carbon emissions from sustainable transportation',
                          'Improved air quality from increased urban greenery',
                          'Less noise pollution and more comfortable living spaces',
                        ],
                      ),
                      SizedBox(width: 16),
                      _ImpactCard(
                        title: '💬 Social Benefits',
                        items: [
                          'More community gathering spaces and social interaction',
                          'Safer streets for children, elderly, and all residents',
                          'Increased accessibility and mobility options for everyone',
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

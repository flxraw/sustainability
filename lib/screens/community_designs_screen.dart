import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/design.dart';

class CommunityDesignsScreen extends StatelessWidget {
  const CommunityDesignsScreen({super.key});

  void _goHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final Box<Design> designBox = Hive.box<Design>('designs');
    final designs = designBox.values.toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.black,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                  OutlinedButton.icon(
                    onPressed: () => _goHome(context),
                    icon: const Icon(Icons.home, color: Color(0xFF60603D)),
                    label: const Text(
                      'Home',
                      style: TextStyle(color: Color(0xFF60603D)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF60603D)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Community Designs',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child:
                  designs.isEmpty
                      ? const Center(child: Text('No designs found.'))
                      : ListView.builder(
                        itemCount: designs.length,
                        itemBuilder: (context, index) {
                          final design = designs[index];
                          final Uint8List imageBytes = base64Decode(
                            design.base64Image,
                          );

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: _DesignCard(
                              design: design,
                              imageBytes: imageBytes,
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesignCard extends StatefulWidget {
  final Design design;
  final Uint8List imageBytes;

  const _DesignCard({required this.design, required this.imageBytes});

  @override
  State<_DesignCard> createState() => _DesignCardState();
}

class _DesignCardState extends State<_DesignCard> {
  int likes = 0;

  void _showImageDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(child: Image.memory(widget.imageBytes)),
    );
  }

  void _launchChangeOrg() async {
    const url = 'https://www.change.org/';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                widget.imageBytes,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.design.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(widget.design.creator, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  '😊 Happiness Score: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(widget.design.happinessScore.toStringAsFixed(1)),
              ],
            ),
            Row(
              children: [
                const Text(
                  '🏭 Pollution Score: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(widget.design.pollutionScore.toStringAsFixed(1)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.thumb_up_alt_outlined),
                  onPressed: () => setState(() => likes++),
                ),
                Text('$likes'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: _showImageDialog,
                ),
                const Text("View"),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _launchChangeOrg,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF60603D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Create Petition',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

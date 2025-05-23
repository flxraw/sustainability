import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/design.dart';

class DesignDetailScreen extends StatefulWidget {
  final String base64Image;
  final double happinessScore;
  final double pollutionScore;

  const DesignDetailScreen({
    super.key,
    required this.base64Image,
    required this.happinessScore,
    required this.pollutionScore,
  });

  @override
  State<DesignDetailScreen> createState() => _DesignDetailScreenState();
}

class _DesignDetailScreenState extends State<DesignDetailScreen> {
  final _nameController = TextEditingController();
  final _creatorController = TextEditingController();
  bool _isSaved = false;

  void _saveDesign() {
    final name = _nameController.text.trim();
    final creator = _creatorController.text.trim();

    if (name.isEmpty || creator.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both name and creator.')),
      );
      return;
    }

    final design = Design(
      name: name,
      creator: creator,
      base64Image: widget.base64Image,
      happinessScore: widget.happinessScore,
      pollutionScore: widget.pollutionScore,
    );

    final box = Hive.box<Design>('designs');
    box.add(design);

    setState(() => _isSaved = true);
    Navigator.pushNamedAndRemoveUntil(context, '/community', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;
    try {
      imageBytes = base64Decode(widget.base64Image);
    } catch (_) {}

    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Your AI-Generated Street Design'),
        leading: BackButton(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        children: [
          if (imageBytes != null)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.memory(
                  imageBytes,
                  height: screenHeight * 0.45,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            const Icon(Icons.broken_image, color: Colors.white, size: 100),

          const SizedBox(height: 32),

          _buildInputField(controller: _nameController, hint: 'Design Name'),
          const SizedBox(height: 20),
          _buildInputField(
            controller: _creatorController,
            hint: 'Creator Name',
          ),

          const SizedBox(height: 28),

          _buildScoreRow('😊', 'Happiness Score', widget.happinessScore),
          const SizedBox(height: 12),
          _buildScoreRow('💬', 'Pollution Score', widget.pollutionScore),

          const SizedBox(height: 40),

          ElevatedButton(
            onPressed: _isSaved ? null : _saveDesign,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCEFF00),
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(36),
              ),
            ),
            child: const Text('Save Design'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        filled: true,
        fillColor: Colors.transparent,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFCEFF00), width: 2),
        ),
      ),
    );
  }

  Widget _buildScoreRow(String emoji, String label, double value) {
    return Row(
      children: [
        Text(
          '$emoji $label:',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value.toStringAsFixed(1),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ],
    );
  }
}

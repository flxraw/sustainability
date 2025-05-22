import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class DesignDetailScreen extends StatelessWidget {
  final String base64Image;

  const DesignDetailScreen({super.key, required this.base64Image});

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;
    try {
      imageBytes = base64Decode(base64Image);
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your AI-Generated Street Design'),
        backgroundColor: Colors.black,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          Center(
            child:
                imageBytes != null
                    ? Image.memory(imageBytes)
                    : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 48,
                          color: Colors.orange,
                        ),
                        SizedBox(height: 8),
                        Text('⚠️ Failed to decode image'),
                      ],
                    ),
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Back to Editor'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

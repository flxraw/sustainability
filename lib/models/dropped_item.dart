import 'package:flutter/material.dart';

class DroppedItem {
  final Offset position;
  final String imagePath;
  final String type;

  DroppedItem({
    required this.position,
    required this.imagePath,
    required this.type,
  });
}

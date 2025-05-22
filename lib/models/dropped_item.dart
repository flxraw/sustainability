import 'package:flutter/material.dart';

class DroppedItem {
  final Offset position;
  final Icon icon;
  final String type;

  DroppedItem({required this.position, required this.icon, required this.type});
}

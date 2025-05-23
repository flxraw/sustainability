import 'package:flutter/material.dart';

class DraggableIcon extends StatelessWidget {
  final String iconPath; // Now expecting asset path instead of IconData
  final String label;
  final String type;
  final void Function(String type)? onDropped;

  const DraggableIcon({
    super.key,
    required this.iconPath,
    required this.label,
    required this.type,
    this.onDropped,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      builder: (context, candidateData, rejectedData) {
        return Draggable<String>(
          data: type,
          feedback: Material(
            color: Colors.transparent,
            child: Image.asset(iconPath, height: 40, width: 40),
          ),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: ListTile(
              leading: Image.asset(iconPath, height: 24, width: 24),
              title: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          child: ListTile(
            leading: Image.asset(iconPath, height: 24, width: 24),
            title: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        );
      },
      onAccept: onDropped,
    );
  }
}

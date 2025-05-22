import 'package:flutter/material.dart';

class DraggableIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final String type;
  final void Function(String type)? onDropped;

  const DraggableIcon({
    super.key,
    required this.icon,
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
            child: Icon(icon, color: Colors.limeAccent, size: 40),
          ),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: ListTile(
              leading: Icon(icon, color: Colors.limeAccent),
              title: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          child: ListTile(
            leading: Icon(icon, color: Colors.limeAccent),
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

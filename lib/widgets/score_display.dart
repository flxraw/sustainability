import 'package:flutter/material.dart';

class ImpactScoreDisplay extends StatelessWidget {
  final double pollution;
  final double happiness;

  const ImpactScoreDisplay({
    super.key,
    required this.pollution,
    required this.happiness,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Impact Scores', style: TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        _ScoreBar(label: 'Pollution', score: pollution),
        const SizedBox(height: 8),
        _ScoreBar(label: 'Happiness', score: happiness),
      ],
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double score;

  const _ScoreBar({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label ${score.toStringAsFixed(0)}%',
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 4),
        Container(
          width: 120,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(6),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: score / 100,
            child: Container(
              decoration: BoxDecoration(
                color: label == 'Pollution' ? Colors.white : Colors.greenAccent,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

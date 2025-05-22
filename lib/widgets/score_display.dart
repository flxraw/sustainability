import 'package:flutter/material.dart';

class ImpactScoreDisplay extends StatelessWidget {
  final double pollution;
  final double happiness;
  final double costScore; // New field

  const ImpactScoreDisplay({
    super.key,
    required this.pollution,
    required this.happiness,
    required this.costScore,
  });

  double _adjustedAQI(double originalAQI, {double treeImpactPercent = 3}) {
    final deltaAQI = (treeImpactPercent / 100) * originalAQI;
    return originalAQI - deltaAQI;
  }

  @override
  Widget build(BuildContext context) {
    final adjustedPollution = _adjustedAQI(pollution);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Impact Scores', style: TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        _ScoreBar(
          label: 'Pollution',
          score: adjustedPollution,
          original: pollution,
        ),
        const SizedBox(height: 8),
        _ScoreBar(label: 'Happiness', score: happiness),
        const SizedBox(height: 8),
        _CostBar(score: costScore),
      ],
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double score;
  final double? original;

  const _ScoreBar({required this.label, required this.score, this.original});

  @override
  Widget build(BuildContext context) {
    final effectiveScore = score.clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label == 'Pollution' && original != null
              ? '$label ${effectiveScore.toStringAsFixed(1)}% ↓ from ${original!.toStringAsFixed(1)}%'
              : '$label ${effectiveScore.toStringAsFixed(1)}%',
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
            widthFactor: effectiveScore / 100,
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

class _CostBar extends StatelessWidget {
  final double score;

  const _CostBar({required this.score});

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cost Impact', style: TextStyle(color: Colors.white)),
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
            widthFactor: clamped / 100,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';

const _moduleLabels = <String, String>{
  'pressure_drop': 'Pressure changes',
  'humidity': 'Humidity',
  'temp_swing': 'Temp swing',
  'air_quality': 'Air quality',
  'sleep_deficit': 'Sleep',
  'hrv_letdown': 'HRV / stress let-down',
  'menstrual_phase': 'Menstrual cycle',
  'refractory': 'Recent attack',
  'alcohol': 'Alcohol',
  'caffeine': 'Caffeine',
  'stress': 'Stress',
  'hydration': 'Hydration',
};

class CorrelationCard extends StatelessWidget {
  final CorrelationResult result;
  const CorrelationCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final label = _moduleLabels[result.exposureId] ?? result.exposureId;
    final fired = result.firedAttackRate;
    final notFired = result.notFiredAttackRate;
    final classification = result.classification;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ClassificationBadge(classification: classification),
                const SizedBox(width: 8),
                Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${(fired.point * 100).round()}% attack rate when this fired '
              '(${fired.trials} days) — '
              'vs ${(notFired.point * 100).round()}% baseline (${notFired.trials} days).',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassificationBadge extends StatelessWidget {
  final CorrelationClassification classification;
  const _ClassificationBadge({required this.classification});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (classification) {
      CorrelationClassification.personalHit =>
        ('Personal hit', BrandColors.bandHigh),
      CorrelationClassification.personalMiss =>
        ('Personal miss', BrandColors.bandLow),
      CorrelationClassification.inconclusive =>
        ('Unclear', BrandColors.sage),
      CorrelationClassification.insufficientData =>
        ('Calibrating', BrandColors.sage),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}

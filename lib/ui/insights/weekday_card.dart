import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/correlation_provider.dart';

const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Attack rate per weekday, with a chip on weekdays whose rate is a
/// statistically-gated personal hit.
class WeekdayCard extends ConsumerWidget {
  const WeekdayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(weekdayResultsProvider);
    return results.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        // Not enough history for a weekday view until most weekdays have
        // a few observations.
        if (!list.any((r) => r.firedAttackRate.trials >= 4)) {
          return const SizedBox.shrink();
        }
        final theme = Theme.of(context);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Attacks by weekday', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (var i = 0; i < list.length; i++)
                  _WeekdayRow(
                    label: _weekdayLabels[i],
                    result: list[i],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  final String label;
  final CorrelationResult result;
  const _WeekdayRow({required this.label, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rate = result.firedAttackRate.point;
    final isHit = result.classification == CorrelationClassification.personalHit;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        SizedBox(
          width: 44,
          child: Text(label,
              style: theme.textTheme.bodySmall!.copyWith(
                  fontWeight: isHit ? FontWeight.bold : FontWeight.normal)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: rate, minHeight: 6),
          ),
        ),
        const SizedBox(width: 8),
        Text('${(rate * 100).round()}%', style: theme.textTheme.bodySmall),
        if (isHit) ...[
          const SizedBox(width: 6),
          Chip(
            label: Text('pattern', style: theme.textTheme.labelSmall),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ]),
    );
  }
}

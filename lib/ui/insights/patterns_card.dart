import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/insights_eligibility_provider.dart';

const _partLabels = {
  DayPart.night: 'Night',
  DayPart.morning: 'Morning',
  DayPart.afternoon: 'Afternoon',
  DayPart.evening: 'Evening',
};

/// Attack-free streaks plus a small time-of-day histogram of attack starts.
class PatternsCard extends ConsumerWidget {
  const PatternsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attacks = ref.watch(recentAttacksProvider);
    return attacks.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        // Bin by LOCAL date wrapped in a UTC-midnight key, matching the
        // heatmap's convention (see insights_screen.dart).
        final attackDays = <DateTime>{};
        for (final a in list) {
          final local = a.startedAt.toLocal();
          attackDays.add(DateTime.utc(local.year, local.month, local.day));
        }
        final d = DateTime.now();
        final today = DateTime.utc(d.year, d.month, d.day);
        final streaks = computeStreaks(
            attackDays: attackDays,
            today: today,
            windowStart: today.subtract(const Duration(days: 90)));
        final parts = attackStartsByDayPart(
            [for (final a in list) Attack(startedAt: a.startedAt.toLocal(), severity: a.severity)]);
        final maxPart = parts.values.fold(0, (a, b) => a > b ? a : b);
        final theme = Theme.of(context);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Patterns', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('${streaks.currentAttackFreeDays} days attack-free '
                    '(longest in 90 days: ${streaks.longestAttackFreeDays})'),
                const SizedBox(height: 12),
                Text('When attacks start', style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                for (final p in DayPart.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      SizedBox(
                          width: 84,
                          child:
                              Text(_partLabels[p]!, style: theme.textTheme.bodySmall)),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                              value: maxPart == 0 ? 0 : parts[p]! / maxPart,
                              minHeight: 6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${parts[p]}', style: theme.textTheme.bodySmall),
                    ]),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

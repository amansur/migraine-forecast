import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/checkin_provider.dart';
import '../../state/insights_eligibility_provider.dart';

/// Next-morning prompt after a high-risk day: one tap logs the outcome
/// either way, closing the feedback loop that calibration and correlations
/// depend on.
class CheckinCard extends ConsumerWidget {
  const CheckinCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompt = ref.watch(checkinPromptProvider);
    final day = prompt.valueOrNull;
    if (day == null) return const SizedBox.shrink();
    return Card(
      key: const Key('checkin-card'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yesterday was a high-risk day',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('Did you get a migraine?'),
            const SizedBox(height: 8),
            Row(children: [
              FilledButton(
                key: const Key('checkin-yes'),
                onPressed: () async {
                  // Deliberately no day_checkins write here: the completed
                  // attack log is what suppresses the prompt (via the
                  // attackYesterday check). If the user backs out of /log,
                  // the card re-shows instead of losing the data point.
                  final local = DateTime(day.year, day.month, day.day, 12);
                  await context.push('/log', extra: local);
                  if (!context.mounted) return;
                  ref.invalidate(recentAttacksProvider);
                  ref.invalidate(checkinPromptProvider);
                },
                child: const Text('Yes'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                key: const Key('checkin-no'),
                onPressed: () async {
                  await ref.read(checkinRepoProvider).record(
                      day: day, hadAttack: false, at: DateTime.now().toUtc());
                  if (!context.mounted) return;
                  ref.invalidate(checkinPromptProvider);
                },
                child: const Text('No'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

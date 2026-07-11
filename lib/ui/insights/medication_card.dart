import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/medication_provider.dart';

const _classPlurals = {
  MedClass.triptan: 'triptans',
  MedClass.simpleAnalgesic: 'pain relievers',
  MedClass.combination: 'combination analgesics',
  MedClass.other: 'abortive medication',
};

String mohWarningText(MohStatus s) {
  final cls = _classPlurals[s.medClass] ?? 'abortive medication';
  return s.level == MohLevel.exceeded
      ? "You've used $cls on ${s.daysUsed} of the last 30 days — at or above "
          'the ICHD-3 medication-overuse threshold (${s.thresholdDays} '
          'days/month). Frequent abortive use can itself sustain headaches; '
          'worth discussing with your clinician.'
      : "You've used $cls on ${s.daysUsed} of the last 30 days — approaching "
          'the ICHD-3 medication-overuse threshold (${s.thresholdDays} '
          'days/month).';
}

/// Medication efficacy ("helped N of M times") + ICHD-3 overuse warning.
class MedicationCard extends ConsumerWidget {
  const MedicationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doses = ref.watch(recentMedicationDosesProvider);
    final moh = ref.watch(mohStatusProvider);
    return doses.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        final mohStatus = moh.asData?.value;
        final showWarning =
            mohStatus != null && mohStatus.level != MohLevel.none;

        // Efficacy per name: rated doses only, at least 3 to say anything.
        final byName = <String, List<MedicationDose>>{};
        for (final d in list) {
          if (d.reliefRating != null) byName.putIfAbsent(d.name, () => []).add(d);
        }
        final efficacy = [
          for (final e in byName.entries)
            if (e.value.length >= 3)
              (
                name: e.key,
                helped: e.value.where((d) => d.reliefRating! >= 1).length,
                rated: e.value.length,
              ),
        ];

        if (!showWarning && efficacy.isEmpty) return const SizedBox.shrink();
        final theme = Theme.of(context);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Medications', style: theme.textTheme.titleMedium),
                if (showWarning) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_outlined,
                          color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(mohWarningText(mohStatus),
                            key: const Key('moh-warning')),
                      ),
                    ],
                  ),
                ],
                for (final e in efficacy) ...[
                  const SizedBox(height: 8),
                  Text('${e.name} — helped ${e.helped} of ${e.rated} times'),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Compact one-line banner for the Today screen; only when approaching or
/// exceeding the ICHD-3 threshold.
class MohBanner extends ConsumerWidget {
  const MohBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moh = ref.watch(mohStatusProvider).asData?.value;
    if (moh == null || moh.level == MohLevel.none) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final cls = _classPlurals[moh.medClass] ?? 'abortive medication';
    return Card(
      key: const Key('moh-banner'),
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Icon(Icons.warning_amber_outlined, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${moh.daysUsed} days of $cls in 30 days '
              '(ICHD-3 threshold: ${moh.thresholdDays}) — see Insights.',
              style: theme.textTheme.bodySmall!
                  .copyWith(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ]),
      ),
    );
  }
}

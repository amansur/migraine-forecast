import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../state/risk_assessment_provider.dart';
import '../../state/settings_provider.dart';
import 'risk_display.dart';
import 'why_chips.dart';

class TomorrowDetailScreen extends ConsumerWidget {
  const TomorrowDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ass = ref.watch(tomorrowRiskAssessmentProvider);
    final mode = ref.watch(riskDisplayModeProvider).asData?.value ?? RiskDisplayMode.gauge;
    final targetDate = ass.asData?.value.targetDate.toLocal();
    final dateStr = targetDate == null ? '' : DateFormat('EEE, MMM d').format(targetDate);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Tomorrow'),
            if (dateStr.isNotEmpty)
              Text(dateStr, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(tomorrowRiskAssessmentProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ass.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('Could not compute risk: $e')),
              ),
              data: (a) {
                final hasChips = a.contributors.any((c) => c.contribution > 0);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: RiskDisplay(assessment: a, mode: mode),
                    ),
                    const SizedBox(height: 16),
                    if (hasChips) WhyChips(contributors: a.contributors),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

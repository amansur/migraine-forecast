import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../state/risk_assessment_provider.dart';
import '../../state/settings_provider.dart';
import 'risk_display.dart';
import 'why_chips.dart';

/// Detail view for a future day. Without [assessment] it shows the live
/// tomorrow provider (refreshable); with one — an outlook day (d+2..d+6) —
/// it renders that assessment directly and titles itself with the weekday.
class TomorrowDetailScreen extends ConsumerWidget {
  final RiskAssessment? assessment;
  const TomorrowDetailScreen({super.key, this.assessment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(riskDisplayModeProvider).asData?.value ?? RiskDisplayMode.gauge;

    final fixed = assessment;
    if (fixed != null) {
      final local = fixed.targetDate.toUtc();
      final title = DateFormat('EEEE').format(DateTime(local.year, local.month, local.day));
      final dateStr = DateFormat('EEE, MMM d').format(DateTime(local.year, local.month, local.day));
      return Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              Text(title),
              Text(dateStr, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [_AssessmentBody(assessment: fixed, mode: mode)],
        ),
      );
    }

    final ass = ref.watch(tomorrowRiskAssessmentProvider);
    final dateStr = DateFormat('EEE, MMM d').format(DateTime.now().add(const Duration(days: 1)));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Tomorrow'),
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
              data: (a) => _AssessmentBody(assessment: a, mode: mode),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssessmentBody extends StatelessWidget {
  final RiskAssessment assessment;
  final RiskDisplayMode mode;
  const _AssessmentBody({required this.assessment, required this.mode});

  @override
  Widget build(BuildContext context) {
    final hasChips = assessment.contributors.any((c) => c.contribution > 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: RiskDisplay(assessment: assessment, mode: mode),
          ),
        ),
        const SizedBox(height: 16),
        if (hasChips) WhyChips(contributors: assessment.contributors),
      ],
    );
  }
}

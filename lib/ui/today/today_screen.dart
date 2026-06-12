import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../state/insights_eligibility_provider.dart';
import '../../state/risk_assessment_provider.dart';
import '../../state/settings_provider.dart';
import 'risk_display.dart';
import 'tomorrow_tile.dart';
import 'why_chips.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ass = ref.watch(riskAssessmentProvider);
    final mode = ref.watch(riskDisplayModeProvider).asData?.value ?? RiskDisplayMode.gauge;
    final dateStr = DateFormat('EEE, MMM d').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Today'),
            Text(dateStr, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        actions: [
          Consumer(builder: (context, ref, _) {
            final eligible = ref.watch(insightsEligibleProvider).asData?.value ?? false;
            if (!eligible) return const SizedBox.shrink();
            return IconButton(
              onPressed: () => context.push('/insights'),
              icon: const Icon(Icons.insights_outlined),
            );
          }),
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(riskAssessmentProvider.notifier).refresh(),
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
                if (a.isOnboarding) {
                  return _OnboardingCard(onSetup: () => context.push('/settings'));
                }
                final hasChips = a.contributors.any((c) => c.contribution > 0);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: RiskDisplay(assessment: a, mode: mode),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const TomorrowTile(),
                    const SizedBox(height: 16),
                    if (hasChips) ...[
                      WhyChips(contributors: a.contributors),
                      const SizedBox(height: 24),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.push('/log'),
                        icon: const Icon(Icons.add),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Log a migraine'),
                        ),
                      ),
                    ),
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

class _OnboardingCard extends StatelessWidget {
  final VoidCallback onSetup;
  const _OnboardingCard({required this.onSetup});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set up your personal risk profile',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Grant location and Health permissions to start seeing risk predictions.'),
            const SizedBox(height: 16),
            FilledButton(onPressed: onSetup, child: const Text('Open Settings')),
          ],
        ),
      ),
    );
  }
}

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../state/cycle_provider.dart';
import '../../state/insights_eligibility_provider.dart';
import '../../state/providers.dart';
import '../../state/risk_assessment_provider.dart';
import '../../state/settings_provider.dart';
import '../cycle/baseline_severity_dialog.dart';
import '../log/log_picker_sheet.dart';
import 'risk_display.dart';
import 'tomorrow_tile.dart';
import 'why_chips.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final granted = ref.read(permissionServiceProvider).locationGranted;
      final ass = ref.read(riskAssessmentProvider);
      if (granted && (ass.asData?.value.isOnboarding ?? false)) {
        ref.read(riskAssessmentProvider.notifier).refresh();
        ref.read(tomorrowRiskAssessmentProvider.notifier).refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ass = ref.watch(riskAssessmentProvider);
    final mode = ref.watch(riskDisplayModeProvider).asData?.value ?? RiskDisplayMode.gauge;
    final dateStr = DateFormat('EEE, MMM d').format(DateTime.now());

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('today-log-fab'),
        icon: const Icon(Icons.add),
        label: const Text('Log'),
        onPressed: () => showModalBottomSheet(
          context: context,
          showDragHandle: false,
          builder: (_) => const LogPickerSheet(),
        ),
      ),
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
                  final granted = ref.read(permissionServiceProvider).locationGranted;
                  if (!granted) {
                    return _OnboardingCard(onSetup: () => context.push('/settings'));
                  } else {
                    return _NoDataCard(onSetup: () => context.push('/settings'));
                  }
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
                    const SizedBox(height: 8),
                    const _PeriodButton(),
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

class _PeriodButton extends ConsumerWidget {
  const _PeriodButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(cycleTrackingEnabledProvider).asData?.value ?? true;
    if (!enabled) return const SizedBox.shrink();
    final current = ref.watch(currentPeriodProvider);
    final inProgress = current != null;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        key: const Key('period-button'),
        icon: Icon(inProgress ? Icons.water_drop : Icons.water_drop_outlined),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(inProgress ? 'End period' : 'Log period'),
        ),
        onPressed: () async {
          final journal = ref.read(journalSourceProvider);
          if (inProgress) {
            await journal.endPeriod(current.startedAt, DateTime.now().toUtc());
            return;
          }
          final severity = await BaselineSeverityDialog.show(context);
          if (severity == null) return;
          await journal.addPeriod(PeriodEvent(
            startedAt: DateTime.now().toUtc(),
            baselineSeverity: severity,
          ));
        },
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

class _NoDataCard extends StatelessWidget {
  final VoidCallback onSetup;
  const _NoDataCard({required this.onSetup});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data unavailable',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('We could not fetch data for your triggers. Please check your network connection or set a manual location in Settings.'),
            const SizedBox(height: 16),
            FilledButton(onPressed: onSetup, child: const Text('Open Settings')),
          ],
        ),
      ),
    );
  }
}

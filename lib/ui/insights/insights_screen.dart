import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../state/backfill_provider.dart';
import '../../state/correlation_provider.dart';
import '../../state/cycle_provider.dart';
import '../../state/insights_eligibility_provider.dart';
import '../../state/providers.dart';
import '../../state/settings_provider.dart';
import '../../state/suggestions_provider.dart';
import '../cycle/baseline_severity_dialog.dart';
import '../shared/contributor_order.dart';
import 'calendar_heatmap.dart';
import 'correlation_card.dart';
import 'phase_ribbon.dart';
import 'suggestion_card.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eligible = ref.watch(insightsEligibleProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: eligible.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (ok) => ok ? const _Body() : const _NotEligible(),
      ),
    );
  }
}

class _NotEligible extends StatelessWidget {
  const _NotEligible();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Calibrating', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Insights will appear after your first logged migraine.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body();

  void _showDayDetail(BuildContext context, DateTime day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DayDetailSheet(day: day),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAttacks = ref.watch(recentAttacksProvider);
    final correlations = ref.watch(correlationResultsProvider);
    final suggestions = ref.watch(suggestionsProvider);
    final backfillProgress = ref.watch(backfillProgressProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (backfillProgress != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _BackfillProgressStrip(
              done: backfillProgress.done,
              total: backfillProgress.total,
            ),
          ),
        Text('Last 8 weeks', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        recentAttacks.when(
          loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Text('Error loading heatmap: $e'),
          data: (attacks) {
            // Build day → max severity map. Bin by LOCAL date (wrapped in
            // a UTC midnight key) so the bucket matches the heatmap tile,
            // which is also keyed off local-now. Binning by UTC date would
            // push attacks logged late-evening (negative offsets) or
            // shortly past midnight (positive offsets) onto the wrong tile.
            final severityByDay = <DateTime, int>{};
            for (final a in attacks) {
              final local = a.startedAt.toLocal();
              final day = DateTime.utc(local.year, local.month, local.day);
              final prev = severityByDay[day] ?? 0;
              if (a.severity > prev) severityByDay[day] = a.severity;
            }
            final d = DateTime.now();
            final now = DateTime.utc(d.year, d.month, d.day);
            // The heatmap window (8 weeks) is intentionally narrower than the
            // correlation engine's 90-day query window — attacks 9+ weeks old
            // still influence correlation results but won't show as cells.
            final windowStart = now.subtract(const Duration(days: 55));
            final cycleOn = ref.watch(cycleTrackingEnabledProvider).asData?.value ?? true;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cycleOn) ...[
                  Consumer(builder: (context, ref, _) {
                    return PhaseRibbon(
                      windowStart: windowStart,
                      windowEnd: now,
                      resolver: (day) => ref.read(dayPhaseProvider(day)),
                    );
                  }),
                  const SizedBox(height: 6),
                ],
                CalendarHeatmap(
                  severityByDay: severityByDay,
                  windowStart: windowStart,
                  windowEnd: now,
                  onTap: (day) => _showDayDetail(context, day),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Text('Trigger correlations', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        correlations.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (results) {
            final shown = results.where((r) =>
                r.classification == CorrelationClassification.personalHit ||
                r.classification == CorrelationClassification.personalMiss).toList();
            if (shown.isEmpty) {
              return const Text('No clear correlations yet — keep logging.');
            }
            return Column(
              children: shown.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CorrelationCard(result: r),
              )).toList(),
            );
          },
        ),
        const SizedBox(height: 24),
        Text('Suggested adjustments', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        suggestions.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => Text('Error: $e'),
          data: (list) {
            if (list.isEmpty) {
              return const Text('No suggestions right now.');
            }
            return Column(
              children: list.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SuggestionCard(suggestion: s, onDismiss: () {}),
              )).toList(),
            );
          },
        ),
      ],
    );
  }
}

class DayDetailSheet extends ConsumerWidget {
  final DateTime day;
  const DayDetailSheet({super.key, required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessment = ref.watch(dayAssessmentProvider(day));
    final attacks = ref.watch(dayAttacksProvider(day));

    final d = DateTime.now();
    // Compare normalized markers (both UTC midnight)
    final todayMarker = DateTime.utc(d.year, d.month, d.day);
    final isToday = day.isAtSameMomentAs(todayMarker);
    
    final dateTitle = isToday
        ? 'Today, ${DateFormat('MMMM d').format(day)}'
        : DateFormat('EEEE, MMMM d').format(day);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              dateTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _CycleRow(day: day),
            const SizedBox(height: 12),
            Text('Risk Assessment', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            assessment.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading assessment: $e'),
              data: (a) {
                if (a == null) return const Text('No risk data recorded for this day.');
                final factors = sortContributorsForDisplay(
                  a.contributors.where((c) => c.contribution > 0),
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score: ${a.score} (${a.band.name})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (factors.isEmpty)
                      const Text('No contributing triggers identified.')
                    else
                      Column(
                        children: factors
                            .map((f) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.info_outline, size: 16, color: Colors.blueGrey),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${f.moduleId}: ${f.explanation}',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Text('Logged Migraines', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            attacks.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading attacks: $e'),
              data: (list) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (list.isEmpty)
                      const Text('No migraines logged on this day.')
                    else
                      ...list.map((a) {
                        final start = DateFormat('jm').format(a.startedAt.toLocal());
                        final endLabel = a.inProgress
                            ? 'In progress'
                            : a.endedAt != null
                                ? DateFormat('jm').format(a.endedAt!.toLocal())
                                : 'No end time recorded';
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Severity ${a.severity}'),
                          subtitle: Text('$start - $endLabel'),
                          leading: const Icon(Icons.bolt, color: Colors.orange),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () {
                                  Navigator.pop(context); // Close sheet
                                  context.push('/log', extra: a);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete record?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                        TextButton(
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete'),
                                    ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await ref.read(journalSourceProvider).deleteAttack(a.startedAt);
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/log', extra: day);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add migraine'),
                    ),
                    _PeriodMarkAction(day: day),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _CycleRow extends ConsumerWidget {
  final DateTime day;
  const _CycleRow({required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(cycleTrackingEnabledProvider).asData?.value ?? true;
    if (!enabled) return const SizedBox.shrink();
    final phase = ref.watch(dayPhaseProvider(day));
    if (phase is PhaseUnknown) return const SizedBox.shrink();

    final (CyclePhase cyclePhase, int dayOfCycle, bool predicted) = switch (phase) {
      PhaseConfirmed(:final phase, :final dayOfCycle) => (phase, dayOfCycle, false),
      PhasePredicted(:final phase, :final dayOfCycle) => (phase, dayOfCycle, true),
      _ => throw StateError('unreachable'),
    };

    final inMenses = cyclePhase == CyclePhase.menses;
    final effectiveSeverity =
        inMenses ? ref.watch(effectiveDaySeverityProvider(day)) : null;

    final phaseName = cyclePhase.name;
    final predictedSuffix = predicted ? ' (predicted)' : '';
    final severitySuffix =
        (inMenses && effectiveSeverity != null) ? ' · Severity $effectiveSeverity' : '';
    final tapSuffix = (inMenses && !predicted) ? ' (tap to adjust)' : '';
    final label =
        'Day $dayOfCycle · ${phaseName[0].toUpperCase()}${phaseName.substring(1)}$severitySuffix$predictedSuffix$tapSuffix';

    final row = Row(
      children: [
        const Icon(Icons.water_drop, size: 16, color: Color(0xFFC15B7A)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: predicted
                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                      : null,
                ),
          ),
        ),
      ],
    );

    if (!inMenses || predicted) {
      return Padding(padding: const EdgeInsets.only(bottom: 4), child: row);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        key: const Key('cycle-row-tap'),
        onTap: () async {
          final v = await BaselineSeverityDialog.show(
            context,
            title: 'Severity for this day',
            initial: effectiveSeverity ?? 5,
          );
          if (v == null) return;
          await ref.read(journalSourceProvider).upsertPeriodDaySeverity(
                PeriodDaySeverity(
                  day: DateTime.utc(day.year, day.month, day.day),
                  severity: v,
                ),
              );
        },
        child: row,
      ),
    );
  }
}

class _PeriodMarkAction extends ConsumerWidget {
  final DateTime day;
  const _PeriodMarkAction({required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(cycleTrackingEnabledProvider).asData?.value ?? true;
    if (!enabled) return const SizedBox.shrink();
    final periods = ref.watch(recentPeriodsProvider).asData?.value ?? const <PeriodEvent>[];
    final dayUtc = DateTime.utc(day.year, day.month, day.day);
    final noon = dayUtc.add(const Duration(hours: 12));

    PeriodEvent? overlap;
    PeriodEvent? openBefore;
    for (final p in periods) {
      final start = DateTime.utc(p.startedAt.year, p.startedAt.month, p.startedAt.day);
      final end = p.endedAt != null
          ? DateTime.utc(p.endedAt!.year, p.endedAt!.month, p.endedAt!.day)
          : start.add(const Duration(days: 4));
      if (!dayUtc.isBefore(start) && !dayUtc.isAfter(end)) {
        overlap = p;
      }
      if (p.endedAt == null && start.isBefore(dayUtc)) {
        openBefore = p;
      }
    }

    final actions = <Widget>[];

    if (openBefore != null) {
      actions.add(TextButton.icon(
        key: const Key('mark-period-end'),
        onPressed: () async {
          await ref
              .read(journalSourceProvider)
              .endPeriod(openBefore!.startedAt, noon);
        },
        icon: const Icon(Icons.water_drop),
        label: const Text('Mark period end'),
      ));
    }

    if (overlap == null && openBefore == null) {
      actions.add(TextButton.icon(
        key: const Key('mark-period-start'),
        onPressed: () async {
          final v = await BaselineSeverityDialog.show(context);
          if (v == null) return;
          await ref.read(journalSourceProvider).addPeriod(PeriodEvent(
                startedAt: noon,
                baselineSeverity: v,
              ));
        },
        icon: const Icon(Icons.water_drop_outlined),
        label: const Text('Mark period start'),
      ));
    }

    if (overlap != null) {
      actions.add(TextButton.icon(
        key: const Key('remove-period'),
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Remove this period?'),
              content: const Text('The period record and any per-day severity overrides inside it will be deleted.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Remove'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await ref.read(journalSourceProvider).deletePeriod(overlap!.startedAt);
          }
        },
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        label: const Text('Remove period', style: TextStyle(color: Colors.red)),
      ));
    }

    if (actions.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: actions);
  }
}

class _BackfillProgressStrip extends StatelessWidget {
  final int done;
  final int total;
  const _BackfillProgressStrip({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : done / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Building history... $done / $total days',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: pct),
      ],
    );
  }
}

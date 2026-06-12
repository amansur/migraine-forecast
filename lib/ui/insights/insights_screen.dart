import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../state/correlation_provider.dart';
import '../../state/insights_eligibility_provider.dart';
import '../../state/providers.dart';
import '../../state/suggestions_provider.dart';
import 'calendar_heatmap.dart';
import 'correlation_card.dart';
import 'suggestion_card.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eligible = ref.watch(insightsEligibleProvider);
    final attackCount = ref.watch(attackCountProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: eligible.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (ok) {
          if (!ok) {
            final count = attackCount.asData?.value ?? 0;
            return _NotEligible(count: count);
          }
          return const _Body();
        },
      ),
    );
  }
}

class _NotEligible extends StatelessWidget {
  final int count;
  const _NotEligible({required this.count});

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
            Text(
              'Insights unlock after you\'ve logged 3 migraines. '
              'You\'ve logged $count so far.',
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
      builder: (_) => _DayDetailSheet(day: day),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAttacks = ref.watch(recentAttacksProvider);
    final correlations = ref.watch(correlationResultsProvider);
    final suggestions = ref.watch(suggestionsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Last 8 weeks', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        recentAttacks.when(
          loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Text('Error loading heatmap: $e'),
          data: (attacks) {
            // Build day → max severity map (UTC midnight keys).
            final severityByDay = <DateTime, int>{};
            for (final a in attacks) {
              final utc = a.startedAt.toUtc();
              final day = DateTime.utc(utc.year, utc.month, utc.day);
              final prev = severityByDay[day] ?? 0;
              if (a.severity > prev) severityByDay[day] = a.severity;
            }
            final d = DateTime.now();
            final now = DateTime.utc(d.year, d.month, d.day);
            // Show 8 weeks (56 days) for a compact, week-aligned view.
            return CalendarHeatmap(
              severityByDay: severityByDay,
              windowStart: now.subtract(const Duration(days: 55)),
              windowEnd: now,
              onTap: (day) => _showDayDetail(context, day),
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

class _DayDetailSheet extends ConsumerWidget {
  final DateTime day;
  const _DayDetailSheet({required this.day});

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
            const SizedBox(height: 24),
            Text('Risk Assessment', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            assessment.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading assessment: $e'),
              data: (a) {
                if (a == null) return const Text('No risk data recorded for this day.');
                final factors = a.contributors.where((c) => c.contribution > 0).toList();
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
                      }).toList(),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/log', extra: day);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add migraine'),
                    ),
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

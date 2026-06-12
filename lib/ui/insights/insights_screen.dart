import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAttacks = ref.watch(recentAttacksProvider);
    final correlations = ref.watch(correlationResultsProvider);
    final suggestions = ref.watch(suggestionsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Last 90 days', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        recentAttacks.when(
          loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Text('Error loading heatmap: $e'),
          data: (attacks) {
            final days = attacks
                .map((a) => DateTime.utc(a.startedAt.year, a.startedAt.month, a.startedAt.day))
                .toSet();
            final now = DateTime.now().toUtc();
            return CalendarHeatmap(
              attackDays: days,
              windowStart: now.subtract(const Duration(days: 89)),
              windowEnd: now,
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

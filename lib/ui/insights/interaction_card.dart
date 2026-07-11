import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/correlation_provider.dart';
import '../shared/module_labels.dart';

/// Trigger pairs whose joint attack rate beats both triggers alone.
/// Deliberately hedged copy: pattern-surfacing, not causal proof.
class InteractionCard extends ConsumerWidget {
  const InteractionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(interactionResultsProvider);
    return results.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        final theme = Theme.of(context);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trigger combinations', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final r in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _InteractionRow(r: r),
                  ),
                Text(
                  'Patterns worth watching, not proof — both triggers together '
                  'preceded attacks more often than either alone.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InteractionRow extends StatelessWidget {
  final InteractionResult r;
  const _InteractionRow({required this.r});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (r.pair.firedAttackRate.point * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${moduleLabel(r.idA)} + ${moduleLabel(r.idB)}',
            style: theme.textTheme.titleSmall),
        Text(
            'Attacks on $pct% of the ${r.pair.firedAttackRate.trials} days '
            'both fired.',
            style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/suggestion_engine.dart';
import '../../state/trigger_flags_provider.dart';
import '../shared/module_labels.dart';

class SuggestionCard extends ConsumerWidget {
  final WeightSuggestion suggestion;
  final VoidCallback onDismiss;
  const SuggestionCard({super.key, required this.suggestion, required this.onDismiss});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = moduleLabel(suggestion.moduleId);
    final increase = suggestion.recommendedOverride > 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(increase ? Icons.trending_up : Icons.trending_down,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
              ],
            ),
            const SizedBox(height: 8),
            Text(suggestion.rationale, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(
                  onPressed: () => _accept(ref),
                  child: Text(increase ? 'Increase weight' : 'Decrease weight'),
                ),
                const SizedBox(width: 12),
                TextButton(onPressed: onDismiss, child: const Text('Not now')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _accept(WidgetRef ref) async {
    final flags = await ref.read(triggerFlagsProvider.future);
    final overrides = Map<String, double>.from(flags.weightOverrides);
    overrides[suggestion.moduleId] = suggestion.recommendedOverride;
    await ref.read(saveTriggerFlagsProvider)(UserTriggerFlags(
      flaggedModuleIds: flags.flaggedModuleIds,
      weightOverrides: overrides,
    ));
  }
}

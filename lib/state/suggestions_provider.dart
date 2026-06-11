import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/suggestion_engine.dart';
import 'correlation_provider.dart';
import 'trigger_flags_provider.dart';

final suggestionEngineProvider = Provider<SuggestionEngine>((_) => const SuggestionEngine());

final suggestionsProvider = FutureProvider<List<WeightSuggestion>>((ref) async {
  final results = await ref.watch(correlationResultsProvider.future);
  final flags = await ref.watch(triggerFlagsProvider.future);
  final engine = ref.watch(suggestionEngineProvider);
  return engine.suggestionsFor(
    results: results,
    currentOverrides: flags.weightOverrides,
    dismissedAt: const {},
    now: DateTime.now().toUtc(),
  );
});

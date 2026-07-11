import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'trigger_flags_provider.dart';

/// Risk for days d+2..d+6. Computed on demand, never persisted: stored
/// assessments feed correlation + calibration, which must only contain
/// today/tomorrow rows (AssessmentRepository.save enforces this). The first
/// ContextBuilder.build fetches the 7-day series once; the remaining days
/// hit the coverage-aware weather cache.
final outlookProvider = FutureProvider<List<RiskAssessment>>((ref) async {
  await ref.watch(triggerFlagsProvider.future);
  final builder = ref.read(contextBuilderProvider);
  final cfg = await ref.read(rulesConfigProvider.future);
  final engine = ref.read(riskEngineProvider);
  final now = DateTime.now();
  final today = DateTime.utc(now.year, now.month, now.day);
  final out = <RiskAssessment>[];
  for (var i = 2; i <= 6; i++) {
    final ctx =
        await builder.build(now: now.toUtc(), target: today.add(Duration(days: i)));
    out.add(engine.evaluate(ctx, cfg, horizon: RiskHorizon.outlook));
  }
  return out;
});

import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

final riskAssessmentProvider =
    AsyncNotifierProvider<RiskAssessmentNotifier, RiskAssessment>(RiskAssessmentNotifier.new);

class RiskAssessmentNotifier extends AsyncNotifier<RiskAssessment> {
  @override
  Future<RiskAssessment> build() async {
    return _compute();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_compute);
  }

  Future<RiskAssessment> _compute() async {
    final builder = ref.read(contextBuilderProvider);
    final cfg = await ref.read(rulesConfigProvider.future);
    final engine = ref.read(riskEngineProvider);
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final ctx = await builder.build(now: now, target: today);
    final ass = engine.evaluate(ctx, cfg, horizon: RiskHorizon.today);
    await ref.read(assessmentRepoProvider).save(ass);
    return ass;
  }
}

final tomorrowRiskAssessmentProvider =
    AsyncNotifierProvider<TomorrowRiskAssessmentNotifier, RiskAssessment>(TomorrowRiskAssessmentNotifier.new);

class TomorrowRiskAssessmentNotifier extends AsyncNotifier<RiskAssessment> {
  @override
  Future<RiskAssessment> build() async {
    return _compute();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_compute);
  }

  Future<RiskAssessment> _compute() async {
    final builder = ref.read(contextBuilderProvider);
    final cfg = await ref.read(rulesConfigProvider.future);
    final engine = ref.read(riskEngineProvider);
    final now = DateTime.now().toUtc();
    final tomorrow = DateTime.utc(now.year, now.month, now.day).add(const Duration(days: 1));
    final ctx = await builder.build(now: now, target: tomorrow);
    final ass = engine.evaluate(ctx, cfg, horizon: RiskHorizon.tomorrow);
    await ref.read(assessmentRepoProvider).save(ass);
    return ass;
  }
}

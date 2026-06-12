import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'trigger_flags_provider.dart';

final riskAssessmentProvider =
    AsyncNotifierProvider<RiskAssessmentNotifier, RiskAssessment>(RiskAssessmentNotifier.new);

class RiskAssessmentNotifier extends AsyncNotifier<RiskAssessment> {
  @override
  Future<RiskAssessment> build() async {
    await ref.watch(triggerFlagsProvider.future);
    return _compute();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_compute);
  }

  Future<RiskAssessment> backfill(DateTime target) async {
    final builder = ref.read(contextBuilderProvider);
    final cfg = await ref.read(rulesConfigProvider.future);
    final engine = ref.read(riskEngineProvider);

    // For backfill, 'now' should be the end of the target day to ensure we get a full snapshot.
    final d = target.toUtc();
    final endOfDay = DateTime.utc(d.year, d.month, d.day, 23, 59, 59);

    final ctx = await builder.build(now: endOfDay, target: target.toUtc());
    final raw = engine.evaluate(ctx, cfg, horizon: RiskHorizon.today);
    final ass = RiskAssessment(
      score: raw.score,
      band: raw.band,
      contributors: raw.contributors,
      computedAt: raw.computedAt,
      configVersion: raw.configVersion,
      targetDate: raw.targetDate,
      horizon: raw.horizon,
      backfilled: true,
    );
    await ref.read(assessmentRepoProvider).save(ass);
    return ass;
  }

  Future<RiskAssessment> _compute() async {
    final builder = ref.read(contextBuilderProvider);
    final cfg = await ref.read(rulesConfigProvider.future);
    final engine = ref.read(riskEngineProvider);
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final ctx = await builder.build(now: now.toUtc(), target: today);
    final ass = engine.evaluate(ctx, cfg, horizon: RiskHorizon.today);
    await ref.read(assessmentRepoProvider).save(ass);
    final enabled = await ref.read(settingsRepoProvider).getBool('notifications_enabled');
    await ref.read(highRiskNotifierProvider).maybeNotify(ass, enabled: enabled);
    return ass;
  }
}

final tomorrowRiskAssessmentProvider =
    AsyncNotifierProvider<TomorrowRiskAssessmentNotifier, RiskAssessment>(TomorrowRiskAssessmentNotifier.new);

class TomorrowRiskAssessmentNotifier extends AsyncNotifier<RiskAssessment> {
  @override
  Future<RiskAssessment> build() async {
    await ref.watch(triggerFlagsProvider.future);
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
    final now = DateTime.now();
    final tomorrow = DateTime.utc(now.year, now.month, now.day).add(const Duration(days: 1));
    final ctx = await builder.build(now: now.toUtc(), target: tomorrow);
    final ass = engine.evaluate(ctx, cfg, horizon: RiskHorizon.tomorrow);
    await ref.read(assessmentRepoProvider).save(ass);
    final enabled = await ref.read(settingsRepoProvider).getBool('notifications_enabled');
    await ref.read(highRiskNotifierProvider).maybeNotify(ass, enabled: enabled);
    return ass;
  }
}

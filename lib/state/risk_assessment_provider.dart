import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'correlation_provider.dart';
import 'insights_eligibility_provider.dart';
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

  /// Re-evaluates and persists the risk assessment for [day] using the current
  /// location override (if any). Call this after setting or clearing an override
  /// via [LocationOverridesRepo] so the stored assessment and UI reflect the
  /// corrected location.
  ///
  /// Steps:
  /// 1. Force-refresh weather for the override location (or live location when
  ///    clearing) so the cache contains fresh data for [day].
  /// 2. Re-build the EvaluationContext anchored to [day].
  /// 3. Evaluate risk → upsert into RiskAssessments (the v5 unique index
  ///    on (target_date, horizon) ensures an existing row is replaced).
  /// 4. Invalidate downstream providers so the UI picks up the new values.
  Future<void> recalculateForDay(DateTime day) async {
    final overridesRepo = ref.read(locationOverridesRepoProvider);
    final weatherSource = ref.read(weatherSourceProvider);
    final locationSource = ref.read(locationSourceProvider);
    final builder = ref.read(contextBuilderProvider);
    final cfg = await ref.read(rulesConfigProvider.future);
    final engine = ref.read(riskEngineProvider);

    final dayUtc = day.toUtc();
    final targetUtc = DateTime.utc(dayUtc.year, dayUtc.month, dayUtc.day);
    final endOfDay = DateTime.utc(dayUtc.year, dayUtc.month, dayUtc.day, 23, 59, 59);

    // Resolve effective location (override or live).
    final overrideLoc = await overridesRepo.forDay(targetUtc);
    final loc = overrideLoc ?? await locationSource.current();

    // Force-refresh weather so the cache contains data for the override location.
    if (loc != null) {
      try {
        await weatherSource.fetch(
          lat: loc.lat,
          lon: loc.lon,
          now: targetUtc,
          forceRefresh: true,
        );
      } catch (_) {
        // Degraded: continue with whatever cache exists; assessment may lack weather.
      }
    }

    final ctx = await builder.build(now: endOfDay, target: targetUtc);
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

    // Invalidate downstream providers so the UI picks up the refreshed data.
    ref.invalidate(dayAssessmentProvider(targetUtc));
    ref.invalidate(correlationResultsProvider);
    ref.invalidate(recentAttacksProvider);
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

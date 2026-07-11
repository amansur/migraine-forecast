import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repos/correlation_repo.dart';
import '../data/repos/day_timeline_repo.dart';
import 'insights_eligibility_provider.dart';
import 'providers.dart';

const _moduleIds = [
  'pressure_drop',
  'humidity',
  'temp_swing',
  'air_quality',
  'sleep_deficit',
  'hrv_letdown',
  'menstrual_phase',
  'refractory',
  'alcohol',
  'caffeine',
  'stress',
  'hydration',
  'intraday_pressure_swing',
];

final correlationRepoProvider = Provider<CorrelationRepo>((ref) {
  return CorrelationRepo(ref.watch(databaseProvider));
});

final dayTimelineRepoProvider =
    Provider<DayTimelineRepo>((ref) => DayTimelineRepo(ref.watch(databaseProvider)));

/// Trailing-90-day timeline of COMPLETED days, shared by the
/// correlation-family analyses (calibration, weekday patterns, interactions).
///
/// Today (still in progress) and tomorrow (forecast-only row) are trimmed
/// here: an unfinished day always reads hadAttack=false and would deflate
/// every rate computed downstream. Day keys are local calendar days wrapped
/// in UTC midnights (see RiskAssessmentNotifier._compute), so "today" is
/// derived from local wall-clock components.
final dayTimelineProvider = FutureProvider<List<DayRecord>>((ref) async {
  ref.watch(recentAttacksProvider); // re-run when attacks change
  final now = DateTime.now();
  final todayKey = DateTime.utc(now.year, now.month, now.day);
  final timeline = await ref.watch(dayTimelineRepoProvider).buildTimeline(
        windowStart: now.toUtc().subtract(const Duration(days: 90)),
        windowEnd: now.toUtc().add(const Duration(days: 1)),
      );
  return [
    for (final d in timeline)
      if (d.day.isBefore(todayKey)) d,
  ];
});

/// Attack-rate correlation per weekday (Monday-first, exposureId
/// 'weekday_1'..'weekday_7') over the shared timeline. Display-only —
/// never feed these into the SuggestionEngine (see its precondition).
final weekdayResultsProvider = FutureProvider<List<CorrelationResult>>((ref) async {
  final timeline = await ref.watch(dayTimelineProvider.future);
  return [
    for (var wd = DateTime.monday; wd <= DateTime.sunday; wd++)
      const CorrelationAnalyzer().analyze(buildCohort(timeline, Exposure.weekday(wd))),
  ];
});

/// Conservative pairwise trigger-interaction scan over the shared timeline.
/// Display-only — never feed these into the SuggestionEngine.
///
/// Excludes 'refractory' (internal post-attack damping, not a lifestyle
/// trigger) and 'intraday_pressure_swing' (redundantly pairs with
/// pressure_drop) — same rationale as the settings flag list.
final interactionResultsProvider = FutureProvider<List<InteractionResult>>((ref) async {
  final timeline = await ref.watch(dayTimelineProvider.future);
  final ids = [
    for (final id in _moduleIds)
      if (id != 'refractory' && id != 'intraday_pressure_swing') id,
  ];
  return analyzeInteractions(timeline, ids);
});

final correlationResultsProvider = FutureProvider<List<CorrelationResult>>((ref) async {
  // Watch recentAttacksProvider to re-run when attacks change
  ref.watch(recentAttacksProvider);

  final repo = ref.watch(correlationRepoProvider);
  final now = DateTime.now().toUtc();
  final cohorts = await repo.buildCohorts(
    windowStart: now.subtract(const Duration(days: 90)),
    windowEnd: now.add(const Duration(days: 1)),
    moduleIds: _moduleIds,
  );
  return cohorts.map((c) => const CorrelationAnalyzer().analyze(c)).toList();
});

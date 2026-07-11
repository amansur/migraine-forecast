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

/// Trailing-90-day timeline shared by the correlation-family analyses
/// (module correlations, calibration, weekday patterns, interactions).
final dayTimelineProvider = FutureProvider<List<DayRecord>>((ref) async {
  ref.watch(recentAttacksProvider); // re-run when attacks change
  final now = DateTime.now().toUtc();
  return ref.watch(dayTimelineRepoProvider).buildTimeline(
        windowStart: now.subtract(const Duration(days: 90)),
        windowEnd: now.add(const Duration(days: 1)),
      );
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

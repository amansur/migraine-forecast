import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repos/correlation_repo.dart';
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
];

final correlationRepoProvider = Provider<CorrelationRepo>((ref) {
  return CorrelationRepo(ref.watch(databaseProvider));
});

final correlationResultsProvider = FutureProvider<List<CorrelationResult>>((ref) async {
  final repo = ref.watch(correlationRepoProvider);
  final now = DateTime.now().toUtc();
  final cohorts = await repo.buildCohorts(
    windowStart: now.subtract(const Duration(days: 90)),
    windowEnd: now.add(const Duration(days: 1)),
    moduleIds: _moduleIds,
  );
  return cohorts.map((c) => const CorrelationAnalyzer().analyze(c)).toList();
});

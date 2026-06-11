import 'package:domain/domain.dart';
import 'package:health/health.dart';

import 'health_source.dart';

class HealthPackageSource implements HealthSource {
  final Health _health;
  final Set<HealthCategory> _granted = {};

  HealthPackageSource({Health? health}) : _health = health ?? Health();

  static const _typeMap = <HealthCategory, List<HealthDataType>>{
    HealthCategory.sleep: [
      HealthDataType.SLEEP_SESSION,
      HealthDataType.SLEEP_IN_BED,
    ],
    HealthCategory.hrv: [HealthDataType.HEART_RATE_VARIABILITY_SDNN],
    HealthCategory.menstrual: [HealthDataType.MENSTRUATION_FLOW],
  };

  @override
  Set<HealthCategory> get grantedCategories => Set.of(_granted);

  @override
  Future<Set<HealthCategory>> requestPermissions(Set<HealthCategory> categories) async {
    final types = categories.expand((c) => _typeMap[c] ?? const <HealthDataType>[]).toList();
    final permissions = List.filled(types.length, HealthDataAccess.READ);
    final granted = await _health.requestAuthorization(types, permissions: permissions);
    if (granted) {
      _granted.addAll(categories);
    }
    return Set.of(_granted).intersection(categories);
  }

  @override
  Future<HealthMetrics> recentMetrics({required Duration window}) async {
    final end = DateTime.now();
    final start = end.subtract(window);
    final sleep = _granted.contains(HealthCategory.sleep) ? await _fetchSleep(start, end) : <SleepRecord>[];
    final hrv = _granted.contains(HealthCategory.hrv) ? await _fetchHrv(start, end) : <HrvSample>[];
    final menstrual = _granted.contains(HealthCategory.menstrual) ? await _fetchMenstrual(start, end) : <MenstrualEvent>[];
    return HealthMetrics(recentSleep: sleep, recentHrv: hrv, menstrualHistory: menstrual);
  }

  Future<List<SleepRecord>> _fetchSleep(DateTime start, DateTime end) async {
    try {
      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.SLEEP_SESSION, HealthDataType.SLEEP_IN_BED],
      );
      final byNight = <DateTime, List<HealthDataPoint>>{};
      for (final p in points) {
        final night = DateTime.utc(p.dateFrom.year, p.dateFrom.month, p.dateFrom.day);
        byNight.putIfAbsent(night, () => []).add(p);
      }
      return byNight.entries.map((e) {
        final session = e.value.firstWhere(
          (p) => p.type == HealthDataType.SLEEP_SESSION,
          orElse: () => e.value.first,
        );
        final inBed = e.value.firstWhere(
          (p) => p.type == HealthDataType.SLEEP_IN_BED,
          orElse: () => session,
        );
        final totalSleep = session.dateTo.difference(session.dateFrom);
        final inBedDuration = inBed.dateTo.difference(inBed.dateFrom);
        final efficiency = inBedDuration.inMinutes == 0
            ? 1.0
            : totalSleep.inMinutes / inBedDuration.inMinutes;
        return SleepRecord(
          night: e.key,
          totalSleep: totalSleep,
          efficiency: efficiency.clamp(0.0, 1.0).toDouble(),
          sleepStart: session.dateFrom,
        );
      }).toList()
        ..sort((a, b) => b.night.compareTo(a.night));
    } catch (_) {
      return const [];
    }
  }

  Future<List<HrvSample>> _fetchHrv(DateTime start, DateTime end) async {
    try {
      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: const [HealthDataType.HEART_RATE_VARIABILITY_SDNN],
      );
      return points
          .map((p) => HrvSample(
                at: p.dateFrom,
                rmssdMs: (p.value as NumericHealthValue).numericValue.toDouble(),
              ))
          .toList()
        ..sort((a, b) => b.at.compareTo(a.at));
    } catch (_) {
      return const [];
    }
  }

  Future<List<MenstrualEvent>> _fetchMenstrual(DateTime start, DateTime end) async {
    try {
      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: const [HealthDataType.MENSTRUATION_FLOW],
      );
      // Detect onsets: first flow record per >2-day gap.
      final dates = points.map((p) => DateTime.utc(p.dateFrom.year, p.dateFrom.month, p.dateFrom.day)).toSet().toList()
        ..sort();
      final onsets = <DateTime>[];
      for (var i = 0; i < dates.length; i++) {
        if (i == 0 || dates[i].difference(dates[i - 1]).inDays > 2) {
          onsets.add(dates[i]);
        }
      }
      return onsets.map((d) => MenstrualEvent(onsetDate: d)).toList()
        ..sort((a, b) => b.onsetDate.compareTo(a.onsetDate));
    } catch (_) {
      return const [];
    }
  }
}

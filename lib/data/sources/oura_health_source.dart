import 'package:domain/domain.dart';
import 'package:drift/drift.dart' show Value;

import '../database.dart' as db;
import '../models/oura_models.dart';
import 'health_source.dart';
import 'oura_api_client.dart';
import 'oura_auth_manager.dart';

class OuraHealthSource implements HealthSource {
  final OuraAuthManager authManager;
  final OuraApiClient apiClient;
  final db.AppDatabase database;

  OuraHealthSource({
    required this.authManager,
    required this.apiClient,
    required this.database,
  });

  @override
  Set<HealthCategory> get grantedCategories => {
        HealthCategory.sleep,
        HealthCategory.hrv,
      };

  @override
  Future<Set<HealthCategory>> requestPermissions(Set<HealthCategory> categories) async {
    return grantedCategories.intersection(categories);
  }

  @override
  Future<HealthMetrics> recentMetrics({required Duration window}) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(window);

    try {
      final results = await Future.wait([
        apiClient.getSleep(startDate: startDate, endDate: endDate),
        apiClient.getDailySleep(startDate: startDate, endDate: endDate),
        apiClient.getActivity(startDate: startDate, endDate: endDate),
        apiClient.getReadiness(startDate: startDate, endDate: endDate),
      ]);

      final sleep = results[0] as OuraSleepData;
      final dailySleep = results[1] as OuraDailySleepData;
      final activity = results[2] as OuraActivityData;
      final readiness = results[3] as OuraReadinessData;

      final now = DateTime.now();

      // Persist to cache.
      if (sleep.records.isNotEmpty) {
        await database.upsertOuraSleep(sleep.records.map((r) => db.OuraSleepCompanion(
              id: Value(r.id),
              day: Value(DateTime.parse('${r.day}T00:00:00Z')),
              lowestHeartRate: Value(r.lowestHeartRate),
              restlessPeriods: Value(r.restlessPeriods),
              averageHeartRate: Value(r.averageHeartRate?.round()),
              averageHrv: Value(r.averageHrv),
              fetchedAt: Value(now),
            )).toList());
      }

      if (dailySleep.records.isNotEmpty) {
        await database.upsertOuraDailySleep(dailySleep.records.map((r) => db.OuraDailySleepCompanion(
              id: Value(r.id),
              day: Value(DateTime.parse('${r.day}T00:00:00Z')),
              score: Value(r.score),
              fetchedAt: Value(now),
            )).toList());
      }

      if (activity.records.isNotEmpty) {
        await database.upsertOuraActivity(activity.records.map((r) => db.OuraActivityCompanion(
              id: Value(r.id),
              day: Value(DateTime.parse('${r.day}T00:00:00Z')),
              activityScore: Value(r.score),
              fetchedAt: Value(now),
            )).toList());
      }

      if (readiness.records.isNotEmpty) {
        await database.upsertOuraReadiness(readiness.records.map((r) => db.OuraReadinessCompanion(
              id: Value(r.id),
              day: Value(DateTime.parse('${r.day}T00:00:00Z')),
              readinessScore: Value(r.score),
              temperatureDeviation: Value(r.temperatureDeviation),
              fetchedAt: Value(now),
            )).toList());
      }

      return _buildFromApi(sleep, dailySleep, activity, readiness, now);
    } on OuraAuthException {
      rethrow;
    } catch (e) {
      // RateLimitException or any other transient failure — try cache.
      final cached = await _buildFromCache(window);
      if (cached != null) return cached;
      rethrow;
    }
  }

  HealthMetrics _buildFromApi(
    OuraSleepData sleep,
    OuraDailySleepData dailySleep,
    OuraActivityData activity,
    OuraReadinessData readiness,
    DateTime fetchedAt,
  ) {
    final mostRecentSleep = sleep.records.isNotEmpty
        ? (sleep.records.toList()..sort((a, b) => b.day.compareTo(a.day))).first
        : null;
    final mostRecentDailySleep = dailySleep.records.isNotEmpty
        ? (dailySleep.records.toList()..sort((a, b) => b.day.compareTo(a.day))).first
        : null;
    final mostRecentActivity = activity.records.isNotEmpty
        ? (activity.records.toList()..sort((a, b) => b.day.compareTo(a.day))).first
        : null;
    final mostRecentReadiness = readiness.records.isNotEmpty
        ? (readiness.records.toList()..sort((a, b) => b.day.compareTo(a.day))).first
        : null;

    return HealthMetrics(
      sleepScore: mostRecentDailySleep?.score,
      lowestHeartRate: mostRecentSleep?.lowestHeartRate,
      sleepInterruptions: mostRecentSleep?.restlessPeriods,
      activityScore: mostRecentActivity?.score,
      readinessScore: mostRecentReadiness?.score,
      temperatureDeviation: mostRecentReadiness?.temperatureDeviation,
      averageHeartRate: mostRecentSleep?.averageHeartRate,
      averageHrv: mostRecentSleep?.averageHrv,
      source: DataSource.oura,
      lastFetched: fetchedAt,
    );
  }

  Future<HealthMetrics?> _buildFromCache(Duration window) async {
    final sleepRows = await database.recentOuraSleep(window: window);
    final dailySleepRows = await database.recentOuraDailySleep(window: window);
    final activityRows = await database.recentOuraActivity(window: window);
    final readinessRows = await database.recentOuraReadiness(window: window);

    if (sleepRows.isEmpty &&
        dailySleepRows.isEmpty &&
        activityRows.isEmpty &&
        readinessRows.isEmpty) {
      return null;
    }

    final mostRecentSleep = sleepRows.isNotEmpty ? sleepRows.first : null;
    final mostRecentDailySleep = dailySleepRows.isNotEmpty ? dailySleepRows.first : null;
    final mostRecentActivity = activityRows.isNotEmpty ? activityRows.first : null;
    final mostRecentReadiness = readinessRows.isNotEmpty ? readinessRows.first : null;

    // lastFetched = most recent fetchedAt across all cached rows.
    final allFetchedAts = [
      if (mostRecentSleep != null) mostRecentSleep.fetchedAt,
      if (mostRecentDailySleep != null) mostRecentDailySleep.fetchedAt,
      if (mostRecentActivity != null) mostRecentActivity.fetchedAt,
      if (mostRecentReadiness != null) mostRecentReadiness.fetchedAt,
    ];
    final lastFetched = allFetchedAts.reduce((a, b) => a.isAfter(b) ? a : b);

    return HealthMetrics(
      sleepScore: mostRecentDailySleep?.score,
      lowestHeartRate: mostRecentSleep?.lowestHeartRate,
      sleepInterruptions: mostRecentSleep?.restlessPeriods,
      activityScore: mostRecentActivity?.activityScore,
      readinessScore: mostRecentReadiness?.readinessScore,
      temperatureDeviation: mostRecentReadiness?.temperatureDeviation,
      averageHeartRate: mostRecentSleep?.averageHeartRate?.toDouble(),
      averageHrv: mostRecentSleep?.averageHrv,
      source: DataSource.oura,
      lastFetched: lastFetched,
    );
  }
}

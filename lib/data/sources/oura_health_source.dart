import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

import '../models/oura_models.dart';
import 'health_source.dart';
import 'oura_api_client.dart';
import 'oura_auth_manager.dart';

class OuraHealthSource implements HealthSource {
  final OuraAuthManager authManager;
  final OuraApiClient apiClient;
  final QueryExecutor database;

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
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(window);

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

      final mostRecentSleep = sleep.records.isNotEmpty ? sleep.records.last : null;
      final mostRecentDailySleep = dailySleep.records.isNotEmpty ? dailySleep.records.last : null;
      final mostRecentActivity = activity.records.isNotEmpty ? activity.records.last : null;
      final mostRecentReadiness = readiness.records.isNotEmpty ? readiness.records.last : null;

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
        lastFetched: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to fetch Oura health metrics: $e');
    }
  }
}

import 'package:domain/domain.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/models/oura_models.dart';
import 'package:migraine_forecast/data/sources/health_source.dart';
import 'package:migraine_forecast/data/sources/oura_api_client.dart';
import 'package:migraine_forecast/data/sources/oura_auth_manager.dart';
import 'package:migraine_forecast/data/sources/oura_health_source.dart';
import 'package:mocktail/mocktail.dart';

class MockOuraAuthManager extends Mock implements OuraAuthManager {}

class MockOuraApiClient extends Mock implements OuraApiClient {}

void main() {
  group('OuraHealthSource', () {
    late MockOuraAuthManager mockAuthManager;
    late MockOuraApiClient mockApiClient;
    late NativeDatabase database;
    late OuraHealthSource source;

    setUp(() {
      mockAuthManager = MockOuraAuthManager();
      mockApiClient = MockOuraApiClient();
      database = NativeDatabase.memory();
      source = OuraHealthSource(
        authManager: mockAuthManager,
        apiClient: mockApiClient,
        database: database,
      );
    });

    test('grantedCategories returns sleep and hrv', () {
      expect(
        source.grantedCategories,
        equals({HealthCategory.sleep, HealthCategory.hrv}),
      );
    });

    test('recentMetrics returns HealthMetrics with Oura data populated', () async {
      when(() => mockApiClient.getSleep(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          )).thenAnswer((_) async => OuraSleepData(
            records: [
              OuraSleepRecord(
                id: 'sleep-001',
                day: '2026-06-13',
                lowestHeartRate: 45,
                restlessPeriods: 2,
                averageHeartRate: 52.5,
                averageHrv: 35,
                timestamp: '2026-06-13T06:00:00Z',
              ),
            ],
          ));

      when(() => mockApiClient.getDailySleep(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          )).thenAnswer((_) async => OuraDailySleepData(
            records: [
              OuraDailySleepRecord(
                id: 'daily-sleep-001',
                day: '2026-06-13',
                score: 85,
                timestamp: '2026-06-13T06:00:00Z',
              ),
            ],
          ));

      when(() => mockApiClient.getActivity(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          )).thenAnswer((_) async => OuraActivityData(
            records: [
              OuraActivityRecord(
                id: 'activity-001',
                day: '2026-06-13',
                score: 75,
                timestamp: '2026-06-13T06:00:00Z',
              ),
            ],
          ));

      when(() => mockApiClient.getReadiness(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          )).thenAnswer((_) async => OuraReadinessData(
            records: [
              OuraReadinessRecord(
                id: 'readiness-001',
                day: '2026-06-13',
                score: 88,
                temperatureDeviation: 0.2,
                timestamp: '2026-06-13T06:00:00Z',
              ),
            ],
          ));

      final metrics = await source.recentMetrics(window: const Duration(days: 7));

      expect(metrics.source, equals(DataSource.oura));
      expect(metrics.sleepScore, equals(85));
      expect(metrics.lowestHeartRate, equals(45));
      expect(metrics.sleepInterruptions, equals(2));
      expect(metrics.activityScore, equals(75));
      expect(metrics.readinessScore, equals(88));
      expect(metrics.temperatureDeviation, closeTo(0.2, 0.01));
      expect(metrics.averageHeartRate, closeTo(52.5, 0.1));
      expect(metrics.averageHrv, equals(35));
      expect(metrics.lastFetched, isNotNull);
    });
  });
}

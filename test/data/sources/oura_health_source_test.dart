import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart' as db;
import 'package:migraine_forecast/data/models/oura_models.dart';
import 'package:migraine_forecast/data/sources/health_source.dart';
import 'package:migraine_forecast/data/sources/oura_api_client.dart';
import 'package:migraine_forecast/data/sources/oura_auth_manager.dart';
import 'package:migraine_forecast/data/sources/oura_health_source.dart';
import 'package:mocktail/mocktail.dart';

class MockOuraAuthManager extends Mock implements OuraAuthManager {}

class MockOuraApiClient extends Mock implements OuraApiClient {}

// ---------------------------------------------------------------------------
// Helpers to build stubbed API responses
// ---------------------------------------------------------------------------

/// Returns a date string (yyyy-MM-dd) for [daysAgo] days before today so
/// that stub data always falls within any reasonable recent-metrics window.
String _recentDay([int daysAgo = 1]) {
  final d = DateTime.now().toUtc().subtract(Duration(days: daysAgo));
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}

String _recentTs([int daysAgo = 1]) => '${_recentDay(daysAgo)}T06:00:00Z';

OuraSleepData _sleepData() => OuraSleepData(records: [
      OuraSleepRecord(
        id: 'sleep-001',
        day: _recentDay(),
        lowestHeartRate: 45,
        restlessPeriods: 2,
        averageHeartRate: 52.5,
        averageHrv: 35,
        timestamp: _recentTs(),
      ),
    ]);

OuraDailySleepData _dailySleepData() => OuraDailySleepData(records: [
      OuraDailySleepRecord(
        id: 'daily-sleep-001',
        day: _recentDay(),
        score: 85,
        timestamp: _recentTs(),
      ),
    ]);

OuraActivityData _activityData() => OuraActivityData(records: [
      OuraActivityRecord(
        id: 'activity-001',
        day: _recentDay(),
        score: 75,
        timestamp: _recentTs(),
      ),
    ]);

OuraReadinessData _readinessData() => OuraReadinessData(records: [
      OuraReadinessRecord(
        id: 'readiness-001',
        day: _recentDay(),
        score: 88,
        temperatureDeviation: 0.2,
        timestamp: _recentTs(),
      ),
    ]);

void _stubApiSuccess(MockOuraApiClient mock) {
  when(() => mock.getSleep(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => _sleepData());

  when(() => mock.getDailySleep(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => _dailySleepData());

  when(() => mock.getActivity(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => _activityData());

  when(() => mock.getReadiness(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => _readinessData());
}

void _stubApiRateLimit(MockOuraApiClient mock) {
  when(() => mock.getSleep(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenThrow(RateLimitException(null));

  when(() => mock.getDailySleep(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenThrow(RateLimitException(null));

  when(() => mock.getActivity(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenThrow(RateLimitException(null));

  when(() => mock.getReadiness(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenThrow(RateLimitException(null));
}

void _stubApiAuthError(MockOuraApiClient mock) {
  when(() => mock.getSleep(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenThrow(OuraAuthException('token expired'));

  when(() => mock.getDailySleep(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenThrow(OuraAuthException('token expired'));

  when(() => mock.getActivity(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenThrow(OuraAuthException('token expired'));

  when(() => mock.getReadiness(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenThrow(OuraAuthException('token expired'));
}

void main() {
  group('OuraHealthSource', () {
    late MockOuraAuthManager mockAuthManager;
    late MockOuraApiClient mockApiClient;
    late db.AppDatabase database;
    late OuraHealthSource source;

    setUp(() {
      mockAuthManager = MockOuraAuthManager();
      mockApiClient = MockOuraApiClient();
      database = db.AppDatabase.memory();
      source = OuraHealthSource(
        authManager: mockAuthManager,
        apiClient: mockApiClient,
        database: database,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('grantedCategories returns sleep and hrv', () {
      expect(
        source.grantedCategories,
        equals({HealthCategory.sleep, HealthCategory.hrv}),
      );
    });

    test('recentMetrics returns HealthMetrics with Oura data populated', () async {
      _stubApiSuccess(mockApiClient);

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

    test('after successful recentMetrics, Drift tables contain the persisted rows', () async {
      _stubApiSuccess(mockApiClient);

      await source.recentMetrics(window: const Duration(days: 7));

      final sleepRows = await database.select(database.ouraSleep).get();
      expect(sleepRows.length, 1);
      expect(sleepRows.first.id, 'sleep-001');
      expect(sleepRows.first.lowestHeartRate, 45);

      final dailySleepRows = await database.select(database.ouraDailySleep).get();
      expect(dailySleepRows.length, 1);
      expect(dailySleepRows.first.id, 'daily-sleep-001');
      expect(dailySleepRows.first.score, 85);

      final activityRows = await database.select(database.ouraActivity).get();
      expect(activityRows.length, 1);
      expect(activityRows.first.activityScore, 75);

      final readinessRows = await database.select(database.ouraReadiness).get();
      expect(readinessRows.length, 1);
      expect(readinessRows.first.readinessScore, 88);
    });

    test('recentMetrics returns cached data when API raises RateLimitException', () async {
      // Seed the cache first.
      _stubApiSuccess(mockApiClient);
      await source.recentMetrics(window: const Duration(days: 7));

      // Now stub the API to rate-limit.
      _stubApiRateLimit(mockApiClient);

      final metrics = await source.recentMetrics(window: const Duration(days: 7));

      expect(metrics.source, equals(DataSource.oura));
      expect(metrics.readinessScore, equals(88));
      expect(metrics.activityScore, equals(75));
      expect(metrics.lowestHeartRate, equals(45));
      expect(metrics.lastFetched, isNotNull);
    });

    test('recentMetrics rethrows RateLimitException when cache is also empty', () async {
      _stubApiRateLimit(mockApiClient);

      expect(
        () => source.recentMetrics(window: const Duration(days: 7)),
        throwsA(isA<RateLimitException>()),
      );
    });

    test('OuraAuthException is rethrown without touching the cache', () async {
      _stubApiAuthError(mockApiClient);

      expect(
        () => source.recentMetrics(window: const Duration(days: 7)),
        throwsA(isA<OuraAuthException>()),
      );

      // Cache must still be empty — auth errors must not be swallowed.
      final sleepRows = await database.select(database.ouraSleep).get();
      expect(sleepRows, isEmpty);
    });
  });
}

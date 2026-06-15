/// Integration test: verifies the complete Oura authentication and metrics flow.
///
/// Tests:
/// 1. OuraAuthManager stores and retrieves tokens securely
/// 2. OuraApiClient fetches data from mocked Oura API
/// 3. OuraHealthSource combines API responses into HealthMetrics
/// 4. HealthSourceFactory intelligently selects between Oura and Apple Health
///
/// Uses mocked HTTP client and secure storage, with real component integration.
library;

import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:migraine_forecast/data/sources/health_source.dart';
import 'package:migraine_forecast/data/sources/health_source_factory.dart';
import 'package:migraine_forecast/data/sources/oura_api_client.dart';
import 'package:migraine_forecast/data/sources/oura_auth_manager.dart';
import 'package:migraine_forecast/data/sources/oura_health_source.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockHttpClient extends Mock implements http.Client {}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

// ---------------------------------------------------------------------------
// Test-specific FakeHealthSource for fallback testing
// ---------------------------------------------------------------------------

class _FakeAppleHealthSource implements HealthSource {
  final HealthMetrics metrics;

  _FakeAppleHealthSource(this.metrics);

  @override
  Set<HealthCategory> get grantedCategories => {HealthCategory.sleep, HealthCategory.hrv};

  @override
  Future<HealthMetrics> recentMetrics({required Duration window}) async => metrics;

  @override
  Future<Set<HealthCategory>> requestPermissions(Set<HealthCategory> categories) async =>
      grantedCategories.intersection(categories);
}

// ---------------------------------------------------------------------------
// Helper functions
// ---------------------------------------------------------------------------

/// Helper to build a mock sleep API response
String _buildSleepResponse() => jsonEncode({
      'data': [
        {
          'id': 'sleep-001',
          'day': '2026-06-13',
          'lowest_heart_rate': 45,
          'restless_periods': 2,
          'average_heart_rate': 52.5,
          'average_hrv': 35,
          'timestamp': '2026-06-13T06:00:00Z',
        }
      ]
    });

/// Helper to build a mock daily sleep API response
String _buildDailySleepResponse() => jsonEncode({
      'data': [
        {
          'id': 'daily-sleep-001',
          'day': '2026-06-13',
          'score': 85,
          'timestamp': '2026-06-13T06:00:00Z',
        }
      ]
    });

/// Helper to build a mock activity API response
String _buildActivityResponse() => jsonEncode({
      'data': [
        {
          'id': 'activity-001',
          'day': '2026-06-13',
          'score': 75,
          'timestamp': '2026-06-13T06:00:00Z',
        }
      ]
    });

/// Helper to build a mock readiness API response
String _buildReadinessResponse() => jsonEncode({
      'data': [
        {
          'id': 'readiness-001',
          'day': '2026-06-13',
          'score': 88,
          'temperature_deviation': 0.2,
          'timestamp': '2026-06-13T06:00:00Z',
        }
      ]
    });

void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
  });

  group('Oura Integration Test', () {
    test('Factory returns Oura metrics when preferred and fresh', () async {
      // -----------------------------------------------------------------------
      // Setup: Mock secure storage
      // -----------------------------------------------------------------------
      final mockStorage = MockSecureStorage();
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});
      when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
      when(() => mockStorage.delete(key: any(named: 'key'))).thenAnswer((_) async {});

      // -----------------------------------------------------------------------
      // Setup: Mock HTTP client with all 4 API responses
      // -----------------------------------------------------------------------
      final mockHttpClient = MockHttpClient();

      // Setup a generic response handler that routes based on the URL path
      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((invocation) {
        final uri = invocation.positionalArguments[0] as Uri;
        final uriString = uri.toString();

        // Check daily_sleep before sleep to avoid partial matches
        if (uriString.contains('daily_sleep?')) {
          return Future.value(http.Response(_buildDailySleepResponse(), 200));
        } else if (uriString.contains('sleep?')) {
          return Future.value(http.Response(_buildSleepResponse(), 200));
        } else if (uriString.contains('activity?')) {
          return Future.value(http.Response(_buildActivityResponse(), 200));
        } else if (uriString.contains('readiness?')) {
          return Future.value(http.Response(_buildReadinessResponse(), 200));
        } else {
          return Future.value(http.Response('{"data": []}', 200));
        }
      });

      // -----------------------------------------------------------------------
      // Setup: Create components in the correct order
      // -----------------------------------------------------------------------

      // 1. Create OuraAuthManager with mock storage
      final authManager = OuraAuthManager(storage: mockStorage);

      // 2. Simulate OAuth callback: set credentials with a far-future expiry
      await authManager.saveTokens(
        accessToken: 'mock-access-token',
        refreshToken: 'mock-refresh-token',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        userEmail: 'user@example.com',
      );

      // 3. Create OuraApiClient with mock HTTP and the token callback
      final apiClient = OuraApiClient(
        tokenProvider: authManager.getValidAccessToken,
        httpClient: mockHttpClient,
      );

      // 4. Create OuraHealthSource combining auth + API
      final ouraSource = OuraHealthSource(
        authManager: authManager,
        apiClient: apiClient,
      );

      // 6. Create fallback Apple Health source (returns fresh data)
      final appleSource = _FakeAppleHealthSource(
        HealthMetrics(
          recentSleep: [
            SleepRecord(
              night: DateTime.utc(2026, 6, 13),
              totalSleep: const Duration(hours: 6),
              efficiency: 0.85,
              sleepStart: DateTime.utc(2026, 6, 13, 22, 0),
            ),
          ],
          source: DataSource.appleHealth,
          lastFetched: DateTime.utc(2026, 6, 13, 12, 0),
        ),
      );

      // 7. Create factory preferring Oura with a fixed clock for staleness check
      final now = DateTime.utc(2026, 6, 13, 14, 0); // 2 hours after API timestamp
      final factory = HealthSourceFactory(
        ouraHealthSource: ouraSource,
        appleHealthSource: appleSource,
        preferOura: true,
        clock: () => now,
      );

      // -----------------------------------------------------------------------
      // Act: Get metrics from the factory
      // -----------------------------------------------------------------------
      final metrics = await factory.recentMetrics(window: const Duration(days: 7));

      // -----------------------------------------------------------------------
      // Verify: Metrics come from Oura and have correct values
      // -----------------------------------------------------------------------
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

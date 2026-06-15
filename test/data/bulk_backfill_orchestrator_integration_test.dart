/// Integration test: verifies that a full 7-day backfill issues exactly
/// one forecast + one air-quality HTTP request (the wide prime fetch), and
/// zero additional network calls during the per-day loop.
///
/// Uses a real [OpenMeteoWeatherSource] backed by a mocked [http.Client] that
/// records every outbound request, and an in-memory Drift DB — same pattern
/// as the unit tests in [bulk_backfill_orchestrator_test.dart].
library;

import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:migraine_forecast/data/bulk_backfill_orchestrator.dart';
import 'package:migraine_forecast/data/context_builder.dart';
import 'package:migraine_forecast/data/database.dart'
    hide JournalEntry, WeatherSnapshot, RiskAssessment, PeriodDaySeverity;
import 'package:migraine_forecast/data/repos/assessment_repository.dart';
import 'package:migraine_forecast/data/repos/baseline_snapshot_builder.dart';
import 'package:migraine_forecast/data/sources/drift_journal_source.dart';
import 'package:migraine_forecast/data/sources/fake_health_source.dart';
import 'package:migraine_forecast/data/sources/manual_location_source.dart';
import 'package:migraine_forecast/data/sources/open_meteo/open_meteo_weather_source.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _NoFlagsRepo implements UserTriggerFlagsRepo {
  @override
  Future<UserTriggerFlags> load() async => const UserTriggerFlags();
  @override
  Future<void> save(UserTriggerFlags flags) async {}
}

/// Builds a forecast JSON whose hourly time series spans from [startDay] to
/// [endDay] (inclusive) with one sample per day at noon UTC. The parser only
/// needs pressure, temperature, and humidity arrays of matching length.
String _buildForecastJson(DateTime startDay, DateTime endDay) {
  final times = <String>[];
  var d = startDay;
  while (!d.isAfter(endDay)) {
    times.add(
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}T12:00',
    );
    d = d.add(const Duration(days: 1));
  }
  final n = times.length;
  final pressures = List.filled(n, 1013.0);
  final temps = List.filled(n, 20.0);
  final humidities = List.filled(n, 50);
  return jsonEncode({
    'latitude': 37.7,
    'longitude': -122.4,
    'timezone': 'UTC',
    'hourly': {
      'time': times,
      'pressure_msl': pressures,
      'temperature_2m': temps,
      'relative_humidity_2m': humidities,
    },
  });
}

/// Minimal air-quality JSON accepted by [OpenMeteoParser.parseAirQuality].
String _buildAqJson() => jsonEncode({
      'latitude': 37.7,
      'longitude': -122.4,
      'timezone': 'UTC',
      'hourly': {
        'time': ['2026-01-01T00:00'],
        'pm2_5': [10.0],
      },
    });

// ---------------------------------------------------------------------------
// Test
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'full 7-day backfill issues exactly 1 forecast + 1 air-quality HTTP request',
    () async {
      // -----------------------------------------------------------------------
      // Setup: in-memory DB, real OpenMeteoWeatherSource, mocked HTTP client.
      // -----------------------------------------------------------------------
      final db = AppDatabase.memory();
      addTearDown(db.close);

      final now = DateTime.now().toUtc();
      final today = DateTime.utc(now.year, now.month, now.day);
      // The prime fetch requests pastDays = 7, covering the full window.
      final windowStart = today.subtract(const Duration(days: 7));

      final forecastJson = _buildForecastJson(
        windowStart.subtract(const Duration(days: 2)), // 2-day padding
        today.add(const Duration(days: 3)),            // forward forecast
      );
      final aqJson = _buildAqJson();

      final recordedUrls = <Uri>[];
      final mockClient = MockClient((req) async {
        recordedUrls.add(req.url);
        if (req.url.host == 'api.open-meteo.com') {
          return http.Response(forecastJson, 200);
        }
        if (req.url.host.contains('air-quality')) {
          return http.Response(aqJson, 200);
        }
        return http.Response('{}', 404);
      });

      final weatherSource = OpenMeteoWeatherSource(
        client: mockClient,
        db: db,
        // Set freshness very long so the primed row is always cache-fresh
        // when the per-day loop looks it up.
        freshness: const Duration(days: 1),
      );

      final location = ManualLocationSource();
      await location.set(lat: 37.7, lon: -122.4);

      final journal = DriftJournalSource(db);
      final health = FakeHealthSource();

      final builder = ContextBuilder(
        weather: weatherSource,
        health: health,
        journal: journal,
        location: location,
        flagsRepo: _NoFlagsRepo(),
        baselineBuilder: const BaselineSnapshotBuilder(BaselineStore()),
        db: db,
      );

      final cfgText = await rootBundle.loadString('assets/rules_config_v1.json');
      final cfg = RulesConfigLoader.parse(cfgText);
      final engine = RiskEngine(modules: [
        PressureDropModule(),
        HumidityModule(),
        TempSwingModule(),
        AirQualityModule(),
        SleepDeficitModule(),
        HrvLetdownModule(),
        MenstrualPhaseModule(),
        RefractoryModule(),
        AlcoholModule(),
        CaffeineModule(),
        StressModule(),
        HydrationModule(),
        IntradayPressureSwingModule(),
      ]);

      final repo = AssessmentRepository(db);

      final orchestrator = BulkBackfillOrchestrator(
        contextBuilder: builder,
        riskEngine: engine,
        rulesConfig: cfg,
        assessmentRepo: repo,
        locationSource: location,
        weatherSource: weatherSource,
      );

      // -----------------------------------------------------------------------
      // Execute: 7-day backfill on an empty DB.
      // -----------------------------------------------------------------------
      final report = await orchestrator.run(window: const Duration(days: 7));

      // -----------------------------------------------------------------------
      // Assert: exactly 2 outbound HTTP calls — 1 forecast + 1 air-quality.
      // All per-day cache lookups must resolve from the primed row without
      // additional network traffic.
      // -----------------------------------------------------------------------
      expect(
        report.weatherFetchSucceeded,
        isTrue,
        reason: 'prime fetch should succeed',
      );
      expect(
        report.daysProcessed,
        7,
        reason: 'all 7 days should be written on a fresh DB',
      );

      final forecastCalls =
          recordedUrls.where((u) => u.host == 'api.open-meteo.com').toList();
      final aqCalls =
          recordedUrls.where((u) => u.host.contains('air-quality')).toList();

      expect(
        forecastCalls,
        hasLength(1),
        reason: 'exactly 1 forecast call (the prime); per-day loop must hit cache',
      );
      expect(
        aqCalls,
        hasLength(1),
        reason: 'exactly 1 air-quality call (the prime)',
      );
      expect(
        recordedUrls,
        hasLength(2),
        reason: 'total network calls must be exactly 2',
      );

      // Verify the prime used the correct pastDays query parameter.
      final forecastUri = forecastCalls.single;
      expect(
        forecastUri.queryParameters['past_days'],
        '7',
        reason: 'prime fetch must request past_days = window.inDays',
      );
    },
  );
}

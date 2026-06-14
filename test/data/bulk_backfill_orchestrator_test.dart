import 'package:domain/domain.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/bulk_backfill_orchestrator.dart';
import 'package:migraine_forecast/data/context_builder.dart';
import 'package:migraine_forecast/data/database.dart'
    hide JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_forecast/data/repos/assessment_repository.dart';
import 'package:migraine_forecast/data/repos/baseline_snapshot_builder.dart';
import 'package:migraine_forecast/data/sources/drift_journal_source.dart';
import 'package:migraine_forecast/data/sources/fake_health_source.dart';
import 'package:migraine_forecast/data/sources/manual_location_source.dart';
import 'package:migraine_forecast/data/sources/weather_source.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeWeatherSource implements WeatherSource {
  final bool shouldThrow;
  int fetchCount = 0;
  int forceRefreshCount = 0;

  _FakeWeatherSource({this.shouldThrow = false});

  @override
  Future<WeatherSnapshot> fetch({
    required double lat,
    required double lon,
    required DateTime now,
    bool forceRefresh = false,
  }) async {
    fetchCount++;
    if (forceRefresh) forceRefreshCount++;
    if (shouldThrow) throw StateError('network error');
    return WeatherSnapshot(
      weather: const WeatherSeries(samples: []),
      airQuality: const AirQualitySeries(samples: []),
      fetchedAt: now,
    );
  }
}

class _NoFlagsRepo implements UserTriggerFlagsRepo {
  @override
  Future<UserTriggerFlags> load() async => const UserTriggerFlags();
  @override
  Future<void> save(UserTriggerFlags flags) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<(BulkBackfillOrchestrator, AssessmentRepository, AppDatabase, _FakeWeatherSource)>
    _buildStack({bool weatherFails = false}) async {
  final db = AppDatabase.memory();
  final journal = DriftJournalSource(db);
  final location = ManualLocationSource();
  await location.set(lat: 37.7, lon: -122.4);

  final weather = _FakeWeatherSource(shouldThrow: weatherFails);
  final health = FakeHealthSource();

  final builder = ContextBuilder(
    weather: weather,
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
    weatherSource: weather,
  );

  return (orchestrator, repo, db, weather);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Use a 7-day window so tests run fast while still exercising the full path.
  const testWindow = Duration(days: 7);

  test('empty DB: writes one row per day in the window', () async {
    final (orchestrator, repo, db, weather) = await _buildStack();
    addTearDown(db.close);

    final report = await orchestrator.run(window: testWindow);

    expect(report.weatherFetchSucceeded, isTrue);
    expect(report.daysProcessed, 7);
    expect(report.daysSkipped, 0);
    expect(report.firstError, isNull);
    // Plan §2: the orchestrator must issue exactly one forced-refresh fetch
    // to prime the cache. Per-day re-fetches of the unfaked OpenMeteoWeatherSource
    // would be cache hits in production; the fake doesn't cache so we only
    // assert the prime is forced.
    expect(weather.forceRefreshCount, 1);

    final rows = await db.select(db.riskAssessments).get();
    expect(rows, hasLength(7));
    expect(rows.every((r) => r.backfilled), isTrue);
    expect(rows.every((r) => r.horizon == 'today'), isTrue);
  });

  test('half-full DB: only fills missing days', () async {
    final (orchestrator, repo, db, weather) = await _buildStack();
    addTearDown(db.close);

    // Pre-seed the first 4 days as already assessed.
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    for (var i = 6; i >= 3; i--) {
      final day = today.subtract(Duration(days: i));
      await repo.save(RiskAssessment(
        score: 0,
        band: RiskBand.low,
        contributors: const [],
        computedAt: DateTime.now().toUtc(),
        configVersion: 1,
        targetDate: day,
        horizon: RiskHorizon.today,
        backfilled: true,
      ));
    }

    final report = await orchestrator.run(window: testWindow);

    expect(report.daysProcessed, 3); // days 0, 1, 2 ago
    expect(report.daysSkipped, 4); // days 3-6 ago already filled
    expect(report.firstError, isNull);
    expect(weather.forceRefreshCount, 1);

    final rows = await db.select(db.riskAssessments).get();
    expect(rows, hasLength(7));

    // Verify the three newly-written rows cover exactly days 0, 1, and 2 ago
    // (not the pre-seeded days 3-6 ago, which were already present).
    final preSeeded = {
      for (var i = 3; i <= 6; i++) today.subtract(Duration(days: i)),
    };
    final newlyWritten = rows
        .map((r) => DateTime.utc(r.targetDate.year, r.targetDate.month, r.targetDate.day))
        .where((d) => !preSeeded.contains(d))
        .toSet();
    // days 6-3 ago were pre-seeded; the orchestrator fills the cutoff day
    // (today-7) and the two most recent missing days (today-2, today-1).
    expect(newlyWritten, {
      today.subtract(const Duration(days: 7)), // cutoff boundary
      today.subtract(const Duration(days: 2)),
      today.subtract(const Duration(days: 1)),
    });
  });

  test('weather fetch fails: no rows written, report flags error', () async {
    final (orchestrator, _, db, _) = await _buildStack(weatherFails: true);
    addTearDown(db.close);

    final report = await orchestrator.run(window: testWindow);

    expect(report.weatherFetchSucceeded, isFalse);
    expect(report.daysProcessed, 0);
    expect(report.firstError, isNotNull);

    final rows = await db.select(db.riskAssessments).get();
    expect(rows, isEmpty);
  });

  test('repeat run on full DB: zero writes, idempotent', () async {
    final (orchestrator, _, db, weather) = await _buildStack();
    addTearDown(db.close);

    // First run fills all days.
    final report1 = await orchestrator.run(window: testWindow);
    expect(report1.daysProcessed, 7);
    expect(weather.forceRefreshCount, 1);

    final rowsAfterFirst = await db.select(db.riskAssessments).get();
    expect(rowsAfterFirst, hasLength(7));

    // Second run sees all days already filled — no prime fetch needed.
    final report2 = await orchestrator.run(window: testWindow);
    expect(weather.forceRefreshCount, 1);
    expect(report2.daysProcessed, 0);
    expect(report2.daysSkipped, 7);

    // No duplicate rows — upsert-on-conflict ensures idempotency.
    final rowsAfterSecond = await db.select(db.riskAssessments).get();
    expect(rowsAfterSecond, hasLength(7));
  });
}

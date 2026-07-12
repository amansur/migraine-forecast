import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/context_builder.dart';
import 'package:migraine_forecast/data/database.dart'
    hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_forecast/data/repos/assessment_repository.dart';
import 'package:migraine_forecast/data/sources/drift_journal_source.dart';
import 'package:migraine_forecast/data/sources/fake_health_source.dart';
import 'package:migraine_forecast/data/sources/manual_location_source.dart';
import 'package:migraine_forecast/data/sources/weather_source.dart';
import 'package:migraine_forecast/state/outlook_provider.dart';
import 'package:migraine_forecast/state/providers.dart';

class _StubWeather implements WeatherSource {
  @override
  Future<void> primeArchive(
      {required double lat,
      required double lon,
      required DateTime startDate,
      required DateTime endDate}) async {}

  @override
  Future<WeatherSnapshot> fetch(
          {required double lat,
          required double lon,
          required DateTime now,
          bool forceRefresh = false,
          int? pastDays}) async =>
      WeatherSnapshot(
        weather: const WeatherSeries(samples: []),
        airQuality: const AirQualitySeries(samples: []),
        fetchedAt: now,
      );
}

class _MemFlagsRepo implements UserTriggerFlagsRepo {
  UserTriggerFlags _f = const UserTriggerFlags();
  @override
  Future<UserTriggerFlags> load() async => _f;
  @override
  Future<void> save(UserTriggerFlags flags) async => _f = flags;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('computes d+2..d+6 outlook assessments without persisting any', () async {
    final db = AppDatabase.memory();
    final location = ManualLocationSource();
    await location.set(lat: 40.7, lon: -74.0);
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      weatherSourceProvider.overrideWithValue(_StubWeather()),
      healthSourceProvider.overrideWithValue(FakeHealthSource()),
      journalSourceProvider.overrideWithValue(DriftJournalSource(db)),
      locationSourceProvider.overrideWithValue(location),
      flagsRepoProvider.overrideWithValue(_MemFlagsRepo()),
    ]);
    addTearDown(container.dispose);
    addTearDown(db.close);

    final outlook = await container.read(outlookProvider.future);

    expect(outlook, hasLength(5));
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    for (var i = 0; i < 5; i++) {
      expect(outlook[i].targetDate, today.add(Duration(days: i + 2)));
      expect(outlook[i].horizon, RiskHorizon.outlook);
    }

    // Nothing written: the outlook must never reach the assessments table.
    final rows = await db.select(db.riskAssessments).get();
    expect(rows, isEmpty);
  });

  test('AssessmentRepository.save rejects outlook assessments', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final ass = RiskAssessment(
      score: 10,
      band: RiskBand.low,
      contributors: const [],
      computedAt: DateTime.utc(2026, 7, 11),
      configVersion: 2,
      targetDate: DateTime.utc(2026, 7, 14),
      horizon: RiskHorizon.outlook,
    );
    expect(() => AssessmentRepository(db).save(ass), throwsArgumentError);
  });
}

import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/context_builder.dart';
import 'package:migraine_forecast/data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_forecast/data/repos/assessment_repository.dart';
import 'package:migraine_forecast/data/sources/drift_journal_source.dart';
import 'package:migraine_forecast/data/sources/fake_health_source.dart';
import 'package:migraine_forecast/data/sources/manual_location_source.dart';
import 'package:migraine_forecast/data/sources/weather_source.dart';
import 'package:migraine_forecast/state/providers.dart';
import 'package:migraine_forecast/state/risk_assessment_provider.dart';

class _StubWeather implements WeatherSource {
  @override
  Future<WeatherSnapshot> fetch({required double lat, required double lon, required DateTime now}) async =>
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

  test('refresh produces an onboarding assessment with empty inputs', () async {
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

    final notifier = container.read(riskAssessmentProvider.notifier);
    await notifier.refresh();
    final ass = container.read(riskAssessmentProvider).requireValue;
    expect(ass.isOnboarding, isTrue);
    expect(ass.score, 0);
  });

  test('backfill saves an assessment marked backfilled=true', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final location = ManualLocationSource();
    await location.set(lat: 40.7, lon: -74.0);

    // Stub weather + journal so context-builder doesn't hit the network.
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      weatherSourceProvider.overrideWithValue(_StubWeather()),
      healthSourceProvider.overrideWithValue(FakeHealthSource()),
      journalSourceProvider.overrideWithValue(DriftJournalSource(db)),
      locationSourceProvider.overrideWithValue(location),
      flagsRepoProvider.overrideWithValue(_MemFlagsRepo()),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(riskAssessmentProvider.notifier);
    final target = DateTime.utc(2026, 6, 5);
    await notifier.backfill(target);

    final repo = AssessmentRepository(db);
    final loaded = await repo.latestForDate(target: target, horizon: RiskHorizon.today);
    expect(loaded, isNotNull);
    expect(loaded!.backfilled, isTrue);
  });
}

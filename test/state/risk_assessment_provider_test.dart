import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/context_builder.dart';
import 'package:migraine_weatherr/data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_weatherr/data/sources/drift_journal_source.dart';
import 'package:migraine_weatherr/data/sources/fake_health_source.dart';
import 'package:migraine_weatherr/data/sources/manual_location_source.dart';
import 'package:migraine_weatherr/data/sources/weather_source.dart';
import 'package:migraine_weatherr/state/providers.dart';
import 'package:migraine_weatherr/state/risk_assessment_provider.dart';

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
}

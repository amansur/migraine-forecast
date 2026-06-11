import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/app/app.dart';
import 'package:migraine_weatherr/data/context_builder.dart';
import 'package:migraine_weatherr/data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_weatherr/data/sources/drift_journal_source.dart';
import 'package:migraine_weatherr/data/sources/fake_health_source.dart';
import 'package:migraine_weatherr/data/sources/manual_location_source.dart';
import 'package:migraine_weatherr/data/sources/weather_source.dart';
import 'package:migraine_weatherr/state/providers.dart';

class _StubWeather implements WeatherSource {
  @override
  Future<WeatherSnapshot> fetch({required double lat, required double lon, required DateTime now}) async => WeatherSnapshot(
        weather: const WeatherSeries(samples: []),
        airQuality: const AirQualitySeries(samples: []),
        fetchedAt: now,
      );
}

class _MemFlagsRepo implements UserTriggerFlagsRepo {
  UserTriggerFlags _f = const UserTriggerFlags();
  @override Future<UserTriggerFlags> load() async => _f;
  @override Future<void> save(UserTriggerFlags flags) async => _f = flags;
}

void main() {
  testWidgets('launches into onboarding when not completed', (tester) async {
    final db = AppDatabase.memory();
    final loc = ManualLocationSource();
    await loc.set(lat: 40.7, lon: -74.0);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          weatherSourceProvider.overrideWithValue(_StubWeather()),
          healthSourceProvider.overrideWithValue(FakeHealthSource()),
          journalSourceProvider.overrideWithValue(DriftJournalSource(db)),
          locationSourceProvider.overrideWithValue(loc),
          flagsRepoProvider.overrideWithValue(_MemFlagsRepo()),
        ],
        child: const MigraineWeatherrApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Migraine Weatherr'), findsOneWidget);
    addTearDown(db.close);
  });
}

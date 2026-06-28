import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/app/app.dart';
import 'package:migraine_forecast/data/context_builder.dart';
import 'package:migraine_forecast/data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_forecast/data/sources/drift_journal_source.dart';
import 'package:migraine_forecast/data/sources/fake_health_source.dart';
import 'package:migraine_forecast/data/sources/manual_location_source.dart';
import 'package:migraine_forecast/data/sources/weather_source.dart';
import 'package:migraine_forecast/state/providers.dart';

class _StubWeather implements WeatherSource {
  @override
  Future<void> primeArchive({required double lat, required double lon, required DateTime startDate, required DateTime endDate}) async {}

  @override
  Future<WeatherSnapshot> fetch({required double lat, required double lon, required DateTime now, bool forceRefresh = false, int? pastDays}) async => WeatherSnapshot(
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
    addTearDown(db.close);
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
        // MediaQuery is placed here (between ProviderScope and MigraineForecastApp)
        // so that MaterialApp.router, created inside MigraineForecastApp.build(),
        // inherits disableAnimations: true and the mascot idle loop doesn't block
        // pumpAndSettle.
        child: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MigraineForecastApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Migraine Forecast'), findsOneWidget);
    // Replace the app with an empty widget to trigger ProviderScope disposal,
    // then pump once to flush the zero-duration timer Drift schedules when
    // stream subscriptions are cancelled during cleanup.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(); // fire the zero-duration Drift timer
    await tester.pump(); // drain any timers scheduled by that callback
  });
}

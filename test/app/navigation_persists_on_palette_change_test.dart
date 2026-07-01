import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/app/app.dart';
import 'package:migraine_forecast/data/context_builder.dart';
import 'package:migraine_forecast/data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_forecast/data/repos/settings_repo.dart';
import 'package:migraine_forecast/state/onboarding_provider.dart';
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
  testWidgets('navigation stays on Settings when the dark palette changes', (tester) async {
    // Tall surface so the palette section (below the fold on Settings) renders
    // on-screen and its cards are tappable.
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(db.close);
    final loc = ManualLocationSource();
    await loc.set(lat: 40.7, lon: -74.0);

    // Returning user: onboarding already completed.
    await SettingsRepo(db).setBool('onboarding_completed', true);

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      weatherSourceProvider.overrideWithValue(_StubWeather()),
      healthSourceProvider.overrideWithValue(FakeHealthSource()),
      journalSourceProvider.overrideWithValue(DriftJournalSource(db)),
      locationSourceProvider.overrideWithValue(loc),
      flagsRepoProvider.overrideWithValue(_MemFlagsRepo()),
    ]);
    addTearDown(container.dispose);

    // Pre-warm so the router's redirect sees onboarding=completed on first pass.
    await container.read(onboardingCompletedProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MigraineForecastApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Returning user lands on Today, not Onboarding.
    expect(find.text('Welcome to Migraine Forecast'), findsNothing);

    // Navigate to Settings.
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Dark palette'), findsOneWidget);

    // Change the palette — this rebuilds the app theme. Before the router was
    // memoized, this recreated the GoRouter and bounced the user back to Today.
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('palette-card-deepPlum')));
      await tester.pump();
    });
    await tester.pumpAndSettle();

    // Still on Settings.
    expect(find.text('Dark palette'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await Future<void>.delayed(Duration.zero);
    });
  });
}

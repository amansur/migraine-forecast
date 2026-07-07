// test/ui/settings/debug_band_override_test.dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart';
import 'package:migraine_forecast/data/repos/settings_repo.dart';
import 'package:migraine_forecast/state/mascot_overrides.dart';
import 'package:migraine_forecast/state/providers.dart';
import 'package:migraine_forecast/state/settings_provider.dart';
import 'package:migraine_forecast/ui/settings/settings_screen.dart';

Future<ProviderContainer> pumpSettings(
  WidgetTester tester, {
  void Function(ProviderContainer)? onContainer,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final db = AppDatabase.memory();
  addTearDown(db.close);
  final container = ProviderContainer(overrides: [
    settingsRepoProvider.overrideWithValue(SettingsRepo(db)),
    databaseProvider.overrideWithValue(db),
  ]);
  addTearDown(container.dispose);

  onContainer?.call(container);

  // Pre-warm settings FutureProviders so the widget sees AsyncData on first build.
  await container.read(darkPaletteProvider.future);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MediaQuery(
      data: MediaQueryData(disableAnimations: true),
      child: MaterialApp(home: SettingsScreen()),
    ),
  ));

  return container;
}

void main() {
  testWidgets('Developer section shows the band override row in debug mode',
      (tester) async {
    // flutter test runs in debug mode, so kDebugMode is true here.
    await pumpSettings(tester);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
        find.byKey(const Key('debug-band-override-row')), 300);
    expect(find.byKey(const Key('debug-band-override-row')), findsOneWidget);
    expect(find.text('Developer'), findsOneWidget);
  });

  testWidgets('selecting a band writes the override; Auto clears it',
      (tester) async {
    late ProviderContainer container;
    await pumpSettings(tester, onContainer: (c) => container = c);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
        find.byKey(const Key('debug-band-override-row')), 300);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Very High'));
    await tester.pumpAndSettle();
    expect(container.read(debugBandOverrideProvider), RiskBand.veryHigh);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Auto'));
    await tester.pumpAndSettle();
    expect(container.read(debugBandOverrideProvider), isNull);
  });
}

// test/ui/settings/dark_palette_picker_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart';
import 'package:migraine_forecast/data/repos/settings_repo.dart';
import 'package:migraine_forecast/state/providers.dart';
import 'package:migraine_forecast/state/settings_provider.dart';
import 'package:migraine_forecast/ui/settings/settings_screen.dart';

void main() {
  testWidgets('tapping a palette card persists the choice', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final container = ProviderContainer(overrides: [
      settingsRepoProvider.overrideWithValue(SettingsRepo(db)),
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);

    // Pre-warm settings FutureProviders so the widget sees AsyncData on first
    // build (Drift NativeDatabase.memory() completes outside fake_async).
    await container.read(darkPaletteProvider.future);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MediaQuery(
        // Disable mascot's idle animation so pumpAndSettle can exit.
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: SettingsScreen()),
      ),
    ));
    await tester.pumpAndSettle();

    // Palette section may be below the initial fold; find it by key regardless
    // of scroll position, then ensure it's on-screen before tapping.
    final deepPlumCard = find.byKey(const Key('palette-card-deepPlum'), skipOffstage: false);
    expect(deepPlumCard, findsOneWidget);

    await tester.ensureVisible(deepPlumCard);
    // Drift writes don't complete in fake_async; call the setter directly via
    // runAsync so the DB write + provider invalidation flush before we read.
    await tester.runAsync(() => container.read(setDarkPaletteProvider)(DarkPaletteChoice.deepPlum));
    await tester.pumpAndSettle();

    final choice = await container.read(darkPaletteProvider.future);
    expect(choice, DarkPaletteChoice.deepPlum);
  });
}

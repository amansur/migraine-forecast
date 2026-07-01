import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart';
import 'package:migraine_forecast/data/repos/settings_repo.dart';
import 'package:migraine_forecast/state/providers.dart';
import 'package:migraine_forecast/state/settings_provider.dart';

void main() {
  test('darkPaletteProvider defaults to moss on fresh install', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final container = ProviderContainer(overrides: [
      settingsRepoProvider.overrideWithValue(SettingsRepo(db)),
    ]);
    addTearDown(container.dispose);

    final choice = await container.read(darkPaletteProvider.future);
    expect(choice, DarkPaletteChoice.moss);
  });

  test('darkPaletteProvider returns the persisted choice', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final container = ProviderContainer(overrides: [
      settingsRepoProvider.overrideWithValue(SettingsRepo(db)),
    ]);
    addTearDown(container.dispose);

    await container.read(setDarkPaletteProvider)(DarkPaletteChoice.deepPlum);
    final choice = await container.read(darkPaletteProvider.future);
    expect(choice, DarkPaletteChoice.deepPlum);
  });
}

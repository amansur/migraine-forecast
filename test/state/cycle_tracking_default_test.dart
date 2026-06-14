import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart';
import 'package:migraine_forecast/data/repos/settings_repo.dart';
import 'package:migraine_forecast/state/providers.dart';
import 'package:migraine_forecast/state/settings_provider.dart';

void main() {
  test('cycleTrackingEnabledProvider defaults to false on fresh install', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);

    final container = ProviderContainer(overrides: [
      settingsRepoProvider.overrideWithValue(SettingsRepo(db)),
    ]);
    addTearDown(container.dispose);

    final enabled = await container.read(cycleTrackingEnabledProvider.future);
    expect(enabled, isFalse);
  });

  test('cycleTrackingEnabledProvider returns true after explicit enable', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);

    final container = ProviderContainer(overrides: [
      settingsRepoProvider.overrideWithValue(SettingsRepo(db)),
    ]);
    addTearDown(container.dispose);

    await container.read(setCycleTrackingEnabledProvider)(true);
    final enabled = await container.read(cycleTrackingEnabledProvider.future);
    expect(enabled, isTrue);
  });
}

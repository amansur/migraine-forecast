import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart';
import 'package:migraine_forecast/data/repos/settings_repo.dart';
import 'package:migraine_forecast/state/providers.dart';
import 'package:migraine_forecast/state/settings_provider.dart';
import 'package:migraine_forecast/state/mascot_character.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      settingsRepoProvider.overrideWithValue(SettingsRepo(db)),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('defaults to bee when unset', () async {
    final c = await container.read(mascotCharacterProvider.future);
    expect(c, MascotCharacter.bee);
  });

  test('setter persists and re-reads as the chosen character', () async {
    await container.read(setMascotCharacterProvider)(MascotCharacter.bee);
    final c = await container.read(mascotCharacterProvider.future);
    expect(c, MascotCharacter.bee);
  });
}

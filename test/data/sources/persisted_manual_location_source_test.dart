import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart';
import 'package:migraine_forecast/data/repos/settings_repo.dart';
import 'package:migraine_forecast/data/sources/persisted_manual_location_source.dart';

void main() {
  test('set persists label and current() returns it (via fresh instance)', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final settings = SettingsRepo(db);

    await PersistedManualLocationSource(settings)
        .set(lat: 37.8044, lon: -122.2712, label: 'Oakland, California');

    // New instance forces a read from storage, bypassing the in-memory cache.
    final loc = await PersistedManualLocationSource(settings).current();
    expect(loc, isNotNull);
    expect(loc!.label, 'Oakland, California');
    expect(loc.lat, closeTo(37.8044, 0.0001));
    expect(loc.lon, closeTo(-122.2712, 0.0001));
  });

  test('set with null label stores no label', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final settings = SettingsRepo(db);

    await PersistedManualLocationSource(settings).set(lat: 1.0, lon: 2.0);
    final loc = await PersistedManualLocationSource(settings).current();
    expect(loc!.label, isNull);
  });

  test('clear removes the persisted location', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final settings = SettingsRepo(db);

    final source = PersistedManualLocationSource(settings);
    await source.set(lat: 1.0, lon: 2.0, label: 'Somewhere');
    await source.clear();

    final loc = await PersistedManualLocationSource(settings).current();
    expect(loc, isNull);
  });
}

import 'package:drift/drift.dart';

import '../database.dart';

class SettingsRepo {
  final AppDatabase _db;
  SettingsRepo(this._db);

  Future<String?> getString(String key) async {
    final rows = await (_db.select(_db.settings)..where((t) => t.key.equals(key))).get();
    return rows.isEmpty ? null : rows.first.value;
  }

  Future<void> setString(String key, String value) async {
    await _db.into(_db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(key: key, value: value),
        );
  }

  Future<bool> getBool(String key) async {
    final s = await getString(key);
    return s == 'true';
  }

  Future<void> setBool(String key, bool value) async => setString(key, value ? 'true' : 'false');

  Future<int?> getInt(String key) async {
    final s = await getString(key);
    return s == null ? null : int.tryParse(s);
  }

  Future<void> setInt(String key, int value) async => setString(key, value.toString());
}

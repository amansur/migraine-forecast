import 'package:drift/drift.dart';

import '../database.dart';
import '../sources/location_source.dart';

/// Repository for per-day location overrides.
///
/// When a row exists for a given calendar day (UTC midnight key), ContextBuilder
/// uses its (lat, lon) instead of the live GPS/manual location. This lets
/// users correct their location for past days they spent while travelling.
class LocationOverridesRepo {
  final AppDatabase _db;

  LocationOverridesRepo(this._db);

  /// Returns the override location for [day], or null if none is set.
  ///
  /// [day] is normalised to UTC midnight before lookup, so callers can pass
  /// any DateTime on the same calendar day.
  Future<UserLocation?> forDay(DateTime day) async {
    final key = _toUtcMidnight(day);
    final query = _db.select(_db.dayLocationOverrides)
      ..where((t) => t.day.equals(key));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return UserLocation(lat: row.lat, lon: row.lon);
  }

  /// Persists a location override for [day], replacing any existing row.
  Future<void> set(DateTime day, UserLocation loc, String displayName) async {
    final key = _toUtcMidnight(day);
    await _db.into(_db.dayLocationOverrides).insertOnConflictUpdate(
          DayLocationOverridesCompanion.insert(
            day: key,
            lat: loc.lat,
            lon: loc.lon,
            displayName: displayName,
            setAt: DateTime.now().toUtc(),
          ),
        );
  }

  /// Removes the override for [day] (no-op if none exists).
  Future<void> clear(DateTime day) async {
    final key = _toUtcMidnight(day);
    await (_db.delete(_db.dayLocationOverrides)
          ..where((t) => t.day.equals(key)))
        .go();
  }

  /// Streams all active overrides as a map from UTC-midnight day → UserLocation.
  /// Emits a new value whenever any override is added, updated, or removed.
  Stream<Map<DateTime, UserLocation>> watchAll() {
    return _db.select(_db.dayLocationOverrides).watch().map((rows) {
      return {
        for (final r in rows) r.day: UserLocation(lat: r.lat, lon: r.lon),
      };
    });
  }

  /// Streams the override for a single [day], or null if none exists.
  Stream<DayLocationOverride?> watchForDay(DateTime day) {
    final key = _toUtcMidnight(day);
    return (_db.select(_db.dayLocationOverrides)
          ..where((t) => t.day.equals(key)))
        .watchSingleOrNull();
  }

  static DateTime _toUtcMidnight(DateTime d) {
    final u = d.toUtc();
    return DateTime.utc(u.year, u.month, u.day);
  }
}

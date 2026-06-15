import 'package:migraine_forecast/data/database.dart' show DayLocationOverride;
import 'package:migraine_forecast/data/repos/location_overrides_repo.dart';
import 'package:migraine_forecast/data/sources/location_source.dart';

/// In-memory fake used by widget tests to avoid drift's streaming-query
/// pollers, which leave pending timers after the widget tree disposes.
class FakeLocationOverridesRepo implements LocationOverridesRepo {
  final Map<DateTime, ({UserLocation loc, String displayName})> _byDay = {};

  void seed(DateTime day, UserLocation loc, String displayName) {
    _byDay[_key(day)] = (loc: loc, displayName: displayName);
  }

  @override
  Future<UserLocation?> forDay(DateTime day) async => _byDay[_key(day)]?.loc;

  @override
  Future<void> set(DateTime day, UserLocation loc, String displayName) async {
    _byDay[_key(day)] = (loc: loc, displayName: displayName);
  }

  @override
  Future<void> clear(DateTime day) async {
    _byDay.remove(_key(day));
  }

  @override
  Stream<Map<DateTime, UserLocation>> watchAll() => Stream.value(
        {for (final e in _byDay.entries) e.key: e.value.loc},
      );

  @override
  Stream<DayLocationOverride?> watchForDay(DateTime day) {
    final entry = _byDay[_key(day)];
    if (entry == null) return Stream.value(null);
    return Stream.value(DayLocationOverride(
      day: _key(day),
      lat: entry.loc.lat,
      lon: entry.loc.lon,
      displayName: entry.displayName,
      setAt: DateTime.utc(2026, 1, 1),
    ));
  }

  static DateTime _key(DateTime d) {
    final u = d.toUtc();
    return DateTime.utc(u.year, u.month, u.day);
  }
}

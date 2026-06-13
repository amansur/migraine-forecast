import 'package:domain/domain.dart';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import '../../database.dart' hide WeatherSnapshot;
import '../weather_source.dart';
import 'open_meteo_parser.dart';
import 'open_meteo_url_builder.dart';

class OpenMeteoWeatherSource implements WeatherSource {
  final http.Client client;
  final AppDatabase db;
  final Duration freshness;

  OpenMeteoWeatherSource({
    required this.client,
    required this.db,
    this.freshness = const Duration(hours: 1),
  });

  @override
  Future<WeatherSnapshot> fetch({required double lat, required double lon, required DateTime now}) async {
    final nowUtc = now.toUtc();
    final requestedDay = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);

    final cached = await _cachedForDay(lat, lon, requestedDay);
    // Bypass cache for backfills (past days) to avoid returning historically bad caches.
    final todayStart = DateTime.now().toUtc().subtract(const Duration(days: 1)); // allow yesterday/today cache
    final isBackfill = requestedDay.isBefore(todayStart);

    if (cached != null && !isBackfill) {
      final diff = nowUtc.difference(cached.fetchedAt as DateTime);
      if (!diff.isNegative && diff <= freshness) {
        return _toSnapshot(cached, stale: false);
      }
    }

    try {
      final today = DateTime.now().toUtc();
      final todayStart = DateTime.utc(today.year, today.month, today.day);
      final diffDays = todayStart.difference(requestedDay).inDays.abs();
      // Add 2 days of padding because triggers need historical data (leadTime up to 48h)
      // prior to the requested day to calculate trends/drops.
      final pastDays = (diffDays + 2).clamp(1, 90);
      final forecastRes = await client.get(OpenMeteoUrlBuilder.forecast(lat: lat, lon: lon, pastDays: pastDays));
      final aqRes = await client.get(OpenMeteoUrlBuilder.airQuality(lat: lat, lon: lon, pastDays: pastDays));
      if (forecastRes.statusCode >= 400 || aqRes.statusCode >= 400) {
        if (cached != null) return _toSnapshot(cached, stale: true);
        throw StateError('Open-Meteo fetch failed (no cache)');
      }
      await db.into(db.weatherSnapshots).insert(
            WeatherSnapshotsCompanion.insert(
              fetchedAt: nowUtc,
              lat: lat,
              lon: lon,
              forecastJson: forecastRes.body,
              airQualityJson: Value(aqRes.body),
            ),
          );
      return WeatherSnapshot(
        weather: OpenMeteoParser.parseForecast(forecastRes.body),
        airQuality: OpenMeteoParser.parseAirQuality(aqRes.body),
        fetchedAt: nowUtc,
        stale: false,
      );
    } catch (_) {
      if (cached != null) return _toSnapshot(cached, stale: true);
      rethrow;
    }
  }

  Future<dynamic> _cachedForDay(double lat, double lon, DateTime day) async {
    final start = day;
    final end = day.add(const Duration(days: 1));
    final q = db.select(db.weatherSnapshots)
      ..where((t) =>
          t.lat.equals(lat) &
          t.lon.equals(lon) &
          t.fetchedAt.isBiggerOrEqualValue(start) &
          t.fetchedAt.isSmallerThanValue(end))
      ..orderBy([(t) => OrderingTerm.desc(t.fetchedAt)])
      ..limit(1);
    final rows = await q.get();
    return rows.isEmpty ? null : rows.first;
  }

  WeatherSnapshot _toSnapshot(dynamic row, {required bool stale}) => WeatherSnapshot(
        weather: OpenMeteoParser.parseForecast(row.forecastJson),
        airQuality: row.airQualityJson == null
            ? const AirQualitySeries(samples: [])
            : OpenMeteoParser.parseAirQuality(row.airQualityJson!),
        fetchedAt: row.fetchedAt,
        stale: stale,
      );
}

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
    final cached = await _latestCached(lat, lon);
    if (cached != null && now.difference(cached.fetchedAt) <= freshness) {
      return _toSnapshot(cached, stale: false);
    }
    try {
      final diffDays = DateTime.now().difference(now).inDays.abs();
      final pastDays = diffDays.clamp(1, 90);
      final forecastRes = await client.get(OpenMeteoUrlBuilder.forecast(lat: lat, lon: lon, pastDays: pastDays));
      final aqRes = await client.get(OpenMeteoUrlBuilder.airQuality(lat: lat, lon: lon));
      if (forecastRes.statusCode >= 400 || aqRes.statusCode >= 400) {
        if (cached != null) return _toSnapshot(cached, stale: true);
        throw StateError('Open-Meteo fetch failed (no cache)');
      }
      await db.into(db.weatherSnapshots).insert(
            WeatherSnapshotsCompanion.insert(
              fetchedAt: now,
              lat: lat,
              lon: lon,
              forecastJson: forecastRes.body,
              airQualityJson: Value(aqRes.body),
            ),
          );
      return WeatherSnapshot(
        weather: OpenMeteoParser.parseForecast(forecastRes.body),
        airQuality: OpenMeteoParser.parseAirQuality(aqRes.body),
        fetchedAt: now,
        stale: false,
      );
    } catch (_) {
      if (cached != null) return _toSnapshot(cached, stale: true);
      rethrow;
    }
  }

  Future<dynamic> _latestCached(double lat, double lon) async {
    final q = db.select(db.weatherSnapshots)
      ..where((t) => t.lat.equals(lat) & t.lon.equals(lon))
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

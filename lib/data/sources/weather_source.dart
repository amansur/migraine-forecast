import 'package:domain/domain.dart';

class WeatherSnapshot {
  final WeatherSeries weather;
  final AirQualitySeries airQuality;
  final DateTime fetchedAt;
  final bool stale;
  const WeatherSnapshot({
    required this.weather,
    required this.airQuality,
    required this.fetchedAt,
    this.stale = false,
  });
}

abstract class WeatherSource {
  /// Returns the latest cached snapshot if fresh (per the source's freshness
  /// policy), otherwise fetches a new one. Returns a stale snapshot if a fetch
  /// fails and a cached value exists.
  ///
  /// Pass [forceRefresh] = true to bypass the cache and issue a new network
  /// request immediately (used by BulkBackfillOrchestrator to prime the cache
  /// with a single 90-day fetch before the per-day loop).
  Future<WeatherSnapshot> fetch({
    required double lat,
    required double lon,
    required DateTime now,
    bool forceRefresh = false,
  });
}

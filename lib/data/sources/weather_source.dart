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
  /// with a single wide fetch before the per-day loop).
  ///
  /// Pass [pastDays] to override the number of past days requested from the
  /// API. When null, the source derives pastDays from the difference between
  /// today and [now] (existing behaviour, unchanged for today/tomorrow flows).
  Future<WeatherSnapshot> fetch({
    required double lat,
    required double lon,
    required DateTime now,
    bool forceRefresh = false,
    int? pastDays,
  });

  /// Fetches the archive (truly historical) weather series covering
  /// [startDate]..[endDate] inclusive and writes it to the cache so subsequent
  /// per-day cache lookups for dates in that range succeed.
  ///
  /// Used by [BulkBackfillOrchestrator] to fill the >30-day-back portion of
  /// the backfill window, which Open-Meteo's forecast endpoint returns as
  /// nulls. Default implementation is a no-op so test fakes don't have to
  /// implement archive support.
  Future<void> primeArchive({
    required double lat,
    required double lon,
    required DateTime startDate,
    required DateTime endDate,
  }) async {}
}

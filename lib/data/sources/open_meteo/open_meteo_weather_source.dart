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
  Future<WeatherSnapshot> fetch({
    required double lat,
    required double lon,
    required DateTime now,
    bool forceRefresh = false,
    int? pastDays,
  }) async {
    final nowUtc = now.toUtc();
    final requestedDay = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);

    final today = DateTime.now().toUtc();
    final todayStart = DateTime.utc(today.year, today.month, today.day);

    final cached = await _cachedForDay(lat, lon, requestedDay);
    if (cached != null && !forceRefresh) {
      // For past days the data is immutable historical, so a coverage match is
      // always good enough — skip the freshness check (the cache row was fetched
      // "after" the requested day, so the diff would be negative and the old
      // freshness gate would reject it). For today/tomorrow we still require
      // the cached row to be within [0, freshness] of `now`.
      if (requestedDay.isBefore(todayStart)) {
        return _toSnapshot(cached, stale: false);
      }
      final diff = nowUtc.difference(cached.fetchedAt as DateTime);
      if (!diff.isNegative && diff <= freshness) {
        return _toSnapshot(cached, stale: false);
      }
    }

    try {
      final diffDays = todayStart.difference(requestedDay).inDays.abs();
      final useArchive = diffDays > 30;
      final http.Response forecastRes;
      final String sourceTag;
      if (useArchive) {
        forecastRes = await client.get(
          OpenMeteoUrlBuilder.archive(
            lat: lat,
            lon: lon,
            startDate: requestedDay.subtract(const Duration(days: 2)),
            endDate: requestedDay.add(const Duration(days: 1)),
          ),
        );
        sourceTag = 'archive';
      } else {
        // Add 2 days of padding because triggers need historical data (leadTime up to 48h)
        // prior to the requested day to calculate trends/drops. Caller may
        // supply pastDays explicitly (e.g. the prime fetch in BulkBackfillOrchestrator).
        final effectivePastDays = pastDays != null
            ? pastDays.clamp(1, 90)
            : (diffDays + 2).clamp(1, 90);
        forecastRes = await client.get(
          OpenMeteoUrlBuilder.forecast(lat: lat, lon: lon, pastDays: effectivePastDays),
        );
        sourceTag = 'forecast';
      }
      final aqPastDays = pastDays != null
          ? pastDays.clamp(1, 92)
          : (diffDays + 2).clamp(1, 92);
      final aqRes = await client.get(OpenMeteoUrlBuilder.airQuality(lat: lat, lon: lon, pastDays: aqPastDays));
      if (forecastRes.statusCode >= 400 || aqRes.statusCode >= 400) {
        if (cached != null) return _toSnapshot(cached, stale: true);
        throw StateError('Open-Meteo fetch failed (no cache)');
      }

      // Derive coverage window from the returned forecast series so future
      // coverage-aware cache lookups can find this row without parsing JSON.
      final times = AppDatabase.extractForecastTimes(forecastRes.body);
      final coverageStart = times.isNotEmpty ? times.first : null;
      final coverageEnd = times.isNotEmpty ? times.last : null;

      await db.into(db.weatherSnapshots).insert(
            WeatherSnapshotsCompanion.insert(
              fetchedAt: nowUtc,
              lat: lat,
              lon: lon,
              forecastJson: forecastRes.body,
              airQualityJson: Value(aqRes.body),
              source: Value(sourceTag),
              coverageStart: Value(coverageStart),
              coverageEnd: Value(coverageEnd),
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

  @override
  Future<void> primeArchive({
    required double lat,
    required double lon,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startUtc = DateTime.utc(startDate.year, startDate.month, startDate.day);
    final endUtc = DateTime.utc(endDate.year, endDate.month, endDate.day);
    if (!endUtc.isAfter(startUtc)) return;

    final forecastRes =
        await client.get(OpenMeteoUrlBuilder.archive(lat: lat, lon: lon, startDate: startUtc, endDate: endUtc));
    if (forecastRes.statusCode >= 400) {
      throw StateError('Open-Meteo archive prime failed (${forecastRes.statusCode})');
    }

    // Air quality archive isn't supported by Open-Meteo's archive endpoint;
    // store an empty AQ JSON so the parser yields an empty series for these
    // older days. AQ contributors degrade naturally.
    const emptyAq = '{"hourly":{"time":[],"pm2_5":[]}}';

    final times = AppDatabase.extractForecastTimes(forecastRes.body);
    final coverageStart = times.isNotEmpty ? times.first : null;
    final coverageEnd = times.isNotEmpty ? times.last : null;

    await db.into(db.weatherSnapshots).insert(
          WeatherSnapshotsCompanion.insert(
            fetchedAt: DateTime.now().toUtc(),
            lat: lat,
            lon: lon,
            forecastJson: forecastRes.body,
            airQualityJson: const Value(emptyAq),
            source: const Value('archive'),
            coverageStart: Value(coverageStart),
            coverageEnd: Value(coverageEnd),
          ),
        );
  }

  /// Returns the most recently fetched snapshot for [lat]/[lon] whose forecast
  /// series *covers* [day] (i.e. coverageStart <= day <= coverageEnd).
  ///
  /// Falls back to the fetchedAt-keyed lookup (same-day bucket) for rows where
  /// coverage doesn't match — this keeps the today/tomorrow flows working with
  /// the existing fixtures and with pre-v7 rows migrated without coverage data.
  Future<dynamic> _cachedForDay(double lat, double lon, DateTime day) async {
    final dayEnd = day.add(const Duration(days: 1));

    // Coverage-aware query: the series must span at least [day, day].
    final coverageQuery = db.select(db.weatherSnapshots)
      ..where((t) =>
          t.lat.equals(lat) &
          t.lon.equals(lon) &
          t.coverageStart.isSmallerOrEqualValue(day) &
          t.coverageEnd.isBiggerOrEqualValue(day))
      ..orderBy([(t) => OrderingTerm.desc(t.fetchedAt)])
      ..limit(1);
    final coverageRows = await coverageQuery.get();
    if (coverageRows.isNotEmpty) return coverageRows.first;

    // Fallback: fetchedAt-keyed lookup for rows fetched on the same calendar
    // day. Covers two cases:
    //   1. Pre-v7 rows whose coverage columns are null (migration left them null
    //      if forecastJson was unparseable).
    //   2. Rows fetched today whose coverage window doesn't literally include
    //      today (e.g. fixture JSON with hardcoded past dates in unit tests).
    // This fallback is only safe for "today" requests where `day` equals the
    // fetch date — it preserves the original freshness-based caching semantics
    // without breaking the coverage invariant for genuine past-day lookups.
    final legacyQuery = db.select(db.weatherSnapshots)
      ..where((t) =>
          t.lat.equals(lat) &
          t.lon.equals(lon) &
          t.fetchedAt.isBiggerOrEqualValue(day) &
          t.fetchedAt.isSmallerThanValue(dayEnd))
      ..orderBy([(t) => OrderingTerm.desc(t.fetchedAt)])
      ..limit(1);
    final legacyRows = await legacyQuery.get();
    return legacyRows.isEmpty ? null : legacyRows.first;
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

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:migraine_forecast/data/database.dart';
import 'package:migraine_forecast/data/sources/open_meteo/open_meteo_weather_source.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  Future<String> fx(String name) async =>
      File('test/data/sources/fixtures/open_meteo/$name').readAsString();

  test('fetches once and caches within freshness window', () async {
    var calls = 0;
    final client = MockClient((req) async {
      calls++;
      if (req.url.host == 'api.open-meteo.com') {
        return http.Response(await fx('forecast_typical_day.json'), 200);
      }
      return http.Response(await fx('air_quality_typical.json'), 200);
    });
    final source = OpenMeteoWeatherSource(client: client, db: db, freshness: const Duration(hours: 1));
    final realNow = DateTime.now().toUtc();
    final now = DateTime.utc(realNow.year, realNow.month, realNow.day, 6); // Use real now so it isn't treated as a backfill
    final first = await source.fetch(lat: 40.7, lon: -74.0, now: now);
    expect(first.stale, isFalse);
    expect(calls, 2);

    // 30 minutes later, no new HTTP calls.
    final second = await source.fetch(lat: 40.7, lon: -74.0, now: now.add(const Duration(minutes: 30)));
    expect(second.stale, isFalse);
    expect(calls, 2);
  });

  test('returns stale snapshot when network fails after cache expires', () async {
    var calls = 0;
    final client = MockClient((req) async {
      calls++;
      if (calls <= 2) {
        return http.Response(
          req.url.host == 'api.open-meteo.com'
              ? await fx('forecast_typical_day.json')
              : await fx('air_quality_typical.json'),
          200,
        );
      }
      throw const SocketException('offline');
    });
    // Freshness is measured against the real wall clock, so expiry is
    // simulated by advancing an injected clock rather than the `now` anchor.
    var clock = DateTime.utc(2026, 6, 11, 6);
    final source = OpenMeteoWeatherSource(
        client: client, db: db, freshness: const Duration(hours: 1), clock: () => clock);
    final now = DateTime.utc(2026, 6, 11, 6);
    await source.fetch(lat: 40.7, lon: -74.0, now: now);

    clock = clock.add(const Duration(hours: 3));
    final stale = await source.fetch(lat: 40.7, lon: -74.0, now: now.add(const Duration(hours: 3)));
    expect(stale.stale, isTrue);
    expect(stale.weather.samples, isNotEmpty);
  });

  test('past-day fetch does not return today\'s cached snapshot', () async {
    final today = DateTime.utc(2026, 6, 11, 12);
    final fiveDaysAgo = DateTime.utc(2026, 6, 6, 12);

    // Seed cache with today's snapshot.
    var calls = 0;
    final seedClient = MockClient((req) async {
      calls++;
      if (req.url.host == 'api.open-meteo.com') {
        return http.Response(await fx('forecast_typical_day.json'), 200);
      }
      return http.Response(await fx('air_quality_typical.json'), 200);
    });
    final seedSource =
        OpenMeteoWeatherSource(client: seedClient, db: db, freshness: const Duration(hours: 1), clock: () => today);
    await seedSource.fetch(lat: 40.7, lon: -74.0, now: today);
    expect(calls, 2);

    // Now fetch for 5 days ago. Must hit the network — cache covers today only.
    Uri? hitUrl;
    final pastClient = MockClient((req) async {
      hitUrl = req.url;
      if (req.url.host == 'api.open-meteo.com') {
        return http.Response(await fx('forecast_pressure_drop.json'), 200);
      }
      return http.Response(await fx('air_quality_typical.json'), 200);
    });
    final source =
        OpenMeteoWeatherSource(client: pastClient, db: db, freshness: const Duration(hours: 1), clock: () => today);
    final snapshot = await source.fetch(lat: 40.7, lon: -74.0, now: fiveDaysAgo);

    expect(hitUrl, isNotNull, reason: 'past-day fetch must hit the network');
    // fetchedAt is the real fetch time (the injected clock), not the anchor.
    expect(snapshot.fetchedAt, today);
    expect(snapshot.stale, isFalse);
  });

  test('past-day fetch returns from coverage-aware cache on second call within freshness', () async {
    // After the coverage-aware cache was introduced (v7), the `!isBackfill`
    // bypass was removed. A past-day snapshot is stored with coverageStart /
    // coverageEnd and is found on subsequent lookups within the freshness window,
    // just like today's snapshots. This eliminates the per-day network calls
    // during backfill while keeping the cache correct.
    final pastDay = DateTime.utc(2026, 6, 6, 12);
    // Series genuinely covering Jun 5–7 so the coverage-aware lookup can
    // serve the repeat request (the old fixture only spanned Jun 10–11 and
    // the test silently leaned on the legacy fetchedAt-bucket fallback).
    String coveringForecast() {
      final times = <String>[];
      for (var d = 5; d <= 7; d++) {
        for (var h = 0; h < 24; h++) {
          times.add('"2026-06-${d.toString().padLeft(2, '0')}T${h.toString().padLeft(2, '0')}:00"');
        }
      }
      final vals = List.filled(times.length, 1013).join(',');
      return '{"hourly":{"time":[${times.join(',')}],"pressure_msl":[$vals],"temperature_2m":[$vals],"relative_humidity_2m":[$vals]}}';
    }

    var calls = 0;
    final client = MockClient((req) async {
      calls++;
      if (req.url.host == 'api.open-meteo.com') {
        return http.Response(coveringForecast(), 200);
      }
      return http.Response(await fx('air_quality_typical.json'), 200);
    });
    final source =
        OpenMeteoWeatherSource(client: client, db: db, freshness: const Duration(hours: 1), clock: () => DateTime.utc(2026, 6, 11, 12));

    await source.fetch(lat: 40.7, lon: -74.0, now: pastDay);
    expect(calls, 2);

    // Re-fetch the same past day 10 minutes later — returns from cache (no new calls).
    final second = await source.fetch(
      lat: 40.7,
      lon: -74.0,
      now: pastDay.add(const Duration(minutes: 10)),
    );
    expect(calls, 2, reason: 'coverage-aware cache serves past-day within freshness');
    expect(second.stale, isFalse);
  });

  test('fetch routes to archive endpoint when requestedDay is > 30 days old',
      () async {
    final calls = <Uri>[];
    final client = MockClient((req) async {
      calls.add(req.url);
      if (req.url.host.contains('archive-api')) {
        return http.Response(
          '{"hourly":{"time":[],"pressure_msl":[],"temperature_2m":[],"relative_humidity_2m":[]}}',
          200,
        );
      }
      if (req.url.host.contains('air-quality')) {
        return http.Response('{"hourly":{"time":[],"pm2_5":[]}}', 200);
      }
      return http.Response('{"hourly":{"time":[],"pressure_msl":[],"temperature_2m":[],"relative_humidity_2m":[]}}', 200);
    });
    final fixedToday = DateTime.utc(2026, 6, 11, 12);
    final source = OpenMeteoWeatherSource(client: client, db: db, clock: () => fixedToday);

    // 60 days ago relative to fixed "today" (2026-06-11)
    final old = DateTime.utc(2026, 6, 11).subtract(const Duration(days: 60));

    await source.fetch(lat: 0, lon: 0, now: old, forceRefresh: true);

    expect(calls.any((u) => u.host.contains('archive-api')), isTrue);
    expect(
      calls.any((u) => u.host == 'api.open-meteo.com' && u.path == '/v1/forecast'),
      isFalse,
    );
  });

  test('one 7-day fetch serves outlook days and today from cache', () async {
    // Regression for the outlook cache blocker: a fresh 7-day series must
    // serve future-day (d+2..d+6) requests via coverage, and outlook fetches
    // must never poison subsequent today lookups.
    final clock = DateTime.utc(2026, 6, 11, 12);
    String sevenDayForecast() {
      final times = <String>[];
      final vals = <num>[];
      for (var d = 0; d < 7; d++) {
        for (var h = 0; h < 24; h++) {
          times.add('2026-06-${11 + d}T${h.toString().padLeft(2, '0')}:00');
          vals.add(1013);
        }
      }
      final t = times.map((s) => '"$s"').join(',');
      final p = vals.join(',');
      return '{"hourly":{"time":[$t],"pressure_msl":[$p],"temperature_2m":[$p],"relative_humidity_2m":[$p]}}';
    }

    var calls = 0;
    final client = MockClient((req) async {
      calls++;
      if (req.url.host == 'api.open-meteo.com') {
        return http.Response(sevenDayForecast(), 200);
      }
      return http.Response('{"hourly":{"time":[],"pm2_5":[]}}', 200);
    });
    final source = OpenMeteoWeatherSource(
        client: client, db: db, freshness: const Duration(hours: 1), clock: () => clock);

    final today = DateTime.utc(2026, 6, 11, 12);
    await source.fetch(lat: 40.7, lon: -74.0, now: today);
    expect(calls, 2);

    // Outlook days d+2..d+6: all served from the covering series.
    for (var i = 2; i <= 6; i++) {
      final s = await source.fetch(
          lat: 40.7, lon: -74.0, now: DateTime.utc(2026, 6, 11 + i));
      expect(s.stale, isFalse);
    }
    expect(calls, 2, reason: 'outlook days must hit the coverage-aware cache');

    // Today again after outlook traffic: still cached.
    await source.fetch(lat: 40.7, lon: -74.0, now: today);
    expect(calls, 2, reason: 'outlook fetches must not poison the today cache');
  });
}

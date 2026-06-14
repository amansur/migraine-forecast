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
    final source = OpenMeteoWeatherSource(client: client, db: db, freshness: const Duration(hours: 1));
    final realNow = DateTime.now().toUtc();
    final now = DateTime.utc(realNow.year, realNow.month, realNow.day, 6); // start at 6am to avoid crossing midnight when adding 3 hours
    await source.fetch(lat: 40.7, lon: -74.0, now: now);

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
        OpenMeteoWeatherSource(client: seedClient, db: db, freshness: const Duration(hours: 1));
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
        OpenMeteoWeatherSource(client: pastClient, db: db, freshness: const Duration(hours: 1));
    final snapshot = await source.fetch(lat: 40.7, lon: -74.0, now: fiveDaysAgo);

    expect(hitUrl, isNotNull, reason: 'past-day fetch must hit the network');
    expect(snapshot.fetchedAt, fiveDaysAgo);
    expect(snapshot.stale, isFalse);
  });

  test('past-day fetch ALWAYS hits network to ensure self-healing', () async {
    final pastDay = DateTime.utc(2026, 6, 6, 12);
    var calls = 0;
    final client = MockClient((req) async {
      calls++;
      if (req.url.host == 'api.open-meteo.com') {
        return http.Response(await fx('forecast_pressure_drop.json'), 200);
      }
      return http.Response(await fx('air_quality_typical.json'), 200);
    });
    final source =
        OpenMeteoWeatherSource(client: client, db: db, freshness: const Duration(hours: 1));

    await source.fetch(lat: 40.7, lon: -74.0, now: pastDay);
    expect(calls, 2);

    // Re-fetch the same past day 10 minutes later — it WILL hit network again because
    // backfills bypass cache to guarantee historical healing.
    final second = await source.fetch(
      lat: 40.7,
      lon: -74.0,
      now: pastDay.add(const Duration(minutes: 10)),
    );
    expect(calls, 4, reason: 'backfills always bypass cache');
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
    final source = OpenMeteoWeatherSource(client: client, db: db);

    // 60 days ago relative to current real "today"
    final realToday = DateTime.now().toUtc();
    final old = DateTime.utc(realToday.year, realToday.month, realToday.day)
        .subtract(const Duration(days: 60));

    await source.fetch(lat: 0, lon: 0, now: old, forceRefresh: true);

    expect(calls.any((u) => u.host.contains('archive-api')), isTrue);
    expect(
      calls.any((u) => u.host == 'api.open-meteo.com' && u.path == '/v1/forecast'),
      isFalse,
    );
  });
}

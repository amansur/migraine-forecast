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
    final now = DateTime.utc(2026, 6, 10, 6);
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
    final now = DateTime.utc(2026, 6, 10, 6);
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

  test('past-day fetch is cached on subsequent calls for the same day', () async {
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

    // Re-fetch the same past day 10 minutes later — should hit cache.
    final second = await source.fetch(
      lat: 40.7,
      lon: -74.0,
      now: pastDay.add(const Duration(minutes: 10)),
    );
    expect(calls, 2, reason: 'same-day cache hit must not hit the network');
    expect(second.stale, isFalse);
  });
}

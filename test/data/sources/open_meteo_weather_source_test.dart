import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:migraine_weatherr/data/database.dart';
import 'package:migraine_weatherr/data/sources/open_meteo/open_meteo_weather_source.dart';

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
}

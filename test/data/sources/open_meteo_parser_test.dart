import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:migraine_forecast/data/sources/open_meteo/open_meteo_parser.dart';

void main() {
  test('parses a typical forecast into a WeatherSeries', () {
    final json = File('test/data/sources/fixtures/open_meteo/forecast_typical_day.json').readAsStringSync();
    final series = OpenMeteoParser.parseForecast(json);
    expect(series.samples, hasLength(8));
    expect(series.samples.first.pressureMsl, 1015.0);
    expect(series.samples.first.at, DateTime.utc(2026, 6, 10, 0));
    expect(series.samples.first.humidityPct, 55);
  });

  test('parses a pressure-drop scenario and the WeatherSeries surfaces the drop', () {
    final json = File('test/data/sources/fixtures/open_meteo/forecast_pressure_drop.json').readAsStringSync();
    final series = OpenMeteoParser.parseForecast(json);
    final anchor = series.samples.last.at;
    final drop = series.maxPressureDropAround(anchor, const Duration(hours: 24), now: anchor);
    expect(drop, closeTo(14.0, 0.1)); // 1020 -> 1006 over 24h
  });

  test('parses air quality JSON', () {
    final json = File('test/data/sources/fixtures/open_meteo/air_quality_typical.json').readAsStringSync();
    final aq = OpenMeteoParser.parseAirQuality(json);
    expect(aq.samples, hasLength(4));
    expect(aq.samples.last.pm25, 28.0);
  });

  test('parses an archive-endpoint response with the same parser', () {
    final json = File('test/data/sources/fixtures/open_meteo/archive_typical_day.json').readAsStringSync();
    final series = OpenMeteoParser.parseForecast(json);
    expect(series.samples, hasLength(6));
    expect(series.samples.first.pressureMsl, 1012.4);
    expect(series.samples.first.at, DateTime.utc(2026, 3, 16, 0));
    expect(series.samples.last.humidityPct, 80);
  });

  test('throws on malformed JSON', () {
    expect(() => OpenMeteoParser.parseForecast('not json'), throwsFormatException);
  });

  test('series without wind_gusts_10m parses with null gusts (pre-wind cache rows)', () {
    final json = File('test/data/sources/fixtures/open_meteo/forecast_typical_day.json')
        .readAsStringSync();
    final series = OpenMeteoParser.parseForecast(json);
    expect(series.samples, isNotEmpty);
    expect(series.samples.every((s) => s.windGustKph == null), isTrue);
  });

  test('series with wind_gusts_10m carries gust values', () {
    const body = '{"hourly":{"time":["2026-07-09T00:00","2026-07-09T01:00"],'
        '"pressure_msl":[1013,1012],"temperature_2m":[20,21],'
        '"relative_humidity_2m":[50,55],"wind_gusts_10m":[38.5,null]}}';
    final series = OpenMeteoParser.parseForecast(body);
    expect(series.samples, hasLength(2));
    expect(series.samples.first.windGustKph, 38.5);
    expect(series.samples.last.windGustKph, isNull);
  });
}

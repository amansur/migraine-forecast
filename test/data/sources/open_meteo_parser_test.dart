import 'dart:io';

import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/sources/open_meteo/open_meteo_parser.dart';

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
    final drop = series.maxPressureDropOver(const Duration(hours: 24));
    expect(drop, closeTo(14.0, 0.1)); // 1020 -> 1006 over 24h
  });

  test('parses air quality JSON', () {
    final json = File('test/data/sources/fixtures/open_meteo/air_quality_typical.json').readAsStringSync();
    final aq = OpenMeteoParser.parseAirQuality(json);
    expect(aq.samples, hasLength(4));
    expect(aq.samples.last.pm25, 28.0);
  });

  test('throws on malformed JSON', () {
    expect(() => OpenMeteoParser.parseForecast('not json'), throwsFormatException);
  });
}

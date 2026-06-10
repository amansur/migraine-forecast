import 'dart:convert';

import 'package:domain/domain.dart';

class OpenMeteoParser {
  static WeatherSeries parseForecast(String body) {
    final root = jsonDecode(body) as Map<String, Object?>;
    final hourly = root['hourly'] as Map<String, Object?>?;
    if (hourly == null) {
      throw const FormatException('Open-Meteo response missing "hourly"');
    }
    final times = (hourly['time'] as List).cast<String>();
    final pressures = (hourly['pressure_msl'] as List).cast<num>();
    final temps = (hourly['temperature_2m'] as List).cast<num>();
    final humidities = (hourly['relative_humidity_2m'] as List).cast<num>();
    final samples = <WeatherSample>[];
    for (var i = 0; i < times.length; i++) {
      samples.add(WeatherSample(
        at: _parseUtc(times[i]),
        pressureMsl: pressures[i].toDouble(),
        temperatureC: temps[i].toDouble(),
        humidityPct: humidities[i].toDouble(),
      ));
    }
    return WeatherSeries(samples: samples);
  }

  static AirQualitySeries parseAirQuality(String body) {
    final root = jsonDecode(body) as Map<String, Object?>;
    final hourly = root['hourly'] as Map<String, Object?>?;
    if (hourly == null) {
      throw const FormatException('Open-Meteo AQ response missing "hourly"');
    }
    final times = (hourly['time'] as List).cast<String>();
    final pm25 = (hourly['pm2_5'] as List).cast<num>();
    final samples = <AirQualitySample>[];
    for (var i = 0; i < times.length; i++) {
      samples.add(AirQualitySample(at: _parseUtc(times[i]), pm25: pm25[i].toDouble()));
    }
    return AirQualitySeries(samples: samples);
  }

  static DateTime _parseUtc(String s) =>
      DateTime.parse(s.endsWith('Z') || s.contains('+') ? s : '${s}Z');
}

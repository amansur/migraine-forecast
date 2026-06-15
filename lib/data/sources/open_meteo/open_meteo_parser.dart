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
    final pressures = (hourly['pressure_msl'] as List);
    final temps = (hourly['temperature_2m'] as List);
    final humidities = (hourly['relative_humidity_2m'] as List);
    final samples = <WeatherSample>[];
    for (var i = 0; i < times.length; i++) {
      // Open-Meteo returns nulls for hours where a series is unavailable
      // (partial current hour, sparse archive coverage). Skip those samples
      // rather than failing the whole parse.
      final p = pressures[i];
      final t = temps[i];
      final h = humidities[i];
      if (p is! num || t is! num || h is! num) continue;
      samples.add(WeatherSample(
        at: _parseUtc(times[i]),
        pressureMsl: p.toDouble(),
        temperatureC: t.toDouble(),
        humidityPct: h.toDouble(),
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
    final pm25 = (hourly['pm2_5'] as List);
    final samples = <AirQualitySample>[];
    for (var i = 0; i < times.length; i++) {
      final v = pm25[i];
      if (v is! num) continue;
      samples.add(AirQualitySample(at: _parseUtc(times[i]), pm25: v.toDouble()));
    }
    return AirQualitySeries(samples: samples);
  }

  static DateTime _parseUtc(String s) =>
      DateTime.parse(s.endsWith('Z') || s.contains('+') ? s : '${s}Z');
}

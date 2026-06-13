import 'package:equatable/equatable.dart';

class WeatherSample extends Equatable {
  final DateTime at;
  final double pressureMsl;     // hPa
  final double temperatureC;
  final double humidityPct;
  const WeatherSample({
    required this.at,
    required this.pressureMsl,
    required this.temperatureC,
    required this.humidityPct,
  });
  @override
  List<Object?> get props => [at, pressureMsl, temperatureC, humidityPct];
}

class WeatherSeries extends Equatable {
  /// Hourly samples, sorted ascending by `at`. May include historical + forecast.
  final List<WeatherSample> samples;
  const WeatherSeries({required this.samples});

  /// Past when [anchor] ≤ [now]: [anchor - window, anchor]. Future otherwise:
  /// [anchor, anchor + window]. Inclusive at both ends.
  Iterable<WeatherSample> _around(DateTime anchor, Duration window, DateTime now) {
    if (anchor.isAfter(now)) {
      return samples.where((s) => !s.at.isBefore(anchor) && !s.at.isAfter(anchor.add(window)));
    }
    return samples.where((s) => !s.at.isBefore(anchor.subtract(window)) && !s.at.isAfter(anchor));
  }

  /// Max pressure drop across any pair within [slidingSpan] of each other, where
  /// both samples lie in the outer window of [anchor]±[window]. [slidingSpan]
  /// defaults to 24h — the migraine-relevant timeframe — independent of how far
  /// the outer horizon reaches.
  double? maxPressureDropAround(
    DateTime anchor,
    Duration window, {
    required DateTime now,
    Duration slidingSpan = const Duration(hours: 24),
  }) {
    final inWindow = _around(anchor, window, now).toList();
    if (inWindow.length < 2) return null;
    double maxDrop = 0;
    int j = 0;
    for (int i = 0; i < inWindow.length; i++) {
      while (j < inWindow.length && inWindow[j].at.difference(inWindow[i].at) <= slidingSpan) {
        j++;
      }
      for (int k = i + 1; k < j; k++) {
        final drop = inWindow[i].pressureMsl - inWindow[k].pressureMsl;
        if (drop > maxDrop) maxDrop = drop;
      }
    }
    return maxDrop;
  }

  double? tempSwingAround(DateTime anchor, Duration window, {required DateTime now}) {
    final inWindow = _around(anchor, window, now).toList();
    if (inWindow.isEmpty) return null;
    final max = inWindow.map((s) => s.temperatureC).reduce((a, b) => a > b ? a : b);
    final min = inWindow.map((s) => s.temperatureC).reduce((a, b) => a < b ? a : b);
    return max - min;
  }

  double? tempTrendAround(DateTime anchor, Duration window, {required DateTime now}) {
    final inWindow = _around(anchor, window, now).toList();
    if (inWindow.length < 2) return null;
    return inWindow.last.temperatureC - inWindow.first.temperatureC;
  }

  double? humidityTrendAround(DateTime anchor, Duration window, {required DateTime now}) {
    final inWindow = _around(anchor, window, now).toList();
    if (inWindow.length < 2) return null;
    return inWindow.last.humidityPct - inWindow.first.humidityPct;
  }

  double? maxHumidityAround(DateTime anchor, Duration window, {required DateTime now}) {
    final inWindow = _around(anchor, window, now).toList();
    if (inWindow.isEmpty) return null;
    return inWindow.map((s) => s.humidityPct).reduce((a, b) => a > b ? a : b);
  }

  @override
  List<Object?> get props => [samples];
}

class AirQualitySample extends Equatable {
  final DateTime at;
  final double pm25;      // µg/m³
  const AirQualitySample({required this.at, required this.pm25});
  @override
  List<Object?> get props => [at, pm25];
}

class AirQualitySeries extends Equatable {
  final List<AirQualitySample> samples;
  const AirQualitySeries({required this.samples});

  Iterable<AirQualitySample> _around(DateTime anchor, Duration window, DateTime now) {
    if (anchor.isAfter(now)) {
      return samples.where((s) => !s.at.isBefore(anchor) && !s.at.isAfter(anchor.add(window)));
    }
    return samples.where((s) => !s.at.isBefore(anchor.subtract(window)) && !s.at.isAfter(anchor));
  }

  double? maxPm25Around(DateTime anchor, Duration window, {required DateTime now}) {
    final inWindow = _around(anchor, window, now).toList();
    if (inWindow.isEmpty) return null;
    return inWindow.map((s) => s.pm25).reduce((a, b) => a > b ? a : b);
  }

  @override
  List<Object?> get props => [samples];
}

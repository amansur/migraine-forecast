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

  /// Returns the maximum drop in pressure within any [window]-sized sliding pair.
  /// Returns null if the series is empty or has only one sample.
  double? maxPressureDropOver(Duration window) {
    if (samples.length < 2) return null;
    double maxDrop = 0;
    int j = 0;
    for (int i = 0; i < samples.length; i++) {
      while (j < samples.length && samples[j].at.difference(samples[i].at) <= window) {
        j++;
      }
      for (int k = i + 1; k < j; k++) {
        final drop = samples[i].pressureMsl - samples[k].pressureMsl;
        if (drop > maxDrop) maxDrop = drop;
      }
    }
    return maxDrop;
  }

  /// Returns the max minus min temperature within [window] of the latest sample.
  double? tempSwingInLast(Duration window) {
    if (samples.isEmpty) return null;
    final cutoff = samples.last.at.subtract(window);
    final inWindow = samples.where((s) => !s.at.isBefore(cutoff)).toList();
    if (inWindow.isEmpty) return null;
    final max = inWindow.map((s) => s.temperatureC).reduce((a, b) => a > b ? a : b);
    final min = inWindow.map((s) => s.temperatureC).reduce((a, b) => a < b ? a : b);
    return max - min;
  }

  /// Returns last - first temperature within [window] of the latest sample.
  /// Positive = warming, negative = cooling.
  double? tempTrendInLast(Duration window) {
    if (samples.isEmpty) return null;
    final cutoff = samples.last.at.subtract(window);
    final inWindow = samples.where((s) => !s.at.isBefore(cutoff)).toList();
    if (inWindow.length < 2) return null;
    return inWindow.last.temperatureC - inWindow.first.temperatureC;
  }

  /// Returns last - first humidity within [window] of the latest sample.
  /// Positive = rising, negative = falling.
  double? humidityTrendInLast(Duration window) {
    if (samples.isEmpty) return null;
    final cutoff = samples.last.at.subtract(window);
    final inWindow = samples.where((s) => !s.at.isBefore(cutoff)).toList();
    if (inWindow.length < 2) return null;
    return inWindow.last.humidityPct - inWindow.first.humidityPct;
  }

  /// Maximum humidity value across the next [window] starting from [from].
  double? maxHumidityFrom(DateTime from, Duration window) {
    final inWindow = samples.where(
      (s) => !s.at.isBefore(from) && s.at.isBefore(from.add(window)),
    );
    if (inWindow.isEmpty) return null;
    return inWindow.map((s) => s.humidityPct).reduce((a, b) => a > b ? a : b);
  }

  List<WeatherSample> _between(DateTime start, DateTime end) =>
      samples.where((s) => !s.at.isBefore(start) && !s.at.isAfter(end)).toList();

  /// Max pressure drop within any 24h-or-smaller sliding pair in [start, end].
  double? maxPressureDropInWindow(DateTime start, DateTime end) {
    final inWindow = _between(start, end);
    if (inWindow.length < 2) return null;
    double maxDrop = 0;
    int j = 0;
    for (int i = 0; i < inWindow.length; i++) {
      while (j < inWindow.length && inWindow[j].at.difference(inWindow[i].at) <= const Duration(hours: 24)) {
        j++;
      }
      for (int k = i + 1; k < j; k++) {
        final drop = inWindow[i].pressureMsl - inWindow[k].pressureMsl;
        if (drop > maxDrop) maxDrop = drop;
      }
    }
    return maxDrop;
  }

  /// Max minus min temperature within [start, end].
  double? tempSwingInWindow(DateTime start, DateTime end) {
    final inWindow = _between(start, end);
    if (inWindow.isEmpty) return null;
    final max = inWindow.map((s) => s.temperatureC).reduce((a, b) => a > b ? a : b);
    final min = inWindow.map((s) => s.temperatureC).reduce((a, b) => a < b ? a : b);
    return max - min;
  }

  /// Last minus first temperature within [start, end]. Positive = warming.
  double? tempTrendInWindow(DateTime start, DateTime end) {
    final inWindow = _between(start, end);
    if (inWindow.length < 2) return null;
    return inWindow.last.temperatureC - inWindow.first.temperatureC;
  }

  /// Last minus first humidity within [start, end]. Positive = rising.
  double? humidityTrendInWindow(DateTime start, DateTime end) {
    final inWindow = _between(start, end);
    if (inWindow.length < 2) return null;
    return inWindow.last.humidityPct - inWindow.first.humidityPct;
  }

  /// Peak humidity within [start, end].
  double? maxHumidityInWindow(DateTime start, DateTime end) {
    final inWindow = _between(start, end);
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

  double? maxPm25From(DateTime from, Duration window) {
    final inWindow = samples.where(
      (s) => !s.at.isBefore(from) && s.at.isBefore(from.add(window)),
    );
    if (inWindow.isEmpty) return null;
    return inWindow.map((s) => s.pm25).reduce((a, b) => a > b ? a : b);
  }

  /// Peak PM2.5 within [start, end] inclusive.
  double? maxPm25InWindow(DateTime start, DateTime end) {
    final inWindow = samples.where(
      (s) => !s.at.isBefore(start) && !s.at.isAfter(end),
    );
    if (inWindow.isEmpty) return null;
    return inWindow.map((s) => s.pm25).reduce((a, b) => a > b ? a : b);
  }

  @override
  List<Object?> get props => [samples];
}


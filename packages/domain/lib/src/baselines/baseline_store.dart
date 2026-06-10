class BaselineStore {
  const BaselineStore();

  double _median(List<double> values) {
    if (values.isEmpty) return double.nan;
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2.0;
  }

  double? medianSleepHours(List<double> hours, {int minSamples = 3}) {
    if (hours.length < minSamples) return null;
    return _median(hours);
  }

  double? hrvRmssdBaseline(List<double> rmssdValues, {int minSamples = 10}) {
    if (rmssdValues.length < minSamples) return null;
    return _median(rmssdValues);
  }

  double? pressureBaseline(List<double> pressures, {int minSamples = 3}) {
    if (pressures.length < minSamples) return null;
    return _median(pressures);
  }

  double? caffeineBaselineMg(List<double> dailyMg, {int minSamples = 7}) {
    if (dailyMg.length < minSamples) return null;
    return _median(dailyMg);
  }
}

import 'package:domain/domain.dart';

class BaselineSnapshotBuilder {
  final BaselineStore _store;
  const BaselineSnapshotBuilder(this._store);

  BaselineSnapshot build({
    required List<SleepRecord> sleep,
    required List<HrvSample> hrv,
    required List<double> pastDailyCaffeineMg,
    required List<double> pastPressures,
  }) {
    final sleepMedianHours = _store.medianSleepHours(
      sleep.map((s) => s.totalSleep.inMinutes / 60.0).toList(),
    );
    final hrvBaseline =
        _store.hrvRmssdBaseline(hrv.map((h) => h.rmssdMs).toList());
    final caffeine = _store.caffeineBaselineMg(pastDailyCaffeineMg);
    final pressure = _store.pressureBaseline(pastPressures);

    return BaselineSnapshot(
      sleepMedian7d: sleepMedianHours == null
          ? null
          : Duration(minutes: (sleepMedianHours * 60).round()),
      hrvRmssdBaseline14d: hrvBaseline,
      caffeineDailyMg: caffeine,
      pressureBaseline: pressure,
    );
  }
}

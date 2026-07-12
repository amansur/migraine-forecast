import 'correlation_analyzer.dart';
import 'day_record.dart';

/// A named boolean predicate over a day — "was the user exposed to X?".
class Exposure {
  final String id;
  final bool Function(DayRecord day) test;
  const Exposure(this.id, this.test);

  static Exposure moduleFired(String moduleId) =>
      Exposure(moduleId, (d) => d.firedModuleIds.contains(moduleId));

  /// [weekday] uses DateTime constants (monday = 1 … sunday = 7).
  static Exposure weekday(int weekday) =>
      Exposure('weekday_$weekday', (d) => d.day.weekday == weekday);

  static Exposure both(Exposure a, Exposure b) =>
      Exposure('${a.id}+${b.id}', (d) => a.test(d) && b.test(d));
}

Cohort buildCohort(List<DayRecord> days, Exposure exposure) {
  var firedWithAttack = 0, firedTotal = 0, notFiredWithAttack = 0, notFiredTotal = 0;
  for (final d in days) {
    if (exposure.test(d)) {
      firedTotal++;
      if (d.hadAttack) firedWithAttack++;
    } else {
      notFiredTotal++;
      if (d.hadAttack) notFiredWithAttack++;
    }
  }
  return Cohort(
    exposureId: exposure.id,
    daysFiredWithAttack: firedWithAttack,
    daysFiredTotal: firedTotal,
    daysNotFiredWithAttack: notFiredWithAttack,
    daysNotFiredTotal: notFiredTotal,
  );
}

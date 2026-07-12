import 'package:domain/domain.dart';
import 'package:test/test.dart';

DayRecord day(int d, {Set<String> fired = const {}, bool attack = false}) =>
    DayRecord(
      day: DateTime.utc(2026, 7, d),
      firedModuleIds: fired,
      hadAttack: attack,
    );

void main() {
  test('moduleFired exposure partitions days into 2x2 cohort', () {
    final days = [
      day(1, fired: {'alcohol'}, attack: true),
      day(2, fired: {'alcohol'}),
      day(3, attack: true),
      day(4),
    ];
    final c = buildCohort(days, Exposure.moduleFired('alcohol'));
    expect(c.exposureId, 'alcohol');
    expect(c.daysFiredWithAttack, 1);
    expect(c.daysFiredTotal, 2);
    expect(c.daysNotFiredWithAttack, 1);
    expect(c.daysNotFiredTotal, 2);
  });

  test('weekday exposure selects matching weekdays', () {
    // 2026-07-06 is a Monday.
    final days = [day(6, attack: true), day(7), day(13)];
    final c = buildCohort(days, Exposure.weekday(DateTime.monday));
    expect(c.exposureId, 'weekday_1');
    expect(c.daysFiredTotal, 2);
    expect(c.daysFiredWithAttack, 1);
    expect(c.daysNotFiredTotal, 1);
  });

  test('both() requires both exposures on the same day', () {
    final days = [
      day(1, fired: {'alcohol', 'sleep_deficit'}, attack: true),
      day(2, fired: {'alcohol'}),
    ];
    final c = buildCohort(
        days,
        Exposure.both(
            Exposure.moduleFired('alcohol'), Exposure.moduleFired('sleep_deficit')));
    expect(c.exposureId, 'alcohol+sleep_deficit');
    expect(c.daysFiredTotal, 1);
    expect(c.daysNotFiredTotal, 1);
  });

  test('analyzer accepts generalized cohort unchanged', () {
    final r = const CorrelationAnalyzer().analyze(const Cohort(
      exposureId: 'weekday_1',
      daysFiredWithAttack: 5,
      daysFiredTotal: 10,
      daysNotFiredWithAttack: 2,
      daysNotFiredTotal: 60,
    ));
    expect(r.exposureId, 'weekday_1');
    expect(r.classification, CorrelationClassification.personalHit);
  });
}

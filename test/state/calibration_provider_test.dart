import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/state/calibration_provider.dart';
import 'package:migraine_forecast/state/correlation_provider.dart';

DayRecord scored(DateTime day, {bool attack = false, bool backfilled = false}) =>
    DayRecord(
        day: day,
        score: 60,
        band: RiskBand.high,
        hadAttack: attack,
        backfilled: backfilled);

/// Local-calendar-day key, matching how assessments are stamped.
DateTime dayKey(DateTime local) => DateTime.utc(local.year, local.month, local.day);

void main() {
  Future<CalibrationView> run(List<DayRecord> timeline) async {
    final container = ProviderContainer(overrides: [
      dayTimelineProvider.overrideWith((ref) async => timeline),
    ]);
    addTearDown(container.dispose);
    return container.read(calibrationReportProvider.future);
  }

  test('excludes today (in progress) and tomorrow from calibration', () async {
    final now = DateTime.now();
    final today = dayKey(now);
    final timeline = [
      for (var i = 1; i <= 20; i++)
        scored(today.subtract(Duration(days: i))), // completed days
      scored(today), // in progress — must not count
      scored(today.add(const Duration(days: 1))), // tomorrow row — must not count
    ];
    final v = await run(timeline);
    expect(v.report.scoredDays, 20);
    expect(v.usedBackfilled, isFalse);
  });

  test('few prospective days without any backfilled ones: no backfill footnote',
      () async {
    final now = DateTime.now();
    final today = dayKey(now);
    final timeline = [
      for (var i = 1; i <= 5; i++) scored(today.subtract(Duration(days: i))),
    ];
    final v = await run(timeline);
    expect(v.report.scoredDays, 5);
    expect(v.usedBackfilled, isFalse);
  });

  test('backfilled days included and flagged when prospective history is thin',
      () async {
    final now = DateTime.now();
    final today = dayKey(now);
    final timeline = [
      for (var i = 1; i <= 5; i++) scored(today.subtract(Duration(days: i))),
      for (var i = 6; i <= 30; i++)
        scored(today.subtract(Duration(days: i)), backfilled: true),
    ];
    final v = await run(timeline);
    expect(v.report.scoredDays, 30);
    expect(v.usedBackfilled, isTrue);
  });
}

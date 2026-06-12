import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/repos/baseline_snapshot_builder.dart';

void main() {
  test('builds a snapshot from health + journal history', () {
    const builder = BaselineSnapshotBuilder(BaselineStore());
    final sleep = List.generate(
      7,
      (i) => SleepRecord(
        night: DateTime.utc(2026, 6, 1 + i),
        totalSleep: const Duration(hours: 7),
        efficiency: 0.9,
        sleepStart: DateTime.utc(2026, 6, 1 + i, 22),
      ),
    );
    final hrv = List.generate(
      14,
      (i) => HrvSample(at: DateTime.utc(2026, 5, 27 + i), rmssdMs: (40 + i).toDouble()),
    );
    final caffeineDays = <double>[180, 200, 150, 220, 190, 175, 210];

    final snap = builder.build(
      sleep: sleep,
      hrv: hrv,
      pastDailyCaffeineMg: caffeineDays,
      pastPressures: const [],
    );
    expect(snap.sleepMedian7d, const Duration(hours: 7));
    expect(snap.hrvRmssdBaseline14d, 46.5);
    expect(snap.caffeineDailyMg, 190);
    expect(snap.pressureBaseline, isNull);
  });

  test('returns empty for missing inputs', () {
    const builder = BaselineSnapshotBuilder(BaselineStore());
    final snap = builder.build(
      sleep: const [],
      hrv: const [],
      pastDailyCaffeineMg: const [],
      pastPressures: const [],
    );
    expect(snap, BaselineSnapshot.empty);
  });
}

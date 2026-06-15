import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/sources/health_source.dart';
import 'package:migraine_forecast/data/sources/manual_sleep_source.dart';
import 'package:migraine_forecast/data/sources/merged_health_source.dart';

class _FakeHealth implements HealthSource {
  _FakeHealth(this.metrics, this.granted);
  HealthMetrics metrics;
  Set<HealthCategory> granted;
  @override
  Future<HealthMetrics> recentMetrics({required Duration window}) async => metrics;
  @override
  Future<Set<HealthCategory>> requestPermissions(Set<HealthCategory> categories) async => granted;
  @override
  Set<HealthCategory> get grantedCategories => granted;
}

class _FakeManual implements ManualSleepSource {
  _FakeManual(this.records);
  List<SleepRecord> records;
  @override
  Future<void> upsert(SleepRecord r) async {}
  @override
  Future<void> delete(DateTime night) async {}
  @override
  Future<List<SleepRecord>> recent(Duration window, {required DateTime now}) async => records;
  @override
  Stream<List<SleepRecord>> watchRecent(Duration window, {required DateTime now}) =>
      Stream.value(records);
}

SleepRecord night(int day, {int hours = 7}) {
  final n = DateTime.utc(2026, 6, day);
  return SleepRecord(
    night: n,
    totalSleep: Duration(hours: hours),
    efficiency: 1.0,
    sleepStart: n.add(const Duration(hours: 22)),
  );
}

void main() {
  test('manual fills gaps where OS source has no record for that night', () async {
    final os = _FakeHealth(HealthMetrics(recentSleep: [night(12, hours: 7)], source: DataSource.manual), {HealthCategory.sleep});
    final manual = _FakeManual([night(11, hours: 6)]);
    final merged = MergedHealthSource(os, manual, clock: () => DateTime.utc(2026, 6, 13));
    final m = await merged.recentMetrics(window: const Duration(days: 7));
    // Total of two nights merged, newest first.
    expect(m.recentSleep, hasLength(2));
    expect(m.recentSleep.map((r) => r.night).toList(),
        [DateTime.utc(2026, 6, 12), DateTime.utc(2026, 6, 11)]);
    expect(m.recentSleep.first.night, DateTime.utc(2026, 6, 12));
  });

  test('OS-supplied night wins when both have the same night', () async {
    final os = _FakeHealth(HealthMetrics(recentSleep: [night(12, hours: 8)], source: DataSource.manual), {HealthCategory.sleep});
    final manual = _FakeManual([night(12, hours: 4)]);
    final merged = MergedHealthSource(os, manual, clock: () => DateTime.utc(2026, 6, 13));
    final m = await merged.recentMetrics(window: const Duration(days: 7));
    expect(m.recentSleep, hasLength(1));
    expect(m.recentSleep.single.totalSleep, const Duration(hours: 8));
  });

  test('grantedCategories delegates to OS source', () {
    final os = _FakeHealth(const HealthMetrics(source: DataSource.manual), {HealthCategory.hrv});
    final merged = MergedHealthSource(os, _FakeManual(const []), clock: DateTime.now);
    expect(merged.grantedCategories, {HealthCategory.hrv});
  });

  test('HRV and menstrual data pass through from OS', () async {
    final os = _FakeHealth(
      HealthMetrics(
        recentSleep: const [],
        recentHrv: [HrvSample(at: DateTime.utc(2026, 6, 12), rmssdMs: 40)],
        menstrualHistory: [MenstrualEvent(onsetDate: DateTime.utc(2026, 6, 1))],
        source: DataSource.manual,
      ),
      {HealthCategory.sleep, HealthCategory.hrv, HealthCategory.menstrual},
    );
    final merged = MergedHealthSource(os, _FakeManual(const []), clock: () => DateTime.utc(2026, 6, 13));
    final m = await merged.recentMetrics(window: const Duration(days: 30));
    expect(m.recentHrv, hasLength(1));
    expect(m.menstrualHistory, hasLength(1));
  });
}

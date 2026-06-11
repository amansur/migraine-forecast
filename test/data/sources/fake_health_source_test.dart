import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/sources/fake_health_source.dart';
import 'package:migraine_weatherr/data/sources/health_source.dart';

void main() {
  test('returns canned values for each call', () async {
    final fake = FakeHealthSource()
      ..sleep = [
        SleepRecord(
          night: DateTime.utc(2026, 6, 9),
          totalSleep: const Duration(hours: 7),
          efficiency: 0.9,
          sleepStart: DateTime.utc(2026, 6, 9, 22),
        ),
      ]
      ..hrv = [HrvSample(at: DateTime.utc(2026, 6, 10), rmssdMs: 50)];
    final metrics = await fake.recentMetrics(window: const Duration(days: 14));
    expect(metrics.recentSleep, hasLength(1));
    expect(metrics.recentHrv, hasLength(1));
    expect(metrics.menstrualHistory, isEmpty);
  });

  test('permission denial yields empty metrics for that category', () async {
    final fake = FakeHealthSource()..granted = {HealthCategory.sleep};
    fake.sleep = [
      SleepRecord(
        night: DateTime.utc(2026, 6, 9),
        totalSleep: const Duration(hours: 7),
        efficiency: 0.9,
        sleepStart: DateTime.utc(2026, 6, 9, 22),
      ),
    ];
    fake.hrv = [HrvSample(at: DateTime.utc(2026, 6, 10), rmssdMs: 50)];
    final metrics = await fake.recentMetrics(window: const Duration(days: 14));
    expect(metrics.recentSleep, hasLength(1));
    expect(metrics.recentHrv, isEmpty); // hrv permission not granted
  });
}

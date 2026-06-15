import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/sources/health_source.dart';
import 'package:migraine_forecast/data/sources/health_source_factory.dart';

class _FakeHealthSource implements HealthSource {
  _FakeHealthSource(this.metrics, this.granted);
  HealthMetrics metrics;
  Set<HealthCategory> granted;
  @override
  Future<HealthMetrics> recentMetrics({required Duration window}) async => metrics;
  @override
  Future<Set<HealthCategory>> requestPermissions(Set<HealthCategory> categories) async => granted;
  @override
  Set<HealthCategory> get grantedCategories => granted;
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
  group('HealthSourceFactory', () {
    test('uses Oura when preferred and data is fresh', () async {
      final now = DateTime.utc(2026, 6, 13, 12, 0, 0);
      final freshTime = now.subtract(const Duration(hours: 12)); // 12 hours ago

      final ouraMetrics = HealthMetrics(
        recentSleep: [night(12, hours: 8)],
        source: DataSource.oura,
        lastFetched: freshTime,
      );
      final oura = _FakeHealthSource(ouraMetrics, {HealthCategory.sleep});

      final appleMetrics = HealthMetrics(
        recentSleep: [night(11, hours: 6)],
        source: DataSource.appleHealth,
        lastFetched: now,
      );
      final apple = _FakeHealthSource(appleMetrics, {HealthCategory.sleep});

      final factory = HealthSourceFactory(
        ouraHealthSource: oura,
        appleHealthSource: apple,
        preferOura: true,
        clock: () => now,
      );

      final result = await factory.recentMetrics(window: const Duration(days: 30));

      expect(result.recentSleep.first.totalSleep, const Duration(hours: 8));
      expect(result.source, DataSource.oura);
    });

    test('falls back to Apple Health if Oura data is stale (>24h old)', () async {
      final now = DateTime.utc(2026, 6, 13, 12, 0, 0);
      final staleTime = now.subtract(const Duration(hours: 25)); // 25 hours ago

      final ouraMetrics = HealthMetrics(
        recentSleep: [night(12, hours: 8)],
        source: DataSource.oura,
        lastFetched: staleTime,
      );
      final oura = _FakeHealthSource(ouraMetrics, {HealthCategory.sleep});

      final appleMetrics = HealthMetrics(
        recentSleep: [night(11, hours: 6)],
        source: DataSource.appleHealth,
        lastFetched: now,
      );
      final apple = _FakeHealthSource(appleMetrics, {HealthCategory.sleep});

      final factory = HealthSourceFactory(
        ouraHealthSource: oura,
        appleHealthSource: apple,
        preferOura: true,
        clock: () => now,
      );

      final result = await factory.recentMetrics(window: const Duration(days: 30));

      expect(result.recentSleep.first.totalSleep, const Duration(hours: 6));
      expect(result.source, DataSource.appleHealth);
    });

    test('uses Apple Health when not preferred', () async {
      final ouraMetrics = HealthMetrics(
        recentSleep: [night(12, hours: 8)],
        source: DataSource.oura,
        lastFetched: DateTime.utc(2026, 6, 13, 12, 0, 0),
      );
      final oura = _FakeHealthSource(ouraMetrics, {HealthCategory.sleep});

      final appleMetrics = HealthMetrics(
        recentSleep: [night(11, hours: 6)],
        source: DataSource.appleHealth,
        lastFetched: DateTime.utc(2026, 6, 13, 12, 0, 0),
      );
      final apple = _FakeHealthSource(appleMetrics, {HealthCategory.sleep});

      final factory = HealthSourceFactory(
        ouraHealthSource: oura,
        appleHealthSource: apple,
        preferOura: false,
      );

      final result = await factory.recentMetrics(window: const Duration(days: 30));

      expect(result.recentSleep.first.totalSleep, const Duration(hours: 6));
      expect(result.source, DataSource.appleHealth);
    });
  });
}

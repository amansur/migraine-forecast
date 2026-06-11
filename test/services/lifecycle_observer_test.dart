import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/services/lifecycle_observer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('refreshes when resumed after stale window', () async {
    var refreshes = 0;
    final now = DateTime.utc(2026, 6, 11, 12);
    final observer = AppLifecycleObserver(
      staleAfter: const Duration(hours: 6),
      lastRefreshAt: () async => now.subtract(const Duration(hours: 7)),
      refresh: () async => refreshes++,
      clock: () => now,
    );
    await observer.didChangeAppLifecycleStateForTest(AppLifecycleState.resumed);
    expect(refreshes, 1);
  });

  test('does not refresh when within freshness window', () async {
    var refreshes = 0;
    final now = DateTime.utc(2026, 6, 11, 12);
    final observer = AppLifecycleObserver(
      staleAfter: const Duration(hours: 6),
      lastRefreshAt: () async => now.subtract(const Duration(hours: 2)),
      refresh: () async => refreshes++,
      clock: () => now,
    );
    await observer.didChangeAppLifecycleStateForTest(AppLifecycleState.resumed);
    expect(refreshes, 0);
  });

  test('does not refresh on backgrounding', () async {
    var refreshes = 0;
    final observer = AppLifecycleObserver(
      staleAfter: const Duration(hours: 6),
      lastRefreshAt: () async => DateTime.utc(2026, 6, 10),
      refresh: () async => refreshes++,
      clock: () => DateTime.utc(2026, 6, 11, 12),
    );
    await observer.didChangeAppLifecycleStateForTest(AppLifecycleState.paused);
    expect(refreshes, 0);
  });
}

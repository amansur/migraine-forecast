import 'package:flutter/widgets.dart';

class AppLifecycleObserver extends WidgetsBindingObserver {
  final Duration staleAfter;
  final Future<DateTime?> Function() lastRefreshAt;
  final Future<void> Function() refresh;
  final DateTime Function() clock;

  AppLifecycleObserver({
    required this.staleAfter,
    required this.lastRefreshAt,
    required this.refresh,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    didChangeAppLifecycleStateForTest(state);
  }

  /// Same as [didChangeAppLifecycleState] but awaits the work so tests can
  /// assert on it.
  Future<void> didChangeAppLifecycleStateForTest(AppLifecycleState state) async {
    if (state != AppLifecycleState.resumed) return;
    final last = await lastRefreshAt();
    if (last == null) {
      await refresh();
      return;
    }
    final age = clock().difference(last);
    if (age >= staleAfter) await refresh();
  }
}

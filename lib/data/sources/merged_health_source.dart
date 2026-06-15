import 'package:domain/domain.dart';

import 'health_source.dart';
import 'manual_sleep_source.dart';

class MergedHealthSource implements HealthSource {
  final HealthSource _os;
  final ManualSleepSource _manual;
  final DateTime Function() _clock;

  MergedHealthSource(this._os, this._manual, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  @override
  Set<HealthCategory> get grantedCategories => _os.grantedCategories;

  @override
  Future<Set<HealthCategory>> requestPermissions(Set<HealthCategory> categories) =>
      _os.requestPermissions(categories);

  @override
  Future<HealthMetrics> recentMetrics({required Duration window}) async {
    final os = await _os.recentMetrics(window: window);
    final manual = await _manual.recent(window, now: _clock());
    final osNights = os.recentSleep.map((r) => r.night).toSet();
    final extras = manual.where((r) => !osNights.contains(r.night)).toList();
    final merged = [...os.recentSleep, ...extras]
      ..sort((a, b) => b.night.compareTo(a.night));
    return HealthMetrics(
      recentSleep: merged,
      recentHrv: os.recentHrv,
      menstrualHistory: os.menstrualHistory,
    );
  }
}

import 'package:domain/domain.dart';

import 'health_source.dart';

/// Factory that implements preference-based health source selection with
/// intelligent fallback. When Oura is preferred, it uses Oura data if fresh
/// (≤24h old), otherwise falls back to Apple Health. If Oura raises an error,
/// falls back to Apple Health. When Apple Health is preferred, always uses
/// Apple Health.
class HealthSourceFactory implements HealthSource {
  final HealthSource ouraHealthSource;
  final HealthSource appleHealthSource;
  final bool preferOura;
  final DateTime Function() _clock;

  HealthSourceFactory({
    required this.ouraHealthSource,
    required this.appleHealthSource,
    required this.preferOura,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  @override
  Set<HealthCategory> get grantedCategories {
    if (preferOura) {
      return ouraHealthSource.grantedCategories;
    } else {
      return appleHealthSource.grantedCategories;
    }
  }

  @override
  Future<Set<HealthCategory>> requestPermissions(Set<HealthCategory> categories) {
    if (preferOura) {
      return ouraHealthSource.requestPermissions(categories);
    } else {
      return appleHealthSource.requestPermissions(categories);
    }
  }

  @override
  Future<HealthMetrics> recentMetrics({required Duration window}) async {
    if (preferOura) {
      try {
        final ouraMetrics = await ouraHealthSource.recentMetrics(window: window);
        if (ouraMetrics.isStale(clock: _clock)) {
          return appleHealthSource.recentMetrics(window: window);
        }
        return ouraMetrics;
      } catch (_) {
        return appleHealthSource.recentMetrics(window: window);
      }
    } else {
      return appleHealthSource.recentMetrics(window: window);
    }
  }

}

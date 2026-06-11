import 'package:domain/domain.dart';

enum HealthCategory { sleep, hrv, menstrual }

abstract class HealthSource {
  /// Returns metrics over the given window for each granted category.
  Future<HealthMetrics> recentMetrics({required Duration window});

  /// Request permissions for the specified categories. Returns the categories
  /// that ended up granted (subset of [categories]).
  Future<Set<HealthCategory>> requestPermissions(Set<HealthCategory> categories);

  Set<HealthCategory> get grantedCategories;
}

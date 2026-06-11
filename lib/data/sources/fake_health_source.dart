import 'package:domain/domain.dart';

import 'health_source.dart';

class FakeHealthSource implements HealthSource {
  List<SleepRecord> sleep = const [];
  List<HrvSample> hrv = const [];
  List<MenstrualEvent> menstrual = const [];
  Set<HealthCategory> granted = HealthCategory.values.toSet();

  @override
  Future<HealthMetrics> recentMetrics({required Duration window}) async {
    return HealthMetrics(
      recentSleep: granted.contains(HealthCategory.sleep) ? sleep : const [],
      recentHrv: granted.contains(HealthCategory.hrv) ? hrv : const [],
      menstrualHistory:
          granted.contains(HealthCategory.menstrual) ? menstrual : const [],
    );
  }

  @override
  Future<Set<HealthCategory>> requestPermissions(Set<HealthCategory> categories) async {
    granted = {...granted, ...categories};
    return granted.intersection(categories);
  }

  @override
  Set<HealthCategory> get grantedCategories => granted;
}

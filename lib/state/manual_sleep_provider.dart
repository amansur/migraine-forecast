import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sources/health_source.dart';
import '../data/sources/manual_sleep_source.dart';
import 'providers.dart';

final manualSleepSourceProvider = Provider<ManualSleepSource>(
  (ref) => DriftManualSleepSource(ref.watch(databaseProvider)),
);

/// True when the OS health source did not grant sleep access, meaning the
/// "Log sleep" affordance should be shown.
final manualSleepEnabledProvider = Provider<bool>((ref) {
  final granted = ref.watch(healthSourceProvider).grantedCategories;
  return !granted.contains(HealthCategory.sleep);
});

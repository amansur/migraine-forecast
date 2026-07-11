import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'correlation_provider.dart';

/// Prefer prospective (non-backfilled) forecasts; fall back to including
/// backfilled ones until 14 prospective days exist, flagged via [usedBackfilled].
typedef CalibrationView = ({CalibrationReport report, bool usedBackfilled});

final calibrationReportProvider = FutureProvider<CalibrationView>((ref) async {
  final timeline = await ref.watch(dayTimelineProvider.future);
  // Calibration compares forecasts against outcomes, so only completed days
  // count — today (still in progress) and tomorrow would read as false
  // negatives. See dayTimelineProvider's window note.
  final now = DateTime.now().toUtc();
  final todayUtc = DateTime.utc(now.year, now.month, now.day);
  final completed = timeline.where((d) => d.day.isBefore(todayUtc)).toList();

  final prospective = analyzeCalibration(completed);
  if (prospective.scoredDays >= 14) {
    return (report: prospective, usedBackfilled: false);
  }
  return (
    report: analyzeCalibration(completed, includeBackfilled: true),
    usedBackfilled: true
  );
});

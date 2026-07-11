import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'correlation_provider.dart';

/// Prefer prospective (non-backfilled) forecasts; fall back to including
/// backfilled ones until 14 prospective days exist, flagged via
/// [usedBackfilled] when that fallback actually added days.
typedef CalibrationView = ({CalibrationReport report, bool usedBackfilled});

final calibrationReportProvider = FutureProvider<CalibrationView>((ref) async {
  final timeline = await ref.watch(dayTimelineProvider.future);
  // Calibration compares forecasts against outcomes, so only completed days
  // count — today (still in progress) and tomorrow would read as false
  // negatives. Assessments are keyed by the LOCAL calendar day wrapped in a
  // UTC-midnight key (see RiskAssessmentNotifier._compute), so "today" must
  // be derived from local wall-clock components, not from toUtc().
  final now = DateTime.now();
  final todayKey = DateTime.utc(now.year, now.month, now.day);
  final completed = timeline.where((d) => d.day.isBefore(todayKey)).toList();

  final prospective = analyzeCalibration(completed);
  if (prospective.scoredDays >= 14) {
    return (report: prospective, usedBackfilled: false);
  }
  // Note: as old prospective days age out of the 90-day window the report can
  // flip back to mixed mode; scoredDays/rates then jump. Acceptable — the
  // footnote flags it — but keep in mind when reading bug reports.
  final mixed = analyzeCalibration(completed, includeBackfilled: true);
  return (
    report: mixed,
    usedBackfilled: mixed.scoredDays > prospective.scoredDays,
  );
});

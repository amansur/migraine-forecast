import 'package:equatable/equatable.dart';

import '../types/risk_assessment.dart';
import 'day_record.dart';
import 'wilson_interval.dart';

class BandCalibration extends Equatable {
  final RiskBand band;
  final WilsonInterval attackRate;
  final int days;
  const BandCalibration(
      {required this.band, required this.attackRate, required this.days});
  @override
  List<Object?> get props => [band, attackRate, days];
}

class CalibrationReport extends Equatable {
  /// Bands with at least one scored day, ordered low → veryHigh.
  final List<BandCalibration> bands;

  /// Mean squared error of (score/100) vs attack outcome. Null when no scored days.
  final double? brierScore;
  final int scoredDays;
  const CalibrationReport(
      {required this.bands, required this.brierScore, required this.scoredDays});
  @override
  List<Object?> get props => [bands, brierScore, scoredDays];
}

/// Prospective forecasts only by default: backfilled assessments were computed
/// with hindsight data and would flatter the model. Callers must pass completed
/// days only (trim day >= today — see dayTimelineProvider's note).
CalibrationReport analyzeCalibration(List<DayRecord> days,
    {bool includeBackfilled = false}) {
  final scored = days
      .where((d) =>
          d.score != null && d.band != null && (includeBackfilled || !d.backfilled))
      .toList();
  final bands = <BandCalibration>[];
  for (final band in RiskBand.values) {
    final inBand = scored.where((d) => d.band == band).toList();
    if (inBand.isEmpty) continue;
    bands.add(BandCalibration(
      band: band,
      attackRate: WilsonInterval.compute(
          successes: inBand.where((d) => d.hadAttack).length, trials: inBand.length),
      days: inBand.length,
    ));
  }
  double? brier;
  if (scored.isNotEmpty) {
    brier = scored.fold<double>(0, (acc, d) {
          final p = d.score! / 100.0;
          final o = d.hadAttack ? 1.0 : 0.0;
          return acc + (p - o) * (p - o);
        }) /
        scored.length;
  }
  return CalibrationReport(bands: bands, brierScore: brier, scoredDays: scored.length);
}

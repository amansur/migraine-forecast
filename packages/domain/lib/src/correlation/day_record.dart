import 'package:equatable/equatable.dart';

import '../types/risk_assessment.dart';

/// One calendar day's summary, the shared input for all correlation-family
/// analyses. [day] is the user's LOCAL calendar day wrapped in a UTC-midnight
/// key (DateTime.utc(local.y, local.m, local.d) — the convention assessments
/// and the heatmap use; do not "fix" it to a true UTC day: Exposure.weekday
/// reads .weekday off this key). [score]/[band]/[backfilled] come from the
/// day's today-horizon assessment when one exists.
class DayRecord extends Equatable {
  final DateTime day;
  final Set<String> firedModuleIds;
  final bool hadAttack;
  final int? score;
  final RiskBand? band;
  final bool backfilled;

  const DayRecord({
    required this.day,
    this.firedModuleIds = const {},
    this.hadAttack = false,
    this.score,
    this.band,
    this.backfilled = false,
  });

  @override
  List<Object?> get props => [day, firedModuleIds, hadAttack, score, band, backfilled];
}

import 'package:equatable/equatable.dart';
import 'trigger_signal.dart';

enum RiskBand { low, moderate, high, veryHigh }

/// [outlook] marks on-demand d+2..d+6 assessments. They are NEVER persisted
/// (AssessmentRepository.save rejects them) so correlation and calibration
/// timelines only ever contain today/tomorrow rows.
enum RiskHorizon { today, tomorrow, outlook }

class ScoreBands extends Equatable {
  /// Boundary between low and moderate.
  final int low;
  /// Boundary between moderate and high.
  final int moderate;
  /// Boundary between high and veryHigh.
  final int high;
  const ScoreBands({required this.low, required this.moderate, required this.high});

  /// A score equal to a boundary falls into the higher band.
  RiskBand bandFor(int score) {
    if (score >= high) return RiskBand.veryHigh;
    if (score >= moderate) return RiskBand.high;
    if (score >= low) return RiskBand.moderate;
    return RiskBand.low;
  }

  @override
  List<Object?> get props => [low, moderate, high];
}

class RiskAssessment extends Equatable {
  final int score;                       // 0..100
  final RiskBand band;
  final List<TriggerSignal> contributors; // sorted by contribution desc
  final DateTime computedAt;
  final int configVersion;
  final DateTime targetDate;
  final RiskHorizon horizon;
  final bool backfilled;

  const RiskAssessment({
    required this.score,
    required this.band,
    required this.contributors,
    required this.computedAt,
    required this.configVersion,
    required this.targetDate,
    required this.horizon,
    this.backfilled = false,
  });

  bool get isOnboarding =>
      contributors.isNotEmpty && contributors.every((c) => c.confidence == 0);

  @override
  List<Object?> get props =>
      [score, band, contributors, computedAt, configVersion, targetDate, horizon, backfilled];
}

import 'package:equatable/equatable.dart';

enum JournalKind { alcohol, caffeine, stress, hydration }

class JournalEntry extends Equatable {
  final DateTime at;
  final JournalKind kind;
  /// Free-form payload. By convention:
  /// - alcohol: {"units": double}
  /// - caffeine: {"mg": double}
  /// - stress: {"rating": int 1..5}
  /// - hydration: {"liters": double}
  final Map<String, Object?> payload;
  const JournalEntry({required this.at, required this.kind, required this.payload});
  @override
  List<Object?> get props => [at, kind, payload];
}

class Attack extends Equatable {
  final DateTime startedAt;
  final DateTime? endedAt;
  final int severity; // 1..10
  final bool inProgress;
  const Attack({
    required this.startedAt,
    this.endedAt,
    required this.severity,
    this.inProgress = false,
  });
  @override
  List<Object?> get props => [startedAt, endedAt, severity, inProgress];
}

/// A user-logged menstrual period. `endedAt == null` means in-progress.
/// `baselineSeverity` is on the same 1..10 scale as [Attack.severity].
class PeriodEvent extends Equatable {
  final DateTime startedAt;
  final DateTime? endedAt;
  final int baselineSeverity;
  const PeriodEvent({
    required this.startedAt,
    this.endedAt,
    required this.baselineSeverity,
  });
  @override
  List<Object?> get props => [startedAt, endedAt, baselineSeverity];
}

/// Sparse per-day override of [PeriodEvent.baselineSeverity] for a single
/// day inside a logged period. `day` is UTC midnight.
class PeriodDaySeverity extends Equatable {
  final DateTime day;
  final int severity;
  const PeriodDaySeverity({required this.day, required this.severity});
  @override
  List<Object?> get props => [day, severity];
}

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

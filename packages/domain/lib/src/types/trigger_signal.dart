import 'package:equatable/equatable.dart';
import 'data_requirement.dart';

class TriggerSignal extends Equatable {
  final String moduleId;
  final double weight;
  final double confidence;
  final String explanation;
  final DataRequirement? missing; // non-null when zero confidence due to missing data

  TriggerSignal({
    required this.moduleId,
    required this.weight,
    required double confidence,
    required this.explanation,
    this.missing,
  }) : confidence = confidence.clamp(0.0, 1.0).toDouble();

  factory TriggerSignal.zero({
    required String moduleId,
    required String reason,
    DataRequirement? missing,
  }) =>
      TriggerSignal(
        moduleId: moduleId,
        weight: 0,
        confidence: 0,
        explanation: reason,
        missing: missing ?? DataRequirement(id: moduleId, label: moduleId),
      );

  double get contribution => weight * confidence;

  @override
  List<Object?> get props => [moduleId, weight, confidence, explanation, missing];
}

import 'package:equatable/equatable.dart';

class UserTriggerFlags extends Equatable {
  /// Module IDs the user flagged during onboarding as suspected triggers.
  final Set<String> flaggedModuleIds;
  /// Per-module weight override in [-2.0, +2.0]. Missing key = 0 (no override).
  final Map<String, double> weightOverrides;
  const UserTriggerFlags({
    this.flaggedModuleIds = const {},
    this.weightOverrides = const {},
  });

  bool isFlagged(String moduleId) => flaggedModuleIds.contains(moduleId);
  double overrideFor(String moduleId) =>
      (weightOverrides[moduleId] ?? 0.0).clamp(-2.0, 2.0).toDouble();

  @override
  List<Object?> get props => [flaggedModuleIds, weightOverrides];
}

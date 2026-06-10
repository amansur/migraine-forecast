import 'package:equatable/equatable.dart';
import '../types/risk_assessment.dart';

class ModuleParams extends Equatable {
  final bool enabled;
  final double weightMax;
  final Map<String, Object?> params;
  const ModuleParams({
    required this.enabled,
    required this.weightMax,
    this.params = const {},
  });

  T get<T>(String key, T fallback) {
    final v = params[key];
    return v is T ? v : fallback;
  }

  double getDouble(String key, double fallback) {
    final v = params[key];
    if (v is num) return v.toDouble();
    return fallback;
  }

  int getInt(String key, int fallback) {
    final v = params[key];
    if (v is num) return v.toInt();
    return fallback;
  }

  @override
  List<Object?> get props => [enabled, weightMax, params];
}

class RulesConfig extends Equatable {
  final int version;
  final Map<String, ModuleParams> modules;
  final ScoreBands bands;
  final double unflaggedConfidenceMultiplier;

  const RulesConfig({
    required this.version,
    required this.modules,
    required this.bands,
    required this.unflaggedConfidenceMultiplier,
  });

  /// Minimal fallback used when bundled config is unreadable.
  /// All modules disabled — the engine will produce an onboarding signal.
  factory RulesConfig.minimalDefault() => const RulesConfig(
        version: 0,
        modules: {},
        bands: ScoreBands(low: 25, moderate: 50, high: 75),
        unflaggedConfidenceMultiplier: 0.6,
      );

  @override
  List<Object?> get props => [version, modules, bands, unflaggedConfidenceMultiplier];
}

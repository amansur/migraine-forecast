import 'dart:convert';
import '../types/risk_assessment.dart';
import 'rules_config.dart';

class RulesConfigException implements Exception {
  final String message;
  RulesConfigException(this.message);
  @override
  String toString() => 'RulesConfigException: $message';
}

class RulesConfigLoader {
  /// Parses JSON text and validates the config. Throws RulesConfigException on bad input.
  static RulesConfig parse(String jsonText) {
    final Map<String, Object?> root;
    try {
      root = jsonDecode(jsonText) as Map<String, Object?>;
    } catch (_) {
      throw RulesConfigException('invalid JSON');
    }

    final version = root['version'];
    if (version is! int) throw RulesConfigException('missing or non-integer "version"');

    final modulesRaw = root['modules'];
    if (modulesRaw is! Map) throw RulesConfigException('missing "modules" map');

    final modules = <String, ModuleParams>{};
    modulesRaw.forEach((key, value) {
      if (value is! Map) {
        throw RulesConfigException('module "$key" is not an object');
      }
      final enabled = value['enabled'];
      final weightMax = value['weight_max'];
      if (enabled is! bool) throw RulesConfigException('module "$key" missing bool "enabled"');
      if (weightMax is! num) throw RulesConfigException('module "$key" missing numeric "weight_max"');
      final params = (value['params'] is Map)
          ? Map<String, Object?>.from(value['params'] as Map)
          : <String, Object?>{};
      modules[key.toString()] = ModuleParams(
        enabled: enabled,
        weightMax: weightMax.toDouble(),
        params: params,
      );
    });

    final bandsRaw = root['score_bands'];
    if (bandsRaw is! Map) throw RulesConfigException('missing "score_bands"');
    final low = bandsRaw['low'];
    final mod = bandsRaw['moderate'];
    final high = bandsRaw['high'];
    if (low is! num || mod is! num || high is! num) {
      throw RulesConfigException('score_bands must have numeric low/moderate/high');
    }
    if (!(low < mod && mod < high && high < 100)) {
      throw RulesConfigException('score_bands must satisfy low < moderate < high < 100');
    }
    final bands = ScoreBands(low: low.toInt(), moderate: mod.toInt(), high: high.toInt());

    final mult = root['unflagged_trigger_confidence_multiplier'];
    if (mult is! num) {
      throw RulesConfigException('missing numeric "unflagged_trigger_confidence_multiplier"');
    }
    final multD = mult.toDouble();
    if (multD < 0 || multD > 1) {
      throw RulesConfigException('unflagged multiplier must be in [0, 1]');
    }

    return RulesConfig(
      version: version,
      modules: modules,
      bands: bands,
      unflaggedConfidenceMultiplier: multD,
    );
  }

  static RulesConfig parseOrFallback(String jsonText, {required RulesConfig fallback}) {
    try {
      return parse(jsonText);
    } catch (_) {
      return fallback;
    }
  }
}

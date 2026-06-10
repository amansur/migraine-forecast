import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('RulesConfigLoader', () {
    const validJson = '''
    {
      "version": 1,
      "modules": {
        "pressure_drop": { "enabled": true, "weight_max": 18, "params": {"threshold_hpa": 5} }
      },
      "score_bands": { "low": 25, "moderate": 50, "high": 75 },
      "unflagged_trigger_confidence_multiplier": 0.6
    }
    ''';

    test('parses a valid config', () {
      final cfg = RulesConfigLoader.parse(validJson);
      expect(cfg.version, 1);
      expect(cfg.modules['pressure_drop']!.enabled, isTrue);
      expect(cfg.modules['pressure_drop']!.weightMax, 18);
      expect(cfg.modules['pressure_drop']!.params['threshold_hpa'], 5);
      expect(cfg.bands.low, 25);
      expect(cfg.unflaggedConfidenceMultiplier, 0.6);
    });

    test('rejects missing version', () {
      expect(
        () => RulesConfigLoader.parse('{"modules": {}, "score_bands": {"low": 25, "moderate": 50, "high": 75}}'),
        throwsA(isA<RulesConfigException>()),
      );
    });

    test('rejects bad band ordering', () {
      const bad = '''
      {"version": 1, "modules": {}, "score_bands": {"low": 50, "moderate": 25, "high": 75}, "unflagged_trigger_confidence_multiplier": 0.6}
      ''';
      expect(() => RulesConfigLoader.parse(bad), throwsA(isA<RulesConfigException>()));
    });

    test('parseOrFallback returns fallback on bad input', () {
      final fb = RulesConfig.minimalDefault();
      final cfg = RulesConfigLoader.parseOrFallback('not json', fallback: fb);
      expect(cfg, equals(fb));
    });
  });
}

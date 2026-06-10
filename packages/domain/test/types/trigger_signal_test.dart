import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('TriggerSignal', () {
    test('clamps weight and confidence into valid ranges', () {
      final s = TriggerSignal(
        moduleId: 'x',
        weight: 100,
        confidence: 2,
        explanation: 'oversaturated',
      );
      expect(s.weight, 100);          // unclamped at construction; engine clamps the sum
      expect(s.confidence, 1.0);      // confidence MUST be clamped to [0,1] at construction
    });

    test('zero() factory produces a zero-contribution signal', () {
      final s = TriggerSignal.zero(moduleId: 'sleep_deficit', reason: 'no data');
      expect(s.weight, 0);
      expect(s.confidence, 0);
      expect(s.explanation, 'no data');
      expect(s.missing, isNotNull);
    });

    test('value equality', () {
      final a = TriggerSignal(moduleId: 'x', weight: 5, confidence: 0.5, explanation: 'a');
      final b = TriggerSignal(moduleId: 'x', weight: 5, confidence: 0.5, explanation: 'a');
      expect(a, equals(b));
    });
  });
}

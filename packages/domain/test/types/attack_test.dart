import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('Attack', () {
    test('defaults inProgress to false', () {
      final a = Attack(startedAt: DateTime.utc(2026, 6, 1, 12), severity: 5);
      expect(a.inProgress, isFalse);
    });

    test('inProgress and endedAt are independent fields', () {
      final ongoing = Attack(
        startedAt: DateTime.utc(2026, 6, 1, 12),
        severity: 5,
        inProgress: true,
      );
      expect(ongoing.endedAt, isNull);
      expect(ongoing.inProgress, isTrue);
    });

    test('equality includes inProgress', () {
      final a = Attack(startedAt: DateTime.utc(2026, 6, 1, 12), severity: 5);
      final b = Attack(startedAt: DateTime.utc(2026, 6, 1, 12), severity: 5, inProgress: true);
      expect(a, isNot(equals(b)));
    });
  });
}

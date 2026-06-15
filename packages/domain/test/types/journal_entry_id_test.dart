import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('JournalEntry.id', () {
    test('defaults to null and is omitted from equality contributions when null', () {
      final a = JournalEntry(
        at: DateTime.utc(2026, 6, 13, 10),
        kind: JournalKind.alcohol,
        payload: const {'units': 2.0},
      );
      final b = JournalEntry(
        at: DateTime.utc(2026, 6, 13, 10),
        kind: JournalKind.alcohol,
        payload: const {'units': 2.0},
      );
      expect(a.id, isNull);
      expect(a, equals(b));
    });

    test('different ids make entries unequal', () {
      final a = JournalEntry(
        id: 1,
        at: DateTime.utc(2026, 6, 13, 10),
        kind: JournalKind.alcohol,
        payload: const {'units': 2.0},
      );
      final b = JournalEntry(
        id: 2,
        at: DateTime.utc(2026, 6, 13, 10),
        kind: JournalKind.alcohol,
        payload: const {'units': 2.0},
      );
      expect(a, isNot(equals(b)));
    });
  });
}

import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  test('current streak counts days since last attack; longest scans window', () {
    final s = computeStreaks(
      attackDays: {DateTime.utc(2026, 7, 1), DateTime.utc(2026, 7, 5)},
      today: DateTime.utc(2026, 7, 9),
      windowStart: DateTime.utc(2026, 6, 25),
    );
    expect(s.currentAttackFreeDays, 4); // Jul 6,7,8,9
    expect(s.longestAttackFreeDays, 6); // Jun 25–30
  });

  test('no attacks: whole window is the streak', () {
    final s = computeStreaks(
        attackDays: {},
        today: DateTime.utc(2026, 7, 9),
        windowStart: DateTime.utc(2026, 7, 1));
    expect(s.currentAttackFreeDays, 9);
    expect(s.longestAttackFreeDays, 9);
  });

  test('attack today: current streak is zero', () {
    final s = computeStreaks(
        attackDays: {DateTime.utc(2026, 7, 9)},
        today: DateTime.utc(2026, 7, 9),
        windowStart: DateTime.utc(2026, 7, 1));
    expect(s.currentAttackFreeDays, 0);
    expect(s.longestAttackFreeDays, 8);
  });

  test('day parts bucket attack start hours as given (caller converts zones)', () {
    final m = attackStartsByDayPart([
      Attack(startedAt: DateTime.utc(2026, 7, 1, 7), severity: 5), // morning 6–12
      Attack(startedAt: DateTime.utc(2026, 7, 2, 13), severity: 5), // afternoon 12–18
      Attack(startedAt: DateTime.utc(2026, 7, 3, 23), severity: 5), // evening 18–24
      Attack(startedAt: DateTime.utc(2026, 7, 4, 2), severity: 5), // night 0–6
      Attack(startedAt: DateTime.utc(2026, 7, 5, 8), severity: 5), // morning
    ]);
    expect(m[DayPart.morning], 2);
    expect(m[DayPart.afternoon], 1);
    expect(m[DayPart.evening], 1);
    expect(m[DayPart.night], 1);
  });
}

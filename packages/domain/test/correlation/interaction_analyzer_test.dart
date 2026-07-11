import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  test('surfaces a pair whose joint lift beats both singles', () {
    // 80 days: A fires days 0-39, B fires days 20-59, overlap 20-39.
    // Attacks: 13 of the 20 overlap days (i % 3 != 0), plus day 0 (A alone),
    // day 45 (B alone), day 70 (neither).
    final days = <DayRecord>[];
    for (var i = 0; i < 80; i++) {
      final a = i < 40;
      final b = i >= 20 && i < 60;
      final attack = (a && b && i % 3 != 0) || i == 0 || i == 45 || i == 70;
      days.add(DayRecord(
        day: DateTime.utc(2026, 4, 1).add(Duration(days: i)),
        firedModuleIds: {if (a) 'a', if (b) 'b'},
        hadAttack: attack,
      ));
    }
    final out = analyzeInteractions(days, ['a', 'b']);
    expect(out, hasLength(1));
    expect(out.single.pair.exposureId, 'a+b');
    expect(out.single.pair.classification, CorrelationClassification.personalHit);
    expect(out.single.pair.lift.point, greaterThan(out.single.singleLiftA));
    expect(out.single.pair.lift.point, greaterThan(out.single.singleLiftB));
  });

  test('skips pairs below support thresholds', () {
    final days = [
      for (var i = 0; i < 30; i++)
        DayRecord(
            day: DateTime.utc(2026, 4, 1).add(Duration(days: i)),
            firedModuleIds: {if (i < 3) 'a', if (i < 3) 'b'},
            hadAttack: i < 3),
    ];
    expect(analyzeInteractions(days, ['a', 'b']), isEmpty);
  });

  test('caps results at maxResults ordered by pair lift', () {
    // Three modules that all fire together on high-attack days, generating
    // three qualifying pairs; maxResults 2 keeps the strongest two.
    final days = <DayRecord>[];
    for (var i = 0; i < 60; i++) {
      final together = i < 15;
      days.add(DayRecord(
        day: DateTime.utc(2026, 4, 1).add(Duration(days: i)),
        firedModuleIds: together ? {'x', 'y', 'z'} : {},
        hadAttack: together && i % 3 != 0,
      ));
    }
    final out = analyzeInteractions(days, ['x', 'y', 'z'], maxResults: 2);
    expect(out, hasLength(2));
  });
}

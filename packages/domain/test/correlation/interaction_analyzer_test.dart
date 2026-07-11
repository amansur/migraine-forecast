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

  test('caps results at maxResults, keeping the strongest pair', () {
    // Two disjoint blocks, each shaped like the first test: (a,b) overlap has
    // 13/20 attack days (stronger), (c,d) overlap has 10/20 (weaker). Both
    // pairs qualify; maxResults 1 must keep only the stronger a+b.
    final days = <DayRecord>[];
    for (var i = 0; i < 80; i++) {
      final a = i < 40;
      final b = i >= 20 && i < 60;
      final attack = (a && b && i % 3 != 0) || i == 0 || i == 45 || i == 70;
      days.add(DayRecord(
        day: DateTime.utc(2026, 3, 1).add(Duration(days: i)),
        firedModuleIds: {if (a) 'a', if (b) 'b'},
        hadAttack: attack,
      ));
    }
    for (var i = 0; i < 80; i++) {
      final c = i < 40;
      final d = i >= 20 && i < 60;
      final attack = (c && d && i % 2 == 0) || i == 0 || i == 45 || i == 70;
      days.add(DayRecord(
        day: DateTime.utc(2026, 5, 20).add(Duration(days: i)),
        firedModuleIds: {if (c) 'c', if (d) 'd'},
        hadAttack: attack,
      ));
    }
    final all = analyzeInteractions(days, ['a', 'b', 'c', 'd']);
    expect(all, hasLength(2)); // both pairs qualify before capping

    final capped = analyzeInteractions(days, ['a', 'b', 'c', 'd'], maxResults: 1);
    expect(capped.single.pair.exposureId, 'a+b');
  });
}

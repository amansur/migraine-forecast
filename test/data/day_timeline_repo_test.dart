import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart'
    hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_forecast/data/repos/day_timeline_repo.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  String contributors(List<(String, double, double)> mods) => jsonEncode([
        for (final (id, w, c) in mods)
          {'moduleId': id, 'weight': w, 'confidence': c, 'explanation': ''}
      ]);

  test('builds one DayRecord per assessed day with fired modules, attack flag, and score',
      () async {
    final d1 = DateTime.utc(2026, 7, 1);
    final d2 = DateTime.utc(2026, 7, 2);
    await db.into(db.riskAssessments).insert(RiskAssessmentsCompanion.insert(
        targetDate: d1,
        horizon: 'today',
        score: 70,
        band: 'high',
        computedAt: d1,
        configVersion: 2,
        contributorsJson: contributors([('alcohol', 10, 1.0), ('humidity', 0, 1.0)]),
        backfilled: const Value(true)));
    await db.into(db.riskAssessments).insert(RiskAssessmentsCompanion.insert(
        targetDate: d2,
        horizon: 'today',
        score: 10,
        band: 'low',
        computedAt: d2,
        configVersion: 2,
        contributorsJson: contributors([])));
    // Local noon so the attack bins onto d1's local-day key on any machine TZ.
    await db.into(db.attacks).insert(AttacksCompanion.insert(
        startedAt: DateTime(2026, 7, 1, 12), severity: 5));

    final tl = await DayTimelineRepo(db).buildTimeline(
        windowStart: DateTime.utc(2026, 6, 30), windowEnd: DateTime.utc(2026, 7, 3));

    expect(tl.length, 2);
    expect(tl.first.day, d1);
    expect(tl.first.firedModuleIds, {'alcohol'}); // humidity: weight*confidence == 0
    expect(tl.first.hadAttack, isTrue);
    expect(tl.first.score, 70);
    expect(tl.first.band, RiskBand.high);
    expect(tl.first.backfilled, isTrue);
    expect(tl.last.hadAttack, isFalse);
    expect(tl.last.band, RiskBand.low);
  });

  test('fired modules union across horizons; score/band come from today row only',
      () async {
    final d = DateTime.utc(2026, 7, 6);
    await db.into(db.riskAssessments).insert(RiskAssessmentsCompanion.insert(
        targetDate: d,
        horizon: 'today',
        score: 40,
        band: 'moderate',
        computedAt: d,
        configVersion: 2,
        contributorsJson: contributors([('alcohol', 8, 1.0)])));
    await db.into(db.riskAssessments).insert(RiskAssessmentsCompanion.insert(
        targetDate: d,
        horizon: 'tomorrow',
        score: 70,
        band: 'high',
        computedAt: d.subtract(const Duration(days: 1)),
        configVersion: 2,
        contributorsJson: contributors([('pressure_drop', 12, 1.0)])));

    final tl = await DayTimelineRepo(db).buildTimeline(
        windowStart: d, windowEnd: d.add(const Duration(days: 1)));

    expect(tl.single.firedModuleIds, {'alcohol', 'pressure_drop'});
    expect(tl.single.score, 40);
    expect(tl.single.band, RiskBand.moderate);
  });

  test('malformed band string from an imported backup yields null band, not a crash',
      () async {
    final d = DateTime.utc(2026, 7, 7);
    await db.into(db.riskAssessments).insert(RiskAssessmentsCompanion.insert(
        targetDate: d,
        horizon: 'today',
        score: 50,
        band: 'bogus-band',
        computedAt: d,
        configVersion: 2,
        contributorsJson: contributors([])));

    final tl = await DayTimelineRepo(db).buildTimeline(
        windowStart: d, windowEnd: d.add(const Duration(days: 1)));

    expect(tl.single.band, isNull);
    expect(tl.single.score, 50);
  });

  test('tomorrow-horizon rows contribute fired modules but not score', () async {
    final d = DateTime.utc(2026, 7, 5);
    await db.into(db.riskAssessments).insert(RiskAssessmentsCompanion.insert(
        targetDate: d,
        horizon: 'tomorrow',
        score: 55,
        band: 'high',
        computedAt: d,
        configVersion: 2,
        contributorsJson:
            '[{"moduleId":"pressure_drop","weight":12,"confidence":1.0}]'));
    final tl = await DayTimelineRepo(db).buildTimeline(
        windowStart: d, windowEnd: d.add(const Duration(days: 1)));
    expect(tl.single.firedModuleIds, {'pressure_drop'});
    expect(tl.single.score, isNull);
  });
}

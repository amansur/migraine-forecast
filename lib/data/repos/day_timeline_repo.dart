import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

import '../database.dart';

/// Builds the per-day timeline consumed by all correlation-family analyses.
/// Fired-ness unions across horizons (matching the pre-plan6 CorrelationRepo
/// behavior); score/band/backfilled come from the today-horizon row only.
class DayTimelineRepo {
  final AppDatabase _db;
  DayTimelineRepo(this._db);

  Future<List<DayRecord>> buildTimeline({
    required DateTime windowStart,
    required DateTime windowEnd,
  }) async {
    final s = windowStart.toUtc();
    final utcStart = DateTime.utc(s.year, s.month, s.day);
    final e = windowEnd.toUtc();
    final utcEnd = DateTime.utc(e.year, e.month, e.day).add(const Duration(days: 1));

    final assessmentRows = await (_db.select(_db.riskAssessments)
          ..where((t) =>
              t.targetDate.isBiggerOrEqualValue(utcStart) &
              t.targetDate.isSmallerThanValue(utcEnd)))
        .get();

    // Drift's generated row class for RiskAssessments would shadow the domain
    // RiskAssessment type; avoid naming it by projecting into a record.
    final firedByDay = <DateTime, Set<String>>{};
    final todayByDay = <DateTime, ({int score, String band, bool backfilled})>{};
    for (final row in assessmentRows) {
      final d = row.targetDate.toUtc();
      final day = DateTime.utc(d.year, d.month, d.day);
      final fired = firedByDay.putIfAbsent(day, () => <String>{});
      final contributors = jsonDecode(row.contributorsJson) as List;
      for (final c in contributors) {
        final m = c as Map<String, Object?>;
        final weight = (m['weight'] as num).toDouble();
        final confidence = (m['confidence'] as num).toDouble();
        if (weight * confidence > 0) fired.add(m['moduleId'] as String);
      }
      if (row.horizon == 'today') {
        todayByDay[day] =
            (score: row.score, band: row.band, backfilled: row.backfilled);
      }
    }

    final attackRows = await (_db.select(_db.attacks)
          ..where((t) =>
              t.startedAt.isBiggerOrEqualValue(utcStart) &
              t.startedAt.isSmallerThanValue(utcEnd)))
        .get();
    final attackDays = <DateTime>{
      for (final a in attackRows)
        DateTime.utc(a.startedAt.toUtc().year, a.startedAt.toUtc().month,
            a.startedAt.toUtc().day),
    };

    final days = firedByDay.keys.toList()..sort();
    return [
      for (final day in days)
        DayRecord(
          day: day,
          firedModuleIds: firedByDay[day]!,
          hadAttack: attackDays.contains(day),
          score: todayByDay[day]?.score,
          band: todayByDay[day] == null
              ? null
              : RiskBand.values.byName(todayByDay[day]!.band),
          backfilled: todayByDay[day]?.backfilled ?? false,
        ),
    ];
  }
}

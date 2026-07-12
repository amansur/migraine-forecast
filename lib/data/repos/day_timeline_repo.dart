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

    // Assessment days are LOCAL calendar days wrapped in UTC-midnight keys
    // (see RiskAssessmentNotifier._compute and the heatmap binning note in
    // insights_screen.dart), so attacks must bin the same way or evening
    // attacks west of UTC land on the wrong day. Widen the query by a day on
    // each side so timezone offsets can't push a relevant attack outside it.
    final attackRows = await (_db.select(_db.attacks)
          ..where((t) =>
              t.startedAt.isBiggerOrEqualValue(
                  utcStart.subtract(const Duration(days: 1))) &
              t.startedAt.isSmallerThanValue(utcEnd.add(const Duration(days: 1)))))
        .get();
    final attackDays = <DateTime>{};
    for (final a in attackRows) {
      final local = a.startedAt.toLocal();
      attackDays.add(DateTime.utc(local.year, local.month, local.day));
    }

    final days = firedByDay.keys.toList()..sort();
    final records = <DayRecord>[];
    for (final day in days) {
      final today = todayByDay[day];
      records.add(DayRecord(
        day: day,
        firedModuleIds: Set.unmodifiable(firedByDay[day]!),
        hadAttack: attackDays.contains(day),
        score: today?.score,
        band: today == null ? null : _parseBand(today.band),
        backfilled: today?.backfilled ?? false,
      ));
    }
    return records;
  }

  /// Tolerant band parse: imported backups can carry arbitrary band strings
  /// (import_repo writes them unvalidated), and one bad row must not take
  /// down every correlation-family analysis.
  static RiskBand? _parseBand(String name) {
    for (final b in RiskBand.values) {
      if (b.name == name) return b;
    }
    return null;
  }
}

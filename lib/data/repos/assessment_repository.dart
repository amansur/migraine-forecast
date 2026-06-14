import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

import '../database.dart' hide RiskAssessment;

class AssessmentRepository {
  final AppDatabase _db;
  AssessmentRepository(this._db);

  Future<int> save(RiskAssessment ass) async {
    final d = ass.targetDate.toUtc();
    final utcTarget = DateTime.utc(d.year, d.month, d.day);
    final companion = RiskAssessmentsCompanion.insert(
      targetDate: utcTarget,
      horizon: ass.horizon.name,
      score: ass.score,
      band: ass.band.name,
      computedAt: ass.computedAt.toUtc(),
      configVersion: ass.configVersion,
      contributorsJson: jsonEncode(ass.contributors
          .map((c) => {
                'moduleId': c.moduleId,
                'weight': c.weight,
                'confidence': c.confidence,
                'explanation': c.explanation,
              })
          .toList()),
      backfilled: Value(ass.backfilled),
    );
    return _db.into(_db.riskAssessments).insert(
          companion,
          onConflict: DoUpdate(
            (_) => companion,
            // Explicit target for clarity if additional unique indexes are
            // added later (e.g. from the location-override plan).
            target: [_db.riskAssessments.targetDate, _db.riskAssessments.horizon],
          ),
        );
  }

  Future<RiskAssessment?> latestForDate({
    required DateTime target,
    required RiskHorizon horizon,
  }) async {
    final d = target.toUtc();
    final start = DateTime.utc(d.year, d.month, d.day);
    final end = start.add(const Duration(days: 1));

    final rows = await (_db.select(_db.riskAssessments)
          ..where((t) =>
              t.targetDate.isBiggerOrEqualValue(start) &
              t.targetDate.isSmallerThanValue(end) &
              t.horizon.equals(horizon.name))
          ..orderBy([(t) => OrderingTerm.desc(t.computedAt)])
          ..limit(1))
        .get();
    return rows.isEmpty ? null : _toDomain(rows.first);
  }

  Future<RiskAssessment?> activeAt(DateTime when) async {
    final utcWhen = when.toUtc();
    final rows = await (_db.select(_db.riskAssessments)
          ..where((t) => t.computedAt.isSmallerOrEqualValue(utcWhen))
          ..orderBy([(t) => OrderingTerm.desc(t.computedAt)])
          ..limit(1))
        .get();
    return rows.isEmpty ? null : _toDomain(rows.first);
  }

  Future<int?> activeAtRowId(DateTime when) async {
    final utcWhen = when.toUtc();
    final rows = await (_db.select(_db.riskAssessments)
          ..where((t) => t.computedAt.isSmallerOrEqualValue(utcWhen))
          ..orderBy([(t) => OrderingTerm.desc(t.computedAt)])
          ..limit(1))
        .get();
    return rows.isEmpty ? null : rows.first.id;
  }

  /// Returns the row ID of the most recently computed assessment for the given
  /// target date (UTC day) and horizon, regardless of `computedAt`. This is
  /// the correct lookup for backfilled assessments whose `computedAt` is the
  /// current wall-clock time rather than the target day.
  Future<int?> rowIdForDate({required DateTime target, required RiskHorizon horizon}) async {
    final d = target.toUtc();
    final start = DateTime.utc(d.year, d.month, d.day);
    final end = start.add(const Duration(days: 1));
    final rows = await (_db.select(_db.riskAssessments)
          ..where((t) =>
              t.targetDate.isBiggerOrEqualValue(start) &
              t.targetDate.isSmallerThanValue(end) &
              t.horizon.equals(horizon.name))
          ..orderBy([(t) => OrderingTerm.desc(t.computedAt)])
          ..limit(1))
        .get();
    return rows.isEmpty ? null : rows.first.id;
  }

  /// Returns the set of UTC-midnight targetDates for rows with [horizon] at or
  /// after [cutoff]. Used by [BulkBackfillOrchestrator] to skip days that are
  /// already filled.
  Future<Set<DateTime>> existingDatesInWindow({
    required DateTime cutoff,
    required RiskHorizon horizon,
  }) async {
    final rows = await (_db.select(_db.riskAssessments)
          ..where((t) =>
              t.horizon.equals(horizon.name) &
              t.targetDate.isBiggerOrEqualValue(cutoff.toUtc())))
        .get();
    return {
      for (final r in rows)
        () {
          final d = r.targetDate.toUtc();
          return DateTime.utc(d.year, d.month, d.day);
        }(),
    };
  }

  Future<DateTime?> latestComputedAt() async {
    final rows = await (_db.select(_db.riskAssessments)
          ..orderBy([(t) => OrderingTerm.desc(t.computedAt)])
          ..limit(1))
        .get();
    return rows.isEmpty ? null : rows.first.computedAt.toUtc();
  }

  RiskAssessment _toDomain(dynamic row) {
    final contributors = (jsonDecode(row.contributorsJson) as List)
        .map((e) {
          final m = e as Map<String, Object?>;
          return TriggerSignal(
            moduleId: m['moduleId'] as String,
            weight: (m['weight'] as num).toDouble(),
            confidence: (m['confidence'] as num).toDouble(),
            explanation: m['explanation'] as String,
          );
        })
        .toList();
    return RiskAssessment(
      score: row.score as int,
      band: RiskBand.values.firstWhere((b) => b.name == row.band),
      contributors: contributors,
      computedAt: (row.computedAt as DateTime).toUtc(),
      configVersion: row.configVersion as int,
      targetDate: (row.targetDate as DateTime).toUtc(),
      horizon: RiskHorizon.values.firstWhere((h) => h.name == row.horizon),
      backfilled: row.backfilled as bool,
    );
  }
}

import 'dart:convert';

import 'package:domain/domain.dart' as domain;
import 'package:drift/drift.dart';

import '../database.dart' hide Attack;
import 'journal_source.dart';

class DriftJournalSource implements JournalSource {
  final AppDatabase _db;
  DriftJournalSource(this._db);

  @override
  Future<void> addEntry(domain.JournalEntry entry) async {
    await _db.into(_db.journalEntries).insert(
          JournalEntriesCompanion.insert(
            at: entry.at.toUtc(),
            kind: entry.kind.name,
            payloadJson: jsonEncode(entry.payload),
          ),
        );
  }

  @override
  Future<List<domain.JournalEntry>> recentEntries(Duration window, {required DateTime now}) async {
    final utcNow = now.toUtc();
    final cutoff = utcNow.subtract(window);
    final rows = await (_db.select(_db.journalEntries)
          ..where((t) => t.at.isBiggerOrEqualValue(cutoff) & t.at.isSmallerThanValue(utcNow))
          ..orderBy([(t) => OrderingTerm.desc(t.at)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  domain.JournalEntry _toDomain(JournalEntry r) => domain.JournalEntry(
        id: r.id,
        at: r.at.toUtc(),
        kind: domain.JournalKind.values.firstWhere((k) => k.name == r.kind),
        payload: Map<String, Object?>.from(jsonDecode(r.payloadJson) as Map),
      );

  @override
  Future<void> updateEntry(domain.JournalEntry entry) async {
    final id = entry.id;
    if (id == null) {
      throw ArgumentError('updateEntry requires JournalEntry.id to be non-null');
    }
    await (_db.update(_db.journalEntries)..where((t) => t.id.equals(id))).write(
      JournalEntriesCompanion(
        at: Value(entry.at.toUtc()),
        kind: Value(entry.kind.name),
        payloadJson: Value(jsonEncode(entry.payload)),
      ),
    );
  }

  @override
  Future<void> deleteEntry(int id) async {
    await (_db.delete(_db.journalEntries)..where((t) => t.id.equals(id))).go();
  }

  @override
  Stream<List<domain.JournalEntry>> watchRecentEntries(Duration window, {required DateTime now}) {
    final utcNow = now.toUtc();
    final cutoff = utcNow.subtract(window);
    final q = _db.select(_db.journalEntries)
      ..where((t) => t.at.isBiggerOrEqualValue(cutoff) & t.at.isSmallerThanValue(utcNow))
      ..orderBy([(t) => OrderingTerm.desc(t.at)]);
    return q.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<int> addAttack(domain.Attack attack, {int? riskAssessmentId}) async {
    return _db.into(_db.attacks).insert(
          AttacksCompanion.insert(
            startedAt: attack.startedAt.toUtc(),
            endedAt: Value(attack.endedAt?.toUtc()),
            severity: attack.severity,
            notes: const Value.absent(),
            riskAssessmentId: Value(riskAssessmentId),
            inProgress: Value(attack.inProgress),
          ),
        );
  }

  @override
  Future<List<domain.Attack>> recentAttacks(Duration window, {required DateTime now}) async {
    final utcNow = now.toUtc();
    final cutoff = utcNow.subtract(window);
    final rows = await (_db.select(_db.attacks)
          ..where((t) => t.startedAt.isBiggerOrEqualValue(cutoff) & t.startedAt.isSmallerThanValue(utcNow))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
    return rows
        .map((r) => domain.Attack(
              startedAt: r.startedAt.toUtc(),
              endedAt: r.endedAt?.toUtc(),
              severity: r.severity,
              inProgress: r.inProgress,
            ))
        .toList();
  }

  @override
  Stream<List<domain.Attack>> watchRecentAttacks(Duration window, {required DateTime now}) {
    final utcNow = now.toUtc();
    final cutoff = utcNow.subtract(window);
    final query = _db.select(_db.attacks)
      ..where((t) => t.startedAt.isBiggerOrEqualValue(cutoff) & t.startedAt.isSmallerThanValue(utcNow))
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]);
    return query.watch().map((rows) => rows
        .map((r) => domain.Attack(
              startedAt: r.startedAt.toUtc(),
              endedAt: r.endedAt?.toUtc(),
              severity: r.severity,
              inProgress: r.inProgress,
            ))
        .toList());
  }

  @override
  Future<void> deleteAttack(DateTime startedAt) async {
    final utc = startedAt.toUtc();
    await (_db.delete(_db.attacks)..where((t) => t.startedAt.equals(utc))).go();
  }

  // --- Periods ---

  @override
  Future<int> addPeriod(domain.PeriodEvent period) async {
    return _db.into(_db.periods).insert(
          PeriodsCompanion.insert(
            startedAt: period.startedAt.toUtc(),
            endedAt: Value(period.endedAt?.toUtc()),
            baselineSeverity: period.baselineSeverity,
          ),
        );
  }

  @override
  Future<void> endPeriod(DateTime startedAt, DateTime endedAt) async {
    final utcStart = startedAt.toUtc();
    await (_db.update(_db.periods)..where((t) => t.startedAt.equals(utcStart)))
        .write(PeriodsCompanion(endedAt: Value(endedAt.toUtc())));
  }

  @override
  Future<void> deletePeriod(DateTime startedAt) async {
    final utc = startedAt.toUtc();
    // Look up the row first so we know the span to cascade overrides over.
    final row = await (_db.select(_db.periods)..where((t) => t.startedAt.equals(utc)))
        .getSingleOrNull();
    if (row == null) return;

    final startDay = DateTime.utc(row.startedAt.year, row.startedAt.month, row.startedAt.day);
    final endRaw = row.endedAt ?? row.startedAt.add(const Duration(days: 4));
    final endDay = DateTime.utc(endRaw.year, endRaw.month, endRaw.day);
    final overrideCutoff = endDay.add(const Duration(days: 1));

    await _db.transaction(() async {
      await (_db.delete(_db.periodDaySeverities)
            ..where((t) => t.day.isBiggerOrEqualValue(startDay) & t.day.isSmallerThanValue(overrideCutoff)))
          .go();
      await (_db.delete(_db.periods)..where((t) => t.startedAt.equals(utc))).go();
    });
  }

  @override
  Future<List<domain.PeriodEvent>> recentPeriods(Duration window, {required DateTime now}) async {
    final utcNow = now.toUtc();
    final cutoff = utcNow.subtract(window);
    final rows = await (_db.select(_db.periods)
          ..where((t) => t.startedAt.isBiggerOrEqualValue(cutoff) & t.startedAt.isSmallerThanValue(utcNow))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
    return rows.map(_toDomainPeriod).toList();
  }

  @override
  Stream<List<domain.PeriodEvent>> watchRecentPeriods(Duration window, {required DateTime now}) {
    final utcNow = now.toUtc();
    final cutoff = utcNow.subtract(window);
    final q = _db.select(_db.periods)
      ..where((t) => t.startedAt.isBiggerOrEqualValue(cutoff) & t.startedAt.isSmallerThanValue(utcNow))
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]);
    return q.watch().map((rows) => rows.map(_toDomainPeriod).toList());
  }

  domain.PeriodEvent _toDomainPeriod(Period r) => domain.PeriodEvent(
        startedAt: r.startedAt.toUtc(),
        endedAt: r.endedAt?.toUtc(),
        baselineSeverity: r.baselineSeverity,
      );

  @override
  Future<void> upsertPeriodDaySeverity(domain.PeriodDaySeverity override) async {
    await _db.into(_db.periodDaySeverities).insertOnConflictUpdate(
          PeriodDaySeveritiesCompanion.insert(
            day: override.day.toUtc(),
            severity: override.severity,
          ),
        );
  }

  @override
  Future<List<domain.PeriodDaySeverity>> recentPeriodDaySeverities(Duration window, {required DateTime now}) async {
    final utcNow = now.toUtc();
    final cutoff = utcNow.subtract(window);
    final rows = await (_db.select(_db.periodDaySeverities)
          ..where((t) => t.day.isBiggerOrEqualValue(cutoff) & t.day.isSmallerThanValue(utcNow))
          ..orderBy([(t) => OrderingTerm.desc(t.day)]))
        .get();
    return rows.map(_toDomainOverride).toList();
  }

  @override
  Stream<List<domain.PeriodDaySeverity>> watchRecentPeriodDaySeverities(Duration window, {required DateTime now}) {
    final utcNow = now.toUtc();
    final cutoff = utcNow.subtract(window);
    final q = _db.select(_db.periodDaySeverities)
      ..where((t) => t.day.isBiggerOrEqualValue(cutoff) & t.day.isSmallerThanValue(utcNow))
      ..orderBy([(t) => OrderingTerm.desc(t.day)]);
    return q.watch().map((rows) => rows.map(_toDomainOverride).toList());
  }

  domain.PeriodDaySeverity _toDomainOverride(PeriodDaySeverity r) => domain.PeriodDaySeverity(
        day: r.day.toUtc(),
        severity: r.severity,
      );

  @override
  Future<void> updateAttack(domain.Attack old, domain.Attack updated) async {
    final utcOld = old.startedAt.toUtc();
    await (_db.update(_db.attacks)
          ..where((t) => t.startedAt.equals(utcOld)))
        .write(AttacksCompanion(
          startedAt: Value(updated.startedAt.toUtc()),
          endedAt: Value(updated.endedAt?.toUtc()),
          severity: Value(updated.severity),
          inProgress: Value(updated.inProgress),
        ));
  }
}

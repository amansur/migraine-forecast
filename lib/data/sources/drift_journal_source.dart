import 'dart:convert';

import 'package:domain/domain.dart' as domain;
import 'package:drift/drift.dart';

import '../database.dart' hide Attack, JournalEntry;
import 'journal_source.dart';

class DriftJournalSource implements JournalSource {
  final AppDatabase _db;
  DriftJournalSource(this._db);

  @override
  Future<void> addEntry(domain.JournalEntry entry) async {
    await _db.into(_db.journalEntries).insert(
          JournalEntriesCompanion.insert(
            at: entry.at,
            kind: entry.kind.name,
            payloadJson: jsonEncode(entry.payload),
          ),
        );
  }

  @override
  Future<List<domain.JournalEntry>> recentEntries(Duration window, {required DateTime now}) async {
    final cutoff = now.subtract(window);
    final rows = await (_db.select(_db.journalEntries)
          ..where((t) => t.at.isBiggerOrEqualValue(cutoff))
          ..orderBy([(t) => OrderingTerm.desc(t.at)]))
        .get();
    return rows
        .map((r) => domain.JournalEntry(
              at: r.at,
              kind: domain.JournalKind.values.firstWhere((k) => k.name == r.kind),
              payload: Map<String, Object?>.from(jsonDecode(r.payloadJson) as Map),
            ))
        .toList();
  }

  @override
  Future<int> addAttack(domain.Attack attack, {int? riskAssessmentId}) async {
    return _db.into(_db.attacks).insert(
          AttacksCompanion.insert(
            startedAt: attack.startedAt,
            endedAt: Value(attack.endedAt),
            severity: attack.severity,
            notes: const Value.absent(),
            riskAssessmentId: Value(riskAssessmentId),
          ),
        );
  }

  @override
  Future<List<domain.Attack>> recentAttacks(Duration window, {required DateTime now}) async {
    final cutoff = now.subtract(window);
    final rows = await (_db.select(_db.attacks)
          ..where((t) => t.startedAt.isBiggerOrEqualValue(cutoff))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
    return rows
        .map((r) => domain.Attack(startedAt: r.startedAt, endedAt: r.endedAt, severity: r.severity))
        .toList();
  }
}

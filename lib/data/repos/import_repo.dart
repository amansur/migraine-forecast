import 'dart:convert';

import 'package:drift/drift.dart';

import '../database.dart';

enum ImportMode { replaceAll, merge }

class ImportRepo {
  final AppDatabase _db;
  ImportRepo(this._db);

  /// Imports a JSON string from [ExportRepo.buildJson] (v1) or
  /// [ExportRepo.buildJsonFull] (v2). Returns total rows inserted/upserted.
  /// Throws [FormatException] for malformed JSON or an unsupported
  /// schema_version.
  Future<int> importJson(String jsonStr, ImportMode mode) async {
    final Map<String, Object?> map;
    try {
      map = jsonDecode(jsonStr) as Map<String, Object?>;
    } catch (_) {
      throw const FormatException('The file does not contain valid JSON.');
    }

    final version = map['schema_version'] as int?;
    if (version != 1 && version != 2) {
      throw FormatException(
          'Unsupported schema_version: $version. Expected 1 or 2.');
    }

    int count = 0;
    await _db.transaction(() async {
      count += await _importAttacks(map['attacks'] as List?, mode);
      count += await _importJournalEntries(map['journal_entries'] as List?, mode);
      count += await _importSettings(map['settings'] as List?, mode);
      count += await _importTriggerFlags(map['user_trigger_flags'] as List?, mode);
      if (version == 2) {
        count += await _importRiskAssessments(map['risk_assessments'] as List?, mode);
        count += await _importPeriods(map['periods'] as List?, mode);
        count += await _importPeriodDaySeverities(
            map['period_day_severities'] as List?, mode);
        count += await _importManualSleepRecords(
            map['manual_sleep_records'] as List?, mode);
        count += await _importDayLocationOverrides(
            map['day_location_overrides'] as List?, mode);
      }
    });
    return count;
  }

  Future<int> _importAttacks(List? rows, ImportMode mode) async {
    if (rows == null || rows.isEmpty) return 0;
    if (mode == ImportMode.replaceAll) await _db.delete(_db.attacks).go();
    final companions = rows.cast<Map<String, dynamic>>().map((r) => AttacksCompanion(
          id: Value(r['id'] as int),
          startedAt: Value(DateTime.parse(r['started_at'] as String).toUtc()),
          endedAt: Value(r['ended_at'] != null
              ? DateTime.parse(r['ended_at'] as String).toUtc()
              : null),
          severity: Value(r['severity'] as int),
          notes: Value(r['notes'] as String?),
          riskAssessmentId: Value(r['risk_assessment_id'] as int?),
          inProgress: Value(r['in_progress'] as bool? ?? false),
        )).toList();
    await _db.batch(
        (b) => b.insertAll(_db.attacks, companions, mode: InsertMode.insertOrIgnore));
    return companions.length;
  }

  Future<int> _importJournalEntries(List? rows, ImportMode mode) async {
    if (rows == null || rows.isEmpty) return 0;
    if (mode == ImportMode.replaceAll) await _db.delete(_db.journalEntries).go();
    final companions =
        rows.cast<Map<String, dynamic>>().map((r) => JournalEntriesCompanion(
              id: Value(r['id'] as int),
              at: Value(DateTime.parse(r['at'] as String).toUtc()),
              kind: Value(r['kind'] as String),
              payloadJson: Value(r['payload_json'] as String),
            )).toList();
    await _db.batch((b) =>
        b.insertAll(_db.journalEntries, companions, mode: InsertMode.insertOrIgnore));
    return companions.length;
  }

  Future<int> _importSettings(List? rows, ImportMode mode) async {
    if (rows == null || rows.isEmpty) return 0;
    if (mode == ImportMode.replaceAll) await _db.delete(_db.settings).go();
    final companions = rows.cast<Map<String, dynamic>>().map((r) => SettingsCompanion(
          key: Value(r['key'] as String),
          value: Value(r['value'] as String),
        )).toList();
    await _db.batch(
        (b) => b.insertAll(_db.settings, companions, mode: InsertMode.insertOrReplace));
    return companions.length;
  }

  Future<int> _importTriggerFlags(List? rows, ImportMode mode) async {
    if (rows == null || rows.isEmpty) return 0;
    if (mode == ImportMode.replaceAll) await _db.delete(_db.userTriggerFlagsTbl).go();
    final companions =
        rows.cast<Map<String, dynamic>>().map((r) => UserTriggerFlagsTblCompanion(
              moduleId: Value(r['module_id'] as String),
              flagged: Value(r['flagged'] as bool),
              weightOverride: Value((r['weight_override'] as num).toDouble()),
            )).toList();
    await _db.batch((b) => b.insertAll(_db.userTriggerFlagsTbl, companions,
        mode: InsertMode.insertOrReplace));
    return companions.length;
  }

  Future<int> _importRiskAssessments(List? rows, ImportMode mode) async {
    if (rows == null || rows.isEmpty) return 0;
    if (mode == ImportMode.replaceAll) await _db.delete(_db.riskAssessments).go();
    final companions =
        rows.cast<Map<String, dynamic>>().map((r) => RiskAssessmentsCompanion(
              targetDate: Value(DateTime.parse(r['target_date'] as String).toUtc()),
              horizon: Value(r['horizon'] as String),
              score: Value(r['score'] as int),
              band: Value(r['band'] as String),
              computedAt: Value(DateTime.parse(r['computed_at'] as String).toUtc()),
              configVersion: Value(r['config_version'] as int),
              contributorsJson: Value(r['contributors_json'] as String),
              backfilled: Value(r['backfilled'] as bool? ?? false),
            )).toList();
    await _db.batch((b) => b.insertAll(_db.riskAssessments, companions,
        mode: InsertMode.insertOrReplace));
    return companions.length;
  }

  Future<int> _importPeriods(List? rows, ImportMode mode) async {
    if (rows == null || rows.isEmpty) return 0;
    if (mode == ImportMode.replaceAll) await _db.delete(_db.periods).go();
    final companions = rows.cast<Map<String, dynamic>>().map((r) => PeriodsCompanion(
          id: Value(r['id'] as int),
          startedAt: Value(DateTime.parse(r['started_at'] as String).toUtc()),
          endedAt: Value(r['ended_at'] != null
              ? DateTime.parse(r['ended_at'] as String).toUtc()
              : null),
          baselineSeverity: Value(r['baseline_severity'] as int),
        )).toList();
    await _db.batch(
        (b) => b.insertAll(_db.periods, companions, mode: InsertMode.insertOrIgnore));
    return companions.length;
  }

  Future<int> _importPeriodDaySeverities(List? rows, ImportMode mode) async {
    if (rows == null || rows.isEmpty) return 0;
    if (mode == ImportMode.replaceAll) await _db.delete(_db.periodDaySeverities).go();
    final companions =
        rows.cast<Map<String, dynamic>>().map((r) => PeriodDaySeveritiesCompanion(
              day: Value(DateTime.parse(r['day'] as String).toUtc()),
              severity: Value(r['severity'] as int),
            )).toList();
    await _db.batch((b) => b.insertAll(_db.periodDaySeverities, companions,
        mode: InsertMode.insertOrIgnore));
    return companions.length;
  }

  Future<int> _importManualSleepRecords(List? rows, ImportMode mode) async {
    if (rows == null || rows.isEmpty) return 0;
    if (mode == ImportMode.replaceAll) await _db.delete(_db.manualSleepRecords).go();
    final companions =
        rows.cast<Map<String, dynamic>>().map((r) => ManualSleepRecordsCompanion(
              night: Value(DateTime.parse(r['night'] as String).toUtc()),
              sleepStart: Value(DateTime.parse(r['sleep_start'] as String).toUtc()),
              totalSleepMinutes: Value(r['total_sleep_minutes'] as int),
              efficiency: Value((r['efficiency'] as num?)?.toDouble()),
            )).toList();
    await _db.batch((b) => b.insertAll(_db.manualSleepRecords, companions,
        mode: InsertMode.insertOrIgnore));
    return companions.length;
  }

  Future<int> _importDayLocationOverrides(List? rows, ImportMode mode) async {
    if (rows == null || rows.isEmpty) return 0;
    if (mode == ImportMode.replaceAll) await _db.delete(_db.dayLocationOverrides).go();
    final companions =
        rows.cast<Map<String, dynamic>>().map((r) => DayLocationOverridesCompanion(
              day: Value(DateTime.parse(r['day'] as String).toUtc()),
              lat: Value((r['lat'] as num).toDouble()),
              lon: Value((r['lon'] as num).toDouble()),
              displayName: Value(r['display_name'] as String),
              setAt: Value(DateTime.parse(r['set_at'] as String).toUtc()),
            )).toList();
    await _db.batch((b) => b.insertAll(_db.dayLocationOverrides, companions,
        mode: InsertMode.insertOrIgnore));
    return companions.length;
  }
}

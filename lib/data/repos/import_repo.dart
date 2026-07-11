import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
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

    final version = map['schema_version'] is int ? map['schema_version'] as int : null;
    if (version != 1 && version != 2) {
      throw FormatException(
          'Unsupported schema_version: ${map['schema_version']}. Expected 1 or 2.');
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
        count += await _importDayCheckins(map['day_checkins'] as List?, mode);
        count += await _importMedicationDoses(map['medication_doses'] as List?, mode);
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
              weightOverride: Value((r['weight_override'] as num?)?.toDouble() ?? 0.0),
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
              id: Value(r['id'] as int),
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

  Future<int> _importMedicationDoses(List? rows, ImportMode mode) async {
    if (rows == null || rows.isEmpty) return 0;
    if (mode == ImportMode.replaceAll) await _db.delete(_db.medicationDoses).go();
    final companions = rows.cast<Map<String, dynamic>>().map((r) => MedicationDosesCompanion(
          id: Value(r['id'] as int),
          at: Value(DateTime.parse(r['at'] as String).toUtc()),
          name: Value(r['name'] as String),
          medClass: Value(r['med_class'] as String),
          reliefRating: Value(r['relief_rating'] as int?),
        )).toList();
    await _db.batch((b) =>
        b.insertAll(_db.medicationDoses, companions, mode: InsertMode.insertOrIgnore));
    return companions.length;
  }

  Future<int> _importDayCheckins(List? rows, ImportMode mode) async {
    if (rows == null || rows.isEmpty) return 0;
    if (mode == ImportMode.replaceAll) await _db.delete(_db.dayCheckins).go();
    final companions = rows.cast<Map<String, dynamic>>().map((r) => DayCheckinsCompanion(
          day: Value(DateTime.parse(r['day'] as String).toUtc()),
          hadAttack: Value(r['had_attack'] as bool),
          answeredAt: Value(DateTime.parse(r['answered_at'] as String).toUtc()),
        )).toList();
    await _db.batch((b) =>
        b.insertAll(_db.dayCheckins, companions, mode: InsertMode.insertOrIgnore));
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

  static const _knownModules = [
    'pressure_drop', 'humidity', 'temp_swing', 'air_quality',
    'stress', 'sleep_deficit', 'alcohol', 'caffeine', 'hydration', 'menstrual_phase',
  ];

  /// Imports a ZIP produced by [ExportRepo.buildCsvZipBytes].
  /// Returns total rows inserted/upserted.
  /// Throws [FormatException] for an unreadable ZIP or a CSV missing required
  /// columns.
  Future<int> importCsvZip(Uint8List zipBytes, ImportMode mode) async {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipBytes);
    } catch (_) {
      throw const FormatException('The file could not be read as a ZIP archive.');
    }

    int count = 0;
    await _db.transaction(() async {
      for (final file in archive) {
        if (!file.isFile) continue;
        final content = utf8.decode(file.content as List<int>);
        switch (file.name) {
          case 'attacks.csv':
            count += await _importAttacksCsv(content, mode);
          case 'journal_entries.csv':
            count += await _importJournalEntriesCsv(content, mode);
          case 'risk_assessments.csv':
            count += await _importRiskAssessmentsCsv(content, mode);
        }
        // Unknown filenames are silently ignored.
      }
    });
    return count;
  }

  static List<List<dynamic>> _parseCsv(String content) =>
      const CsvToListConverter(eol: '\n').convert(content.trim());

  static Map<String, int> _headerIndex(List<dynamic> header) =>
      {for (var i = 0; i < header.length; i++) header[i].toString(): i};

  static String? _cell(List<dynamic> row, Map<String, int> idx, String col) {
    final i = idx[col];
    if (i == null || i >= row.length) return null;
    final v = row[i];
    if (v == null || v.toString().isEmpty) return null;
    // Reverse the newline escaping applied during export.
    return v.toString().replaceAll(r'\n', '\n');
  }

  Future<int> _importAttacksCsv(String content, ImportMode mode) async {
    final rows = _parseCsv(content);
    if (rows.length <= 1) return 0; // empty or header-only → skip (do not wipe)
    final idx = _headerIndex(rows.first);
    for (final col in ['id', 'started_at', 'severity', 'in_progress']) {
      if (!idx.containsKey(col)) {
        throw FormatException('attacks.csv is missing required column: $col');
      }
    }
    if (mode == ImportMode.replaceAll) await _db.delete(_db.attacks).go();
    final companions = rows.skip(1).map((r) => AttacksCompanion(
          id: Value(int.parse(_cell(r, idx, 'id')!)),
          startedAt: Value(DateTime.parse(_cell(r, idx, 'started_at')!).toUtc()),
          endedAt: Value(_cell(r, idx, 'ended_at') != null
              ? DateTime.parse(_cell(r, idx, 'ended_at')!).toUtc()
              : null),
          severity: Value(int.parse(_cell(r, idx, 'severity')!)),
          notes: Value(_cell(r, idx, 'notes')),
          riskAssessmentId: Value(_cell(r, idx, 'risk_assessment_id') != null
              ? int.parse(_cell(r, idx, 'risk_assessment_id')!)
              : null),
          inProgress: Value(_cell(r, idx, 'in_progress') == 'true'),
        )).toList();
    await _db.batch(
        (b) => b.insertAll(_db.attacks, companions, mode: InsertMode.insertOrIgnore));
    return companions.length;
  }

  Future<int> _importJournalEntriesCsv(String content, ImportMode mode) async {
    final rows = _parseCsv(content);
    if (rows.length <= 1) return 0; // empty or header-only → skip (do not wipe)
    final idx = _headerIndex(rows.first);
    for (final col in ['id', 'at', 'kind', 'payload_json']) {
      if (!idx.containsKey(col)) {
        throw FormatException(
            'journal_entries.csv is missing required column: $col');
      }
    }
    if (mode == ImportMode.replaceAll) await _db.delete(_db.journalEntries).go();
    final companions = rows.skip(1).map((r) => JournalEntriesCompanion(
          id: Value(int.parse(_cell(r, idx, 'id')!)),
          at: Value(DateTime.parse(_cell(r, idx, 'at')!).toUtc()),
          kind: Value(_cell(r, idx, 'kind')!),
          payloadJson: Value(_cell(r, idx, 'payload_json')!),
        )).toList();
    await _db.batch((b) =>
        b.insertAll(_db.journalEntries, companions, mode: InsertMode.insertOrIgnore));
    return companions.length;
  }

  Future<int> _importRiskAssessmentsCsv(String content, ImportMode mode) async {
    final rows = _parseCsv(content);
    if (rows.length <= 1) return 0; // empty or header-only → skip (do not wipe)
    final idx = _headerIndex(rows.first);
    for (final col in [
      'target_date', 'horizon', 'score', 'band', 'computed_at',
      'config_version', 'backfilled',
    ]) {
      if (!idx.containsKey(col)) {
        throw FormatException(
            'risk_assessments.csv is missing required column: $col');
      }
    }
    if (mode == ImportMode.replaceAll) await _db.delete(_db.riskAssessments).go();

    final companions = rows.skip(1).map((r) {
      // Reconstruct contributors_json from the expanded per-module columns.
      // Export wrote {id}_contribution = weight * confidence; we reconstruct
      // with weight = contribution and confidence = 1.0 so downstream scoring
      // can use contribution as-is.
      final contributors = <Map<String, dynamic>>[];
      for (final m in _knownModules) {
        final contribution = _cell(r, idx, '${m}_contribution');
        final explanation = _cell(r, idx, '${m}_explanation');
        if (contribution != null) {
          contributors.add({
            'moduleId': m,
            'weight': double.parse(contribution),
            'confidence': 1.0,
            'explanation': explanation ?? '',
          });
        }
      }
      return RiskAssessmentsCompanion(
        targetDate: Value(DateTime.parse(_cell(r, idx, 'target_date')!).toUtc()),
        horizon: Value(_cell(r, idx, 'horizon')!),
        score: Value(int.parse(_cell(r, idx, 'score')!)),
        band: Value(_cell(r, idx, 'band')!),
        computedAt: Value(DateTime.parse(_cell(r, idx, 'computed_at')!).toUtc()),
        configVersion: Value(int.parse(_cell(r, idx, 'config_version')!)),
        contributorsJson: Value(jsonEncode(contributors)),
        backfilled: Value(_cell(r, idx, 'backfilled') == 'true'),
      );
    }).toList();
    await _db.batch((b) => b.insertAll(_db.riskAssessments, companions,
        mode: InsertMode.insertOrReplace));
    return companions.length;
  }
}

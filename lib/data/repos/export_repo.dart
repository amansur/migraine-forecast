import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../database.dart';

class ExportRepo {
  final AppDatabase _db;

  ExportRepo(this._db);

  Future<String> buildJson({DateTime? now, String? appVersionOverride}) async {
    final exportedAt = (now ?? DateTime.now()).toUtc();

    final String appVersion;
    if (appVersionOverride != null) {
      appVersion = appVersionOverride;
    } else {
      final info = await PackageInfo.fromPlatform();
      appVersion = info.version;
    }

    final attacks = await _db.select(_db.attacks).get();
    final journalEntries = await _db.select(_db.journalEntries).get();
    final settings = await _db.select(_db.settings).get();
    final userTriggerFlags = await _db.select(_db.userTriggerFlagsTbl).get();

    final payload = {
      'schema_version': 1,
      'app_version': appVersion,
      'exported_at': exportedAt.toIso8601String(),
      'attacks': attacks.map(_attackToMap).toList(),
      'journal_entries': journalEntries.map(_journalEntryToMap).toList(),
      'settings': settings.map(_settingToMap).toList(),
      'user_trigger_flags': userTriggerFlags.map(_userTriggerFlagToMap).toList(),
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(payload);
  }

  Future<String> buildJsonFull({DateTime? now, String? appVersionOverride}) async {
    final exportedAt = (now ?? DateTime.now()).toUtc();
    final String appVersion;
    if (appVersionOverride != null) {
      appVersion = appVersionOverride;
    } else {
      final info = await PackageInfo.fromPlatform();
      appVersion = info.version;
    }

    final attacks = await _db.select(_db.attacks).get();
    final journalEntries = await _db.select(_db.journalEntries).get();
    final settings = await _db.select(_db.settings).get();
    final userTriggerFlags = await _db.select(_db.userTriggerFlagsTbl).get();
    final riskAssessments = await _db.select(_db.riskAssessments).get();
    final periods = await _db.select(_db.periods).get();
    final periodDaySeverities = await _db.select(_db.periodDaySeverities).get();
    final manualSleepRecords = await _db.select(_db.manualSleepRecords).get();
    final dayLocationOverrides = await _db.select(_db.dayLocationOverrides).get();
    final dayCheckins = await _db.select(_db.dayCheckins).get();
    final medicationDoses = await _db.select(_db.medicationDoses).get();

    final payload = {
      'schema_version': 2,
      'app_version': appVersion,
      'exported_at': exportedAt.toIso8601String(),
      'attacks': attacks.map(_attackToMap).toList(),
      'journal_entries': journalEntries.map(_journalEntryToMap).toList(),
      'settings': settings.map(_settingToMap).toList(),
      'user_trigger_flags': userTriggerFlags.map(_userTriggerFlagToMap).toList(),
      'risk_assessments': riskAssessments.map(_riskAssessmentToMap).toList(),
      'periods': periods.map(_periodToMap).toList(),
      'period_day_severities': periodDaySeverities.map(_periodDaySeverityToMap).toList(),
      'manual_sleep_records': manualSleepRecords.map(_manualSleepRecordToMap).toList(),
      'day_location_overrides': dayLocationOverrides.map(_dayLocationOverrideToMap).toList(),
      'day_checkins': dayCheckins.map(_dayCheckinToMap).toList(),
      'medication_doses': medicationDoses.map(_medicationDoseToMap).toList(),
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(payload);
  }

  static const _knownModules = [
    'pressure_drop', 'humidity', 'temp_swing', 'air_quality',
    'stress', 'sleep_deficit', 'alcohol', 'caffeine', 'hydration', 'menstrual_phase',
    'skipped_meals',
  ];

  Future<Uint8List> buildCsvZipBytes() async {
    final attacks = await _db.select(_db.attacks).get();
    final journalEntries = await _db.select(_db.journalEntries).get();
    final riskAssessments = await _db.select(_db.riskAssessments).get();

    final attackBytes = _buildAttacksCsv(attacks);
    final journalBytes = _buildJournalEntriesCsv(journalEntries);
    final riskBytes = _buildRiskAssessmentsCsv(riskAssessments);
    final archive = Archive()
      ..addFile(ArchiveFile('attacks.csv', attackBytes.length, attackBytes))
      ..addFile(ArchiveFile('journal_entries.csv', journalBytes.length, journalBytes))
      ..addFile(ArchiveFile('risk_assessments.csv', riskBytes.length, riskBytes));

    return Uint8List.fromList(ZipEncoder().encode(archive)!);
  }

  static String _csvCell(Object? v) {
    final s = (v?.toString() ?? '').replaceAll('\r\n', r'\n').replaceAll('\n', r'\n');
    if (s.contains(',') || s.contains('"')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static String _csvRow(List<Object?> cells) => cells.map(_csvCell).join(',');

  static List<int> _buildAttacksCsv(List<Attack> rows) {
    final buf = StringBuffer()
      ..writeln(_csvRow(['id', 'started_at', 'ended_at', 'severity', 'notes', 'risk_assessment_id', 'in_progress']));
    for (final r in rows) {
      buf.writeln(_csvRow([
        r.id,
        r.startedAt.toUtc().toIso8601String(),
        r.endedAt?.toUtc().toIso8601String(),
        r.severity,
        r.notes,
        r.riskAssessmentId,
        r.inProgress,
      ]));
    }
    return utf8.encode(buf.toString());
  }

  static List<int> _buildJournalEntriesCsv(List<JournalEntry> rows) {
    final buf = StringBuffer()
      ..writeln(_csvRow(['id', 'at', 'kind', 'payload_json']));
    for (final r in rows) {
      buf.writeln(_csvRow([r.id, r.at.toUtc().toIso8601String(), r.kind, r.payloadJson]));
    }
    return utf8.encode(buf.toString());
  }

  static List<int> _buildRiskAssessmentsCsv(List<RiskAssessment> rows) {
    final headers = [
      'target_date', 'horizon', 'score', 'band', 'computed_at', 'config_version', 'backfilled',
      for (final m in _knownModules) ...['${m}_contribution', '${m}_explanation'],
    ];
    final buf = StringBuffer()..writeln(_csvRow(headers));
    for (final r in rows) {
      final contributors = (jsonDecode(r.contributorsJson) as List).cast<Map<String, dynamic>>();
      final byModule = {for (final c in contributors) c['moduleId'] as String: c};
      final cells = <Object?>[
        r.targetDate.toUtc().toIso8601String(),
        r.horizon,
        r.score,
        r.band,
        r.computedAt.toUtc().toIso8601String(),
        r.configVersion,
        r.backfilled,
        for (final m in _knownModules) ...[
          byModule[m] != null
              ? (byModule[m]!['weight'] as num) * (byModule[m]!['confidence'] as num)
              : null,
          byModule[m]?['explanation'],
        ],
      ];
      buf.writeln(_csvRow(cells));
    }
    return utf8.encode(buf.toString());
  }

  Map<String, Object?> _riskAssessmentToMap(RiskAssessment row) => {
        'id': row.id,
        'target_date': row.targetDate.toUtc().toIso8601String(),
        'horizon': row.horizon,
        'score': row.score,
        'band': row.band,
        'computed_at': row.computedAt.toUtc().toIso8601String(),
        'config_version': row.configVersion,
        'contributors_json': row.contributorsJson,
        'backfilled': row.backfilled,
      };

  Map<String, Object?> _medicationDoseToMap(MedicationDose row) => {
        'id': row.id,
        'at': row.at.toUtc().toIso8601String(),
        'name': row.name,
        'med_class': row.medClass,
        'relief_rating': row.reliefRating,
      };

  Map<String, Object?> _dayCheckinToMap(DayCheckin row) => {
        'day': row.day.toUtc().toIso8601String(),
        'had_attack': row.hadAttack,
        'answered_at': row.answeredAt.toUtc().toIso8601String(),
      };

  Map<String, Object?> _periodToMap(Period row) => {
        'id': row.id,
        'started_at': row.startedAt.toUtc().toIso8601String(),
        'ended_at': row.endedAt?.toUtc().toIso8601String(),
        'baseline_severity': row.baselineSeverity,
      };

  Map<String, Object?> _periodDaySeverityToMap(PeriodDaySeverity row) => {
        'day': row.day.toUtc().toIso8601String(),
        'severity': row.severity,
      };

  Map<String, Object?> _manualSleepRecordToMap(ManualSleepRecord row) => {
        'night': row.night.toUtc().toIso8601String(),
        'sleep_start': row.sleepStart.toUtc().toIso8601String(),
        'total_sleep_minutes': row.totalSleepMinutes,
        'efficiency': row.efficiency,
      };

  Map<String, Object?> _dayLocationOverrideToMap(DayLocationOverride row) => {
        'day': row.day.toUtc().toIso8601String(),
        'lat': row.lat,
        'lon': row.lon,
        'display_name': row.displayName,
        'set_at': row.setAt.toUtc().toIso8601String(),
      };

  Map<String, Object?> _attackToMap(Attack row) => {
        'id': row.id,
        'started_at': row.startedAt.toUtc().toIso8601String(),
        'ended_at': row.endedAt?.toUtc().toIso8601String(),
        'severity': row.severity,
        'notes': row.notes,
        'risk_assessment_id': row.riskAssessmentId,
        'in_progress': row.inProgress,
      };

  Map<String, Object?> _journalEntryToMap(JournalEntry row) => {
        'id': row.id,
        'at': row.at.toUtc().toIso8601String(),
        'kind': row.kind,
        'payload_json': row.payloadJson,
      };

  Map<String, Object?> _settingToMap(Setting row) => {
        'key': row.key,
        'value': row.value,
      };

  Map<String, Object?> _userTriggerFlagToMap(UserTriggerFlagsTblData row) => {
        'module_id': row.moduleId,
        'flagged': row.flagged,
        'weight_override': row.weightOverride,
      };
}

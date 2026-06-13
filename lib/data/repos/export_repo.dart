import 'dart:convert';

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

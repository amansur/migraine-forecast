import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart'
    hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_forecast/data/repos/export_repo.dart';

void main() {
  late AppDatabase db;
  late ExportRepo repo;

  setUp(() {
    db = AppDatabase.memory();
    repo = ExportRepo(db);
  });

  tearDown(() => db.close());

  test('JSON contains required top-level keys and correct schema_version', () async {
    final json = await repo.buildJson(
      now: DateTime.utc(2026, 6, 13, 12, 0, 0),
      appVersionOverride: '1.0.0',
    );
    final map = jsonDecode(json) as Map<String, Object?>;

    expect(map['schema_version'], 1);
    expect(map['app_version'], '1.0.0');
    expect(map['exported_at'], '2026-06-13T12:00:00.000Z');
    expect(map.containsKey('attacks'), isTrue);
    expect(map.containsKey('journal_entries'), isTrue);
    expect(map.containsKey('settings'), isTrue);
    expect(map.containsKey('user_trigger_flags'), isTrue);
  });

  test('derived tables are absent from export', () async {
    final json = await repo.buildJson(appVersionOverride: '1.0.0');
    final map = jsonDecode(json) as Map<String, Object?>;

    expect(map.containsKey('risk_assessments'), isFalse);
    expect(map.containsKey('weather_snapshots'), isFalse);
    expect(map.containsKey('baselines_kv'), isFalse);
  });

  test('seeded data round-trips correctly', () async {
    final attackedAt = DateTime.utc(2026, 6, 10, 9, 0, 0);
    await db.into(db.attacks).insert(
          AttacksCompanion.insert(
            startedAt: attackedAt,
            severity: 3,
            inProgress: const Value(false),
          ),
        );

    final journalAt1 = DateTime.utc(2026, 6, 11, 8, 0, 0);
    final journalAt2 = DateTime.utc(2026, 6, 12, 10, 0, 0);
    await db.into(db.journalEntries).insert(
          JournalEntriesCompanion.insert(
            at: journalAt1,
            kind: 'caffeine',
            payloadJson: '{"cups":2}',
          ),
        );
    await db.into(db.journalEntries).insert(
          JournalEntriesCompanion.insert(
            at: journalAt2,
            kind: 'stress',
            payloadJson: '{"level":7}',
          ),
        );

    await db.into(db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(key: 'display_mode', value: 'gauge'),
        );

    await db.into(db.userTriggerFlagsTbl).insertOnConflictUpdate(
          UserTriggerFlagsTblCompanion.insert(
            moduleId: 'pressure_drop',
            flagged: const Value(true),
            weightOverride: const Value(1.0),
          ),
        );

    final json = await repo.buildJson(appVersionOverride: '1.0.0');
    final map = jsonDecode(json) as Map<String, Object?>;

    final attacks = map['attacks'] as List;
    expect(attacks, hasLength(1));
    expect(attacks.first['severity'], 3);
    expect(attacks.first['started_at'], attackedAt.toIso8601String());

    final journalEntries = map['journal_entries'] as List;
    expect(journalEntries, hasLength(2));
    final kinds = journalEntries.map((e) => (e as Map)['kind']).toSet();
    expect(kinds, containsAll(['caffeine', 'stress']));

    final settings = map['settings'] as List;
    expect(settings, hasLength(1));
    expect(settings.first['key'], 'display_mode');
    expect(settings.first['value'], 'gauge');

    final flags = map['user_trigger_flags'] as List;
    expect(flags, hasLength(1));
    expect(flags.first['module_id'], 'pressure_drop');
    expect(flags.first['flagged'], isTrue);
    expect(flags.first['weight_override'], 1.0);
  });

  test('output is valid pretty-printed JSON', () async {
    final json = await repo.buildJson(appVersionOverride: '1.0.0');
    expect(json, contains('\n'));
    expect(() => jsonDecode(json), returnsNormally);
  });

  test('datetimes are serialized as UTC ISO-8601', () async {
    final localTime = DateTime(2026, 6, 10, 9, 0, 0);
    await db.into(db.attacks).insert(
          AttacksCompanion.insert(
            startedAt: localTime,
            severity: 2,
          ),
        );

    final json = await repo.buildJson(appVersionOverride: '1.0.0');
    final map = jsonDecode(json) as Map<String, Object?>;
    final attacks = map['attacks'] as List;
    final startedAt = attacks.first['started_at'] as String;
    expect(startedAt.endsWith('Z'), isTrue);
  });

  group('buildJsonFull', () {
    test('schema_version is 2 and includes new table keys', () async {
      final json = await repo.buildJsonFull(
        now: DateTime.utc(2026, 6, 23, 12, 0, 0),
        appVersionOverride: '2.0.0',
      );
      final map = jsonDecode(json) as Map<String, Object?>;
      expect(map['schema_version'], 2);
      expect(map.containsKey('risk_assessments'), isTrue);
      expect(map.containsKey('periods'), isTrue);
      expect(map.containsKey('period_day_severities'), isTrue);
      expect(map.containsKey('manual_sleep_records'), isTrue);
      expect(map.containsKey('day_location_overrides'), isTrue);
    });

    test('risk_assessment row round-trips with contributors_json', () async {
      await db.into(db.riskAssessments).insert(
        RiskAssessmentsCompanion.insert(
          targetDate: DateTime.utc(2026, 6, 1),
          horizon: 'today',
          score: 42,
          band: 'moderate',
          computedAt: DateTime.utc(2026, 6, 1, 6),
          configVersion: 1,
          contributorsJson:
              '[{"moduleId":"pressure_drop","weight":0.8,"confidence":0.9,"explanation":"Dropped 5 hPa"}]',
        ),
        onConflict: DoNothing(),
      );
      final json = await repo.buildJsonFull(appVersionOverride: '2.0.0');
      final map = jsonDecode(json) as Map<String, Object?>;
      final assessments = map['risk_assessments'] as List;
      expect(assessments, hasLength(1));
      expect(assessments.first['score'], 42);
      expect(assessments.first['horizon'], 'today');
      expect(assessments.first['contributors_json'], contains('pressure_drop'));
    });

    test('existing buildJson still returns schema_version 1', () async {
      final json = await repo.buildJson(appVersionOverride: '1.0.0');
      final map = jsonDecode(json) as Map<String, Object?>;
      expect(map['schema_version'], 1);
      expect(map.containsKey('risk_assessments'), isFalse);
    });
  });

  group('buildCsvZipBytes', () {
    test('ZIP contains three CSV files with expected names', () async {
      final zipBytes = await repo.buildCsvZipBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final names = archive.map((f) => f.name).toSet();
      expect(names, containsAll(['attacks.csv', 'journal_entries.csv', 'risk_assessments.csv']));
      expect(names, hasLength(3));
    });

    test('attacks.csv has correct header', () async {
      final zipBytes = await repo.buildCsvZipBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final file = archive.firstWhere((f) => f.name == 'attacks.csv');
      final content = utf8.decode(file.content as List<int>);
      expect(content.split('\n').first.trim(),
          'id,started_at,ended_at,severity,notes,risk_assessment_id,in_progress');
    });

    test('risk_assessments.csv has trigger columns', () async {
      final zipBytes = await repo.buildCsvZipBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final file = archive.firstWhere((f) => f.name == 'risk_assessments.csv');
      final content = utf8.decode(file.content as List<int>);
      final header = content.split('\n').first;
      expect(header, contains('pressure_drop_contribution'));
      expect(header, contains('temp_swing_explanation'));
      expect(header, contains('menstrual_phase_contribution'));
    });

    test('seeded attack appears in attacks.csv', () async {
      await db.into(db.attacks).insert(AttacksCompanion.insert(
        startedAt: DateTime.utc(2026, 6, 1, 8),
        severity: 3,
      ));
      final zipBytes = await repo.buildCsvZipBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final file = archive.firstWhere((f) => f.name == 'attacks.csv');
      final content = utf8.decode(file.content as List<int>);
      final lines = content.trim().split('\n');
      expect(lines, hasLength(2)); // header + 1 data row
      expect(lines[1], contains('2026-06-01T08:00:00.000Z'));
      expect(lines[1], contains(',3,'));
    });

    test('risk assessment trigger columns expand correctly', () async {
      await db.into(db.riskAssessments).insert(
        RiskAssessmentsCompanion.insert(
          targetDate: DateTime.utc(2026, 6, 1),
          horizon: 'today',
          score: 30,
          band: 'moderate',
          computedAt: DateTime.utc(2026, 6, 1, 6),
          configVersion: 1,
          contributorsJson:
              '[{"moduleId":"pressure_drop","weight":0.8,"confidence":0.9,"explanation":"Dropped 5 hPa"}]',
        ),
        onConflict: DoNothing(),
      );
      final zipBytes = await repo.buildCsvZipBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final file = archive.firstWhere((f) => f.name == 'risk_assessments.csv');
      final content = utf8.decode(file.content as List<int>);
      expect(content, contains('0.72')); // 0.8 * 0.9
      expect(content, contains('Dropped 5 hPa'));
    });
  });
}

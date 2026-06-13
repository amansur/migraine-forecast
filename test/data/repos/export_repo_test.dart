import 'dart:convert';

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
}

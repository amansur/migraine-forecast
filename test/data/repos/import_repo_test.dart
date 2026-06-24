import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart'
    hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_forecast/data/repos/export_repo.dart';
import 'package:migraine_forecast/data/repos/import_repo.dart';

void main() {
  late AppDatabase db;
  late ExportRepo exportRepo;
  late ImportRepo importRepo;

  setUp(() {
    db = AppDatabase.memory();
    exportRepo = ExportRepo(db);
    importRepo = ImportRepo(db);
  });

  tearDown(() => db.close());

  // ── JSON — replace-all ────────────────────────────────────────────────────

  group('importJson replace-all', () {
    test('imports attacks and wipes existing rows', () async {
      // Pre-seed an attack that must be wiped.
      await db.into(db.attacks).insert(
            AttacksCompanion.insert(startedAt: DateTime.utc(2026, 1, 1), severity: 9),
          );

      // Build a v2 export with one attack via the real ExportRepo.
      final sourceDb = AppDatabase.memory();
      await sourceDb.into(sourceDb.attacks).insert(
            AttacksCompanion.insert(startedAt: DateTime.utc(2026, 6, 1, 8), severity: 3),
          );
      final json = await ExportRepo(sourceDb).buildJsonFull(appVersionOverride: '2.0.0');
      await sourceDb.close();

      final count = await importRepo.importJson(json, ImportMode.replaceAll);

      expect(count, greaterThan(0));
      final attacks = await db.select(db.attacks).get();
      expect(attacks, hasLength(1));
      expect(attacks.first.severity, 3);
      expect(attacks.first.startedAt.toUtc().toIso8601String(),
          '2026-06-01T08:00:00.000Z');
    });

    test('imports all v2 tables', () async {
      final sourceDb = AppDatabase.memory();
      await sourceDb.into(sourceDb.riskAssessments).insert(
            RiskAssessmentsCompanion.insert(
              targetDate: DateTime.utc(2026, 6, 1),
              horizon: 'today',
              score: 42,
              band: 'moderate',
              computedAt: DateTime.utc(2026, 6, 1, 6),
              configVersion: 1,
              contributorsJson: '[]',
            ),
            onConflict: DoNothing(),
          );
      await sourceDb.into(sourceDb.periods).insert(
            PeriodsCompanion.insert(
              startedAt: DateTime.utc(2026, 5, 1),
              baselineSeverity: 2,
            ),
          );
      final json = await ExportRepo(sourceDb).buildJsonFull(appVersionOverride: '2.0.0');
      await sourceDb.close();

      await importRepo.importJson(json, ImportMode.replaceAll);

      final assessments = await db.select(db.riskAssessments).get();
      expect(assessments, hasLength(1));
      expect(assessments.first.score, 42);

      final periods = await db.select(db.periods).get();
      expect(periods, hasLength(1));
    });

    test('attack riskAssessmentId links to preserved risk_assessment id after import',
        () async {
      // Build source DB with one risk assessment and one attack that references it.
      final sourceDb = AppDatabase.memory();
      final raId = await sourceDb.into(sourceDb.riskAssessments).insert(
            RiskAssessmentsCompanion.insert(
              targetDate: DateTime.utc(2026, 6, 1),
              horizon: 'today',
              score: 50,
              band: 'moderate',
              computedAt: DateTime.utc(2026, 6, 1, 6),
              configVersion: 1,
              contributorsJson: '[]',
            ),
            onConflict: DoNothing(),
          );
      await sourceDb.into(sourceDb.attacks).insert(AttacksCompanion(
            startedAt: Value(DateTime.utc(2026, 6, 1, 8)),
            severity: const Value(4),
            riskAssessmentId: Value(raId),
          ));
      final json = await ExportRepo(sourceDb).buildJsonFull(appVersionOverride: '2.0.0');
      await sourceDb.close();

      await importRepo.importJson(json, ImportMode.replaceAll);

      final assessments = await db.select(db.riskAssessments).get();
      expect(assessments, hasLength(1));
      final attacks = await db.select(db.attacks).get();
      expect(attacks, hasLength(1));
      // The attack's riskAssessmentId must match the imported assessment's id.
      expect(attacks.first.riskAssessmentId, assessments.first.id);
    });

    test('v1 JSON imports only the four v1 tables and leaves v2 tables untouched',
        () async {
      // Pre-seed a risk assessment that must survive (absent from v1 file).
      await db.into(db.riskAssessments).insert(
            RiskAssessmentsCompanion.insert(
              targetDate: DateTime.utc(2026, 6, 1),
              horizon: 'today',
              score: 77,
              band: 'high',
              computedAt: DateTime.utc(2026, 6, 1, 6),
              configVersion: 1,
              contributorsJson: '[]',
            ),
            onConflict: DoNothing(),
          );

      final v1 = jsonEncode({
        'schema_version': 1,
        'app_version': '1.0.0',
        'exported_at': '2026-06-01T00:00:00.000Z',
        'attacks': [
          {
            'id': 1,
            'started_at': '2026-06-01T08:00:00.000Z',
            'ended_at': null,
            'severity': 2,
            'notes': null,
            'risk_assessment_id': null,
            'in_progress': false,
          }
        ],
        'journal_entries': [],
        'settings': [],
        'user_trigger_flags': [],
      });

      await importRepo.importJson(v1, ImportMode.replaceAll);

      final attacks = await db.select(db.attacks).get();
      expect(attacks, hasLength(1));
      expect(attacks.first.severity, 2);

      // Risk assessments were NOT in the v1 file, so must be untouched.
      final assessments = await db.select(db.riskAssessments).get();
      expect(assessments, hasLength(1));
      expect(assessments.first.score, 77);
    });

    test('replace-all does not wipe a table whose section is empty', () async {
      // Local attack must survive when the imported file has attacks: [].
      await db.into(db.attacks).insert(
            AttacksCompanion.insert(startedAt: DateTime.utc(2026, 1, 1), severity: 4),
          );

      final file = jsonEncode({
        'schema_version': 1,
        'app_version': '1.0.0',
        'exported_at': '2026-06-01T00:00:00.000Z',
        'attacks': [],
        'journal_entries': [],
        'settings': [
          {'key': 'unit_system', 'value': 'metric'}
        ],
        'user_trigger_flags': [],
      });

      await importRepo.importJson(file, ImportMode.replaceAll);

      final attacks = await db.select(db.attacks).get();
      expect(attacks, hasLength(1)); // empty section did not clear the table
      expect(attacks.first.severity, 4);
    });

    test('rejects schema_version 0', () {
      final bad = jsonEncode({'schema_version': 0, 'attacks': []});
      expect(
        () => importRepo.importJson(bad, ImportMode.replaceAll),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects schema_version 99', () {
      final bad = jsonEncode({'schema_version': 99, 'attacks': []});
      expect(
        () => importRepo.importJson(bad, ImportMode.replaceAll),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects malformed JSON', () {
      expect(
        () => importRepo.importJson('not json', ImportMode.replaceAll),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a top-level JSON array', () {
      expect(
        () => importRepo.importJson('[]', ImportMode.replaceAll),
        throwsA(isA<FormatException>()),
      );
    });
  });

  // ── JSON — merge ──────────────────────────────────────────────────────────

  group('importJson merge', () {
    test('existing attack survives when id collides (INSERT OR IGNORE)', () async {
      await db.into(db.attacks).insert(
            AttacksCompanion.insert(startedAt: DateTime.utc(2026, 6, 1, 8), severity: 5),
          );
      final existingId = (await db.select(db.attacks).get()).first.id;

      // A second DB exports the same id with a different severity.
      final sourceDb = AppDatabase.memory();
      await sourceDb.into(sourceDb.attacks).insert(AttacksCompanion(
            id: Value(existingId),
            startedAt: Value(DateTime.utc(2026, 6, 1, 8)),
            severity: const Value(9),
          ));
      final json =
          await ExportRepo(sourceDb).buildJsonFull(appVersionOverride: '2.0.0');
      await sourceDb.close();

      await importRepo.importJson(json, ImportMode.merge);

      final attacks = await db.select(db.attacks).get();
      expect(attacks, hasLength(1));
      expect(attacks.first.severity, 5); // local value kept
    });

    test('risk assessment is replaced on same (target_date, horizon)', () async {
      await db.into(db.riskAssessments).insert(
            RiskAssessmentsCompanion.insert(
              targetDate: DateTime.utc(2026, 6, 1),
              horizon: 'today',
              score: 10,
              band: 'low',
              computedAt: DateTime.utc(2026, 6, 1, 6),
              configVersion: 1,
              contributorsJson: '[]',
            ),
            onConflict: DoNothing(),
          );

      final incoming = jsonEncode({
        'schema_version': 2,
        'app_version': '2.0.0',
        'exported_at': '2026-06-23T00:00:00.000Z',
        'attacks': [],
        'journal_entries': [],
        'settings': [],
        'user_trigger_flags': [],
        'risk_assessments': [
          {
            'id': 999,
            'target_date': '2026-06-01T00:00:00.000Z',
            'horizon': 'today',
            'score': 75,
            'band': 'high',
            'computed_at': '2026-06-01T06:00:00.000Z',
            'config_version': 1,
            'contributors_json': '[]',
            'backfilled': false,
          }
        ],
        'periods': [],
        'period_day_severities': [],
        'manual_sleep_records': [],
        'day_location_overrides': [],
      });

      await importRepo.importJson(incoming, ImportMode.merge);

      final assessments = await db.select(db.riskAssessments).get();
      expect(assessments, hasLength(1));
      expect(assessments.first.score, 75); // incoming wins
    });

    test('settings key is replaced on merge', () async {
      await db.into(db.settings).insertOnConflictUpdate(
            SettingsCompanion.insert(key: 'unit_system', value: 'metric'),
          );

      final incoming = jsonEncode({
        'schema_version': 1,
        'app_version': '1.0.0',
        'exported_at': '2026-06-01T00:00:00.000Z',
        'attacks': [],
        'journal_entries': [],
        'settings': [
          {'key': 'unit_system', 'value': 'imperial'}
        ],
        'user_trigger_flags': [],
      });

      await importRepo.importJson(incoming, ImportMode.merge);

      final rows = await db.select(db.settings).get();
      expect(rows, hasLength(1));
      expect(rows.first.value, 'imperial');
    });

    test('merge returns total rows upserted', () async {
      final incoming = jsonEncode({
        'schema_version': 1,
        'app_version': '1.0.0',
        'exported_at': '2026-06-01T00:00:00.000Z',
        'attacks': [
          {
            'id': 1,
            'started_at': '2026-06-01T08:00:00.000Z',
            'ended_at': null,
            'severity': 3,
            'notes': null,
            'risk_assessment_id': null,
            'in_progress': false,
          },
          {
            'id': 2,
            'started_at': '2026-06-02T08:00:00.000Z',
            'ended_at': null,
            'severity': 2,
            'notes': null,
            'risk_assessment_id': null,
            'in_progress': false,
          },
        ],
        'journal_entries': [],
        'settings': [
          {'key': 'k', 'value': 'v'}
        ],
        'user_trigger_flags': [],
      });

      final count = await importRepo.importJson(incoming, ImportMode.merge);
      expect(count, 3); // 2 attacks + 1 setting
    });
  });

  // ── CSV ZIP ───────────────────────────────────────────────────────────────

  group('importCsvZip', () {
    test('round-trips attacks through CSV ZIP replace-all', () async {
      await db.into(db.attacks).insert(AttacksCompanion.insert(
            startedAt: DateTime.utc(2026, 6, 1, 8),
            severity: 3,
          ));
      final zipBytes = await exportRepo.buildCsvZipBytes();

      await db.delete(db.attacks).go();
      final count = await importRepo.importCsvZip(zipBytes, ImportMode.replaceAll);

      expect(count, greaterThan(0));
      final attacks = await db.select(db.attacks).get();
      expect(attacks, hasLength(1));
      expect(attacks.first.severity, 3);
      expect(attacks.first.startedAt.toUtc().toIso8601String(),
          '2026-06-01T08:00:00.000Z');
    });

    test('round-trips journal entries through CSV ZIP', () async {
      await db.into(db.journalEntries).insert(JournalEntriesCompanion.insert(
            at: DateTime.utc(2026, 6, 1, 9),
            kind: 'caffeine',
            payloadJson: '{"cups":2}',
          ));
      final zipBytes = await exportRepo.buildCsvZipBytes();
      await db.delete(db.journalEntries).go();

      await importRepo.importCsvZip(zipBytes, ImportMode.replaceAll);

      final entries = await db.select(db.journalEntries).get();
      expect(entries, hasLength(1));
      expect(entries.first.kind, 'caffeine');
      expect(entries.first.payloadJson, '{"cups":2}');
    });

    test('round-trips risk assessments with expanded trigger columns', () async {
      await db.into(db.riskAssessments).insert(
            RiskAssessmentsCompanion.insert(
              targetDate: DateTime.utc(2026, 6, 1),
              horizon: 'today',
              score: 55,
              band: 'moderate',
              computedAt: DateTime.utc(2026, 6, 1, 6),
              configVersion: 1,
              contributorsJson:
                  '[{"moduleId":"pressure_drop","weight":0.8,"confidence":0.9,"explanation":"Dropped 5 hPa"}]',
            ),
            onConflict: DoNothing(),
          );
      final zipBytes = await exportRepo.buildCsvZipBytes();
      await db.delete(db.riskAssessments).go();

      await importRepo.importCsvZip(zipBytes, ImportMode.replaceAll);

      final assessments = await db.select(db.riskAssessments).get();
      expect(assessments, hasLength(1));
      expect(assessments.first.score, 55);
      expect(assessments.first.contributorsJson, contains('pressure_drop'));
      // weight = 0.8 * 0.9 = 0.72 (contribution), confidence reconstructed as 1.0
      expect(assessments.first.contributorsJson, contains('"weight":0.72'));
      expect(assessments.first.contributorsJson, contains('"confidence":1.0'));
    });

    test('merge skips existing attacks by id', () async {
      await db.into(db.attacks).insert(AttacksCompanion.insert(
            startedAt: DateTime.utc(2026, 6, 1, 8),
            severity: 7,
          ));
      final zipBytes = await exportRepo.buildCsvZipBytes();

      // Change local severity after capturing the ZIP.
      final existingId = (await db.select(db.attacks).get()).first.id;
      await (db.update(db.attacks)..where((t) => t.id.equals(existingId)))
          .write(const AttacksCompanion(severity: Value(2)));

      await importRepo.importCsvZip(zipBytes, ImportMode.merge);

      final attacks = await db.select(db.attacks).get();
      expect(attacks, hasLength(1));
      expect(attacks.first.severity, 2); // local change kept via INSERT OR IGNORE
    });

    test('payload_json with commas is preserved after round-trip', () async {
      const payload = '{"note":"coffee, then headache"}';
      await db.into(db.journalEntries).insert(JournalEntriesCompanion.insert(
            at: DateTime.utc(2026, 6, 1, 9),
            kind: 'stress',
            payloadJson: payload,
          ));
      final zipBytes = await exportRepo.buildCsvZipBytes();
      await db.delete(db.journalEntries).go();

      await importRepo.importCsvZip(zipBytes, ImportMode.replaceAll);

      final entries = await db.select(db.journalEntries).get();
      expect(entries.first.payloadJson, payload);
    });

    test('throws FormatException for invalid ZIP bytes', () {
      expect(
        () => importRepo.importCsvZip(
            Uint8List.fromList([1, 2, 3]), ImportMode.replaceAll),
        throwsA(isA<FormatException>()),
      );
    });

    test('unknown files inside ZIP are ignored without error', () async {
      // Build a ZIP that contains an extra unexpected file.
      final validZip = await exportRepo.buildCsvZipBytes();
      final archive = ZipDecoder().decodeBytes(validZip);
      archive.addFile(ArchiveFile('extra.txt', 5, [104, 101, 108, 108, 111]));
      final withExtra = Uint8List.fromList(ZipEncoder().encode(archive)!);

      await expectLater(
        importRepo.importCsvZip(withExtra, ImportMode.replaceAll),
        completes,
      );
    });

    test('header-only attacks.csv does not wipe existing local attacks', () async {
      // Seed a local attack.
      await db.into(db.attacks).insert(AttacksCompanion.insert(
            startedAt: DateTime.utc(2026, 6, 1, 8),
            severity: 5,
          ));

      // Build a ZIP from a separate source DB that has NO attacks — so
      // attacks.csv will be header-only.
      final sourceDb = AppDatabase.memory();
      final zipBytes = await ExportRepo(sourceDb).buildCsvZipBytes();
      await sourceDb.close();

      await importRepo.importCsvZip(zipBytes, ImportMode.replaceAll);

      // The local attack must still exist — header-only section is a no-op.
      final attacks = await db.select(db.attacks).get();
      expect(attacks, hasLength(1));
      expect(attacks.first.severity, 5);
    });

    test('throws FormatException when attacks.csv is missing a required column', () {
      final badCsv = utf8.encode('id,severity,in_progress\n1,3,false\n');
      final archive = Archive()
        ..addFile(ArchiveFile('attacks.csv', badCsv.length, badCsv));
      final badZip = Uint8List.fromList(ZipEncoder().encode(archive)!);

      expect(
        () => importRepo.importCsvZip(badZip, ImportMode.replaceAll),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

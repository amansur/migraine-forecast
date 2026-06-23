# Data Portability (Export & Import) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add JSON and CSV import (replace-all and merge modes) and replace the inaccessible "Save to Documents" export with an OS share sheet that offers both JSON (full v2 backup) and CSV ZIP formats.

**Architecture:** A new `ImportRepo` mirrors the shape of the existing `ExportRepo`, performing all import work inside a single Drift transaction so any failure rolls back atomically. The settings "Export Data" dialog gains a JSON/CSV format picker and a Share action backed by `share_plus`; a new "Import Data" row opens `file_picker`, detects format by extension, prompts for a conflict mode, and delegates to `ImportRepo`.

**Tech Stack:** Flutter, Drift (SQLite), `share_plus ^10.0.0`, `file_picker ^8.0.0`, `archive ^3.6.0`, `csv ^6.0.0`, `path_provider ^2.1.0`

## Global Constraints

- All packages are already in `pubspec.yaml` — do NOT run `flutter pub add`.
- `ExportRepo.buildJsonFull()` (schema_version 2) and `ExportRepo.buildCsvZipBytes()` are already implemented in `lib/data/repos/export_repo.dart` — do NOT touch that file.
- `ExportRepo.buildJson()` (v1) is retained for existing tests; new export UI uses `buildJsonFull()`.
- All DateTime values are serialised as UTC ISO 8601 strings ending in `Z`; parse on import with `DateTime.parse(...).toUtc()`.
- All import operations are wrapped in a single `_db.transaction()`; any failure rolls back the entire import.
- A table section that is **absent OR an empty array** is skipped entirely. In replace-all this means an empty/absent section does NOT wipe the corresponding local table — only tables with at least one row in the file are cleared and replaced. (Matches spec: "replace-all only clears tables that are present in the file.")
- Merge insert modes per table:
  - `attacks`, `journal_entries`, `periods`, `period_day_severities`, `manual_sleep_records`, `day_location_overrides` → `InsertMode.insertOrIgnore` (existing local record always wins).
  - `risk_assessments`, `settings`, `user_trigger_flags` → `InsertMode.insertOrReplace` (incoming wins on the unique/primary key).
- `WeatherSnapshots` and `BaselinesKv` are excluded from all import/export.
- `ArchiveFile` constructor signature in `archive ^3.6.x`: `ArchiveFile(String name, int size, List<int> content)` — there is no `.bytes` factory.
- Drift batch insert: `_db.batch((b) => b.insertAll(table, companions, mode: InsertMode.xxx))`.
- The `user_trigger_flags` Drift accessor is `_db.userTriggerFlagsTbl`; its companion is `UserTriggerFlagsTblCompanion` and its data class is `UserTriggerFlagsTblData`.
- Known trigger module order (must match `ExportRepo._knownModules`): `pressure_drop, humidity, temp_swing, air_quality, stress, sleep_deficit, alcohol, caffeine, hydration, menstrual_phase`.
- Test pattern: `AppDatabase.memory()` for an in-memory DB; hide Drift data-class conflicts with `hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment`.
- `SettingsScreen` is a `ConsumerWidget` (NOT stateful) — screen-level helpers are instance methods with signature `(BuildContext context, WidgetRef ref)`, alongside the existing `_showExportDialog`. `_ExportDataDialog` is a separate `StatefulWidget`.

---

### Task 1: `ImportRepo` — JSON import

**Files:**
- Create: `lib/data/repos/import_repo.dart`
- Create: `test/data/repos/import_repo_test.dart`
- Modify: `lib/state/providers.dart`

**Interfaces:**
- Consumes: `AppDatabase` (from `lib/data/database.dart`), `databaseProvider` (from `lib/state/providers.dart`), `ExportRepo.buildJsonFull({String? appVersionOverride})` (from `lib/data/repos/export_repo.dart`).
- Produces:
  - `enum ImportMode { replaceAll, merge }`
  - `class ImportRepo { ImportRepo(AppDatabase db); }`
  - `Future<int> importJson(String jsonStr, ImportMode mode)` — returns total rows inserted/upserted; throws `FormatException` on malformed JSON or unsupported `schema_version`.
  - `final importRepoProvider = Provider<ImportRepo>((ref) => ImportRepo(ref.watch(databaseProvider)));`

- [ ] **Step 1: Write failing tests**

Create `test/data/repos/import_repo_test.dart`:

```dart
import 'dart:convert';

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
}
```

- [ ] **Step 2: Run to confirm failure**

Run: `flutter test test/data/repos/import_repo_test.dart`
Expected: FAIL — `Target of URI doesn't exist 'package:migraine_forecast/data/repos/import_repo.dart'`

- [ ] **Step 3: Create `lib/data/repos/import_repo.dart`**

```dart
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
```

- [ ] **Step 4: Add `importRepoProvider` to `lib/state/providers.dart`**

Add this import alongside the other repo imports (after the `export_repo.dart` import on line 9):

```dart
import '../data/repos/import_repo.dart';
```

Add this line directly after `exportRepoProvider` (currently line 103):

```dart
final importRepoProvider = Provider<ImportRepo>((ref) => ImportRepo(ref.watch(databaseProvider)));
```

- [ ] **Step 5: Run tests**

Run: `flutter test test/data/repos/import_repo_test.dart`
Expected: PASS — all tests green

- [ ] **Step 6: Commit**

```bash
git add lib/data/repos/import_repo.dart lib/state/providers.dart test/data/repos/import_repo_test.dart
git commit -m "feat(import): ImportRepo — JSON import with replace-all and merge modes"
```

---

### Task 2: `ImportRepo` — CSV ZIP import

**Files:**
- Modify: `lib/data/repos/import_repo.dart`
- Modify: `test/data/repos/import_repo_test.dart`

**Interfaces:**
- Consumes: `ExportRepo.buildCsvZipBytes()` (returns `Future<Uint8List>`), `archive ^3.6.x`, `csv ^6.0.0`.
- Produces: `Future<int> importCsvZip(Uint8List zipBytes, ImportMode mode)` — returns total rows inserted/upserted; throws `FormatException` for an unreadable ZIP or a CSV missing required columns.

**CSV escaping note:** `ExportRepo` quotes any cell containing `,` or `"` and replaces real newlines with the two-character sequence `\n`. Import reverses only the newline escaping (`\n` → newline) via `_cell`; the `csv` package handles unquoting.

- [ ] **Step 1: Write failing tests**

At the top of `test/data/repos/import_repo_test.dart`, add imports:

```dart
import 'dart:typed_data';

import 'package:archive/archive.dart';
```

Add this new group after the existing `importJson` groups (before the final closing `}` of `main`):

```dart
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
  });
```

- [ ] **Step 2: Run to confirm failure**

Run: `flutter test test/data/repos/import_repo_test.dart --name "importCsvZip"`
Expected: FAIL — `The method 'importCsvZip' isn't defined`

- [ ] **Step 3: Add CSV imports and `importCsvZip` to `lib/data/repos/import_repo.dart`**

Add these imports at the top of the file (after the `package:drift/drift.dart` import):

```dart
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
```

Add these members inside `ImportRepo`, below `_importDayLocationOverrides`:

```dart
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
    if (rows.isEmpty) return 0;
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
    if (rows.isEmpty) return 0;
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
    if (rows.isEmpty) return 0;
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
```

- [ ] **Step 4: Run all import tests**

Run: `flutter test test/data/repos/import_repo_test.dart`
Expected: PASS — all tests green

- [ ] **Step 5: Run the full suite to check for regressions**

Run: `flutter test`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/data/repos/import_repo.dart test/data/repos/import_repo_test.dart
git commit -m "feat(import): CSV ZIP import with replace-all and merge modes"
```

---

### Task 3: Export UI redesign — format picker + share sheet

**Files:**
- Modify: `lib/ui/settings/settings_screen.dart`

**Interfaces:**
- Consumes: `exportRepoProvider` (imported via `../../state/providers.dart`), `ExportRepo.buildJsonFull()`, `ExportRepo.buildCsvZipBytes()`, `share_plus`.
- Produces: updated "Export Data" `ListTile` and a redesigned `_ExportDataDialog` with a JSON/CSV format radio and a Share action.

**Context:** The current `_ExportDataDialog` (lines 471–533) calls `buildJson()` and offers "Copy to Clipboard" and "Save to Documents". It is replaced entirely. The `_showExportDialog` helper (line 320) is unchanged.

- [ ] **Step 1: Add missing imports to `settings_screen.dart`**

After the existing `import 'dart:io';` (line 1), add:

```dart
import 'dart:typed_data';
```

After the `import 'package:path_provider/path_provider.dart';` line (line 9), add:

```dart
import 'package:share_plus/share_plus.dart';
```

- [ ] **Step 2: Update the Export Data `ListTile`**

Find (lines 252–257):

```dart
          ListTile(
            title: const Text('Export JSON Data'),
            subtitle: const Text('Copy or save your attacks, journal entries, and settings.'),
            trailing: const Icon(Icons.download_outlined),
            onTap: () => _showExportDialog(context, ref),
          ),
```

Replace with:

```dart
          ListTile(
            title: const Text('Export Data'),
            subtitle: const Text('Share your attacks, journal entries, risk history, and settings as JSON or CSV.'),
            trailing: const Icon(Icons.download_outlined),
            onTap: () => _showExportDialog(context, ref),
          ),
```

- [ ] **Step 3: Replace the entire `_ExportDataDialog` class**

Find the whole class block (lines 471–533) starting at `class _ExportDataDialog extends StatefulWidget {` and ending at its final closing `}`. Replace it with:

```dart
enum _ExportFormat { json, csv }

class _ExportDataDialog extends StatefulWidget {
  final WidgetRef ref;
  const _ExportDataDialog({required this.ref});

  @override
  State<_ExportDataDialog> createState() => _ExportDataDialogState();
}

class _ExportDataDialogState extends State<_ExportDataDialog> {
  bool _loading = false;
  _ExportFormat _format = _ExportFormat.json;

  Future<void> _copyToClipboard() async {
    setState(() => _loading = true);
    try {
      final json = await widget.ref.read(exportRepoProvider).buildJsonFull();
      await Clipboard.setData(ClipboardData(text: json));
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _share() async {
    setState(() => _loading = true);
    try {
      final dir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final XFile xfile;

      if (_format == _ExportFormat.json) {
        final json = await widget.ref.read(exportRepoProvider).buildJsonFull();
        final path = '${dir.path}/migraine_forecast_export_$dateStr.json';
        await File(path).writeAsString(json);
        xfile = XFile(path, mimeType: 'application/json');
      } else {
        final Uint8List zipBytes =
            await widget.ref.read(exportRepoProvider).buildCsvZipBytes();
        final path = '${dir.path}/migraine_forecast_export_$dateStr.zip';
        await File(path).writeAsBytes(zipBytes);
        xfile = XFile(path, mimeType: 'application/zip');
      }

      await Share.shareXFiles([xfile], subject: 'Migraine Forecast Export');
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Data'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              'Includes attacks, journal entries, risk history, and settings.'),
          const SizedBox(height: 12),
          RadioListTile<_ExportFormat>(
            title: const Text('JSON (full backup, importable)'),
            value: _ExportFormat.json,
            groupValue: _format,
            onChanged: _loading ? null : (v) => setState(() => _format = v!),
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<_ExportFormat>(
            title: const Text('CSV (3-file ZIP, opens in spreadsheets)'),
            value: _ExportFormat.csv,
            groupValue: _format,
            onChanged: _loading ? null : (v) => setState(() => _format = v!),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      actions: _loading
          ? [
              const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator())
            ]
          : [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              TextButton(
                onPressed:
                    _format == _ExportFormat.json ? _copyToClipboard : null,
                child: const Text('Copy to Clipboard'),
              ),
              FilledButton(onPressed: _share, child: const Text('Share')),
            ],
    );
  }
}
```

- [ ] **Step 4: Analyze**

Run: `flutter analyze lib/ui/settings/settings_screen.dart`
Expected: No errors. (`getApplicationDocumentsDirectory` is no longer used, but `getTemporaryDirectory` keeps the `path_provider` import in use, so the import stays.)

- [ ] **Step 5: Commit**

```bash
git add lib/ui/settings/settings_screen.dart
git commit -m "feat(export): revamp dialog — JSON/CSV format picker and share sheet via share_plus"
```

---

### Task 4: Import UI — file picker, conflict dialog, restore

**Files:**
- Modify: `lib/ui/settings/settings_screen.dart`

**Interfaces:**
- Consumes: `importRepoProvider`, `ImportRepo.importJson()`, `ImportRepo.importCsvZip()`, `ImportMode`, `file_picker`.
- Produces: an "Import Data" `ListTile` and an `_importData(BuildContext, WidgetRef)` instance method on `SettingsScreen` (a `ConsumerWidget`), placed right after the existing `_showExportDialog`.

- [ ] **Step 1: Add imports to `settings_screen.dart`**

After the `import 'package:share_plus/share_plus.dart';` line (added in Task 3), add:

```dart
import 'package:file_picker/file_picker.dart';
```

In the local import block (the `import '../../...'` group), add:

```dart
import '../../data/repos/import_repo.dart';
```

- [ ] **Step 2: Add the Import Data `ListTile`**

Find the Export Data tile followed directly by the `Consumer(builder: (context, ref, _) {` for "Rebuild risk history". Insert the Import tile between them so the section reads:

```dart
          ListTile(
            title: const Text('Export Data'),
            subtitle: const Text('Share your attacks, journal entries, risk history, and settings as JSON or CSV.'),
            trailing: const Icon(Icons.download_outlined),
            onTap: () => _showExportDialog(context, ref),
          ),
          ListTile(
            title: const Text('Import Data'),
            subtitle: const Text('Restore from a previous JSON or CSV export.'),
            trailing: const Icon(Icons.upload_outlined),
            onTap: () => _importData(context, ref),
          ),
          Consumer(builder: (context, ref, _) {
```

- [ ] **Step 3: Add the `_importData` method**

Locate the existing `_showExportDialog` method (line 320) on `SettingsScreen` and add `_importData` directly after it:

```dart
  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    // 1. Pick a file. FileType.any because MIME/UTI extension filtering is
    //    unreliable on Android/iOS; we validate the extension below.
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.isEmpty) return; // user cancelled

    final path = result.files.first.path;
    if (path == null) return;

    final ext = path.toLowerCase().split('.').last;
    if (ext != 'json' && ext != 'zip') {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Unsupported File'),
          content: const Text(
              'Please select a .json or .zip file exported from Migraine Forecast.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    // 2. Ask how to handle conflicts.
    if (!context.mounted) return;
    final mode = await showDialog<ImportMode>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('How should we handle conflicts?'),
        content: const Text(
          'Replace all: wipe existing data for the imported tables and restore '
          'from file.\n\n'
          'Merge: keep existing records; only import records not already present.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ImportMode.replaceAll),
              child: const Text('Replace All')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ImportMode.merge),
              child: const Text('Merge')),
        ],
      ),
    );
    if (mode == null) return; // user cancelled conflict dialog

    // 3. Import and report.
    try {
      final importRepo = ref.read(importRepoProvider);
      final int count;
      if (ext == 'json') {
        final jsonStr = await File(path).readAsString();
        count = await importRepo.importJson(jsonStr, mode);
      } else {
        final zipBytes = await File(path).readAsBytes();
        count = await importRepo.importCsvZip(zipBytes, mode);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported $count records')),
        );
      }
    } on FormatException catch (e) {
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Import Failed'),
            content: Text(e.message),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK')),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Import Failed'),
            content: Text(
                'An unexpected error occurred. Please try again.\n\n$e'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK')),
            ],
          ),
        );
      }
    }
  }
```

- [ ] **Step 4: Analyze**

Run: `flutter analyze lib/ui/settings/settings_screen.dart lib/data/repos/import_repo.dart lib/state/providers.dart`
Expected: No errors

- [ ] **Step 5: Run the full suite**

Run: `flutter test`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/ui/settings/settings_screen.dart
git commit -m "feat(import): Import Data row — file picker, conflict dialog, JSON and CSV ZIP restore"
```

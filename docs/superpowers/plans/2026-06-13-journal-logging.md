# Journal Logging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users log alcohol, caffeine, hydration, stress, and (gated) manual sleep — with view/edit/delete via a history screen.

**Architecture:** Domain `JournalEntry` gains a nullable `id`. The drift `JournalEntries` table gets update/delete/watch support. A new `manual_sleep_records` drift table backs a `ManualSleepSource`; a `MergedHealthSource` folds manual sleep into the existing `HealthSource` when the OS source lacks a given night. UI: a FAB on Today opens a picker sheet → kind-specific add/edit sheets → and a history screen with swipe-delete + undo.

**Tech Stack:** Flutter, Riverpod, drift, go_router, intl. Tests use `flutter_test` + `drift/native.dart` (in-memory drift).

**Spec:** `docs/superpowers/specs/2026-06-13-journal-logging-design.md`

---

## File Structure

**Domain (`packages/domain/`):**
- Modify: `lib/src/types/journal.dart` — add nullable `id` to `JournalEntry`.

**App data layer (`lib/data/`):**
- Modify: `database.dart` — add `ManualSleepRecords` table, bump `schemaVersion` to 5, add migration.
- Regenerated: `database.g.dart` — via `dart run build_runner build`.
- Modify: `sources/journal_source.dart` — add `updateEntry`, `deleteEntry`, `watchRecentEntries`.
- Modify: `sources/drift_journal_source.dart` — implement the three new methods; surface row id.
- Create: `sources/manual_sleep_source.dart` — abstract + drift impl in same file.
- Create: `sources/merged_health_source.dart` — wraps a `HealthSource` + `ManualSleepSource`.

**State (`lib/state/`):**
- Create: `journal_entries_provider.dart` — `StreamProvider<List<JournalEntry>>` over last 30d.
- Create: `manual_sleep_provider.dart` — source provider + `manualSleepEnabledProvider`.
- Modify: `providers.dart` — switch `healthSourceProvider` to `MergedHealthSource`; expose `manualSleepSourceProvider`.

**UI (`lib/ui/log/`):**
- Create: `log_picker_sheet.dart` — bottom sheet listing the 5 kinds + history link.
- Create: `journal_entry_sheet.dart` — shared add/edit sheet for alcohol/caffeine/hydration/stress.
- Create: `sleep_entry_sheet.dart` — sleep-specific add/edit sheet.
- Create: `log_history_screen.dart` — list with edit/delete.

**Routing & entry (`lib/app/`, `lib/ui/today/`):**
- Modify: `app/router.dart` — add `/log-history` route.
- Modify: `ui/today/today_screen.dart` — add a FAB that opens the picker sheet.

**Tests:**
- `packages/domain/test/types/journal_entry_id_test.dart`
- `test/data/drift_journal_source_test.dart` (extend or add)
- `test/data/manual_sleep_source_test.dart`
- `test/data/merged_health_source_test.dart`
- `test/data/database_migration_test.dart` (extend or add)
- `test/ui/log/journal_entry_sheet_test.dart`
- `test/ui/log/sleep_entry_sheet_test.dart`
- `test/ui/log/log_picker_sheet_test.dart`
- `test/ui/log/log_history_screen_test.dart`

---

## Task 1: Domain — add nullable `id` to `JournalEntry`

**Files:**
- Modify: `packages/domain/lib/src/types/journal.dart`
- Test: `packages/domain/test/types/journal_entry_id_test.dart`

- [ ] **Step 1: Write the failing test**

Create `packages/domain/test/types/journal_entry_id_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('JournalEntry.id', () {
    test('defaults to null and is omitted from equality contributions when null', () {
      final a = JournalEntry(
        at: DateTime.utc(2026, 6, 13, 10),
        kind: JournalKind.alcohol,
        payload: const {'units': 2.0},
      );
      final b = JournalEntry(
        at: DateTime.utc(2026, 6, 13, 10),
        kind: JournalKind.alcohol,
        payload: const {'units': 2.0},
      );
      expect(a.id, isNull);
      expect(a, equals(b));
    });

    test('different ids make entries unequal', () {
      final a = JournalEntry(
        id: 1,
        at: DateTime.utc(2026, 6, 13, 10),
        kind: JournalKind.alcohol,
        payload: const {'units': 2.0},
      );
      final b = JournalEntry(
        id: 2,
        at: DateTime.utc(2026, 6, 13, 10),
        kind: JournalKind.alcohol,
        payload: const {'units': 2.0},
      );
      expect(a, isNot(equals(b)));
    });
  });
}
```

- [ ] **Step 2: Run the test and verify it fails**

Run from `packages/domain`:
```
dart test test/types/journal_entry_id_test.dart
```
Expected: compilation error — `id` not defined.

- [ ] **Step 3: Add the nullable `id` field**

In `packages/domain/lib/src/types/journal.dart`, replace the `JournalEntry` class:

```dart
class JournalEntry extends Equatable {
  final int? id;
  final DateTime at;
  final JournalKind kind;
  /// Free-form payload. By convention:
  /// - alcohol: {"units": double}
  /// - caffeine: {"mg": double}
  /// - stress: {"rating": int 1..5}
  /// - hydration: {"liters": double}
  final Map<String, Object?> payload;
  const JournalEntry({
    this.id,
    required this.at,
    required this.kind,
    required this.payload,
  });
  @override
  List<Object?> get props => [id, at, kind, payload];
}
```

- [ ] **Step 4: Run the test and verify it passes**

```
dart test test/types/journal_entry_id_test.dart
```
Expected: PASS, 2 tests.

- [ ] **Step 5: Run the full domain test suite to confirm no regressions**

```
dart test
```
Expected: PASS. All existing tests still pass because `id` defaults to `null` and constructors are named.

- [ ] **Step 6: Commit**

```bash
git add packages/domain/lib/src/types/journal.dart packages/domain/test/types/journal_entry_id_test.dart
git commit -m "feat(domain): add nullable id to JournalEntry for UI edit/delete identity"
```

---

## Task 2: Drift schema — add `manual_sleep_records` table + migration v4→v5

**Files:**
- Modify: `lib/data/database.dart`
- Regen: `lib/data/database.g.dart` (via build_runner)
- Test: `test/data/database_migration_test.dart`

- [ ] **Step 1: Add the table and bump schemaVersion**

In `lib/data/database.dart`, add the table near the other `Table` classes:

```dart
class ManualSleepRecords extends Table {
  // UTC midnight of the night the sleep belongs to.
  DateTimeColumn get night => dateTime()();
  DateTimeColumn get sleepStart => dateTime()();
  IntColumn get totalSleepMinutes => integer()();
  RealColumn get efficiency => real().nullable()();
  @override
  Set<Column> get primaryKey => {night};
}
```

Then update the `@DriftDatabase(tables: [...])` annotation to include `ManualSleepRecords`. Bump `schemaVersion` from `4` to `5` and extend the migration:

```dart
@override
int get schemaVersion => 5;

@override
MigrationStrategy get migration => MigrationStrategy(
      onCreate: (m) async => m.createAll(),
      onUpgrade: (m, from, to) async {
        if (from < 2) await m.createTable(notificationsSent);
        if (from < 3) {
          await m.addColumn(attacks, attacks.inProgress);
          await m.addColumn(riskAssessments, riskAssessments.backfilled);
        }
        if (from < 4) {
          await m.createTable(periods);
          await m.createTable(periodDaySeverities);
        }
        if (from < 5) {
          await m.createTable(manualSleepRecords);
        }
      },
    );
```

- [ ] **Step 2: Regenerate drift code**

```
dart run build_runner build --delete-conflicting-outputs
```
Expected: `database.g.dart` updates without errors.

- [ ] **Step 3: Write the migration test**

Add to `test/data/database_migration_test.dart` (create if missing):

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/database.dart';

void main() {
  test('schemaVersion is 5 and manual_sleep_records exists on fresh DB', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 5);
    // Insert a row to prove the table exists.
    await db.into(db.manualSleepRecords).insert(
          ManualSleepRecordsCompanion.insert(
            night: DateTime.utc(2026, 6, 12),
            sleepStart: DateTime.utc(2026, 6, 12, 22, 30),
            totalSleepMinutes: 7 * 60 + 15,
          ),
        );
    final rows = await db.select(db.manualSleepRecords).get();
    expect(rows, hasLength(1));
    expect(rows.single.efficiency, isNull);
  });
}
```

- [ ] **Step 4: Run the test and verify it passes**

```
flutter test test/data/database_migration_test.dart
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/database.dart lib/data/database.g.dart test/data/database_migration_test.dart
git commit -m "feat(data): add manual_sleep_records table (schema v5)"
```

---

## Task 3: Extend `JournalSource` interface

**Files:**
- Modify: `lib/data/sources/journal_source.dart`

- [ ] **Step 1: Add the three new abstract methods**

In `lib/data/sources/journal_source.dart`, inside `abstract class JournalSource`, add after `addEntry`:

```dart
  Future<void> updateEntry(JournalEntry entry); // requires entry.id != null
  Future<void> deleteEntry(int id);
  Stream<List<JournalEntry>> watchRecentEntries(Duration window, {required DateTime now});
```

(This will break compilation of `DriftJournalSource` until Task 4 lands. Don't commit yet — combine with Task 4.)

---

## Task 4: Implement `updateEntry`, `deleteEntry`, `watchRecentEntries` in `DriftJournalSource`

**Files:**
- Modify: `lib/data/sources/drift_journal_source.dart`
- Test: `test/data/drift_journal_source_test.dart`

- [ ] **Step 1: Write the failing tests**

Create or extend `test/data/drift_journal_source_test.dart`:

```dart
import 'package:domain/domain.dart' as domain;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/database.dart';
import 'package:migraine_weatherr/data/sources/drift_journal_source.dart';

void main() {
  late AppDatabase db;
  late DriftJournalSource source;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    source = DriftJournalSource(db);
  });
  tearDown(() => db.close());

  test('addEntry then recentEntries returns row with id', () async {
    final now = DateTime.utc(2026, 6, 13, 12);
    await source.addEntry(domain.JournalEntry(
      at: now.subtract(const Duration(hours: 1)),
      kind: domain.JournalKind.alcohol,
      payload: const {'units': 2.0},
    ));
    final entries = await source.recentEntries(const Duration(days: 1), now: now);
    expect(entries, hasLength(1));
    expect(entries.single.id, isNotNull);
    expect(entries.single.kind, domain.JournalKind.alcohol);
  });

  test('updateEntry persists changes to payload and at', () async {
    final now = DateTime.utc(2026, 6, 13, 12);
    await source.addEntry(domain.JournalEntry(
      at: now.subtract(const Duration(hours: 2)),
      kind: domain.JournalKind.caffeine,
      payload: const {'mg': 95.0},
    ));
    final entry = (await source.recentEntries(const Duration(days: 1), now: now)).single;
    final updated = domain.JournalEntry(
      id: entry.id,
      at: now.subtract(const Duration(hours: 1)),
      kind: domain.JournalKind.caffeine,
      payload: const {'mg': 190.0},
    );
    await source.updateEntry(updated);
    final after = await source.recentEntries(const Duration(days: 1), now: now);
    expect(after.single.payload['mg'], 190.0);
    expect(after.single.at, now.subtract(const Duration(hours: 1)));
  });

  test('updateEntry without id throws', () async {
    expect(
      () => source.updateEntry(domain.JournalEntry(
        at: DateTime.utc(2026, 6, 13),
        kind: domain.JournalKind.stress,
        payload: const {'rating': 3},
      )),
      throwsArgumentError,
    );
  });

  test('deleteEntry removes the row', () async {
    final now = DateTime.utc(2026, 6, 13, 12);
    await source.addEntry(domain.JournalEntry(
      at: now.subtract(const Duration(hours: 1)),
      kind: domain.JournalKind.hydration,
      payload: const {'liters': 0.5},
    ));
    final id = (await source.recentEntries(const Duration(days: 1), now: now)).single.id!;
    await source.deleteEntry(id);
    expect(await source.recentEntries(const Duration(days: 1), now: now), isEmpty);
  });

  test('watchRecentEntries emits when an entry is added', () async {
    final now = DateTime.utc(2026, 6, 13, 12);
    final stream = source.watchRecentEntries(const Duration(days: 1), now: now);
    final emissions = <int>[];
    final sub = stream.listen((list) => emissions.add(list.length));
    await source.addEntry(domain.JournalEntry(
      at: now.subtract(const Duration(hours: 1)),
      kind: domain.JournalKind.stress,
      payload: const {'rating': 4},
    ));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();
    expect(emissions, contains(1));
  });
}
```

- [ ] **Step 2: Run tests — verify they fail**

```
flutter test test/data/drift_journal_source_test.dart
```
Expected: FAIL — methods undefined.

- [ ] **Step 3: Implement the three methods + surface id**

In `lib/data/sources/drift_journal_source.dart`:

Replace `recentEntries` mapping so it returns `id`:

```dart
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
```

The existing `addEntry` does not need changes — drift assigns the autoincrement id at insert.

- [ ] **Step 4: Run the tests — verify all pass**

```
flutter test test/data/drift_journal_source_test.dart
```
Expected: PASS, 5 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/data/sources/journal_source.dart lib/data/sources/drift_journal_source.dart test/data/drift_journal_source_test.dart
git commit -m "feat(data): support update/delete/watch on JournalSource and surface row id"
```

---

## Task 5: `ManualSleepSource`

**Files:**
- Create: `lib/data/sources/manual_sleep_source.dart`
- Test: `test/data/manual_sleep_source_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/data/manual_sleep_source_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/database.dart';
import 'package:migraine_weatherr/data/sources/manual_sleep_source.dart';

void main() {
  late AppDatabase db;
  late DriftManualSleepSource source;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    source = DriftManualSleepSource(db);
  });
  tearDown(() => db.close());

  SleepRecord recordFor(DateTime night, {int hours = 7}) => SleepRecord(
        night: night,
        totalSleep: Duration(hours: hours),
        efficiency: 1.0,
        sleepStart: night.add(const Duration(hours: 22)),
      );

  test('upsert then recent returns the record', () async {
    final night = DateTime.utc(2026, 6, 12);
    await source.upsert(recordFor(night));
    final got = await source.recent(const Duration(days: 7), now: DateTime.utc(2026, 6, 13));
    expect(got, hasLength(1));
    expect(got.single.night, night);
    expect(got.single.totalSleep, const Duration(hours: 7));
  });

  test('upsert on existing night overwrites', () async {
    final night = DateTime.utc(2026, 6, 12);
    await source.upsert(recordFor(night, hours: 6));
    await source.upsert(recordFor(night, hours: 8));
    final got = await source.recent(const Duration(days: 7), now: DateTime.utc(2026, 6, 13));
    expect(got, hasLength(1));
    expect(got.single.totalSleep, const Duration(hours: 8));
  });

  test('delete by night removes the row', () async {
    final night = DateTime.utc(2026, 6, 12);
    await source.upsert(recordFor(night));
    await source.delete(night);
    expect(
      await source.recent(const Duration(days: 7), now: DateTime.utc(2026, 6, 13)),
      isEmpty,
    );
  });

  test('watchRecent emits on upsert', () async {
    final emissions = <int>[];
    final sub = source
        .watchRecent(const Duration(days: 7), now: DateTime.utc(2026, 6, 13))
        .listen((l) => emissions.add(l.length));
    await source.upsert(recordFor(DateTime.utc(2026, 6, 12)));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();
    expect(emissions, contains(1));
  });

  test('null efficiency round-trips', () async {
    final night = DateTime.utc(2026, 6, 12);
    await source.upsert(SleepRecord(
      night: night,
      totalSleep: const Duration(hours: 7),
      efficiency: 0.0, // sentinel: source stores null, returns 1.0 by default
      sleepStart: night.add(const Duration(hours: 22)),
    ));
    final got = (await source.recent(const Duration(days: 7), now: DateTime.utc(2026, 6, 13))).single;
    // Engine consumes totalSleep + sleepStart; efficiency comes back as 1.0 (default) when stored null.
    expect(got.efficiency, 1.0);
  });
}
```

- [ ] **Step 2: Run tests — verify they fail**

```
flutter test test/data/manual_sleep_source_test.dart
```
Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Implement `ManualSleepSource`**

Create `lib/data/sources/manual_sleep_source.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

import '../database.dart';

abstract class ManualSleepSource {
  Future<void> upsert(SleepRecord record);
  Future<void> delete(DateTime night);
  Future<List<SleepRecord>> recent(Duration window, {required DateTime now});
  Stream<List<SleepRecord>> watchRecent(Duration window, {required DateTime now});
}

class DriftManualSleepSource implements ManualSleepSource {
  final AppDatabase _db;
  DriftManualSleepSource(this._db);

  @override
  Future<void> upsert(SleepRecord record) async {
    await _db.into(_db.manualSleepRecords).insertOnConflictUpdate(
          ManualSleepRecordsCompanion.insert(
            night: record.night.toUtc(),
            sleepStart: record.sleepStart.toUtc(),
            totalSleepMinutes: record.totalSleep.inMinutes,
            efficiency: const Value.absent(), // MVP: efficiency not captured manually
          ),
        );
  }

  @override
  Future<void> delete(DateTime night) async {
    final utc = DateTime.utc(night.year, night.month, night.day);
    await (_db.delete(_db.manualSleepRecords)..where((t) => t.night.equals(utc))).go();
  }

  @override
  Future<List<SleepRecord>> recent(Duration window, {required DateTime now}) async {
    final utcNow = now.toUtc();
    final cutoff = utcNow.subtract(window);
    final rows = await (_db.select(_db.manualSleepRecords)
          ..where((t) => t.night.isBiggerOrEqualValue(cutoff) & t.night.isSmallerOrEqualValue(utcNow))
          ..orderBy([(t) => OrderingTerm.desc(t.night)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Stream<List<SleepRecord>> watchRecent(Duration window, {required DateTime now}) {
    final utcNow = now.toUtc();
    final cutoff = utcNow.subtract(window);
    final q = _db.select(_db.manualSleepRecords)
      ..where((t) => t.night.isBiggerOrEqualValue(cutoff) & t.night.isSmallerOrEqualValue(utcNow))
      ..orderBy([(t) => OrderingTerm.desc(t.night)]);
    return q.watch().map((rows) => rows.map(_toDomain).toList());
  }

  SleepRecord _toDomain(ManualSleepRecord r) => SleepRecord(
        night: r.night.toUtc(),
        sleepStart: r.sleepStart.toUtc(),
        totalSleep: Duration(minutes: r.totalSleepMinutes),
        efficiency: r.efficiency ?? 1.0,
      );
}
```

- [ ] **Step 4: Run tests — verify all pass**

```
flutter test test/data/manual_sleep_source_test.dart
```
Expected: PASS, 5 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/data/sources/manual_sleep_source.dart test/data/manual_sleep_source_test.dart
git commit -m "feat(data): add ManualSleepSource (drift-backed manual sleep records)"
```

---

## Task 6: `MergedHealthSource`

**Files:**
- Create: `lib/data/sources/merged_health_source.dart`
- Test: `test/data/merged_health_source_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/data/merged_health_source_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/sources/health_source.dart';
import 'package:migraine_weatherr/data/sources/manual_sleep_source.dart';
import 'package:migraine_weatherr/data/sources/merged_health_source.dart';

class _FakeHealth implements HealthSource {
  _FakeHealth(this.metrics, this.granted);
  HealthMetrics metrics;
  Set<HealthCategory> granted;
  @override
  Future<HealthMetrics> recentMetrics({required Duration window}) async => metrics;
  @override
  Future<Set<HealthCategory>> requestPermissions(Set<HealthCategory> categories) async => granted;
  @override
  Set<HealthCategory> get grantedCategories => granted;
}

class _FakeManual implements ManualSleepSource {
  _FakeManual(this.records);
  List<SleepRecord> records;
  @override
  Future<void> upsert(SleepRecord r) async {}
  @override
  Future<void> delete(DateTime night) async {}
  @override
  Future<List<SleepRecord>> recent(Duration window, {required DateTime now}) async => records;
  @override
  Stream<List<SleepRecord>> watchRecent(Duration window, {required DateTime now}) =>
      Stream.value(records);
}

SleepRecord night(int day, {int hours = 7}) {
  final n = DateTime.utc(2026, 6, day);
  return SleepRecord(
    night: n,
    totalSleep: Duration(hours: hours),
    efficiency: 1.0,
    sleepStart: n.add(const Duration(hours: 22)),
  );
}

void main() {
  test('manual fills gaps where OS source has no record for that night', () async {
    final os = _FakeHealth(HealthMetrics(recentSleep: [night(12, hours: 7)]), {HealthCategory.sleep});
    final manual = _FakeManual([night(11, hours: 6)]);
    final merged = MergedHealthSource(os, manual, clock: () => DateTime.utc(2026, 6, 13));
    final m = await merged.recentMetrics(window: const Duration(days: 7));
    expect(m.recentSleep.map((r) => r.night).toList(),
        [DateTime.utc(2026, 12), DateTime.utc(2026, 11)].sublist(0, 0) + [DateTime.utc(2026, 6, 12), DateTime.utc(2026, 6, 11)]);
    // Total of two nights merged, newest first.
    expect(m.recentSleep, hasLength(2));
    expect(m.recentSleep.first.night, DateTime.utc(2026, 6, 12));
  });

  test('OS-supplied night wins when both have the same night', () async {
    final os = _FakeHealth(HealthMetrics(recentSleep: [night(12, hours: 8)]), {HealthCategory.sleep});
    final manual = _FakeManual([night(12, hours: 4)]);
    final merged = MergedHealthSource(os, manual, clock: () => DateTime.utc(2026, 6, 13));
    final m = await merged.recentMetrics(window: const Duration(days: 7));
    expect(m.recentSleep, hasLength(1));
    expect(m.recentSleep.single.totalSleep, const Duration(hours: 8));
  });

  test('grantedCategories delegates to OS source', () {
    final os = _FakeHealth(const HealthMetrics(), {HealthCategory.hrv});
    final merged = MergedHealthSource(os, _FakeManual(const []), clock: DateTime.now);
    expect(merged.grantedCategories, {HealthCategory.hrv});
  });

  test('HRV and menstrual data pass through from OS', () async {
    final os = _FakeHealth(
      HealthMetrics(
        recentSleep: const [],
        recentHrv: [HrvSample(at: DateTime.utc(2026, 6, 12), rmssdMs: 40)],
        menstrualHistory: [MenstrualEvent(onsetDate: DateTime.utc(2026, 6, 1))],
      ),
      {HealthCategory.sleep, HealthCategory.hrv, HealthCategory.menstrual},
    );
    final merged = MergedHealthSource(os, _FakeManual(const []), clock: () => DateTime.utc(2026, 6, 13));
    final m = await merged.recentMetrics(window: const Duration(days: 30));
    expect(m.recentHrv, hasLength(1));
    expect(m.menstrualHistory, hasLength(1));
  });
}
```

Note: fix the first test — the `.sublist(0, 0) +` clause is wrong, simplify:

```dart
    expect(m.recentSleep.map((r) => r.night).toList(),
        [DateTime.utc(2026, 6, 12), DateTime.utc(2026, 6, 11)]);
```

(Replace the broken expectation before running.)

- [ ] **Step 2: Run the test — verify it fails**

```
flutter test test/data/merged_health_source_test.dart
```
Expected: FAIL — `MergedHealthSource` not defined.

- [ ] **Step 3: Implement `MergedHealthSource`**

Create `lib/data/sources/merged_health_source.dart`:

```dart
import 'package:domain/domain.dart';

import 'health_source.dart';
import 'manual_sleep_source.dart';

class MergedHealthSource implements HealthSource {
  final HealthSource _os;
  final ManualSleepSource _manual;
  final DateTime Function() _clock;

  MergedHealthSource(this._os, this._manual, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  @override
  Set<HealthCategory> get grantedCategories => _os.grantedCategories;

  @override
  Future<Set<HealthCategory>> requestPermissions(Set<HealthCategory> categories) =>
      _os.requestPermissions(categories);

  @override
  Future<HealthMetrics> recentMetrics({required Duration window}) async {
    final os = await _os.recentMetrics(window: window);
    final manual = await _manual.recent(window, now: _clock());
    final osNights = os.recentSleep.map((r) => r.night).toSet();
    final extras = manual.where((r) => !osNights.contains(r.night)).toList();
    final merged = [...os.recentSleep, ...extras]
      ..sort((a, b) => b.night.compareTo(a.night));
    return HealthMetrics(
      recentSleep: merged,
      recentHrv: os.recentHrv,
      menstrualHistory: os.menstrualHistory,
    );
  }
}
```

- [ ] **Step 4: Run the tests — verify all pass**

```
flutter test test/data/merged_health_source_test.dart
```
Expected: PASS, 4 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/data/sources/merged_health_source.dart test/data/merged_health_source_test.dart
git commit -m "feat(data): add MergedHealthSource to fold manual sleep into OS health metrics"
```

---

## Task 7: Riverpod providers — manual sleep + merged health + gating

**Files:**
- Create: `lib/state/manual_sleep_provider.dart`
- Modify: `lib/state/providers.dart`

- [ ] **Step 1: Create `manual_sleep_provider.dart`**

Create `lib/state/manual_sleep_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sources/health_source.dart';
import '../data/sources/manual_sleep_source.dart';
import 'providers.dart';

final manualSleepSourceProvider = Provider<ManualSleepSource>(
  (ref) => DriftManualSleepSource(ref.watch(databaseProvider)),
);

/// True when the OS health source did not grant sleep access, meaning the
/// "Log sleep" affordance should be shown.
final manualSleepEnabledProvider = Provider<bool>((ref) {
  final granted = ref.watch(healthSourceProvider).grantedCategories;
  return !granted.contains(HealthCategory.sleep);
});
```

- [ ] **Step 2: Wire `MergedHealthSource` in `providers.dart`**

In `lib/state/providers.dart`, replace the `healthSourceProvider` line:

```dart
final healthSourceProvider = Provider<HealthSource>((ref) => MergedHealthSource(
      HealthPackageSource(),
      DriftManualSleepSource(ref.watch(databaseProvider)),
    ));
```

Add the imports near the other source imports:

```dart
import '../data/sources/manual_sleep_source.dart';
import '../data/sources/merged_health_source.dart';
```

(`manualSleepSourceProvider` and the gating provider live in `manual_sleep_provider.dart`; they read the same DB so there's no double-construction concern, but if you prefer single-instance, you can refactor `healthSourceProvider` to consume `ref.watch(manualSleepSourceProvider)` — do that here:)

```dart
final healthSourceProvider = Provider<HealthSource>((ref) => MergedHealthSource(
      HealthPackageSource(),
      ref.watch(manualSleepSourceProvider),
    ));
```

And import `manual_sleep_provider.dart` for `manualSleepSourceProvider`.

- [ ] **Step 3: Run the existing risk-assessment / providers tests to confirm no regressions**

```
flutter test
```
Expected: PASS. (If a test was using `HealthPackageSource` directly via the provider, it still gets sleep through the merge wrapper. Real `HealthPackageSource` returns whatever the device returns; the merge is additive.)

- [ ] **Step 4: Commit**

```bash
git add lib/state/manual_sleep_provider.dart lib/state/providers.dart
git commit -m "feat(state): add manual sleep source + gating providers, wire MergedHealthSource"
```

---

## Task 8: `journalEntriesProvider` — combined stream for history view

**Files:**
- Create: `lib/state/journal_entries_provider.dart`

- [ ] **Step 1: Define a UI-side row union and stream provider**

Create `lib/state/journal_entries_provider.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import 'manual_sleep_provider.dart';
import 'providers.dart';

/// Item rendered in the history list. Either a journal entry or a manual
/// sleep record. Manual sleep is kept as a distinct case so the edit sheet
/// can route to the sleep-specific editor.
sealed class LogHistoryItem {
  DateTime get at;
}

class JournalLogItem extends LogHistoryItem {
  final JournalEntry entry;
  JournalLogItem(this.entry);
  @override
  DateTime get at => entry.at;
}

class SleepLogItem extends LogHistoryItem {
  final SleepRecord record;
  SleepLogItem(this.record);
  // Use sleepStart so it sorts within the day naturally.
  @override
  DateTime get at => record.sleepStart;
}

const _historyWindow = Duration(days: 30);

final journalHistoryProvider = StreamProvider.autoDispose<List<LogHistoryItem>>((ref) {
  final journal = ref.watch(journalSourceProvider);
  final manual = ref.watch(manualSleepSourceProvider);
  final now = DateTime.now().toUtc();
  return Rx.combineLatest2<List<JournalEntry>, List<SleepRecord>, List<LogHistoryItem>>(
    journal.watchRecentEntries(_historyWindow, now: now),
    manual.watchRecent(_historyWindow, now: now),
    (entries, sleeps) {
      final items = <LogHistoryItem>[
        ...entries.map(JournalLogItem.new),
        ...sleeps.map(SleepLogItem.new),
      ];
      items.sort((a, b) => b.at.compareTo(a.at));
      return items;
    },
  );
});
```

- [ ] **Step 2: Confirm `rxdart` is already a dependency**

```
grep '^  rxdart' pubspec.yaml
```
Expected: a line is found. If not, add it under `dependencies:`:

```yaml
  rxdart: ^0.27.7
```

Then run `flutter pub get`.

- [ ] **Step 3: Type-check**

```
flutter analyze lib/state/journal_entries_provider.dart
```
Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add lib/state/journal_entries_provider.dart pubspec.yaml pubspec.lock
git commit -m "feat(state): add journalHistoryProvider combining journal + manual sleep"
```

---

## Task 9: `JournalEntrySheet` (alcohol / caffeine / hydration / stress)

**Files:**
- Create: `lib/ui/log/journal_entry_sheet.dart`
- Test: `test/ui/log/journal_entry_sheet_test.dart`

- [ ] **Step 1: Write the failing widget tests**

Create `test/ui/log/journal_entry_sheet_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/sources/journal_source.dart';
import 'package:migraine_weatherr/state/providers.dart';
import 'package:migraine_weatherr/ui/log/journal_entry_sheet.dart';

class _FakeJournal implements JournalSource {
  final added = <JournalEntry>[];
  final updated = <JournalEntry>[];
  final deleted = <int>[];

  @override
  Future<void> addEntry(JournalEntry e) async => added.add(e);
  @override
  Future<void> updateEntry(JournalEntry e) async => updated.add(e);
  @override
  Future<void> deleteEntry(int id) async => deleted.add(id);

  // Everything else is unused for these tests:
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Future<void> pumpSheet(WidgetTester tester, _FakeJournal fake, JournalKind kind, {JournalEntry? initial}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [journalSourceProvider.overrideWithValue(fake)],
    child: MaterialApp(
      home: Scaffold(body: JournalEntrySheet(kind: kind, initial: initial)),
    ),
  ));
}

void main() {
  testWidgets('alcohol: tapping +1 then Save writes units=1', (tester) async {
    final fake = _FakeJournal();
    await pumpSheet(tester, fake, JournalKind.alcohol);
    await tester.tap(find.byKey(const Key('alcohol-inc')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('entry-save')));
    await tester.pump();
    expect(fake.added, hasLength(1));
    expect(fake.added.single.kind, JournalKind.alcohol);
    expect(fake.added.single.payload['units'], 1);
  });

  testWidgets('caffeine: selecting Coffee preset writes mg=95', (tester) async {
    final fake = _FakeJournal();
    await pumpSheet(tester, fake, JournalKind.caffeine);
    await tester.tap(find.byKey(const Key('caffeine-preset-coffee')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('entry-save')));
    await tester.pump();
    expect(fake.added.single.payload['mg'], 95);
  });

  testWidgets('hydration: tapping Bottle writes liters=0.5', (tester) async {
    final fake = _FakeJournal();
    await pumpSheet(tester, fake, JournalKind.hydration);
    await tester.tap(find.byKey(const Key('hydration-preset-bottle')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('entry-save')));
    await tester.pump();
    expect(fake.added.single.payload['liters'], 0.5);
  });

  testWidgets('stress: selecting rating 4 writes rating=4', (tester) async {
    final fake = _FakeJournal();
    await pumpSheet(tester, fake, JournalKind.stress);
    await tester.tap(find.byKey(const Key('stress-rating-4')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('entry-save')));
    await tester.pump();
    expect(fake.added.single.payload['rating'], 4);
  });

  testWidgets('edit mode pre-fills and calls updateEntry', (tester) async {
    final fake = _FakeJournal();
    final initial = JournalEntry(
      id: 7,
      at: DateTime.utc(2026, 6, 13, 10),
      kind: JournalKind.stress,
      payload: const {'rating': 2},
    );
    await pumpSheet(tester, fake, JournalKind.stress, initial: initial);
    await tester.tap(find.byKey(const Key('stress-rating-5')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('entry-save')));
    await tester.pump();
    expect(fake.updated, hasLength(1));
    expect(fake.updated.single.id, 7);
    expect(fake.updated.single.payload['rating'], 5);
  });

  testWidgets('save is disabled until payload is valid', (tester) async {
    final fake = _FakeJournal();
    await pumpSheet(tester, fake, JournalKind.stress);
    final saveBtn = tester.widget<FilledButton>(find.byKey(const Key('entry-save')));
    expect(saveBtn.onPressed, isNull);
  });
}
```

- [ ] **Step 2: Run tests — verify they fail**

```
flutter test test/ui/log/journal_entry_sheet_test.dart
```
Expected: FAIL — `JournalEntrySheet` not defined.

- [ ] **Step 3: Implement `JournalEntrySheet`**

Create `lib/ui/log/journal_entry_sheet.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';

class JournalEntrySheet extends ConsumerStatefulWidget {
  final JournalKind kind;
  final JournalEntry? initial;
  const JournalEntrySheet({super.key, required this.kind, this.initial});

  @override
  ConsumerState<JournalEntrySheet> createState() => _JournalEntrySheetState();
}

class _JournalEntrySheetState extends ConsumerState<JournalEntrySheet> {
  late DateTime _at;
  int? _units;     // alcohol
  int? _mg;        // caffeine
  double? _liters; // hydration
  int? _rating;    // stress

  static const _coffeeMg = 95;
  static const _espressoMg = 64;
  static const _teaMg = 47;
  static const _energyMg = 80;

  @override
  void initState() {
    super.initState();
    _at = widget.initial?.at ?? DateTime.now().toUtc();
    final p = widget.initial?.payload;
    if (p != null) {
      switch (widget.kind) {
        case JournalKind.alcohol:
          _units = (p['units'] as num?)?.toInt();
        case JournalKind.caffeine:
          _mg = (p['mg'] as num?)?.toInt();
        case JournalKind.hydration:
          _liters = (p['liters'] as num?)?.toDouble();
        case JournalKind.stress:
          _rating = (p['rating'] as num?)?.toInt();
      }
    }
  }

  bool get _valid {
    switch (widget.kind) {
      case JournalKind.alcohol:
        return (_units ?? 0) >= 1;
      case JournalKind.caffeine:
        return (_mg ?? 0) >= 1;
      case JournalKind.hydration:
        return (_liters ?? 0) > 0;
      case JournalKind.stress:
        return _rating != null;
    }
  }

  Map<String, Object?> _payload() {
    switch (widget.kind) {
      case JournalKind.alcohol:
        return {'units': _units!};
      case JournalKind.caffeine:
        return {'mg': _mg!};
      case JournalKind.hydration:
        return {'liters': _liters!};
      case JournalKind.stress:
        return {'rating': _rating!};
    }
  }

  Future<void> _save() async {
    final journal = ref.read(journalSourceProvider);
    final entry = JournalEntry(
      id: widget.initial?.id,
      at: _at,
      kind: widget.kind,
      payload: _payload(),
    );
    if (entry.id == null) {
      await journal.addEntry(entry);
    } else {
      await journal.updateEntry(entry);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final id = widget.initial?.id;
    if (id == null) return;
    await ref.read(journalSourceProvider).deleteEntry(id);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _pickTime() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _at.toLocal(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_at.toLocal()),
    );
    if (time == null) return;
    setState(() {
      _at = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute)
          .toUtc();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20,
          16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_title(), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildControls(),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickTime,
            icon: const Icon(Icons.schedule),
            label: Text(_at.toLocal().toString().substring(0, 16)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (widget.initial != null)
                TextButton(
                  onPressed: _delete,
                  child: const Text('Delete'),
                ),
              const Spacer(),
              FilledButton(
                key: const Key('entry-save'),
                onPressed: _valid ? _save : null,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _title() {
    switch (widget.kind) {
      case JournalKind.alcohol:   return 'Log alcohol';
      case JournalKind.caffeine:  return 'Log caffeine';
      case JournalKind.hydration: return 'Log hydration';
      case JournalKind.stress:    return 'Log stress';
    }
  }

  Widget _buildControls() {
    switch (widget.kind) {
      case JournalKind.alcohol:   return _alcohol();
      case JournalKind.caffeine:  return _caffeine();
      case JournalKind.hydration: return _hydration();
      case JournalKind.stress:    return _stress();
    }
  }

  Widget _alcohol() {
    final units = _units ?? 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.outlined(
          onPressed: units > 0 ? () => setState(() => _units = units - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text('$units drinks', style: Theme.of(context).textTheme.headlineSmall),
        ),
        IconButton.outlined(
          key: const Key('alcohol-inc'),
          onPressed: () => setState(() => _units = units + 1),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  Widget _caffeine() {
    return Wrap(
      spacing: 8,
      children: [
        _presetChip('Coffee 95mg', _coffeeMg, key: 'caffeine-preset-coffee'),
        _presetChip('Espresso 64mg', _espressoMg, key: 'caffeine-preset-espresso'),
        _presetChip('Tea 47mg', _teaMg, key: 'caffeine-preset-tea'),
        _presetChip('Energy 80mg', _energyMg, key: 'caffeine-preset-energy'),
      ],
    );
  }

  Widget _presetChip(String label, int mg, {required String key}) {
    final selected = _mg == mg;
    return ChoiceChip(
      key: Key(key),
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _mg = mg),
    );
  }

  Widget _hydration() {
    return Wrap(
      spacing: 8,
      children: [
        _hydrationChip('Glass 250ml', 0.25, key: 'hydration-preset-glass'),
        _hydrationChip('Bottle 500ml', 0.5, key: 'hydration-preset-bottle'),
        _hydrationChip('Liter 1000ml', 1.0, key: 'hydration-preset-liter'),
      ],
    );
  }

  Widget _hydrationChip(String label, double liters, {required String key}) {
    final selected = _liters == liters;
    return ChoiceChip(
      key: Key(key),
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _liters = liters),
    );
  }

  Widget _stress() {
    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(5, (i) {
        final v = i + 1;
        return ChoiceChip(
          key: Key('stress-rating-$v'),
          label: Text('$v'),
          selected: _rating == v,
          onSelected: (_) => setState(() => _rating = v),
        );
      }),
    );
  }
}
```

- [ ] **Step 4: Run the tests — verify all pass**

```
flutter test test/ui/log/journal_entry_sheet_test.dart
```
Expected: PASS, 6 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/ui/log/journal_entry_sheet.dart test/ui/log/journal_entry_sheet_test.dart
git commit -m "feat(ui): add JournalEntrySheet for alcohol/caffeine/hydration/stress"
```

---

## Task 10: `SleepEntrySheet`

**Files:**
- Create: `lib/ui/log/sleep_entry_sheet.dart`
- Test: `test/ui/log/sleep_entry_sheet_test.dart`

- [ ] **Step 1: Write the failing widget tests**

Create `test/ui/log/sleep_entry_sheet_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/sources/manual_sleep_source.dart';
import 'package:migraine_weatherr/state/manual_sleep_provider.dart';
import 'package:migraine_weatherr/ui/log/sleep_entry_sheet.dart';

class _FakeManual implements ManualSleepSource {
  final upserted = <SleepRecord>[];
  final deleted = <DateTime>[];
  @override
  Future<void> upsert(SleepRecord r) async => upserted.add(r);
  @override
  Future<void> delete(DateTime n) async => deleted.add(n);
  @override
  Future<List<SleepRecord>> recent(Duration w, {required DateTime now}) async => const [];
  @override
  Stream<List<SleepRecord>> watchRecent(Duration w, {required DateTime now}) =>
      Stream.value(const []);
}

Future<void> pumpSheet(WidgetTester tester, _FakeManual fake, {SleepRecord? initial}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [manualSleepSourceProvider.overrideWithValue(fake)],
    child: MaterialApp(home: Scaffold(body: SleepEntrySheet(initial: initial))),
  ));
}

void main() {
  testWidgets('default 22:00→06:00 computes 8h sleep', (tester) async {
    final fake = _FakeManual();
    await pumpSheet(tester, fake);
    await tester.tap(find.byKey(const Key('sleep-save')));
    await tester.pump();
    expect(fake.upserted, hasLength(1));
    expect(fake.upserted.single.totalSleep, const Duration(hours: 8));
  });

  testWidgets('out-of-range duration disables save', (tester) async {
    final fake = _FakeManual();
    // Compose an initial record with 30min sleep → still invalid because
    // the sheet will internally derive duration from start/end times.
    await pumpSheet(tester, fake, initial: SleepRecord(
      night: DateTime.utc(2026, 6, 12),
      sleepStart: DateTime.utc(2026, 6, 12, 23, 30),
      totalSleep: const Duration(minutes: 30),
      efficiency: 1.0,
    ));
    final btn = tester.widget<FilledButton>(find.byKey(const Key('sleep-save')));
    expect(btn.onPressed, isNull);
  });

  testWidgets('cross-midnight times produce positive duration', (tester) async {
    final fake = _FakeManual();
    await pumpSheet(tester, fake);
    // The sheet's default already crosses midnight; verify night PK is the
    // calendar date of bedtime.
    await tester.tap(find.byKey(const Key('sleep-save')));
    await tester.pump();
    final r = fake.upserted.single;
    expect(r.totalSleep.inHours, greaterThan(0));
    expect(r.night, DateTime.utc(r.sleepStart.toUtc().year, r.sleepStart.toUtc().month, r.sleepStart.toUtc().day));
  });
}
```

- [ ] **Step 2: Run the tests — verify they fail**

```
flutter test test/ui/log/sleep_entry_sheet_test.dart
```
Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Implement `SleepEntrySheet`**

Create `lib/ui/log/sleep_entry_sheet.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/manual_sleep_provider.dart';

class SleepEntrySheet extends ConsumerStatefulWidget {
  final SleepRecord? initial;
  const SleepEntrySheet({super.key, this.initial});

  @override
  ConsumerState<SleepEntrySheet> createState() => _SleepEntrySheetState();
}

class _SleepEntrySheetState extends ConsumerState<SleepEntrySheet> {
  late DateTime _bed;
  late DateTime _wake;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null) {
      _bed = init.sleepStart.toLocal();
      _wake = _bed.add(init.totalSleep);
    } else {
      // Default: last night 22:00 → this morning 06:00 local.
      final today = DateTime.now();
      _bed = DateTime(today.year, today.month, today.day - 1, 22, 0);
      _wake = DateTime(today.year, today.month, today.day, 6, 0);
    }
  }

  Duration get _duration => _wake.difference(_bed);

  bool get _valid =>
      _duration >= const Duration(hours: 1) &&
      _duration <= const Duration(hours: 16);

  DateTime get _night {
    final utc = _bed.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }

  Future<void> _save() async {
    final manual = ref.read(manualSleepSourceProvider);
    await manual.upsert(SleepRecord(
      night: _night,
      sleepStart: _bed.toUtc(),
      totalSleep: _duration,
      efficiency: 1.0,
    ));
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final init = widget.initial;
    if (init == null) return;
    await ref.read(manualSleepSourceProvider).delete(init.night);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<DateTime?> _pick(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 14)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20,
          16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Log sleep', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.bedtime_outlined),
            title: const Text('Bedtime'),
            subtitle: Text(_bed.toString().substring(0, 16)),
            onTap: () async {
              final picked = await _pick(_bed);
              if (picked != null) setState(() => _bed = picked);
            },
          ),
          ListTile(
            leading: const Icon(Icons.wb_sunny_outlined),
            title: const Text('Wake time'),
            subtitle: Text(_wake.toString().substring(0, 16)),
            onTap: () async {
              final picked = await _pick(_wake);
              if (picked != null) setState(() => _wake = picked);
            },
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _valid
                  ? '${_duration.inHours}h ${_duration.inMinutes % 60}m'
                  : 'Sleep must be 1–16h',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (widget.initial != null)
                TextButton(onPressed: _delete, child: const Text('Delete')),
              const Spacer(),
              FilledButton(
                key: const Key('sleep-save'),
                onPressed: _valid ? _save : null,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests — verify all pass**

```
flutter test test/ui/log/sleep_entry_sheet_test.dart
```
Expected: PASS, 3 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/ui/log/sleep_entry_sheet.dart test/ui/log/sleep_entry_sheet_test.dart
git commit -m "feat(ui): add SleepEntrySheet for manual sleep entry"
```

---

## Task 11: `LogPickerSheet`

**Files:**
- Create: `lib/ui/log/log_picker_sheet.dart`
- Test: `test/ui/log/log_picker_sheet_test.dart`

- [ ] **Step 1: Write the failing widget tests**

Create `test/ui/log/log_picker_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/state/manual_sleep_provider.dart';
import 'package:migraine_weatherr/ui/log/log_picker_sheet.dart';

Future<void> pump(WidgetTester tester, {required bool sleepEnabled}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [manualSleepEnabledProvider.overrideWithValue(sleepEnabled)],
    child: const MaterialApp(home: Scaffold(body: LogPickerSheet())),
  ));
}

void main() {
  testWidgets('shows 4 kinds when sleep is granted (manualSleepEnabled=false)',
      (tester) async {
    await pump(tester, sleepEnabled: false);
    expect(find.byKey(const Key('log-kind-alcohol')), findsOneWidget);
    expect(find.byKey(const Key('log-kind-caffeine')), findsOneWidget);
    expect(find.byKey(const Key('log-kind-hydration')), findsOneWidget);
    expect(find.byKey(const Key('log-kind-stress')), findsOneWidget);
    expect(find.byKey(const Key('log-kind-sleep')), findsNothing);
  });

  testWidgets('shows sleep when manualSleepEnabled=true', (tester) async {
    await pump(tester, sleepEnabled: true);
    expect(find.byKey(const Key('log-kind-sleep')), findsOneWidget);
  });

  testWidgets('always shows history link', (tester) async {
    await pump(tester, sleepEnabled: false);
    expect(find.byKey(const Key('log-history-link')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests — verify they fail**

```
flutter test test/ui/log/log_picker_sheet_test.dart
```
Expected: FAIL — file missing.

- [ ] **Step 3: Implement `LogPickerSheet`**

Create `lib/ui/log/log_picker_sheet.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/manual_sleep_provider.dart';
import 'journal_entry_sheet.dart';
import 'sleep_entry_sheet.dart';

class LogPickerSheet extends ConsumerWidget {
  const LogPickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleepEnabled = ref.watch(manualSleepEnabledProvider);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          _kindTile(context, key: 'log-kind-alcohol', icon: Icons.local_bar_outlined,
              label: 'Alcohol', onTap: () => _openJournalSheet(context, JournalKind.alcohol)),
          _kindTile(context, key: 'log-kind-caffeine', icon: Icons.local_cafe_outlined,
              label: 'Caffeine', onTap: () => _openJournalSheet(context, JournalKind.caffeine)),
          _kindTile(context, key: 'log-kind-hydration', icon: Icons.water_drop_outlined,
              label: 'Hydration', onTap: () => _openJournalSheet(context, JournalKind.hydration)),
          _kindTile(context, key: 'log-kind-stress', icon: Icons.psychology_outlined,
              label: 'Stress', onTap: () => _openJournalSheet(context, JournalKind.stress)),
          if (sleepEnabled)
            _kindTile(context, key: 'log-kind-sleep', icon: Icons.bedtime_outlined,
                label: 'Sleep', onTap: () => _openSleepSheet(context)),
          const Divider(height: 1),
          ListTile(
            key: const Key('log-history-link'),
            leading: const Icon(Icons.history),
            title: const Text('View history'),
            onTap: () {
              Navigator.of(context).pop();
              context.push('/log-history');
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _kindTile(BuildContext context,
      {required String key, required IconData icon, required String label, required VoidCallback onTap}) {
    return ListTile(
      key: Key(key),
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }

  Future<void> _openJournalSheet(BuildContext context, JournalKind kind) async {
    Navigator.of(context).pop();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => JournalEntrySheet(kind: kind),
    );
  }

  Future<void> _openSleepSheet(BuildContext context) async {
    Navigator.of(context).pop();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SleepEntrySheet(),
    );
  }
}
```

- [ ] **Step 4: Run the tests — verify all pass**

```
flutter test test/ui/log/log_picker_sheet_test.dart
```
Expected: PASS, 3 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/ui/log/log_picker_sheet.dart test/ui/log/log_picker_sheet_test.dart
git commit -m "feat(ui): add LogPickerSheet (kind chooser + history link)"
```

---

## Task 12: `LogHistoryScreen`

**Files:**
- Create: `lib/ui/log/log_history_screen.dart`
- Test: `test/ui/log/log_history_screen_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/ui/log/log_history_screen_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/state/journal_entries_provider.dart';
import 'package:migraine_weatherr/ui/log/log_history_screen.dart';

void main() {
  testWidgets('renders rows from journalHistoryProvider', (tester) async {
    final entries = <LogHistoryItem>[
      JournalLogItem(JournalEntry(
        id: 1,
        at: DateTime.utc(2026, 6, 13, 10),
        kind: JournalKind.alcohol,
        payload: const {'units': 2},
      )),
      JournalLogItem(JournalEntry(
        id: 2,
        at: DateTime.utc(2026, 6, 13, 9),
        kind: JournalKind.caffeine,
        payload: const {'mg': 95},
      )),
    ];
    await tester.pumpWidget(ProviderScope(
      overrides: [
        journalHistoryProvider.overrideWith((_) => Stream.value(entries)),
      ],
      child: const MaterialApp(home: LogHistoryScreen()),
    ));
    await tester.pump();
    expect(find.text('2 drinks'), findsOneWidget);
    expect(find.text('95 mg'), findsOneWidget);
  });

  testWidgets('empty state renders when no entries', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        journalHistoryProvider.overrideWith((_) => Stream.value(<LogHistoryItem>[])),
      ],
      child: const MaterialApp(home: LogHistoryScreen()),
    ));
    await tester.pump();
    expect(find.text('No entries yet'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test — verify it fails**

```
flutter test test/ui/log/log_history_screen_test.dart
```
Expected: FAIL — screen missing.

- [ ] **Step 3: Implement `LogHistoryScreen`**

Create `lib/ui/log/log_history_screen.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../state/journal_entries_provider.dart';
import '../../state/manual_sleep_provider.dart';
import '../../state/providers.dart';
import 'journal_entry_sheet.dart';
import 'sleep_entry_sheet.dart';

class LogHistoryScreen extends ConsumerWidget {
  const LogHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(journalHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Log history')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No entries yet'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _Row(item: items[i]),
          );
        },
      ),
    );
  }
}

class _Row extends ConsumerWidget {
  final LogHistoryItem item;
  const _Row({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = DateFormat('MMM d, HH:mm').format(item.at.toLocal());
    return Dismissible(
      key: ValueKey(_keyFor(item)),
      direction: DismissDirection.endToStart,
      background: Container(color: Colors.red, alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.white)),
      onDismissed: (_) async {
        await _delete(ref, item);
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(SnackBar(
          content: const Text('Entry deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => _restore(ref, item),
          ),
          duration: const Duration(seconds: 5),
        ));
      },
      child: ListTile(
        leading: Icon(_icon(item)),
        title: Text(_summary(item)),
        subtitle: Text(time),
        onTap: () => _edit(context, item),
      ),
    );
  }

  String _keyFor(LogHistoryItem item) {
    if (item is JournalLogItem) return 'j-${item.entry.id}';
    if (item is SleepLogItem) return 's-${item.record.night.toIso8601String()}';
    return item.hashCode.toString();
  }

  IconData _icon(LogHistoryItem item) {
    if (item is SleepLogItem) return Icons.bedtime_outlined;
    final entry = (item as JournalLogItem).entry;
    switch (entry.kind) {
      case JournalKind.alcohol:   return Icons.local_bar_outlined;
      case JournalKind.caffeine:  return Icons.local_cafe_outlined;
      case JournalKind.hydration: return Icons.water_drop_outlined;
      case JournalKind.stress:    return Icons.psychology_outlined;
    }
  }

  String _summary(LogHistoryItem item) {
    if (item is SleepLogItem) {
      final h = item.record.totalSleep.inHours;
      final m = item.record.totalSleep.inMinutes % 60;
      return '${h}h ${m}m sleep';
    }
    final e = (item as JournalLogItem).entry;
    switch (e.kind) {
      case JournalKind.alcohol:   return '${e.payload['units']} drinks';
      case JournalKind.caffeine:  return '${e.payload['mg']} mg';
      case JournalKind.hydration:
        final l = (e.payload['liters'] as num).toDouble();
        return '${(l * 1000).round()} ml';
      case JournalKind.stress:    return 'Stress ${e.payload['rating']}/5';
    }
  }

  Future<void> _edit(BuildContext context, LogHistoryItem item) async {
    if (item is SleepLogItem) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => SleepEntrySheet(initial: item.record),
      );
    } else if (item is JournalLogItem) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => JournalEntrySheet(kind: item.entry.kind, initial: item.entry),
      );
    }
  }

  Future<void> _delete(WidgetRef ref, LogHistoryItem item) async {
    if (item is JournalLogItem) {
      await ref.read(journalSourceProvider).deleteEntry(item.entry.id!);
    } else if (item is SleepLogItem) {
      await ref.read(manualSleepSourceProvider).delete(item.record.night);
    }
  }

  Future<void> _restore(WidgetRef ref, LogHistoryItem item) async {
    if (item is JournalLogItem) {
      await ref.read(journalSourceProvider).addEntry(item.entry);
    } else if (item is SleepLogItem) {
      await ref.read(manualSleepSourceProvider).upsert(item.record);
    }
  }
}
```

- [ ] **Step 4: Run the test — verify it passes**

```
flutter test test/ui/log/log_history_screen_test.dart
```
Expected: PASS, 2 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/ui/log/log_history_screen.dart test/ui/log/log_history_screen_test.dart
git commit -m "feat(ui): add LogHistoryScreen with edit + swipe-delete + undo"
```

---

## Task 13: Add route and Today FAB

**Files:**
- Modify: `lib/app/router.dart`
- Modify: `lib/ui/today/today_screen.dart`

- [ ] **Step 1: Register `/log-history` route**

In `lib/app/router.dart`, add to the imports:

```dart
import '../ui/log/log_history_screen.dart';
```

And add to the routes list (after the existing `/log` entry):

```dart
      GoRoute(path: '/log-history', builder: (_, __) => const LogHistoryScreen()),
```

- [ ] **Step 2: Add FAB on Today screen**

In `lib/ui/today/today_screen.dart`, add import:

```dart
import '../log/log_picker_sheet.dart';
```

Inside the `Scaffold` returned by `build`, add `floatingActionButton` between `appBar:` and `body:`:

```dart
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('today-log-fab'),
        icon: const Icon(Icons.add),
        label: const Text('Log'),
        onPressed: () => showModalBottomSheet(
          context: context,
          showDragHandle: false,
          builder: (_) => const LogPickerSheet(),
        ),
      ),
```

- [ ] **Step 3: Manual smoke test**

Run the app and verify:

```
flutter run -d <device>
```

Verify on Today: FAB appears. Tap → picker sheet shows the 4 kinds (+ sleep if no HealthKit). Tap a kind → sheet opens → save → returns to Today. Tap "View history" → see the entry → swipe to delete → Undo restores.

Document the result here (PASS / list of issues).

- [ ] **Step 4: Run full test suite**

```
flutter test
```
Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/app/router.dart lib/ui/today/today_screen.dart
git commit -m "feat(ui): add Today FAB for logging + /log-history route"
```

---

## Self-Review

- Spec coverage:
  - Entry point (FAB + picker sheet) → Tasks 11, 13.
  - Per-kind sheets with presets → Task 9.
  - Sleep gated UI + storage + merge → Tasks 2, 5, 6, 7, 10.
  - History view with edit/delete/undo → Tasks 8, 12.
  - Domain `JournalEntry.id` → Task 1.
  - `JournalSource` update/delete/watch → Tasks 3, 4.
  - Drift migration v4→v5 → Task 2.
  - Testing per spec → covered in each task's test step.
- Placeholders: none.
- Type consistency: `JournalEntry({id, at, kind, payload})`, `SleepRecord({night, totalSleep, efficiency, sleepStart})`, `ManualSleepSource.upsert/delete/recent/watchRecent`, `JournalSource.addEntry/updateEntry/deleteEntry/watchRecentEntries`, `LogHistoryItem`/`JournalLogItem`/`SleepLogItem`, `journalHistoryProvider`, `manualSleepEnabledProvider`, `manualSleepSourceProvider`. Consistent across tasks.

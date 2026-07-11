# Plan 6 — Generalized Correlation Platform & Insights Expansion

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generalize the correlation framework from "trigger modules only" to arbitrary day-level exposures, then build on it: forecast-accuracy (calibration) view, next-morning check-in, 7-day outlook, medication tracking with MOH warnings, deeper insights (streaks, weekday/time-of-day patterns, trigger interactions), and two new trigger modules (skipped meals, wind).

**Architecture:** The statistical kernel (`WilsonInterval` + lift + classification) is already exposure-agnostic. Phase A extracts a per-day timeline (`DayRecord`) from the DB once, and turns cohort-building into a pure function over `(List<DayRecord>, Exposure predicate)`. Every subsequent analysis — module correlations, calibration, weekday patterns, interactions — becomes a small pure domain function over that timeline. Features that add data (check-ins, medications) write to new Drift tables and feed the same timeline.

**Tech Stack:** Pure-Dart domain package (`packages/domain`), Drift/SQLite (schema v12 → v14), Riverpod, flutter_local_notifications + timezone (already dependencies), Open-Meteo.

## Global Constraints

- Domain package stays pure Dart: no Flutter, no IO, no `DateTime.now()` without an injectable clock.
- Trigger modules **must not throw** — return `TriggerSignal.zero(...)` on missing data (see `trigger_module.dart` doc comment).
- Days are always **UTC midnight** `DateTime.utc(y,m,d)` — match `CorrelationRepo`'s normalization exactly.
- Tunable thresholds go in `assets/rules_config_v1.json` params, never hardcoded in module logic.
- New module thresholds require a literature citation in the module's doc comment (existing convention: Bertisch 2020, Okuma 2015, etc.).
- Conventional commits: `feat(scope): …`, `test(scope): …`, `chore(scope): …`.
- Domain tests: `cd packages/domain && dart test`. App tests: `flutter test <path>`. Run `flutter analyze` after each task; zero new warnings.
- Drift schema changes: bump `schemaVersion`, add `onUpgrade` block, add a migration test in `test/data/database_migration_test.dart` (follow existing patterns there).
- Every new module id must be added to: `allTriggerModules()` (created in Task 18), `assets/rules_config_v1.json`, `lib/ui/shared/contributor_order.dart`, and the trigger-flag lists in `lib/ui/onboarding/onboarding_screen.dart` + `lib/ui/settings/settings_screen.dart`.
- Out of scope (decided, do not implement): screen-time module (no cross-platform data source yet), travel/altitude module (needs a location-history table first), medication-as-exposure correlation, persisted outlook assessments.

---

## Phase A — Generalize the correlation kernel

### Task 1: Exposure abstraction + generalized Cohort (domain)

**Files:**
- Create: `packages/domain/lib/src/correlation/day_record.dart`
- Create: `packages/domain/lib/src/correlation/exposure.dart`
- Modify: `packages/domain/lib/src/correlation/correlation_analyzer.dart`
- Modify: `packages/domain/lib/domain.dart` (export new files)
- Test: `packages/domain/test/correlation/exposure_test.dart`

**Interfaces:**
- Consumes: `WilsonInterval`, `RiskBand` (existing).
- Produces: `DayRecord`, `Exposure`, `Cohort` (renamed from `ModuleCohort`, field `moduleId` → `exposureId`), `buildCohort(List<DayRecord>, Exposure) → Cohort`, `CorrelationResult.exposureId`. Task 3 consumes all of these; Tasks 4/7/8 consume `DayRecord`.

- [ ] **Step 1: Write the failing tests**

```dart
// packages/domain/test/correlation/exposure_test.dart
import 'package:domain/domain.dart';
import 'package:test/test.dart';

DayRecord day(int d, {Set<String> fired = const {}, bool attack = false}) =>
    DayRecord(
      day: DateTime.utc(2026, 7, d),
      firedModuleIds: fired,
      hadAttack: attack,
    );

void main() {
  test('moduleFired exposure partitions days into 2x2 cohort', () {
    final days = [
      day(1, fired: {'alcohol'}, attack: true),
      day(2, fired: {'alcohol'}),
      day(3, attack: true),
      day(4),
    ];
    final c = buildCohort(days, Exposure.moduleFired('alcohol'));
    expect(c.exposureId, 'alcohol');
    expect(c.daysFiredWithAttack, 1);
    expect(c.daysFiredTotal, 2);
    expect(c.daysNotFiredWithAttack, 1);
    expect(c.daysNotFiredTotal, 2);
  });

  test('weekday exposure selects matching weekdays', () {
    // 2026-07-06 is a Monday.
    final days = [day(6, attack: true), day(7), day(13)];
    final c = buildCohort(days, Exposure.weekday(DateTime.monday));
    expect(c.exposureId, 'weekday_1');
    expect(c.daysFiredTotal, 2);
    expect(c.daysFiredWithAttack, 1);
    expect(c.daysNotFiredTotal, 1);
  });

  test('both() requires both exposures on the same day', () {
    final days = [
      day(1, fired: {'alcohol', 'sleep_deficit'}, attack: true),
      day(2, fired: {'alcohol'}),
    ];
    final c = buildCohort(
        days,
        Exposure.both(
            Exposure.moduleFired('alcohol'), Exposure.moduleFired('sleep_deficit')));
    expect(c.exposureId, 'alcohol+sleep_deficit');
    expect(c.daysFiredTotal, 1);
    expect(c.daysNotFiredTotal, 1);
  });

  test('analyzer accepts generalized cohort unchanged', () {
    final r = const CorrelationAnalyzer().analyze(const Cohort(
      exposureId: 'weekday_1',
      daysFiredWithAttack: 5,
      daysFiredTotal: 10,
      daysNotFiredWithAttack: 2,
      daysNotFiredTotal: 60,
    ));
    expect(r.exposureId, 'weekday_1');
    expect(r.classification, CorrelationClassification.personalHit);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `cd packages/domain && dart test test/correlation/exposure_test.dart`
Expected: FAIL — `DayRecord`, `Exposure`, `buildCohort`, `Cohort` undefined.

- [ ] **Step 3: Implement**

```dart
// packages/domain/lib/src/correlation/day_record.dart
import 'package:equatable/equatable.dart';
import '../types/risk_assessment.dart';

/// One calendar day's summary, the shared input for all correlation-family
/// analyses. [day] is UTC midnight. [score]/[band]/[backfilled] come from the
/// day's today-horizon assessment when one exists.
class DayRecord extends Equatable {
  final DateTime day;
  final Set<String> firedModuleIds;
  final bool hadAttack;
  final int? score;
  final RiskBand? band;
  final bool backfilled;

  const DayRecord({
    required this.day,
    this.firedModuleIds = const {},
    this.hadAttack = false,
    this.score,
    this.band,
    this.backfilled = false,
  });

  @override
  List<Object?> get props => [day, firedModuleIds, hadAttack, score, band, backfilled];
}
```

```dart
// packages/domain/lib/src/correlation/exposure.dart
import 'correlation_analyzer.dart';
import 'day_record.dart';

/// A named boolean predicate over a day — "was the user exposed to X?".
class Exposure {
  final String id;
  final bool Function(DayRecord day) test;
  const Exposure(this.id, this.test);

  static Exposure moduleFired(String moduleId) =>
      Exposure(moduleId, (d) => d.firedModuleIds.contains(moduleId));

  /// [weekday] uses DateTime constants (monday = 1 … sunday = 7).
  static Exposure weekday(int weekday) =>
      Exposure('weekday_$weekday', (d) => d.day.weekday == weekday);

  static Exposure both(Exposure a, Exposure b) =>
      Exposure('${a.id}+${b.id}', (d) => a.test(d) && b.test(d));
}

Cohort buildCohort(List<DayRecord> days, Exposure exposure) {
  var firedWithAttack = 0, firedTotal = 0, notFiredWithAttack = 0, notFiredTotal = 0;
  for (final d in days) {
    if (exposure.test(d)) {
      firedTotal++;
      if (d.hadAttack) firedWithAttack++;
    } else {
      notFiredTotal++;
      if (d.hadAttack) notFiredWithAttack++;
    }
  }
  return Cohort(
    exposureId: exposure.id,
    daysFiredWithAttack: firedWithAttack,
    daysFiredTotal: firedTotal,
    daysNotFiredWithAttack: notFiredWithAttack,
    daysNotFiredTotal: notFiredTotal,
  );
}
```

In `correlation_analyzer.dart`: rename class `ModuleCohort` → `Cohort` and field `moduleId` → `exposureId` (constructor, props, and the `analyze` body). Rename `CorrelationResult.moduleId` → `exposureId` likewise. Add exports to `domain.dart`:

```dart
export 'src/correlation/day_record.dart';
export 'src/correlation/exposure.dart';
```

- [ ] **Step 4: Fix the rename fallout mechanically**

Run: `grep -rn 'ModuleCohort\|\.moduleId' packages/domain lib test --include='*.dart' | grep -v 'TriggerSignal\|trigger_signal\|contributors'`

Expected call sites (update `CorrelationResult.moduleId` / `ModuleCohort` usages only — `TriggerSignal.moduleId` and `WeightSuggestion.moduleId` keep their names, they genuinely refer to modules):
- `lib/data/repos/correlation_repo.dart`
- `lib/services/suggestion_engine.dart` (reads `r.moduleId` → `r.exposureId`; `WeightSuggestion.moduleId` stays, assign `moduleId: r.exposureId`)
- `lib/ui/insights/correlation_card.dart`, `lib/ui/insights/suggestion_card.dart`
- `packages/domain/test/correlation/*`, `test/state/*`, `test/services/suggestion_engine_test.dart`, `test/ui/insights/*`

Run `flutter analyze` — the analyzer catches any missed site.

- [ ] **Step 5: Run all tests, then commit**

Run: `cd packages/domain && dart test && cd ../.. && flutter test`
Expected: PASS (existing correlation/suggestion/insights tests prove the rename is behavior-preserving).

```bash
git add -A && git commit -m "feat(domain): generalize correlation kernel to arbitrary day exposures"
```

### Task 2: DayTimelineRepo + shared timeline provider (data/state)

**Files:**
- Create: `lib/data/repos/day_timeline_repo.dart`
- Modify: `lib/data/repos/correlation_repo.dart` (delegate to timeline)
- Modify: `lib/state/correlation_provider.dart` (expose `dayTimelineProvider`)
- Test: `test/data/day_timeline_repo_test.dart`

**Interfaces:**
- Consumes: `AppDatabase` (`riskAssessments`, `attacks` tables), `DayRecord`, `buildCohort`, `Exposure` from Task 1.
- Produces: `DayTimelineRepo.buildTimeline({required DateTime windowStart, required DateTime windowEnd}) → Future<List<DayRecord>>` (sorted ascending by day); Riverpod `dayTimelineProvider: FutureProvider<List<DayRecord>>` (trailing 90 days, re-runs when `recentAttacksProvider` changes). Tasks 5, 7, 8, and the refactored `correlationResultsProvider` consume these.

- [ ] **Step 1: Write the failing test**

```dart
// test/data/day_timeline_repo_test.dart
import 'dart:convert';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart';
import 'package:migraine_forecast/data/repos/day_timeline_repo.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  String contributors(List<(String, double, double)> mods) => jsonEncode([
        for (final (id, w, c) in mods)
          {'moduleId': id, 'weight': w, 'confidence': c, 'explanation': ''}
      ]);

  test('builds one DayRecord per assessed day with fired modules, attack flag, and score', () async {
    final d1 = DateTime.utc(2026, 7, 1);
    final d2 = DateTime.utc(2026, 7, 2);
    await db.into(db.riskAssessments).insert(RiskAssessmentsCompanion.insert(
        targetDate: d1, horizon: 'today', score: 70, band: 'high',
        computedAt: d1, configVersion: 2,
        contributorsJson: contributors([('alcohol', 10, 1.0), ('humidity', 0, 1.0)]),
        backfilled: const Value(true)));
    await db.into(db.riskAssessments).insert(RiskAssessmentsCompanion.insert(
        targetDate: d2, horizon: 'today', score: 10, band: 'low',
        computedAt: d2, configVersion: 2,
        contributorsJson: contributors([])));
    await db.into(db.attacks).insert(AttacksCompanion.insert(
        startedAt: d1.add(const Duration(hours: 9)), severity: 5));

    final tl = await DayTimelineRepo(db).buildTimeline(
        windowStart: DateTime.utc(2026, 6, 30), windowEnd: DateTime.utc(2026, 7, 3));

    expect(tl.length, 2);
    expect(tl.first.day, d1);
    expect(tl.first.firedModuleIds, {'alcohol'}); // humidity: weight*confidence == 0
    expect(tl.first.hadAttack, isTrue);
    expect(tl.first.score, 70);
    expect(tl.first.band, RiskBand.high);
    expect(tl.first.backfilled, isTrue);
    expect(tl.last.hadAttack, isFalse);
    expect(tl.last.band, RiskBand.low);
  });

  test('tomorrow-horizon rows contribute fired modules but not score', () async {
    final d = DateTime.utc(2026, 7, 5);
    await db.into(db.riskAssessments).insert(RiskAssessmentsCompanion.insert(
        targetDate: d, horizon: 'tomorrow', score: 55, band: 'high',
        computedAt: d, configVersion: 2,
        contributorsJson: '[{"moduleId":"pressure_drop","weight":12,"confidence":1.0}]'));
    final tl = await DayTimelineRepo(db).buildTimeline(
        windowStart: d, windowEnd: d.add(const Duration(days: 1)));
    expect(tl.single.firedModuleIds, {'pressure_drop'});
    expect(tl.single.score, isNull);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/data/day_timeline_repo_test.dart`
Expected: FAIL — `day_timeline_repo.dart` does not exist.

- [ ] **Step 3: Implement**

```dart
// lib/data/repos/day_timeline_repo.dart
import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

import '../database.dart';

/// Builds the per-day timeline consumed by all correlation-family analyses.
/// Fired-ness unions across horizons (matching the pre-plan6 CorrelationRepo
/// behavior); score/band/backfilled come from the today-horizon row only.
class DayTimelineRepo {
  final AppDatabase _db;
  DayTimelineRepo(this._db);

  Future<List<DayRecord>> buildTimeline({
    required DateTime windowStart,
    required DateTime windowEnd,
  }) async {
    final s = windowStart.toUtc();
    final utcStart = DateTime.utc(s.year, s.month, s.day);
    final e = windowEnd.toUtc();
    final utcEnd = DateTime.utc(e.year, e.month, e.day).add(const Duration(days: 1));

    final assessmentRows = await (_db.select(_db.riskAssessments)
          ..where((t) =>
              t.targetDate.isBiggerOrEqualValue(utcStart) &
              t.targetDate.isSmallerThanValue(utcEnd)))
        .get();

    // Drift's generated row class for RiskAssessments would shadow the domain
    // RiskAssessment type; avoid naming it by projecting into a record.
    final firedByDay = <DateTime, Set<String>>{};
    final todayByDay = <DateTime, ({int score, String band, bool backfilled})>{};
    for (final row in assessmentRows) {
      final d = row.targetDate.toUtc();
      final day = DateTime.utc(d.year, d.month, d.day);
      final fired = firedByDay.putIfAbsent(day, () => <String>{});
      final contributors = jsonDecode(row.contributorsJson) as List;
      for (final c in contributors) {
        final m = c as Map<String, Object?>;
        final weight = (m['weight'] as num).toDouble();
        final confidence = (m['confidence'] as num).toDouble();
        if (weight * confidence > 0) fired.add(m['moduleId'] as String);
      }
      if (row.horizon == 'today') {
        todayByDay[day] =
            (score: row.score, band: row.band, backfilled: row.backfilled);
      }
    }

    final attackRows = await (_db.select(_db.attacks)
          ..where((t) =>
              t.startedAt.isBiggerOrEqualValue(utcStart) &
              t.startedAt.isSmallerThanValue(utcEnd)))
        .get();
    final attackDays = <DateTime>{
      for (final a in attackRows)
        DateTime.utc(a.startedAt.toUtc().year, a.startedAt.toUtc().month,
            a.startedAt.toUtc().day),
    };

    final days = firedByDay.keys.toList()..sort();
    return [
      for (final day in days)
        DayRecord(
          day: day,
          firedModuleIds: firedByDay[day]!,
          hadAttack: attackDays.contains(day),
          score: todayByDay[day]?.score,
          band: todayByDay[day] == null
              ? null
              : RiskBand.values.byName(todayByDay[day]!.band),
          backfilled: todayByDay[day]?.backfilled ?? false,
        ),
    ];
  }
}
```

Rewrite `CorrelationRepo.buildCohorts` to delegate — **keep its public signature** so `correlation_provider.dart` and existing tests keep passing:

```dart
class CorrelationRepo {
  final AppDatabase _db;
  CorrelationRepo(this._db);

  Future<List<Cohort>> buildCohorts({
    required DateTime windowStart,
    required DateTime windowEnd,
    required List<String> moduleIds,
  }) async {
    final timeline = await DayTimelineRepo(_db)
        .buildTimeline(windowStart: windowStart, windowEnd: windowEnd);
    return [
      for (final id in moduleIds) buildCohort(timeline, Exposure.moduleFired(id)),
    ];
  }
}
```

Add to `lib/state/correlation_provider.dart`:

```dart
final dayTimelineRepoProvider =
    Provider<DayTimelineRepo>((ref) => DayTimelineRepo(ref.watch(databaseProvider)));

final dayTimelineProvider = FutureProvider<List<DayRecord>>((ref) async {
  ref.watch(recentAttacksProvider); // re-run when attacks change
  final now = DateTime.now().toUtc();
  return ref.watch(dayTimelineRepoProvider).buildTimeline(
        windowStart: now.subtract(const Duration(days: 90)),
        windowEnd: now.add(const Duration(days: 1)),
      );
});
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/data/day_timeline_repo_test.dart test/data/context_builder_test.dart test/state/ && flutter test test/ui/insights/`
Expected: PASS — including the pre-existing correlation repo test (regression proof).

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat(data): DayTimelineRepo shared timeline; CorrelationRepo delegates to generic cohorts"
```

---

## Phase B — Forecast accuracy (calibration) view

### Task 3: CalibrationAnalyzer (domain)

**Files:**
- Create: `packages/domain/lib/src/correlation/calibration.dart`
- Modify: `packages/domain/lib/domain.dart` (export)
- Test: `packages/domain/test/correlation/calibration_test.dart`

**Interfaces:**
- Consumes: `DayRecord`, `WilsonInterval`, `RiskBand`.
- Produces: `CalibrationReport analyzeCalibration(List<DayRecord> days, {bool includeBackfilled = false})` with `List<BandCalibration> bands` (only bands having ≥1 scored day, ordered low→veryHigh), `double? brierScore`, `int scoredDays`. Task 4 consumes.

- [ ] **Step 1: Write the failing test**

```dart
// packages/domain/test/correlation/calibration_test.dart
import 'package:domain/domain.dart';
import 'package:test/test.dart';

DayRecord scored(int d, int score, RiskBand band,
        {bool attack = false, bool backfilled = false}) =>
    DayRecord(
        day: DateTime.utc(2026, 6, d),
        score: score, band: band, hadAttack: attack, backfilled: backfilled);

void main() {
  test('groups observed attack rate per band with Wilson CIs and Brier score', () {
    final days = [
      scored(1, 10, RiskBand.low),
      scored(2, 15, RiskBand.low),
      scored(3, 80, RiskBand.veryHigh, attack: true),
      scored(4, 85, RiskBand.veryHigh),
      DayRecord(day: DateTime.utc(2026, 6, 5)), // unscored → excluded
    ];

    final r = analyzeCalibration(days);
    expect(r.scoredDays, 4);
    expect(r.bands.length, 2);
    expect(r.bands.first.band, RiskBand.low);
    expect(r.bands.first.attackRate.point, 0);
    expect(r.bands.last.band, RiskBand.veryHigh);
    expect(r.bands.last.attackRate.point, 0.5);
    // Brier: mean of (0.1-0)^2, (0.15-0)^2, (0.8-1)^2, (0.85-0)^2
    expect(r.brierScore, closeTo((0.01 + 0.0225 + 0.04 + 0.7225) / 4, 1e-9));
  });

  test('excludes backfilled days by default, includes them on request', () {
    final days = [
      scored(1, 80, RiskBand.veryHigh, attack: true, backfilled: true),
      scored(2, 20, RiskBand.low),
    ];
    expect(analyzeCalibration(days).scoredDays, 1);
    expect(analyzeCalibration(days, includeBackfilled: true).scoredDays, 2);
  });

  test('empty input yields null Brier and no bands', () {
    final r = analyzeCalibration(const []);
    expect(r.brierScore, isNull);
    expect(r.bands, isEmpty);
  });
}
```

(Clean up the placeholder line in the first test when writing it — the unscored day is simply `DayRecord(day: DateTime.utc(2026, 6, 5))`.)

- [ ] **Step 2: Run to verify failure**

Run: `cd packages/domain && dart test test/correlation/calibration_test.dart`
Expected: FAIL — `analyzeCalibration` undefined.

- [ ] **Step 3: Implement**

```dart
// packages/domain/lib/src/correlation/calibration.dart
import 'package:equatable/equatable.dart';

import '../types/risk_assessment.dart';
import 'day_record.dart';
import 'wilson_interval.dart';

class BandCalibration extends Equatable {
  final RiskBand band;
  final WilsonInterval attackRate;
  final int days;
  const BandCalibration({required this.band, required this.attackRate, required this.days});
  @override
  List<Object?> get props => [band, attackRate, days];
}

class CalibrationReport extends Equatable {
  /// Bands with at least one scored day, ordered low → veryHigh.
  final List<BandCalibration> bands;
  /// Mean squared error of (score/100) vs attack outcome. Null when no scored days.
  final double? brierScore;
  final int scoredDays;
  const CalibrationReport({required this.bands, required this.brierScore, required this.scoredDays});
  @override
  List<Object?> get props => [bands, brierScore, scoredDays];
}

/// Prospective forecasts only by default: backfilled assessments were computed
/// with hindsight data and would flatter the model.
CalibrationReport analyzeCalibration(List<DayRecord> days, {bool includeBackfilled = false}) {
  final scored = days
      .where((d) => d.score != null && d.band != null && (includeBackfilled || !d.backfilled))
      .toList();
  final bands = <BandCalibration>[];
  for (final band in RiskBand.values) {
    final inBand = scored.where((d) => d.band == band).toList();
    if (inBand.isEmpty) continue;
    bands.add(BandCalibration(
      band: band,
      attackRate: WilsonInterval.compute(
          successes: inBand.where((d) => d.hadAttack).length, trials: inBand.length),
      days: inBand.length,
    ));
  }
  double? brier;
  if (scored.isNotEmpty) {
    brier = scored.fold<double>(0, (acc, d) {
          final p = d.score! / 100.0;
          final o = d.hadAttack ? 1.0 : 0.0;
          return acc + (p - o) * (p - o);
        }) /
        scored.length;
  }
  return CalibrationReport(bands: bands, brierScore: brier, scoredDays: scored.length);
}
```

Export from `domain.dart`: `export 'src/correlation/calibration.dart';`

- [ ] **Step 4: Run test to verify pass** — `cd packages/domain && dart test`
- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat(domain): calibration analyzer (per-band attack rates + Brier score)"`

### Task 4: Calibration card in Insights (UI)

**Files:**
- Create: `lib/ui/insights/calibration_card.dart`
- Create: `lib/state/calibration_provider.dart`
- Modify: `lib/ui/insights/insights_screen.dart` (add card to `_Body`, above correlation cards)
- Test: `test/ui/insights/calibration_card_test.dart`

**Interfaces:**
- Consumes: `dayTimelineProvider` (Task 2), `analyzeCalibration` (Task 3).
- Produces: `calibrationReportProvider: FutureProvider<CalibrationReport>`; `CalibrationCard` widget.

- [ ] **Step 1: Provider with prospective-first fallback**

```dart
// lib/state/calibration_provider.dart
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'correlation_provider.dart';

/// Prefer prospective (non-backfilled) forecasts; fall back to including
/// backfilled ones until 14 prospective days exist, flagged via [usedBackfilled].
typedef CalibrationView = ({CalibrationReport report, bool usedBackfilled});

final calibrationReportProvider = FutureProvider<CalibrationView>((ref) async {
  final timeline = await ref.watch(dayTimelineProvider.future);
  final prospective = analyzeCalibration(timeline);
  if (prospective.scoredDays >= 14) return (report: prospective, usedBackfilled: false);
  return (report: analyzeCalibration(timeline, includeBackfilled: true), usedBackfilled: true);
});
```

- [ ] **Step 2: Write the failing widget test**

```dart
// test/ui/insights/calibration_card_test.dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/state/calibration_provider.dart';
import 'package:migraine_forecast/ui/insights/calibration_card.dart';

void main() {
  Widget host(CalibrationView view) => ProviderScope(
        overrides: [calibrationReportProvider.overrideWith((ref) async => view)],
        child: const MaterialApp(home: Scaffold(body: CalibrationCard())),
      );

  testWidgets('shows per-band observed rates and day counts', (tester) async {
    final report = CalibrationReport(
      bands: [
        BandCalibration(band: RiskBand.low,
            attackRate: WilsonInterval.compute(successes: 1, trials: 20), days: 20),
        BandCalibration(band: RiskBand.high,
            attackRate: WilsonInterval.compute(successes: 4, trials: 10), days: 10),
      ],
      brierScore: 0.12, scoredDays: 30,
    );
    await tester.pumpWidget(host((report: report, usedBackfilled: false)));
    await tester.pumpAndSettle();
    expect(find.text('Forecast accuracy'), findsOneWidget);
    expect(find.textContaining('40%'), findsOneWidget); // high-band observed rate
    expect(find.textContaining('5%'), findsOneWidget);  // low-band observed rate
    expect(find.textContaining('30 days'), findsOneWidget);
  });

  testWidgets('flags when backfilled days were included', (tester) async {
    final report = CalibrationReport(
        bands: const [], brierScore: null, scoredDays: 0);
    await tester.pumpWidget(host((report: report, usedBackfilled: true)));
    await tester.pumpAndSettle();
    expect(find.textContaining('reconstructed'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run to verify failure** — `flutter test test/ui/insights/calibration_card_test.dart` → FAIL (no widget).

- [ ] **Step 4: Implement the card**

```dart
// lib/ui/insights/calibration_card.dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/calibration_provider.dart';

const _bandLabels = {
  RiskBand.low: 'Low', RiskBand.moderate: 'Moderate',
  RiskBand.high: 'High', RiskBand.veryHigh: 'Very high',
};

class CalibrationCard extends ConsumerWidget {
  const CalibrationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(calibrationReportProvider);
    return view.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (v) {
        final r = v.report;
        if (r.scoredDays == 0 && !v.usedBackfilled) return const SizedBox.shrink();
        final theme = Theme.of(context);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Forecast accuracy', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('How often attacks actually followed each forecast band '
                    '(${r.scoredDays} days).', style: theme.textTheme.bodySmall),
                const SizedBox(height: 12),
                for (final b in r.bands) _BandRow(b: b),
                if (v.usedBackfilled)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Includes reconstructed (backfilled) days — accuracy will be '
                      'measured on live forecasts as more days accumulate.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BandRow extends StatelessWidget {
  final BandCalibration b;
  const _BandRow({required this.b});

  @override
  Widget build(BuildContext context) {
    final pct = (b.attackRate.point * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 84, child: Text(_bandLabels[b.band]!)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: b.attackRate.point, minHeight: 8),
          ),
        ),
        const SizedBox(width: 8),
        Text('$pct% · ${b.days}d', style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}
```

Wire into `insights_screen.dart` `_Body` above the correlation cards: `const CalibrationCard(),`. Match the band row colors to the existing band color mapping if `_Body`/`risk_display` exposes one (check `lib/ui/today/risk_display.dart` for the band→color function and reuse it for the progress indicator color).

- [ ] **Step 5: Run tests + commit**

Run: `flutter test test/ui/insights/`
```bash
git add -A && git commit -m "feat(insights): forecast-accuracy calibration card"
```

---

## Phase C — Insights depth

### Task 5: Streaks + time-of-day analysis (domain + card)

**Files:**
- Create: `packages/domain/lib/src/correlation/attack_patterns.dart`
- Modify: `packages/domain/lib/domain.dart` (export)
- Create: `lib/ui/insights/patterns_card.dart`
- Modify: `lib/ui/insights/insights_screen.dart`
- Test: `packages/domain/test/correlation/attack_patterns_test.dart`, `test/ui/insights/patterns_card_test.dart`

**Interfaces:**
- Consumes: `Attack` (domain), `recentAttacksProvider` (existing, `lib/state/insights_eligibility_provider.dart` — verify its export location with `grep -rn recentAttacksProvider lib/state`).
- Produces: `StreakStats computeStreaks({required Set<DateTime> attackDays, required DateTime today, required DateTime windowStart})`; `Map<DayPart, int> attackStartsByDayPart(Iterable<Attack> attacks)`; `enum DayPart { night, morning, afternoon, evening }`.

- [ ] **Step 1: Write the failing domain test**

```dart
// packages/domain/test/correlation/attack_patterns_test.dart
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  test('current streak counts days since last attack; longest scans window', () {
    final s = computeStreaks(
      attackDays: {DateTime.utc(2026, 7, 1), DateTime.utc(2026, 7, 5)},
      today: DateTime.utc(2026, 7, 9),
      windowStart: DateTime.utc(2026, 6, 25),
    );
    expect(s.currentAttackFreeDays, 4);   // Jul 6,7,8,9
    expect(s.longestAttackFreeDays, 6);   // Jun 25–30
  });

  test('no attacks: whole window is the streak', () {
    final s = computeStreaks(
        attackDays: {}, today: DateTime.utc(2026, 7, 9),
        windowStart: DateTime.utc(2026, 7, 1));
    expect(s.currentAttackFreeDays, 9);
    expect(s.longestAttackFreeDays, 9);
  });

  test('day parts bucket attack start hours (local wall-clock of stored time)', () {
    final m = attackStartsByDayPart([
      Attack(startedAt: DateTime.utc(2026, 7, 1, 7), severity: 5),   // morning 6–12
      Attack(startedAt: DateTime.utc(2026, 7, 2, 13), severity: 5),  // afternoon 12–18
      Attack(startedAt: DateTime.utc(2026, 7, 3, 23), severity: 5),  // evening 18–24
      Attack(startedAt: DateTime.utc(2026, 7, 4, 2), severity: 5),   // night 0–6
      Attack(startedAt: DateTime.utc(2026, 7, 5, 8), severity: 5),   // morning
    ]);
    expect(m[DayPart.morning], 2);
    expect(m[DayPart.afternoon], 1);
    expect(m[DayPart.evening], 1);
    expect(m[DayPart.night], 1);
  });
}
```

- [ ] **Step 2: Run to verify failure** — `cd packages/domain && dart test test/correlation/attack_patterns_test.dart` → FAIL.

- [ ] **Step 3: Implement**

```dart
// packages/domain/lib/src/correlation/attack_patterns.dart
import 'package:equatable/equatable.dart';
import '../types/journal.dart';

class StreakStats extends Equatable {
  final int currentAttackFreeDays;
  final int longestAttackFreeDays;
  const StreakStats({required this.currentAttackFreeDays, required this.longestAttackFreeDays});
  @override
  List<Object?> get props => [currentAttackFreeDays, longestAttackFreeDays];
}

/// [attackDays] are UTC midnights. [today] and [windowStart] are UTC midnights.
/// The current streak counts attack-free days up to and including [today].
StreakStats computeStreaks({
  required Set<DateTime> attackDays,
  required DateTime today,
  required DateTime windowStart,
}) {
  var current = 0;
  for (var d = today; !d.isBefore(windowStart); d = d.subtract(const Duration(days: 1))) {
    if (attackDays.contains(d)) break;
    current++;
  }
  var longest = 0, run = 0;
  for (var d = windowStart; !d.isAfter(today); d = d.add(const Duration(days: 1))) {
    if (attackDays.contains(d)) {
      run = 0;
    } else {
      run++;
      if (run > longest) longest = run;
    }
  }
  return StreakStats(currentAttackFreeDays: current, longestAttackFreeDays: longest);
}

enum DayPart { night, morning, afternoon, evening }

DayPart dayPartOf(DateTime t) {
  final h = t.hour;
  if (h < 6) return DayPart.night;
  if (h < 12) return DayPart.morning;
  if (h < 18) return DayPart.afternoon;
  return DayPart.evening;
}

Map<DayPart, int> attackStartsByDayPart(Iterable<Attack> attacks) {
  final m = {for (final p in DayPart.values) p: 0};
  for (final a in attacks) {
    m[dayPartOf(a.startedAt)] = m[dayPartOf(a.startedAt)]! + 1;
  }
  return m;
}
```

Export from `domain.dart`. Note: `Attack.startedAt` is stored as the user's logged time; keep bucketing in whatever zone the value carries (UI passes local-converted times if the log screen stores UTC — check `log_attack_screen.dart` storage convention with `grep -n toUtc lib/ui/log/log_attack_screen.dart` and convert in the card if needed so "morning" means the user's morning).

- [ ] **Step 4: Card**

```dart
// lib/ui/insights/patterns_card.dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/insights_eligibility_provider.dart';

const _partLabels = {
  DayPart.night: 'Night', DayPart.morning: 'Morning',
  DayPart.afternoon: 'Afternoon', DayPart.evening: 'Evening',
};

class PatternsCard extends ConsumerWidget {
  const PatternsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attacks = ref.watch(recentAttacksProvider);
    return attacks.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        final now = DateTime.now().toUtc();
        final today = DateTime.utc(now.year, now.month, now.day);
        final attackDays = {
          for (final a in list)
            DateTime.utc(a.startedAt.toUtc().year, a.startedAt.toUtc().month,
                a.startedAt.toUtc().day),
        };
        final streaks = computeStreaks(
            attackDays: attackDays, today: today,
            windowStart: today.subtract(const Duration(days: 90)));
        final parts = attackStartsByDayPart(list.map((a) =>
            Attack(startedAt: a.startedAt.toLocal(), severity: a.severity)));
        final maxPart = parts.values.fold(0, (a, b) => a > b ? a : b);
        final theme = Theme.of(context);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Patterns', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('${streaks.currentAttackFreeDays} days attack-free '
                    '(longest in 90 days: ${streaks.longestAttackFreeDays})'),
                const SizedBox(height: 12),
                for (final p in DayPart.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      SizedBox(width: 84, child: Text(_partLabels[p]!,
                          style: theme.textTheme.bodySmall)),
                      Expanded(
                        child: LinearProgressIndicator(
                            value: maxPart == 0 ? 0 : parts[p]! / maxPart,
                            minHeight: 6),
                      ),
                      const SizedBox(width: 8),
                      Text('${parts[p]}', style: theme.textTheme.bodySmall),
                    ]),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

Widget test (`test/ui/insights/patterns_card_test.dart`): override `recentAttacksProvider` with two attacks (one 7am local, one 13pm local, different days), pump card, expect `find.textContaining('days attack-free')` and row counts `find.text('1')` appearing for morning and afternoon. Follow the override style used in `test/ui/insights/insights_screen_test.dart`.

- [ ] **Step 5: Run `flutter test test/ui/insights/ && cd packages/domain && dart test`, wire card into `insights_screen.dart` `_Body`, commit**

```bash
git add -A && git commit -m "feat(insights): streaks and time-of-day patterns card"
```

### Task 6: Weekday-pattern card (uses the generalized kernel)

**Files:**
- Create: `lib/ui/insights/weekday_card.dart`
- Modify: `lib/state/correlation_provider.dart` (add `weekdayResultsProvider`)
- Modify: `lib/ui/insights/insights_screen.dart`
- Test: `test/state/weekday_results_provider_test.dart`, `test/ui/insights/weekday_card_test.dart`

**Interfaces:**
- Consumes: `dayTimelineProvider`, `Exposure.weekday`, `buildCohort`, `CorrelationAnalyzer`.
- Produces: `weekdayResultsProvider: FutureProvider<List<CorrelationResult>>` (7 results, Monday-first, exposureId `weekday_1`…`weekday_7`).

- [ ] **Step 1: Failing provider test** — seed a `ProviderContainer` overriding `dayTimelineProvider` with 8 weeks of synthetic `DayRecord`s where every Monday has an attack; expect the Monday result classified `personalHit` and the other six not:

```dart
// test/state/weekday_results_provider_test.dart
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/state/correlation_provider.dart';

void main() {
  test('flags a weekday with concentrated attacks as personalHit', () async {
    final days = <DayRecord>[
      for (var i = 0; i < 56; i++)
        DayRecord(
          day: DateTime.utc(2026, 5, 4).add(Duration(days: i)), // 2026-05-04 is a Monday
          hadAttack: DateTime.utc(2026, 5, 4).add(Duration(days: i)).weekday ==
              DateTime.monday,
        ),
    ];
    final container = ProviderContainer(overrides: [
      dayTimelineProvider.overrideWith((ref) async => days),
    ]);
    addTearDown(container.dispose);
    final results = await container.read(weekdayResultsProvider.future);
    expect(results, hasLength(7));
    final monday = results.firstWhere((r) => r.exposureId == 'weekday_1');
    expect(monday.classification, CorrelationClassification.personalHit);
    expect(
        results.where((r) => r.classification == CorrelationClassification.personalHit),
        hasLength(1));
  });
}
```

- [ ] **Step 2: Run to verify failure**, then implement:

```dart
// append to lib/state/correlation_provider.dart
final weekdayResultsProvider = FutureProvider<List<CorrelationResult>>((ref) async {
  final timeline = await ref.watch(dayTimelineProvider.future);
  return [
    for (var wd = DateTime.monday; wd <= DateTime.sunday; wd++)
      const CorrelationAnalyzer().analyze(buildCohort(timeline, Exposure.weekday(wd))),
  ];
});
```

- [ ] **Step 3: Card** — `weekday_card.dart` mirrors `_BandRow` structure from Task 4: seven rows `Mon…Sun`, bar = `firedAttackRate.point`, suffix `${(rate*100).round()}%`; when a weekday is `personalHit`, bold the label and append a chip `Text('pattern')`. Render `SizedBox.shrink()` unless at least one weekday has `daysFiredTotal >= 4`. Widget test: override `weekdayResultsProvider` with a crafted list (one personalHit Monday), expect `find.text('Mon')` bolded row and `find.text('pattern')` findsOneWidget.

- [ ] **Step 4: Wire into `insights_screen.dart`, run `flutter test test/state/weekday_results_provider_test.dart test/ui/insights/`**

- [ ] **Step 5: Commit** — `git commit -am "feat(insights): weekday attack-pattern card via generalized exposures"`

### Task 7: Trigger-interaction analysis (domain + card)

**Files:**
- Create: `packages/domain/lib/src/correlation/interaction_analyzer.dart`
- Modify: `packages/domain/lib/domain.dart`
- Create: `lib/ui/insights/interaction_card.dart`
- Modify: `lib/state/correlation_provider.dart` (add `interactionResultsProvider`)
- Modify: `lib/ui/insights/insights_screen.dart`
- Test: `packages/domain/test/correlation/interaction_analyzer_test.dart`

**Interfaces:**
- Consumes: `DayRecord`, `Exposure`, `buildCohort`, `CorrelationAnalyzer`.
- Produces: `List<InteractionResult> analyzeInteractions(List<DayRecord> days, List<String> moduleIds, {int minSingleFiredDays = 10, int minPairFiredDays = 7, int maxResults = 3})`; `InteractionResult { String idA, idB; CorrelationResult pair; double singleLiftA, singleLiftB; }`.

- [ ] **Step 1: Failing test**

```dart
// packages/domain/test/correlation/interaction_analyzer_test.dart
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  test('surfaces a pair whose joint lift beats both singles', () {
    // 80 days: A fires 40, B fires 40, overlap 20. Attacks: 8 of the 20
    // overlap days, 1 day with A alone, 1 with B alone, 1 with neither.
    final days = <DayRecord>[];
    for (var i = 0; i < 80; i++) {
      final a = i < 40;
      final b = i >= 20 && i < 60;
      final attack = (a && b && i % 3 != 0 && i < 44) || i == 0 || i == 45 || i == 70;
      days.add(DayRecord(
        day: DateTime.utc(2026, 4, 1).add(Duration(days: i)),
        firedModuleIds: {if (a) 'a', if (b) 'b'},
        hadAttack: attack,
      ));
    }
    final out = analyzeInteractions(days, ['a', 'b']);
    expect(out, hasLength(1));
    expect(out.single.pair.exposureId, 'a+b');
    expect(out.single.pair.classification, CorrelationClassification.personalHit);
    expect(out.single.pair.lift.point, greaterThan(out.single.singleLiftA));
    expect(out.single.pair.lift.point, greaterThan(out.single.singleLiftB));
  });

  test('skips pairs below support thresholds', () {
    final days = [
      for (var i = 0; i < 30; i++)
        DayRecord(
            day: DateTime.utc(2026, 4, 1).add(Duration(days: i)),
            firedModuleIds: {if (i < 3) 'a', if (i < 3) 'b'},
            hadAttack: i < 3),
    ];
    expect(analyzeInteractions(days, ['a', 'b']), isEmpty);
  });
}
```

(If the crafted attack pattern in the first test doesn't produce a `personalHit`, adjust the attack assignments until the pair cohort is ≥8 attacks in ~20 fired days vs ~4% baseline — the point of the fixture is a strong joint signal with weak singles. Verify the fixture numbers by hand before writing the implementation.)

- [ ] **Step 2: Run to verify failure**, then implement:

```dart
// packages/domain/lib/src/correlation/interaction_analyzer.dart
import 'correlation_analyzer.dart';
import 'day_record.dart';
import 'exposure.dart';

class InteractionResult {
  final String idA;
  final String idB;
  final CorrelationResult pair;
  final double singleLiftA;
  final double singleLiftB;
  const InteractionResult({
    required this.idA, required this.idB, required this.pair,
    required this.singleLiftA, required this.singleLiftB,
  });
}

/// Pairwise "A and B fired the same day" exposures. Deliberately conservative:
/// support floors + the pair must be a personalHit AND beat both single lifts,
/// and at most [maxResults] are returned — this is pattern-surfacing, not
/// hypothesis testing across dozens of comparisons.
List<InteractionResult> analyzeInteractions(
  List<DayRecord> days,
  List<String> moduleIds, {
  int minSingleFiredDays = 10,
  int minPairFiredDays = 7,
  int maxResults = 3,
}) {
  const analyzer = CorrelationAnalyzer();
  final singles = <String, CorrelationResult>{};
  for (final id in moduleIds) {
    final c = buildCohort(days, Exposure.moduleFired(id));
    if (c.daysFiredTotal >= minSingleFiredDays) singles[id] = analyzer.analyze(c);
  }
  final ids = singles.keys.toList();
  final out = <InteractionResult>[];
  for (var i = 0; i < ids.length; i++) {
    for (var j = i + 1; j < ids.length; j++) {
      final cohort = buildCohort(days,
          Exposure.both(Exposure.moduleFired(ids[i]), Exposure.moduleFired(ids[j])));
      if (cohort.daysFiredTotal < minPairFiredDays) continue;
      final pair = analyzer.analyze(cohort);
      final la = singles[ids[i]]!.lift.point;
      final lb = singles[ids[j]]!.lift.point;
      if (pair.classification != CorrelationClassification.personalHit) continue;
      if (pair.lift.point <= la || pair.lift.point <= lb) continue;
      out.add(InteractionResult(
          idA: ids[i], idB: ids[j], pair: pair, singleLiftA: la, singleLiftB: lb));
    }
  }
  out.sort((a, b) => b.pair.lift.point.compareTo(a.pair.lift.point));
  return out.take(maxResults).toList();
}
```

- [ ] **Step 3: Provider + card**

```dart
// append to lib/state/correlation_provider.dart
final interactionResultsProvider = FutureProvider<List<InteractionResult>>((ref) async {
  final timeline = await ref.watch(dayTimelineProvider.future);
  return analyzeInteractions(timeline, _moduleIds);
});
```

`interaction_card.dart`: for each result render a card row — title `'${displayName(idA)} + ${displayName(idB)}'` (reuse the module display-name mapping used by `correlation_card.dart` — check how it maps ids to labels and use the same helper), body `'Attacks on ${(pair.firedAttackRate.point*100).round()}% of days when both fired — more than either alone. Pattern worth watching, not proof.'`. Hide the whole card when the list is empty.

- [ ] **Step 4: Run `cd packages/domain && dart test && cd ../.. && flutter test test/ui/insights/`, wire into insights screen**
- [ ] **Step 5: Commit** — `git commit -am "feat(insights): trigger-interaction analysis (joint exposures)"`

---

## Phase D — Next-morning check-in

### Task 8: DayCheckins table (schema v13) + repo

**Files:**
- Modify: `lib/data/database.dart` (table + migration)
- Create: `lib/data/repos/checkin_repo.dart`
- Test: `test/data/checkin_repo_test.dart`, extend `test/data/database_migration_test.dart`

**Interfaces:**
- Produces: table `DayCheckins { DateTime day (PK, UTC midnight); bool hadAttack; DateTime answeredAt; }`; `CheckinRepo { Future<DayCheckinRow?> forDay(DateTime day); Future<void> record({required DateTime day, required bool hadAttack, required DateTime at}); }` (use the drift-generated row type name). Tasks 9 and (optionally) the timeline consume it.

- [ ] **Step 1: Failing repo test**

```dart
// test/data/checkin_repo_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart';
import 'package:migraine_forecast/data/repos/checkin_repo.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  test('record then read back; unanswered day is null; re-record replaces', () async {
    final repo = CheckinRepo(db);
    final day = DateTime.utc(2026, 7, 8);
    expect(await repo.forDay(day), isNull);
    await repo.record(day: day, hadAttack: false, at: DateTime.utc(2026, 7, 9, 9));
    expect((await repo.forDay(day))!.hadAttack, isFalse);
    await repo.record(day: day, hadAttack: true, at: DateTime.utc(2026, 7, 9, 10));
    expect((await repo.forDay(day))!.hadAttack, isTrue);
  });
}
```

- [ ] **Step 2: Run to verify failure**, then implement. In `database.dart`:

```dart
/// Next-morning check-in answers ("did yesterday's high-risk day bring a
/// migraine?"). One row per asked day; "no" answers are real negative data.
class DayCheckins extends Table {
  DateTimeColumn get day => dateTime()();
  BoolColumn get hadAttack => boolean()();
  DateTimeColumn get answeredAt => dateTime()();
  @override
  Set<Column> get primaryKey => {day};
}
```

Add `DayCheckins` to the `@DriftDatabase(tables: [...])` list, bump `schemaVersion` to 13, add migration:

```dart
if (from < 13) {
  await m.createTable(dayCheckins);
}
```

Run `dart run build_runner build --delete-conflicting-outputs`. Repo:

```dart
// lib/data/repos/checkin_repo.dart
import 'package:drift/drift.dart';
import '../database.dart';

class CheckinRepo {
  final AppDatabase _db;
  CheckinRepo(this._db);

  Future<DayCheckin?> forDay(DateTime day) =>
      (_db.select(_db.dayCheckins)..where((t) => t.day.equals(day))).getSingleOrNull();

  Future<void> record({required DateTime day, required bool hadAttack, required DateTime at}) =>
      _db.into(_db.dayCheckins).insert(
            DayCheckinsCompanion.insert(day: day, hadAttack: hadAttack, answeredAt: at),
            mode: InsertMode.insertOrReplace,
          );
}
```

(Confirm the generated row class name — drift singularizes `DayCheckins` → `DayCheckin`; adjust to what `database.g.dart` emits.)

- [ ] **Step 3: Migration test** — follow the existing v-to-v pattern in `test/data/database_migration_test.dart` to assert a v12 database upgrades cleanly to 13 and the table accepts inserts.
- [ ] **Step 4: Export/import** — add `day_checkins` to `lib/data/repos/export_repo.dart` and `import_repo.dart` following the exact pattern used there for `periods` (small table, same shape handling).
- [ ] **Step 5: Run `flutter test test/data/`, commit** — `git commit -am "feat(data): day check-ins table (schema v13) + repo, export/import"`

### Task 9: Check-in prompt provider + Today-screen card

**Files:**
- Create: `lib/state/checkin_provider.dart`
- Create: `lib/ui/today/checkin_card.dart`
- Modify: `lib/ui/today/today_screen.dart` (card below the risk display)
- Modify: `lib/ui/log/log_attack_screen.dart` (optional `initialStartedAt` param)
- Test: `test/state/checkin_provider_test.dart`, `test/ui/today/checkin_card_test.dart`

**Interfaces:**
- Consumes: `CheckinRepo` (Task 8), `assessmentRepoProvider` (existing — it must expose a lookup by (day, horizon); check `lib/data/repos/assessment_repository.dart` for the existing `forDay`-style method and reuse; if only `dayAssessmentProvider` exists, use that), `recentAttacksProvider`.
- Produces: `checkinPromptProvider: FutureProvider<DateTime?>` — non-null (yesterday UTC midnight) when yesterday's today-horizon band was high/veryHigh AND no attack was logged yesterday AND no check-in row exists.

- [ ] **Step 1: Failing provider test** — real in-memory DB, seed a high-band assessment for yesterday, expect prompt; then record a check-in and expect null; then variant with an attack logged yesterday → null. Use `ProviderContainer` with `databaseProvider` overridden to `AppDatabase.memory()` (follow the pattern in `test/state/risk_assessment_provider_test.dart`).

- [ ] **Step 2: Implement**

```dart
// lib/state/checkin_provider.dart
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repos/checkin_repo.dart';
import 'insights_eligibility_provider.dart';
import 'providers.dart';

final checkinRepoProvider = Provider<CheckinRepo>((ref) => CheckinRepo(ref.watch(databaseProvider)));

/// Yesterday's UTC midnight when we should ask "did yesterday bring a migraine?",
/// else null. Asks only after high/veryHigh days, once, and only when no attack
/// was already logged for that day.
final checkinPromptProvider = FutureProvider<DateTime?>((ref) async {
  final attacks = await ref.watch(recentAttacksProvider.future);
  final now = DateTime.now().toUtc();
  final yesterday = DateTime.utc(now.year, now.month, now.day)
      .subtract(const Duration(days: 1));

  final ass = await ref.watch(assessmentRepoProvider)
      .forDay(yesterday, horizon: RiskHorizon.today); // adapt to actual repo API
  if (ass == null) return null;
  if (ass.band != RiskBand.high && ass.band != RiskBand.veryHigh) return null;

  final attackYesterday = attacks.any((a) {
    final d = a.startedAt.toUtc();
    return DateTime.utc(d.year, d.month, d.day) == yesterday;
  });
  if (attackYesterday) return null;

  if (await ref.watch(checkinRepoProvider).forDay(yesterday) != null) return null;
  return yesterday;
});
```

(Adapt the assessment lookup line to `assessment_repository.dart`'s real API — read it first; if there is no by-day getter, add `Future<RiskAssessment?> forDay(DateTime day, {required RiskHorizon horizon})` there with a one-query implementation and a test alongside the existing repository tests.)

- [ ] **Step 3: Card**

```dart
// lib/ui/today/checkin_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/checkin_provider.dart';
import '../../state/insights_eligibility_provider.dart';
import '../log/log_attack_screen.dart';

class CheckinCard extends ConsumerWidget {
  const CheckinCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompt = ref.watch(checkinPromptProvider);
    final day = prompt.valueOrNull;
    if (day == null) return const SizedBox.shrink();
    return Card(
      key: const Key('checkin-card'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yesterday was a high-risk day',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('Did you get a migraine?'),
            const SizedBox(height: 8),
            Row(children: [
              FilledButton(
                key: const Key('checkin-yes'),
                onPressed: () async {
                  await ref.read(checkinRepoProvider).record(
                      day: day, hadAttack: true, at: DateTime.now().toUtc());
                  ref.invalidate(checkinPromptProvider);
                  if (!context.mounted) return;
                  await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => LogAttackScreen(
                          initialStartedAt: day.add(const Duration(hours: 12)))));
                  ref.invalidate(recentAttacksProvider);
                },
                child: const Text('Yes'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                key: const Key('checkin-no'),
                onPressed: () async {
                  await ref.read(checkinRepoProvider).record(
                      day: day, hadAttack: false, at: DateTime.now().toUtc());
                  ref.invalidate(checkinPromptProvider);
                },
                child: const Text('No'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
```

Add `initialStartedAt` to `LogAttackScreen`: optional `DateTime?` constructor param that seeds the existing start-time field's initial value (read the screen first; it already has a started-at state — default it to `initialStartedAt ?? now`). Navigation: match how `today_screen.dart` currently opens the log screen (it may route via go_router — if so, pass the date as an extra instead of a direct `MaterialPageRoute`; follow the existing navigation style).

- [ ] **Step 4: Widget test** — override `checkinPromptProvider` → yesterday; tap `checkin-no`; verify repo write via a recorded fake `CheckinRepo` (override `checkinRepoProvider`). Assert card hidden when provider yields null.
- [ ] **Step 5: Run `flutter test test/ui/today/ test/state/`, commit** — `git commit -am "feat(today): next-morning check-in card"`

### Task 10: Morning check-in notification

**Files:**
- Modify: `lib/services/notification_service.dart` (add `scheduleCheckIn`)
- Modify: `lib/state/risk_assessment_provider.dart` (`_compute` of the today notifier: schedule when band ≥ high)
- Modify: `lib/main.dart` (timezone init — check whether `tz.initializeTimeZones()` already runs; `timezone` is a dependency)
- Test: `test/services/notification_checkin_test.dart`

**Interfaces:**
- Produces: `NotificationService.scheduleCheckIn({required int notificationId, required DateTime fireAtLocal, required String title, required String body})` using `zonedSchedule` with `AndroidScheduleMode.inexactAllowWhileIdle` (avoids the exact-alarm permission).

- [ ] **Step 1: Failing test** — construct `NotificationService` with a mocktail-mocked `FlutterLocalNotificationsPlugin` (existing tests in `test/services/` show the pattern); call `scheduleCheckIn`; verify `zonedSchedule` called with a `TZDateTime` matching 9:00 local next day and inexact mode.

- [ ] **Step 2: Implement**

```dart
// additions to notification_service.dart
import 'package:timezone/timezone.dart' as tz;

Future<void> scheduleCheckIn({
  required int notificationId,
  required DateTime fireAtLocal,
  required String title,
  required String body,
}) async {
  await _plugin.zonedSchedule(
    notificationId,
    title,
    body,
    tz.TZDateTime.from(fireAtLocal, tz.local),
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'checkin', 'Morning check-ins',
        channelDescription: 'Asks how a high-risk day went',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  );
}
```

Timezone init in `main.dart` (skip if plan-4 code already does it — `grep -rn initializeTimeZones lib`):

```dart
import 'package:timezone/data/latest.dart' as tzdata;
// in main(): tzdata.initializeTimeZones();
```

In `RiskAssessmentNotifier._compute`, after `maybeNotify`:

```dart
if (enabled && (ass.band == RiskBand.high || ass.band == RiskBand.veryHigh)) {
  final tomorrow9 = DateTime(now.year, now.month, now.day + 1, 9);
  await ref.read(notificationServiceProvider).scheduleCheckIn(
        notificationId: Object.hash('checkin', today.millisecondsSinceEpoch) & 0x7fffffff,
        fireAtLocal: tomorrow9,
        title: 'How did yesterday go?',
        body: 'Yesterday was high risk — log whether you got a migraine.',
      );
}
```

(Stable id per day → OS replaces on recompute instead of stacking. Confirm `notificationServiceProvider` name in `lib/state/providers.dart`.) Web: `flutter_local_notifications` has no web implementation — guard with `if (!kIsWeb)` matching how `high_risk_notifier` call sites handle web (check first; if the service is already no-op-safe on web, skip the guard).

- [ ] **Step 3: Run `flutter test test/services/`, commit** — `git commit -am "feat(notifications): schedule next-morning check-in after high-risk days"`

---

## Phase E — Multi-day outlook

### Task 11: 7-day fetch + `RiskHorizon.outlook` + outlook provider

**Files:**
- Modify: `lib/data/sources/open_meteo/open_meteo_url_builder.dart` (`forecast_days`: `'3'` → `'7'`; air-quality `'2'` → `'7'`)
- Modify: `packages/domain/lib/src/types/risk_assessment.dart` (`enum RiskHorizon { today, tomorrow, outlook }`)
- Create: `lib/state/outlook_provider.dart`
- Test: `test/state/outlook_provider_test.dart`; update `test/data/sources/...` URL-builder expectations if they assert `forecast_days=3`

**Interfaces:**
- Consumes: `contextBuilderProvider`, `rulesConfigProvider`, `riskEngineProvider`, `triggerFlagsProvider` (mirror `TomorrowRiskAssessmentNotifier._compute`).
- Produces: `outlookProvider: FutureProvider<List<RiskAssessment>>` — days d+2 … d+6, horizon `RiskHorizon.outlook`, **never persisted and never passed to HighRiskNotifier**.

- [ ] **Step 1: Enum + URL params.** Add `outlook` to `RiskHorizon`. Then `grep -rn 'RiskHorizon\.' lib packages test | grep -v '\.today\|\.tomorrow\|\.outlook\|\.name\|\.values'` and `grep -rn 'switch.*horizon' lib packages` — fix any exhaustive switch (`flutter analyze` also flags them). Known: `HighRiskNotifier._format` uses a ternary (safe — outlook assessments never reach it, but add `assert(ass.horizon != RiskHorizon.outlook)` at the top of `maybeNotify` to enforce the invariant). Check `assessment_repository.dart` horizon parsing: reading old rows is unaffected; add a guard in `save` to throw `ArgumentError` on outlook (persisting outlook rows would pollute correlation/calibration timelines).

- [ ] **Step 2: Failing provider test** — override the fake sources exactly like `test/state/risk_assessment_provider_test.dart` sets up its container (fake weather with 7-day series, fake location, memory DB); read `outlookProvider`; expect 5 assessments with `targetDate` = today+2…today+6, all `horizon == RiskHorizon.outlook`, and **no rows written** to `riskAssessments` for those dates.

- [ ] **Step 3: Implement**

```dart
// lib/state/outlook_provider.dart
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'trigger_flags_provider.dart';

/// Risk for days d+2..d+6. Computed on demand, never persisted: stored
/// assessments feed correlation + calibration, which must only contain
/// today/tomorrow rows. The first ContextBuilder.build fetches the 7-day
/// series once; the remaining days hit the coverage-aware weather cache.
final outlookProvider = FutureProvider<List<RiskAssessment>>((ref) async {
  await ref.watch(triggerFlagsProvider.future);
  final builder = ref.read(contextBuilderProvider);
  final cfg = await ref.read(rulesConfigProvider.future);
  final engine = ref.read(riskEngineProvider);
  final now = DateTime.now();
  final today = DateTime.utc(now.year, now.month, now.day);
  final out = <RiskAssessment>[];
  for (var i = 2; i <= 6; i++) {
    final ctx = await builder.build(now: now.toUtc(), target: today.add(Duration(days: i)));
    out.add(engine.evaluate(ctx, cfg, horizon: RiskHorizon.outlook));
  }
  return out;
});
```

- [ ] **Step 4: Run `flutter test test/state/ test/data/ && cd packages/domain && dart test`** — fix any URL-builder fixture assertions (`grep -rn forecast_days test`).
- [ ] **Step 5: Commit** — `git commit -am "feat(outlook): 7-day weather fetch and on-demand d+2..d+6 risk"`

### Task 12: Outlook strip on Today + generalized future-day detail

**Files:**
- Create: `lib/ui/today/outlook_strip.dart`
- Modify: `lib/ui/today/today_screen.dart` (strip below `TomorrowTile`)
- Modify: `lib/ui/today/tomorrow_detail_screen.dart` (accept an arbitrary future assessment)
- Test: `test/ui/today/outlook_strip_test.dart`

**Interfaces:**
- Consumes: `outlookProvider` (Task 11), band color mapping from `risk_display.dart`.
- Produces: `OutlookStrip` widget; `TomorrowDetailScreen` gains an optional way to display a non-tomorrow day (read the file first — it likely watches `tomorrowRiskAssessmentProvider`; refactor to accept an optional `RiskAssessment assessment` constructor param that bypasses the provider, and derive the title from `targetDate` weekday via `DateFormat.EEEE`).

- [ ] **Step 1: Failing widget test** — override `outlookProvider` with five assessments (scores 10/30/55/80/20); expect five chips showing weekday abbreviations (`DateFormat.E`) and scores; tap one → pushes detail screen showing that weekday name.

- [ ] **Step 2: Implement**

```dart
// lib/ui/today/outlook_strip.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../state/outlook_provider.dart';
import 'tomorrow_detail_screen.dart';

class OutlookStrip extends ConsumerWidget {
  const OutlookStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outlook = ref.watch(outlookProvider);
    return outlook.when(
      loading: () => const SizedBox(height: 72),
      error: (_, __) => const SizedBox.shrink(),
      data: (days) => SizedBox(
        height: 72,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: days.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final a = days[i];
            return ActionChip(
              key: Key('outlook-${a.targetDate.toIso8601String().substring(0, 10)}'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => TomorrowDetailScreen(assessment: a))),
              label: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(DateFormat.E().format(a.targetDate)),
                Text('${a.score}',
                    style: Theme.of(context).textTheme.titleMedium),
              ]),
            );
          },
        ),
      ),
    );
  }
}
```

Use the same band→color helper as `TomorrowTile` for the chip background (read `tomorrow_tile.dart` first and copy its color usage). Match the existing navigation mechanism (go_router `context.push` with the assessment as `extra` if that's how tomorrow-detail is currently routed).

- [ ] **Step 3: Run `flutter test test/ui/today/`, fix `tomorrow_detail_screen` title logic (weekday name for outlook, "Tomorrow" otherwise), commit**

```bash
git commit -am "feat(today): 5-day outlook strip with tappable day detail"
```

---

## Phase F — Medication tracking + MOH warning

### Task 13: Domain — MedicationDose + MohMonitor

**Files:**
- Create: `packages/domain/lib/src/types/medication.dart`
- Create: `packages/domain/lib/src/analysis/moh_monitor.dart`
- Modify: `packages/domain/lib/domain.dart`
- Test: `packages/domain/test/analysis/moh_monitor_test.dart`

**Interfaces:**
- Produces: `enum MedClass { triptan, simpleAnalgesic, combination, preventive, other }`; `MedicationDose { int? id; DateTime at; String name; MedClass medClass; int? reliefRating /* 0 no, 1 some, 2 yes */; }`; `enum MohLevel { none, approaching, exceeded }`; `MohStatus { MohLevel level; MedClass? medClass; int daysUsed; int thresholdDays; }`; `MohStatus assessMoh(List<MedicationDose> doses, DateTime now)`.

- [ ] **Step 1: Failing test**

```dart
// packages/domain/test/analysis/moh_monitor_test.dart
import 'package:domain/domain.dart';
import 'package:test/test.dart';

MedicationDose dose(int day, MedClass c, {String name = 'x'}) => MedicationDose(
    at: DateTime.utc(2026, 6, day, 10), name: name, medClass: c);

void main() {
  final now = DateTime.utc(2026, 6, 30);

  test('10 distinct triptan days in 30d → exceeded (ICHD-3)', () {
    final doses = [for (var d = 1; d <= 10; d++) dose(d, MedClass.triptan)];
    final s = assessMoh(doses, now);
    expect(s.level, MohLevel.exceeded);
    expect(s.medClass, MedClass.triptan);
    expect(s.daysUsed, 10);
    expect(s.thresholdDays, 10);
  });

  test('8 triptan days → approaching (80% of threshold)', () {
    final doses = [for (var d = 1; d <= 8; d++) dose(d, MedClass.triptan)];
    expect(assessMoh(doses, now).level, MohLevel.approaching);
  });

  test('simple analgesics use the 15-day threshold; two doses same day count once', () {
    final doses = [
      for (var d = 1; d <= 12; d++) dose(d, MedClass.simpleAnalgesic),
      dose(1, MedClass.simpleAnalgesic, name: 'second-same-day'),
    ];
    final s = assessMoh(doses, now);
    expect(s.daysUsed, 12);
    expect(s.level, MohLevel.approaching); // ceil(0.8*15)=12
  });

  test('preventives and doses outside 30d are ignored', () {
    final doses = [
      for (var d = 1; d <= 20; d++) dose(d, MedClass.preventive),
      MedicationDose(at: DateTime.utc(2026, 4, 1), name: 'old', medClass: MedClass.triptan),
    ];
    expect(assessMoh(doses, now).level, MohLevel.none);
  });
}
```

- [ ] **Step 2: Run to verify failure**, then implement:

```dart
// packages/domain/lib/src/types/medication.dart
import 'package:equatable/equatable.dart';

enum MedClass { triptan, simpleAnalgesic, combination, preventive, other }

class MedicationDose extends Equatable {
  final int? id;
  final DateTime at;
  final String name;
  final MedClass medClass;
  /// 0 = didn't help, 1 = helped some, 2 = helped. Null = not rated.
  final int? reliefRating;
  const MedicationDose({
    this.id, required this.at, required this.name,
    required this.medClass, this.reliefRating,
  });
  @override
  List<Object?> get props => [id, at, name, medClass, reliefRating];
}
```

```dart
// packages/domain/lib/src/analysis/moh_monitor.dart
import '../types/medication.dart';

enum MohLevel { none, approaching, exceeded }

class MohStatus {
  final MohLevel level;
  final MedClass? medClass;
  final int daysUsed;
  final int thresholdDays;
  const MohStatus({required this.level, this.medClass,
      this.daysUsed = 0, this.thresholdDays = 0});
}

/// Rolling 30-day approximation of the ICHD-3 medication-overuse-headache
/// criteria: ≥10 days/month for triptans/combination analgesics, ≥15 days/month
/// for simple analgesics (ICHD-3 §8.2). "Approaching" fires at 80% of threshold.
/// Preventives never count.
MohStatus assessMoh(List<MedicationDose> doses, DateTime now) {
  const thresholds = {
    MedClass.triptan: 10,
    MedClass.combination: 10,
    MedClass.simpleAnalgesic: 15,
    MedClass.other: 15,
  };
  final cutoff = now.subtract(const Duration(days: 30));
  MohStatus worst = const MohStatus(level: MohLevel.none);
  for (final entry in thresholds.entries) {
    final days = <DateTime>{
      for (final d in doses)
        if (d.medClass == entry.key && !d.at.isBefore(cutoff))
          DateTime.utc(d.at.year, d.at.month, d.at.day),
    };
    final used = days.length;
    final threshold = entry.value;
    final level = used >= threshold
        ? MohLevel.exceeded
        : used >= (threshold * 0.8).ceil()
            ? MohLevel.approaching
            : MohLevel.none;
    if (level.index > worst.level.index) {
      worst = MohStatus(level: level, medClass: entry.key,
          daysUsed: used, thresholdDays: threshold);
    }
  }
  return worst;
}
```

Export both from `domain.dart`.

- [ ] **Step 3: Run `cd packages/domain && dart test`, commit** — `git commit -am "feat(domain): medication dose type + ICHD-3 MOH monitor"`

### Task 14: Data — MedicationDoses table (schema v14) + repo

**Files:**
- Modify: `lib/data/database.dart`
- Create: `lib/data/repos/medication_repo.dart`
- Modify: `lib/data/repos/export_repo.dart`, `lib/data/repos/import_repo.dart`
- Test: `test/data/medication_repo_test.dart`, extend migration test

**Interfaces:**
- Produces: table `MedicationDoses { id auto; at; name text; medClass text; reliefRating int nullable; }`; `MedicationRepo { Future<int> insert(MedicationDose d); Future<void> setRelief(int id, int rating); Future<List<MedicationDose>> recent({required Duration window, required DateTime now}); Future<List<String>> distinctNames(); }`. Tasks 15–16 consume.

- [ ] **Step 1: Failing repo test** — insert two doses (different classes), read `recent` (maps rows → domain `MedicationDose` with `MedClass.values.byName`), `distinctNames` returns unique names most-recent-first, `setRelief` round-trips.
- [ ] **Step 2: Table + migration v14 + repo.** In `database.dart`:

```dart
class MedicationDoses extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get at => dateTime()();
  TextColumn get name => text()();
  TextColumn get medClass => text()(); // MedClass.name
  IntColumn get reliefRating => integer().nullable()(); // 0 no, 1 some, 2 yes
}
```

Add to the `@DriftDatabase` table list, bump `schemaVersion` to 14, add `if (from < 14) await m.createTable(medicationDoses);`, run `dart run build_runner build --delete-conflicting-outputs`.

```dart
// lib/data/repos/medication_repo.dart
import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

import '../database.dart';

class MedicationRepo {
  final AppDatabase _db;
  MedicationRepo(this._db);

  Future<int> insert(MedicationDose d) =>
      _db.into(_db.medicationDoses).insert(MedicationDosesCompanion.insert(
          at: d.at, name: d.name, medClass: d.medClass.name,
          reliefRating: Value(d.reliefRating)));

  Future<void> setRelief(int id, int rating) =>
      (_db.update(_db.medicationDoses)..where((t) => t.id.equals(id)))
          .write(MedicationDosesCompanion(reliefRating: Value(rating)));

  Future<List<MedicationDose>> recent(
      {required Duration window, required DateTime now}) async {
    final rows = await (_db.select(_db.medicationDoses)
          ..where((t) => t.at.isBiggerOrEqualValue(now.subtract(window)))
          ..orderBy([(t) => OrderingTerm.desc(t.at)]))
        .get();
    return [
      for (final r in rows)
        MedicationDose(id: r.id, at: r.at, name: r.name,
            medClass: MedClass.values.byName(r.medClass),
            reliefRating: r.reliefRating),
    ];
  }

  Future<List<String>> distinctNames() async {
    final rows = await (_db.select(_db.medicationDoses)
          ..orderBy([(t) => OrderingTerm.desc(t.at)]))
        .get();
    final seen = <String>{};
    return [for (final r in rows) if (seen.add(r.name)) r.name];
  }
}
```

(Confirm the generated row/companion names against `database.g.dart` after build_runner.)
- [ ] **Step 3: Export/import wiring** following the `journal_entries` pattern in both repos.
- [ ] **Step 4: Migration test** v13→v14.
- [ ] **Step 5: Run `flutter test test/data/`, commit** — `git commit -am "feat(data): medication doses table (schema v14) + repo, export/import"`

### Task 15: UI — log medication

**Files:**
- Create: `lib/ui/log/medication_entry_sheet.dart`
- Modify: `lib/ui/log/log_picker_sheet.dart` (tile between Stress and Sleep)
- Create: `lib/state/medication_provider.dart`
- Modify: `lib/ui/log/log_history_screen.dart` (render dose entries — read the screen first and follow how sleep/journal rows are merged)
- Test: `test/ui/log/medication_entry_sheet_test.dart`

**Interfaces:**
- Consumes: `MedicationRepo` (Task 14).
- Produces: `medicationRepoProvider`, `recentMedicationDosesProvider: FutureProvider<List<MedicationDose>>` (90-day window), sheet widget.

- [ ] **Step 1: Failing widget test** — pump sheet with overridden repo fake; enter name "Sumatriptan", pick class chip "Triptan", tap Save; expect fake received a `MedicationDose` with `medClass == MedClass.triptan`. Second test: past names appear as tappable autocomplete chips.

- [ ] **Step 2: Implement**

```dart
// lib/state/medication_provider.dart
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repos/medication_repo.dart';
import 'providers.dart';

final medicationRepoProvider =
    Provider<MedicationRepo>((ref) => MedicationRepo(ref.watch(databaseProvider)));

final recentMedicationDosesProvider = FutureProvider<List<MedicationDose>>((ref) =>
    ref.watch(medicationRepoProvider)
        .recent(window: const Duration(days: 90), now: DateTime.now().toUtc()));

final medicationNamesProvider = FutureProvider<List<String>>(
    (ref) => ref.watch(medicationRepoProvider).distinctNames());
```

Sheet: name `TextField` + wrap of past-name `ActionChip`s (tap fills the field and preselects that name's last-used class), `SegmentedButton<MedClass>` with labels Triptan / Pain reliever / Combination / Preventive / Other, optional relief `SegmentedButton<int?>` (No / Some / Yes), Save button inserts via repo, pops, invalidates `recentMedicationDosesProvider`. Follow `journal_entry_sheet.dart` for layout, keys (`med-name`, `med-class-triptan`, `med-save`), and the celebration wiring if journal sheets trigger it (check `celebration_wiring_test.dart` expectations).

Picker tile in `log_picker_sheet.dart`:

```dart
_kindTile(context, key: 'log-kind-medication', icon: Icons.medication_outlined,
    label: 'Medication', onTap: () => _openMedicationSheet(context)),
```

- [ ] **Step 3: Run `flutter test test/ui/log/`, commit** — `git commit -am "feat(log): medication dose logging with name autocomplete"`

### Task 16: UI — MOH warning + medication efficacy card

**Files:**
- Create: `lib/ui/insights/medication_card.dart`
- Modify: `lib/state/medication_provider.dart` (add `mohStatusProvider`)
- Modify: `lib/ui/insights/insights_screen.dart`, `lib/ui/today/today_screen.dart` (warning banner only when approaching/exceeded)
- Test: `test/ui/insights/medication_card_test.dart`

**Interfaces:**
- Consumes: `assessMoh`, `recentMedicationDosesProvider`.
- Produces: `mohStatusProvider: FutureProvider<MohStatus>`; `MedicationCard` (efficacy + MOH); `MohBanner` (compact, Today screen).

- [ ] **Step 1: Provider**

```dart
final mohStatusProvider = FutureProvider<MohStatus>((ref) async {
  final doses = await ref.watch(recentMedicationDosesProvider.future);
  return assessMoh(doses, DateTime.now().toUtc());
});
```

- [ ] **Step 2: Failing widget test** — override providers: (a) exceeded status → expect `find.textContaining('10 of the last 30 days')` and the ICHD-3 wording; (b) doses for "Sumatriptan" with ratings [2,2,0] → expect `find.textContaining('helped 2 of 3')`; (c) `MohLevel.none` + no rated doses → card hidden.

- [ ] **Step 3: Implement.** Efficacy: group rated doses by name, show names with ≥3 rated doses as `'$name — helped $helped of $rated times'` where helped = rating ≥1. MOH warning copy (exceeded): *"You've used {class label} on {daysUsed} of the last 30 days — at or above the ICHD-3 medication-overuse threshold ({thresholdDays} days/month). Frequent abortive use can itself sustain headaches; worth discussing with your clinician."* Approaching variant: *"…approaching the ICHD-3 threshold…"*. Class labels: triptan → 'triptans', simpleAnalgesic → 'pain relievers', combination → 'combination analgesics', other → 'abortive medication'. Banner on Today reuses the same copy in one line with a warning icon; tapping opens Insights.

- [ ] **Step 4: Run `flutter test test/ui/insights/ test/ui/today/`, commit** — `git commit -am "feat(insights): medication efficacy card + ICHD-3 MOH warning"`

---

## Phase G — New trigger modules

### Task 17: Consolidate the module registry

**Files:**
- Create: `packages/domain/lib/src/engine/all_modules.dart`
- Modify: `packages/domain/lib/domain.dart`, `lib/state/providers.dart:130`, `lib/services/background_scheduler.dart:74`, `lib/state/correlation_provider.dart` (derive `_moduleIds`)
- Test: `packages/domain/test/engine/all_modules_test.dart`

**Interfaces:**
- Produces: `List<TriggerModule> allTriggerModules()` — the single source of truth. New modules (Tasks 18–19) register only here + config + UI label lists.

- [ ] **Step 1: Failing test** — `allTriggerModules()` returns 13 modules today; ids are unique and match the key set of `assets/rules_config_v1.json` (hardcode the expected id list in the test).
- [ ] **Step 2: Implement** — move the module list currently at `lib/state/providers.dart:130-…` into the domain factory verbatim; replace both construction sites with `RiskEngine(modules: allTriggerModules())`; in `correlation_provider.dart` replace the hardcoded `_moduleIds` with `final _moduleIds = [for (final m in allTriggerModules()) m.id];`.
- [ ] **Step 3: Run full suite (`cd packages/domain && dart test && cd ../.. && flutter test`), commit** — `git commit -am "chore(domain): single allTriggerModules() registry"`

### Task 18: Skipped-meals module

**Files:**
- Modify: `packages/domain/lib/src/types/journal.dart` (`JournalKind.skippedMeal`)
- Modify: `packages/domain/lib/src/types/data_requirement.dart` (add `journalMeals`)
- Create: `packages/domain/lib/src/modules/skipped_meal.dart`
- Modify: `packages/domain/lib/src/engine/all_modules.dart`, `assets/rules_config_v1.json` (+ bump `version` 2→3), `packages/domain/lib/domain.dart`
- Modify: `lib/ui/log/log_picker_sheet.dart`, `lib/ui/log/journal_entry_sheet.dart` (skipped-meal variant), `lib/ui/shared/contributor_order.dart`, onboarding + settings flag lists, `lib/ui/log/log_history_screen.dart` label map
- Test: `packages/domain/test/modules/skipped_meal_test.dart`, `test/ui/log/journal_entry_sheet_test.dart` (extend)

**Interfaces:**
- Produces: module id `skipped_meals`, `JournalKind.skippedMeal` with payload `{"meal": "breakfast"|"lunch"|"dinner"}`.

- [ ] **Step 1: Failing domain test**

```dart
// packages/domain/test/modules/skipped_meal_test.dart
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 7, 9, 18);
  final target = DateTime.utc(2026, 7, 9);
  const params = ModuleParams(enabled: true, weightMax: 10,
      params: {'lookback_hours': 24});
  EvaluationContext ctx(List<JournalEntry> journal) => EvaluationContext(
      now: now, targetDate: target, recentJournal: journal,
      baselines: BaselineSnapshot.empty);
  final m = SkippedMealModule();

  test('no meal entries ever → zero-confidence with missing requirement', () {
    final s = m.evaluate(ctx(const []), params);
    expect(s.weight * s.confidence, 0);
    expect(s.missing, DataRequirement.journalMeals);
  });

  test('one skipped meal in lookback → 60% of weightMax', () {
    final s = m.evaluate(ctx([
      JournalEntry(at: now.subtract(const Duration(hours: 3)),
          kind: JournalKind.skippedMeal, payload: const {'meal': 'lunch'}),
    ]), params);
    expect(s.weight, closeTo(6.0, 1e-9));
    expect(s.confidence, 1.0);
  });

  test('two or more skipped meals → full weightMax', () {
    final s = m.evaluate(ctx([
      JournalEntry(at: now.subtract(const Duration(hours: 3)),
          kind: JournalKind.skippedMeal, payload: const {'meal': 'lunch'}),
      JournalEntry(at: now.subtract(const Duration(hours: 9)),
          kind: JournalKind.skippedMeal, payload: const {'meal': 'breakfast'}),
    ]), params);
    expect(s.weight, 10.0);
  });

  test('entries exist but none in lookback → weight 0, confidence 1', () {
    final s = m.evaluate(ctx([
      JournalEntry(at: now.subtract(const Duration(days: 5)),
          kind: JournalKind.skippedMeal, payload: const {'meal': 'dinner'}),
    ]), params);
    expect(s.weight, 0);
    expect(s.confidence, 1.0);
  });
}
```

- [ ] **Step 2: Run to verify failure**, then implement (mirrors `AlcoholModule` exactly):

```dart
// packages/domain/lib/src/modules/skipped_meal.dart
import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/journal.dart';
import '../types/trigger_signal.dart';

/// Fasting / missed meals are among the most frequently self-reported triggers
/// (Kelman 2007, Cephalalgia — reported by ~57% of patients; Martin & Vij 2016
/// review). One skipped meal ramps to 60% of weight_max; two or more saturate.
class SkippedMealModule implements TriggerModule {
  @override
  String get id => 'skipped_meals';
  @override
  Set<DataRequirement> get requires => {DataRequirement.journalMeals};
  @override
  Duration get leadTime => const Duration(hours: 12);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    final lookback = Duration(hours: params.getInt('lookback_hours', 24));
    final earliest = ctx.now.subtract(lookback);
    final any = ctx.recentJournal.any((e) => e.kind == JournalKind.skippedMeal);
    if (!any) {
      return TriggerSignal.zero(
          moduleId: id, reason: 'No meals log',
          missing: DataRequirement.journalMeals);
    }
    final count = ctx.recentJournal
        .where((e) => e.kind == JournalKind.skippedMeal && !e.at.isBefore(earliest))
        .length;
    if (count == 0) {
      return TriggerSignal(moduleId: id, weight: 0, confidence: 1.0,
          explanation: 'No skipped meals in last ${lookback.inHours}h');
    }
    final weight = params.weightMax * (count == 1 ? 0.6 : 1.0);
    return TriggerSignal(moduleId: id, weight: weight, confidence: 1.0,
        explanation: '$count skipped meal${count == 1 ? '' : 's'} in last ${lookback.inHours}h');
  }
}
```

`data_requirement.dart` addition: `static const journalMeals = DataRequirement(id: 'journal.meals', label: 'Meals log');`

Config addition (`rules_config_v1.json`, and bump `"version": 3`):

```json
"skipped_meals": { "enabled": true, "weight_max": 10, "params": { "lookback_hours": 24 } }
```

- [ ] **Step 3: Registry + UI wiring.** Add to `allTriggerModules()`. `contributor_order.dart`: append `'skipped_meals'` after `'hydration'`. Picker tile (icon `Icons.no_meals_outlined`, label 'Skipped meal'). `journal_entry_sheet.dart`: for `JournalKind.skippedMeal` render three choice chips breakfast/lunch/dinner → payload `{'meal': …}` (read the sheet's per-kind switch and add a case; also add its display label anywhere kinds are labeled — `grep -rn 'JournalKind\.' lib/ui | grep -v skippedMeal`, the analyzer flags exhaustive switches). Check `drift_journal_source.dart` kind serialization (`.name` round-trip means no change needed). Add flag entries in onboarding/settings module lists ('Skipped meals'). Check `export_repo.dart`/`import_repo.dart` for kind allow-lists (grep `alcohol` there) and extend if present.
- [ ] **Step 4: Run full suite, commit** — `git commit -am "feat(domain): skipped-meals trigger module + meal journal kind"`

### Task 19: Wind module (weather pipeline + module)

**Files:**
- Modify: `packages/domain/lib/src/types/weather.dart` (`WeatherSample.windGustKph` nullable + `maxWindGustAround`)
- Modify: `packages/domain/lib/src/types/data_requirement.dart` (`weatherWind`)
- Create: `packages/domain/lib/src/modules/wind.dart`
- Modify: `lib/data/sources/open_meteo/open_meteo_url_builder.dart` (add `wind_gusts_10m` to both hourly lists), `lib/data/sources/open_meteo/open_meteo_parser.dart` (tolerant parse)
- Modify: `packages/domain/lib/src/engine/all_modules.dart`, `assets/rules_config_v1.json`, `domain.dart`, `contributor_order.dart`, onboarding/settings lists
- Test: `packages/domain/test/modules/wind_test.dart`, extend parser test in `test/data/` (fixtures live at `test/data/sources/fixtures/open_meteo/`)

**Interfaces:**
- Produces: module id `wind`; `WeatherSample` gains `final double? windGustKph` (optional constructor param, added to props); `WeatherSeries.maxWindGustAround(anchor, window, {required now}) → double?`.

- [ ] **Step 1: Failing domain tests**

```dart
// packages/domain/test/modules/wind_test.dart
import 'package:domain/domain.dart';
import 'package:test/test.dart';

WeatherSample sample(int hour, {double? gust}) => WeatherSample(
    at: DateTime.utc(2026, 7, 9, hour), pressureMsl: 1013,
    temperatureC: 20, humidityPct: 50, windGustKph: gust);

void main() {
  final now = DateTime.utc(2026, 7, 9, 20);
  final target = DateTime.utc(2026, 7, 9);
  const params = ModuleParams(enabled: true, weightMax: 10, params: {
    'gust_threshold_kmh': 45.0, 'gust_saturation_kmh': 75.0, 'lookahead_hours': 24,
  });
  EvaluationContext ctx(List<WeatherSample> samples) => EvaluationContext(
      now: now, targetDate: target,
      weather: WeatherSeries(samples: samples),
      baselines: BaselineSnapshot.empty);
  final m = WindModule();

  test('gusts below threshold → weight 0, full confidence', () {
    final s = m.evaluate(ctx([sample(8, gust: 20), sample(12, gust: 30)]), params);
    expect(s.weight, 0);
    expect(s.confidence, 1.0);
  });

  test('gusts at saturation → full weight', () {
    final s = m.evaluate(ctx([sample(8, gust: 80)]), params);
    expect(s.weight, 10.0);
    expect(s.explanation, contains('80'));
  });

  test('midpoint gust ramps linearly', () {
    final s = m.evaluate(ctx([sample(8, gust: 60)]), params); // (60-45)/(75-45)=0.5
    expect(s.weight, closeTo(5.0, 1e-9));
  });

  test('samples without wind data (old cache) → zero-confidence missing signal', () {
    final s = m.evaluate(ctx([sample(8), sample(12)]), params);
    expect(s.weight * s.confidence, 0);
    expect(s.missing, DataRequirement.weatherWind);
  });
}
```

- [ ] **Step 2: Run to verify failure**, then implement.

`weather.dart`: add `final double? windGustKph;` to `WeatherSample` (optional named constructor param, append to props), and:

```dart
double? maxWindGustAround(DateTime anchor, Duration window, {required DateTime now}) {
  final gusts = _around(anchor, window, now)
      .map((s) => s.windGustKph)
      .whereType<double>()
      .toList();
  if (gusts.isEmpty) return null;
  return gusts.reduce((a, b) => a > b ? a : b);
}
```

```dart
// packages/domain/lib/src/modules/wind.dart
import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/trigger_signal.dart';

/// Chinook/foehn-type wind events raise migraine probability in susceptible
/// patients (Cooke, Rose & Becker 2000, Neurology 54;302 — high-wind chinook
/// days). Fires on peak gusts in the day's window; threshold/saturation are
/// config params.
class WindModule implements TriggerModule {
  @override
  String get id => 'wind';
  @override
  Set<DataRequirement> get requires => {DataRequirement.weatherWind};
  @override
  Duration get leadTime => const Duration(hours: 24);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    if (ctx.weather == null || ctx.weather!.samples.isEmpty) {
      return TriggerSignal.zero(moduleId: id, reason: 'No weather data',
          missing: DataRequirement.weatherWind);
    }
    final threshold = params.getDouble('gust_threshold_kmh', 45);
    final saturation = params.getDouble('gust_saturation_kmh', 75);
    final window = Duration(hours: params.getInt('lookahead_hours', 24));
    final direction = directionFor(ctx);
    final anchor = direction == WindowDirection.past ? ctx.now : ctx.targetDate;
    final gust = ctx.weather!.maxWindGustAround(anchor, window, now: ctx.now);
    if (gust == null) {
      // Cached series predating the wind columns — treat as missing, not calm.
      return TriggerSignal.zero(moduleId: id, reason: 'No wind data',
          missing: DataRequirement.weatherWind);
    }
    if (gust < threshold) {
      return TriggerSignal(moduleId: id, weight: 0, confidence: 1.0,
          explanation: 'Winds calm (gusts ${gust.round()} km/h)');
    }
    final t = ((gust - threshold) / (saturation - threshold)).clamp(0.0, 1.0);
    final verb = direction == WindowDirection.past ? 'gusting' : 'forecast to gust';
    return TriggerSignal(moduleId: id, weight: params.weightMax * t, confidence: 1.0,
        explanation: 'Wind $verb ${gust.round()} km/h');
  }
}
```

`data_requirement.dart`: `static const weatherWind = DataRequirement(id: 'weather.wind', label: 'Weather (wind)');`

Parser (`open_meteo_parser.dart` `parseForecast`): read `final gusts = hourly['wind_gusts_10m'] as List?;` and inside the loop `final g = gusts != null && i < gusts.length ? gusts[i] : null;` → pass `windGustKph: g is num ? g.toDouble() : null`. Pressure/temp/humidity gating unchanged — wind absence must not drop the sample. URL builder: append `,wind_gusts_10m` to the `hourly` value in **both** `forecast` and `archive` (the archive API serves `wind_gusts_10m`). Extend a parser test using an existing fixture plus a new fixture containing `wind_gusts_10m`; assert old fixture parses with null gusts.

Config (+ registry + UI label lists, same checklist as Task 18):

```json
"wind": { "enabled": true, "weight_max": 10,
  "params": { "gust_threshold_kmh": 45, "gust_saturation_kmh": 75, "lookahead_hours": 24 } }
```

- [ ] **Step 3: Run full suite (`cd packages/domain && dart test && cd ../.. && flutter test`), commit** — `git commit -am "feat(domain): wind trigger module with gust data through the weather pipeline"`

---

## Sequencing & DB-version note

Dependency order: **1 → 2** unblock 3–7; **8 → 9 → 10**; **11 → 12**; **13 → 14 → 15 → 16**; **17 → 18/19**. Phases D, E, F, G are mutually independent and can be reordered — but schema versions are claimed in plan order (check-ins = 13, medications = 14). If F lands before D, swap the version numbers (same pattern as the v7 note in `database.dart`).

## Verification after each phase

- `cd packages/domain && dart test && cd ../.. && flutter test && flutter analyze`
- Manual smoke on macOS: `flutter run -d macos` — Today renders, Insights renders with new cards, log picker shows new entries.

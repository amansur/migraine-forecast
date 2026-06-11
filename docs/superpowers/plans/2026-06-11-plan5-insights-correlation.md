# Plan 5 — Insights + Correlation engine (+ carry-overs)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Add the Insights screen — calendar heatmap of logged attacks, per-trigger correlation cards backed by a Wilson-score-interval correlation engine, and user-in-the-loop "suggested weight adjustment" cards that personalize the engine without silent ML drift. Also clean up two carry-overs flagged in Plan 4: wire `lastRefreshAt` to the real assessment history, and copy the rules config to a documents-dir path so background isolates can read it.

**Architecture:** A pure-Dart `CorrelationEngine` in `packages/domain/` computes per-module attack-rate lifts with 90% Wilson score intervals — no ML, no opacity, every number derivable from a citeable cohort. A `CorrelationRepo` in `lib/data/repos/` queries Drift for (assessments, attacks, distinct days) over a 90-day window. A `SuggestionEngine` decides which lifts are confident enough to surface as suggestion cards. The Insights screen gates on `≥3 attacks logged`, and surfaces a calendar heatmap, the top correlation cards, and any open suggestion cards. Accepting a suggestion writes to the existing `UserTriggerFlagsRepo` weight overrides — same plumbing as the Settings sliders, no new state machine.

**Tech Stack:** Same as Plans 1–4. New widget: a custom `CalendarHeatmap` painter; no third-party calendar dependency.

---

## File Structure

```
/Users/amansur/projects/migraine-weatherr/
├── packages/domain/
│   ├── lib/src/correlation/
│   │   ├── wilson_interval.dart                    # pure math
│   │   └── correlation_analyzer.dart               # per-module lift + CI
│   └── test/correlation/
│       ├── wilson_interval_test.dart
│       └── correlation_analyzer_test.dart
├── lib/
│   ├── data/
│   │   └── repos/
│   │       └── correlation_repo.dart               # Drift queries over 90d window
│   ├── services/
│   │   └── suggestion_engine.dart                  # decision layer over analyzer results
│   ├── state/
│   │   ├── correlation_provider.dart               # Riverpod
│   │   ├── insights_eligibility_provider.dart      # attack-count gate
│   │   └── last_refresh_provider.dart              # carry-over fix: real lastRefreshAt
│   ├── ui/
│   │   └── insights/
│   │       ├── insights_screen.dart
│   │       ├── calendar_heatmap.dart
│   │       ├── correlation_card.dart
│   │       └── suggestion_card.dart
│   └── app/router.dart                             # add /insights
└── test/
    ├── data/repos/correlation_repo_test.dart
    ├── services/suggestion_engine_test.dart
    ├── state/last_refresh_provider_test.dart
    └── ui/insights/
        ├── insights_screen_test.dart
        ├── correlation_card_test.dart
        └── suggestion_card_test.dart
```

---

## Task 1: Wilson score interval (pure domain math)

**Files:**
- Create: `packages/domain/lib/src/correlation/wilson_interval.dart`
- Test: `packages/domain/test/correlation/wilson_interval_test.dart`
- Modify: `packages/domain/lib/domain.dart` (export)

- [ ] **Step 1: Write failing test**

Create `packages/domain/test/correlation/wilson_interval_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('WilsonInterval', () {
    test('empty trial returns (0,1) wide interval', () {
      final ci = WilsonInterval.compute(successes: 0, trials: 0);
      expect(ci.low, 0.0);
      expect(ci.high, 1.0);
    });

    test('all-success at n=10, z=1.645 (90%)', () {
      final ci = WilsonInterval.compute(successes: 10, trials: 10);
      expect(ci.low, greaterThan(0.7));
      expect(ci.high, 1.0);
    });

    test('half-and-half at n=20 returns a symmetric-ish interval around 0.5', () {
      final ci = WilsonInterval.compute(successes: 10, trials: 20);
      expect(ci.point, 0.5);
      expect(ci.low, closeTo(0.32, 0.05));
      expect(ci.high, closeTo(0.68, 0.05));
    });

    test('rare success: 1 of 30 has low CI bound near 0', () {
      final ci = WilsonInterval.compute(successes: 1, trials: 30);
      expect(ci.low, lessThan(0.05));
      expect(ci.high, greaterThan(0.05));
      expect(ci.high, lessThan(0.2));
    });

    test('liftDifference returns the right direction and width', () {
      // 90% positive rate over 20 vs 30% over 20.
      final fired = WilsonInterval.compute(successes: 18, trials: 20);
      final notFired = WilsonInterval.compute(successes: 6, trials: 20);
      final lift = WilsonInterval.differenceLift(fired, notFired);
      expect(lift.point, closeTo(0.6, 0.01));
      expect(lift.low, greaterThan(0.3));    // CI clearly positive
      expect(lift.high, lessThan(1.0));
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd /Users/amansur/projects/migraine-weatherr/packages/domain && dart test test/correlation/wilson_interval_test.dart
```

- [ ] **Step 3: Implement**

Create `packages/domain/lib/src/correlation/wilson_interval.dart`:

```dart
import 'dart:math' as math;

/// 90% Wilson score interval for a binomial proportion.
///
/// Defined as p + z²/(2n) ± z·sqrt(p(1-p)/n + z²/(4n²)) all over (1 + z²/n).
/// See https://en.wikipedia.org/wiki/Binomial_proportion_confidence_interval#Wilson_score_interval
class WilsonInterval {
  /// Lower bound of the 90% CI.
  final double low;
  /// Point estimate (the observed proportion).
  final double point;
  /// Upper bound of the 90% CI.
  final double high;
  /// Sample size.
  final int trials;
  const WilsonInterval({
    required this.low,
    required this.point,
    required this.high,
    required this.trials,
  });

  /// 90% one-sided z is ~1.645.
  static const double _z90 = 1.6448536269514722;

  static WilsonInterval compute({required int successes, required int trials}) {
    if (trials == 0) {
      return const WilsonInterval(low: 0, point: 0, high: 1, trials: 0);
    }
    final z = _z90;
    final n = trials.toDouble();
    final p = successes / n;
    final z2 = z * z;
    final denom = 1 + z2 / n;
    final centre = p + z2 / (2 * n);
    final spread = z * math.sqrt((p * (1 - p) + z2 / (4 * n)) / n);
    final low = ((centre - spread) / denom).clamp(0.0, 1.0).toDouble();
    final high = ((centre + spread) / denom).clamp(0.0, 1.0).toDouble();
    return WilsonInterval(low: low, point: p, high: high, trials: trials);
  }

  /// Returns the difference of two independent Wilson intervals as a single
  /// interval — useful for comparing two cohorts (fired vs not-fired).
  /// Uses the standard approximation: difference of point estimates ±
  /// sqrt(sum of squared half-widths). Not exact, but defensible at small N.
  static LiftInterval differenceLift(WilsonInterval a, WilsonInterval b) {
    final point = a.point - b.point;
    final halfA = (a.high - a.low) / 2.0;
    final halfB = (b.high - b.low) / 2.0;
    final width = math.sqrt(halfA * halfA + halfB * halfB);
    return LiftInterval(
      point: point,
      low: point - width,
      high: point + width,
      a: a,
      b: b,
    );
  }
}

class LiftInterval {
  /// Difference in point estimates (a.point - b.point).
  final double point;
  /// Approximate lower bound of the difference's 90% CI.
  final double low;
  /// Approximate upper bound of the difference's 90% CI.
  final double high;
  /// The "fired" cohort interval.
  final WilsonInterval a;
  /// The "not fired" cohort interval.
  final WilsonInterval b;
  const LiftInterval({
    required this.point,
    required this.low,
    required this.high,
    required this.a,
    required this.b,
  });

  bool get excludesZero => low > 0 || high < 0;
  bool get pointBelowZero => point < 0 && high < 0;
}
```

- [ ] **Step 4: Update barrel**

Append to `packages/domain/lib/domain.dart`:

```dart
export 'src/correlation/wilson_interval.dart';
```

- [ ] **Step 5: Run — expect PASS**

```bash
cd /Users/amansur/projects/migraine-weatherr/packages/domain && dart test test/correlation/wilson_interval_test.dart
```

Expected: 5 passing.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "domain: Wilson score interval + lift difference primitives"
```

---

## Task 2: CorrelationAnalyzer (pure domain)

**Files:**
- Create: `packages/domain/lib/src/correlation/correlation_analyzer.dart`
- Test: `packages/domain/test/correlation/correlation_analyzer_test.dart`
- Modify: `packages/domain/lib/domain.dart` (export)

- [ ] **Step 1: Write failing test**

Create `packages/domain/test/correlation/correlation_analyzer_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('CorrelationAnalyzer', () {
    final analyzer = const CorrelationAnalyzer();

    test('refuses to produce a result with too few attacks', () {
      final input = ModuleCohort(
        moduleId: 'pressure_drop',
        daysFiredWithAttack: 1,
        daysFiredTotal: 5,
        daysNotFiredWithAttack: 0,
        daysNotFiredTotal: 30,
      );
      final result = analyzer.analyze(input, minAttacks: 3);
      expect(result.classification, CorrelationClassification.insufficientData);
    });

    test('clear positive correlation produces a hit', () {
      final input = ModuleCohort(
        moduleId: 'pressure_drop',
        daysFiredWithAttack: 7,        // module fired, attack happened
        daysFiredTotal: 10,            // 70% attack rate when fired
        daysNotFiredWithAttack: 2,
        daysNotFiredTotal: 50,         // 4% attack rate when not fired
      );
      final result = analyzer.analyze(input, minAttacks: 3);
      expect(result.classification, CorrelationClassification.personalHit);
      expect(result.firedAttackRate.point, closeTo(0.7, 0.01));
      expect(result.notFiredAttackRate.point, closeTo(0.04, 0.01));
      expect(result.lift.point, greaterThan(0.5));
      expect(result.lift.low, greaterThan(0));  // CI excludes 0
    });

    test('clear negative correlation produces a miss', () {
      final input = ModuleCohort(
        moduleId: 'humidity_temp_swing',
        daysFiredWithAttack: 0,
        daysFiredTotal: 20,            // 0% attack rate when fired
        daysNotFiredWithAttack: 8,
        daysNotFiredTotal: 40,         // 20% attack rate when not fired
      );
      final result = analyzer.analyze(input, minAttacks: 3);
      expect(result.classification, CorrelationClassification.personalMiss);
    });

    test('ambiguous correlation produces inconclusive', () {
      final input = ModuleCohort(
        moduleId: 'caffeine',
        daysFiredWithAttack: 3,
        daysFiredTotal: 10,            // 30%
        daysNotFiredWithAttack: 7,
        daysNotFiredTotal: 30,         // 23%
      );
      final result = analyzer.analyze(input, minAttacks: 3);
      expect(result.classification, CorrelationClassification.inconclusive);
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd /Users/amansur/projects/migraine-weatherr/packages/domain && dart test test/correlation/correlation_analyzer_test.dart
```

- [ ] **Step 3: Implement**

Create `packages/domain/lib/src/correlation/correlation_analyzer.dart`:

```dart
import 'package:equatable/equatable.dart';

import 'wilson_interval.dart';

enum CorrelationClassification {
  personalHit,
  personalMiss,
  inconclusive,
  insufficientData,
}

/// Counts for a single module over an observation window. A "day fired" is a
/// calendar day on which the engine recorded a positive contribution for the
/// module in that day's persisted assessment.
class ModuleCohort extends Equatable {
  final String moduleId;
  final int daysFiredWithAttack;
  final int daysFiredTotal;
  final int daysNotFiredWithAttack;
  final int daysNotFiredTotal;
  const ModuleCohort({
    required this.moduleId,
    required this.daysFiredWithAttack,
    required this.daysFiredTotal,
    required this.daysNotFiredWithAttack,
    required this.daysNotFiredTotal,
  });

  int get totalAttacks => daysFiredWithAttack + daysNotFiredWithAttack;
  int get totalDays => daysFiredTotal + daysNotFiredTotal;

  @override
  List<Object?> get props => [
        moduleId,
        daysFiredWithAttack,
        daysFiredTotal,
        daysNotFiredWithAttack,
        daysNotFiredTotal,
      ];
}

class CorrelationResult extends Equatable {
  final String moduleId;
  final CorrelationClassification classification;
  final WilsonInterval firedAttackRate;
  final WilsonInterval notFiredAttackRate;
  final LiftInterval lift;
  final int totalAttacks;
  const CorrelationResult({
    required this.moduleId,
    required this.classification,
    required this.firedAttackRate,
    required this.notFiredAttackRate,
    required this.lift,
    required this.totalAttacks,
  });

  @override
  List<Object?> get props =>
      [moduleId, classification, firedAttackRate, notFiredAttackRate, lift, totalAttacks];
}

class CorrelationAnalyzer {
  const CorrelationAnalyzer();

  /// Defaults: a hit requires the lift's 90% CI to exclude zero AND the point
  /// estimate to be at least 2× the not-fired baseline (large effect size) AND
  /// at least [minAttacks] in the fired cohort to avoid acting on coincidence.
  CorrelationResult analyze(ModuleCohort c, {int minAttacks = 3}) {
    final fired = WilsonInterval.compute(
      successes: c.daysFiredWithAttack,
      trials: c.daysFiredTotal,
    );
    final notFired = WilsonInterval.compute(
      successes: c.daysNotFiredWithAttack,
      trials: c.daysNotFiredTotal,
    );
    final lift = WilsonInterval.differenceLift(fired, notFired);

    CorrelationClassification cls;
    if (c.totalAttacks < minAttacks || c.totalDays < 14) {
      cls = CorrelationClassification.insufficientData;
    } else if (lift.low > 0 && c.daysFiredWithAttack >= minAttacks &&
        fired.point >= 2 * notFired.point) {
      cls = CorrelationClassification.personalHit;
    } else if (lift.high < 0 && c.daysNotFiredWithAttack >= minAttacks) {
      cls = CorrelationClassification.personalMiss;
    } else {
      cls = CorrelationClassification.inconclusive;
    }

    return CorrelationResult(
      moduleId: c.moduleId,
      classification: cls,
      firedAttackRate: fired,
      notFiredAttackRate: notFired,
      lift: lift,
      totalAttacks: c.totalAttacks,
    );
  }
}
```

- [ ] **Step 4: Update barrel**

```dart
export 'src/correlation/correlation_analyzer.dart';
```

- [ ] **Step 5: Run — expect PASS**

```bash
cd /Users/amansur/projects/migraine-weatherr/packages/domain && dart test test/correlation/
```

Expected: 9 passing.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "domain: CorrelationAnalyzer + per-module classification rules"
```

---

## Task 3: CorrelationRepo (Drift queries)

**Files:**
- Create: `lib/data/repos/correlation_repo.dart`
- Test: `test/data/repos/correlation_repo_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/data/repos/correlation_repo_test.dart`:

```dart
import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_weatherr/data/repos/correlation_repo.dart';

void main() {
  late AppDatabase db;
  late CorrelationRepo repo;
  setUp(() {
    db = AppDatabase.memory();
    repo = CorrelationRepo(db);
  });
  tearDown(() => db.close());

  Future<void> insertAssessment({
    required DateTime targetDate,
    required Map<String, double> contributions,
    DateTime? computedAt,
  }) async {
    final contributors = contributions.entries
        .map((e) => {
              'moduleId': e.key,
              'weight': e.value,
              'confidence': 1.0,
              'explanation': '${e.key} test',
            })
        .toList();
    await db.into(db.riskAssessments).insert(
          RiskAssessmentsCompanion.insert(
            targetDate: targetDate,
            horizon: 'today',
            score: contributions.values.fold(0.0, (a, b) => a + b).round(),
            band: 'high',
            computedAt: computedAt ?? targetDate,
            configVersion: 1,
            contributorsJson: jsonEncode(contributors),
          ),
        );
  }

  Future<void> insertAttack(DateTime startedAt) async {
    await db.into(db.attacks).insert(
          AttacksCompanion.insert(
            startedAt: startedAt,
            endedAt: const Value.absent(),
            severity: 5,
            notes: const Value.absent(),
            riskAssessmentId: const Value.absent(),
          ),
        );
  }

  test('cohorts split fired vs not-fired days correctly', () async {
    // 5 days where pressure_drop fired, 3 of which had attacks.
    for (var i = 0; i < 5; i++) {
      final day = DateTime.utc(2026, 6, 1 + i);
      await insertAssessment(targetDate: day, contributions: {'pressure_drop': 10.0});
      if (i < 3) await insertAttack(day.add(const Duration(hours: 6)));
    }
    // 10 days where pressure_drop did NOT fire, 1 of which had an attack.
    for (var i = 0; i < 10; i++) {
      final day = DateTime.utc(2026, 6, 6 + i);
      await insertAssessment(targetDate: day, contributions: {'sleep_deficit': 5.0});
      if (i == 0) await insertAttack(day.add(const Duration(hours: 6)));
    }

    final cohorts = await repo.buildCohorts(
      windowStart: DateTime.utc(2026, 6, 1),
      windowEnd: DateTime.utc(2026, 6, 16),
      moduleIds: const ['pressure_drop', 'sleep_deficit'],
    );

    final pd = cohorts.firstWhere((c) => c.moduleId == 'pressure_drop');
    expect(pd.daysFiredTotal, 5);
    expect(pd.daysFiredWithAttack, 3);
    expect(pd.daysNotFiredTotal, 10);
    expect(pd.daysNotFiredWithAttack, 1);

    final sd = cohorts.firstWhere((c) => c.moduleId == 'sleep_deficit');
    expect(sd.daysFiredTotal, 10);
    expect(sd.daysFiredWithAttack, 1);
  });

  test('returns empty list when no assessments in window', () async {
    final cohorts = await repo.buildCohorts(
      windowStart: DateTime.utc(2026, 6, 1),
      windowEnd: DateTime.utc(2026, 6, 30),
      moduleIds: const ['pressure_drop'],
    );
    final pd = cohorts.firstWhere((c) => c.moduleId == 'pressure_drop');
    expect(pd.totalDays, 0);
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/data/repos/correlation_repo_test.dart
```

- [ ] **Step 3: Implement**

Create `lib/data/repos/correlation_repo.dart`:

```dart
import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

import '../database.dart';

class CorrelationRepo {
  final AppDatabase _db;
  CorrelationRepo(this._db);

  /// Builds a cohort per module over [windowStart, windowEnd). A calendar day
  /// is "fired" for a module if any assessment for that day had a positive
  /// contribution recorded for that module. A day is "with attack" if any
  /// attack started during it.
  Future<List<ModuleCohort>> buildCohorts({
    required DateTime windowStart,
    required DateTime windowEnd,
    required List<String> moduleIds,
  }) async {
    final assessmentRows = await (_db.select(_db.riskAssessments)
          ..where((t) =>
              t.targetDate.isBiggerOrEqualValue(windowStart) &
              t.targetDate.isSmallerThanValue(windowEnd)))
        .get();

    // moduleId → set of days where it fired (had positive contribution).
    final firedDaysByModule = <String, Set<DateTime>>{
      for (final id in moduleIds) id: <DateTime>{},
    };
    final allDays = <DateTime>{};
    for (final row in assessmentRows) {
      final day = DateTime.utc(row.targetDate.year, row.targetDate.month, row.targetDate.day);
      allDays.add(day);
      final contributors = jsonDecode(row.contributorsJson) as List;
      for (final c in contributors) {
        final m = c as Map<String, Object?>;
        final moduleId = m['moduleId'] as String;
        final weight = (m['weight'] as num).toDouble();
        final confidence = (m['confidence'] as num).toDouble();
        if (weight * confidence > 0 && firedDaysByModule.containsKey(moduleId)) {
          firedDaysByModule[moduleId]!.add(day);
        }
      }
    }

    final attackRows = await (_db.select(_db.attacks)
          ..where((t) =>
              t.startedAt.isBiggerOrEqualValue(windowStart) &
              t.startedAt.isSmallerThanValue(windowEnd)))
        .get();
    final attackDays = <DateTime>{};
    for (final a in attackRows) {
      attackDays.add(DateTime.utc(a.startedAt.year, a.startedAt.month, a.startedAt.day));
    }

    return moduleIds.map((id) {
      final firedDays = firedDaysByModule[id] ?? <DateTime>{};
      final notFiredDays = allDays.difference(firedDays);
      final firedWithAttack = firedDays.intersection(attackDays).length;
      final notFiredWithAttack = notFiredDays.intersection(attackDays).length;
      return ModuleCohort(
        moduleId: id,
        daysFiredWithAttack: firedWithAttack,
        daysFiredTotal: firedDays.length,
        daysNotFiredWithAttack: notFiredWithAttack,
        daysNotFiredTotal: notFiredDays.length,
      );
    }).toList();
  }
}
```

- [ ] **Step 4: Run**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/data/repos/correlation_repo_test.dart
```

Expected: 2 passing.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "data: CorrelationRepo builds per-module cohorts over a window"
```

---

## Task 4: SuggestionEngine

**Files:**
- Create: `lib/services/suggestion_engine.dart`
- Test: `test/services/suggestion_engine_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/services/suggestion_engine_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/services/suggestion_engine.dart';

CorrelationResult _hit(String moduleId) => CorrelationResult(
      moduleId: moduleId,
      classification: CorrelationClassification.personalHit,
      firedAttackRate: WilsonInterval.compute(successes: 7, trials: 10),
      notFiredAttackRate: WilsonInterval.compute(successes: 2, trials: 50),
      lift: WilsonInterval.differenceLift(
        WilsonInterval.compute(successes: 7, trials: 10),
        WilsonInterval.compute(successes: 2, trials: 50),
      ),
      totalAttacks: 9,
    );

CorrelationResult _miss(String moduleId) => CorrelationResult(
      moduleId: moduleId,
      classification: CorrelationClassification.personalMiss,
      firedAttackRate: WilsonInterval.compute(successes: 0, trials: 20),
      notFiredAttackRate: WilsonInterval.compute(successes: 8, trials: 40),
      lift: WilsonInterval.differenceLift(
        WilsonInterval.compute(successes: 0, trials: 20),
        WilsonInterval.compute(successes: 8, trials: 40),
      ),
      totalAttacks: 8,
    );

CorrelationResult _none(String moduleId) => CorrelationResult(
      moduleId: moduleId,
      classification: CorrelationClassification.inconclusive,
      firedAttackRate: WilsonInterval.compute(successes: 3, trials: 10),
      notFiredAttackRate: WilsonInterval.compute(successes: 4, trials: 20),
      lift: WilsonInterval.differenceLift(
        WilsonInterval.compute(successes: 3, trials: 10),
        WilsonInterval.compute(successes: 4, trials: 20),
      ),
      totalAttacks: 7,
    );

void main() {
  final engine = const SuggestionEngine();

  test('hits with no existing override suggest +1', () {
    final out = engine.suggestionsFor(
      results: [_hit('pressure_drop')],
      currentOverrides: const {},
      dismissedAt: const {},
      now: DateTime.utc(2026, 6, 11),
    );
    expect(out, hasLength(1));
    expect(out.first.moduleId, 'pressure_drop');
    expect(out.first.recommendedOverride, 1.0);
  });

  test('misses suggest -1', () {
    final out = engine.suggestionsFor(
      results: [_miss('humidity_temp_swing')],
      currentOverrides: const {},
      dismissedAt: const {},
      now: DateTime.utc(2026, 6, 11),
    );
    expect(out, hasLength(1));
    expect(out.first.recommendedOverride, -1.0);
  });

  test('already maxed override produces no suggestion', () {
    final out = engine.suggestionsFor(
      results: [_hit('pressure_drop')],
      currentOverrides: const {'pressure_drop': 2.0},
      dismissedAt: const {},
      now: DateTime.utc(2026, 6, 11),
    );
    expect(out, isEmpty);
  });

  test('recently dismissed suggestion is suppressed for 14 days', () {
    final out = engine.suggestionsFor(
      results: [_hit('pressure_drop')],
      currentOverrides: const {},
      dismissedAt: {'pressure_drop': DateTime.utc(2026, 6, 1)},
      now: DateTime.utc(2026, 6, 10),
    );
    expect(out, isEmpty);

    final later = engine.suggestionsFor(
      results: [_hit('pressure_drop')],
      currentOverrides: const {},
      dismissedAt: {'pressure_drop': DateTime.utc(2026, 6, 1)},
      now: DateTime.utc(2026, 6, 20),
    );
    expect(later, hasLength(1));
  });

  test('inconclusive results never suggest', () {
    final out = engine.suggestionsFor(
      results: [_none('caffeine')],
      currentOverrides: const {},
      dismissedAt: const {},
      now: DateTime.utc(2026, 6, 11),
    );
    expect(out, isEmpty);
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/services/suggestion_engine_test.dart
```

- [ ] **Step 3: Implement**

Create `lib/services/suggestion_engine.dart`:

```dart
import 'package:domain/domain.dart';

class WeightSuggestion {
  final String moduleId;
  final double recommendedOverride; // -2..+2
  final String rationale;
  final CorrelationResult source;
  const WeightSuggestion({
    required this.moduleId,
    required this.recommendedOverride,
    required this.rationale,
    required this.source,
  });
}

class SuggestionEngine {
  final Duration dismissalCooldown;
  const SuggestionEngine({this.dismissalCooldown = const Duration(days: 14)});

  List<WeightSuggestion> suggestionsFor({
    required List<CorrelationResult> results,
    required Map<String, double> currentOverrides,
    required Map<String, DateTime> dismissedAt,
    required DateTime now,
  }) {
    final out = <WeightSuggestion>[];
    for (final r in results) {
      if (r.classification != CorrelationClassification.personalHit &&
          r.classification != CorrelationClassification.personalMiss) {
        continue;
      }
      final current = currentOverrides[r.moduleId] ?? 0.0;
      final delta = r.classification == CorrelationClassification.personalHit ? 1.0 : -1.0;
      final recommended = (current + delta).clamp(-2.0, 2.0).toDouble();
      if (recommended == current) continue; // already maxed in that direction
      final dismissed = dismissedAt[r.moduleId];
      if (dismissed != null && now.difference(dismissed) < dismissalCooldown) continue;

      final rationale = r.classification == CorrelationClassification.personalHit
          ? 'Migraines followed ${(r.firedAttackRate.point * 100).round()}% of days when this trigger fired '
              '(vs ${(r.notFiredAttackRate.point * 100).round()}% baseline).'
          : 'Migraines occurred on ${(r.firedAttackRate.point * 100).round()}% of days when this trigger fired '
              '(vs ${(r.notFiredAttackRate.point * 100).round()}% baseline) — weaker than baseline.';

      out.add(WeightSuggestion(
        moduleId: r.moduleId,
        recommendedOverride: recommended,
        rationale: rationale,
        source: r,
      ));
    }
    return out;
  }
}
```

- [ ] **Step 4: Run**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/services/suggestion_engine_test.dart
```

Expected: 5 passing.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "services: SuggestionEngine over CorrelationResults"
```

---

## Task 5: Attack stamping fix + lastRefresh provider

**Files:**
- Modify: `lib/ui/log/log_attack_screen.dart` (stamp attack with active assessment)
- Create: `lib/state/last_refresh_provider.dart`
- Test: `test/state/last_refresh_provider_test.dart`
- Modify: `lib/app/app.dart` (use the new provider instead of returning null)

- [ ] **Step 1: Attack stamping**

Edit `lib/ui/log/log_attack_screen.dart`. Find the `_save()` method. It currently calls:

```dart
await journal.addAttack(
  Attack(startedAt: _start.toUtc(), endedAt: _end?.toUtc(), severity: _severity.round()),
  riskAssessmentId: null, // Plan 5 will wire the assessment row's PK
);
```

Replace with:

```dart
final repo = ref.read(assessmentRepoProvider);
final active = await repo.activeAt(_start.toUtc());
await journal.addAttack(
  Attack(startedAt: _start.toUtc(), endedAt: _end?.toUtc(), severity: _severity.round()),
  riskAssessmentId: active == null ? null : null, // see note below
);
```

⚠ `RiskAssessment` (the domain class) doesn't carry the persisted row's `id` — `activeAt` reconstructs it from JSON. To stamp, we'd need to extend `RiskAssessment` or have `AssessmentRepository.activeAt` return `(RiskAssessment, int id)`. Add a new method to `AssessmentRepository`:

```dart
Future<int?> activeAtRowId(DateTime when) async {
  final rows = await (_db.select(_db.riskAssessments)
        ..where((t) => t.computedAt.isSmallerOrEqualValue(when))
        ..orderBy([(t) => OrderingTerm.desc(t.computedAt)])
        ..limit(1))
      .get();
  return rows.isEmpty ? null : rows.first.id;
}
```

Then use it:

```dart
final activeId = await ref.read(assessmentRepoProvider).activeAtRowId(_start.toUtc());
await journal.addAttack(
  Attack(startedAt: _start.toUtc(), endedAt: _end?.toUtc(), severity: _severity.round()),
  riskAssessmentId: activeId,
);
```

Add the new method to `lib/data/repos/assessment_repository.dart`.

- [ ] **Step 2: Write failing test for last refresh provider**

Create `test/state/last_refresh_provider_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_weatherr/data/repos/assessment_repository.dart';
import 'package:migraine_weatherr/state/last_refresh_provider.dart';
import 'package:migraine_weatherr/state/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns null when no assessments saved', () async {
    final db = AppDatabase.memory();
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);
    addTearDown(db.close);
    final last = await container.read(lastRefreshAtProvider.future);
    expect(last, isNull);
  });

  test('returns the latest computedAt across all assessments', () async {
    final db = AppDatabase.memory();
    final repo = AssessmentRepository(db);
    final t1 = DateTime.utc(2026, 6, 10, 6);
    final t2 = DateTime.utc(2026, 6, 11, 6);
    final base = RiskAssessment(
      score: 30,
      band: RiskBand.moderate,
      contributors: const [],
      computedAt: t1,
      configVersion: 1,
      targetDate: DateTime.utc(2026, 6, 10),
      horizon: RiskHorizon.today,
    );
    await repo.save(base);
    await repo.save(RiskAssessment(
      score: 60,
      band: RiskBand.high,
      contributors: const [],
      computedAt: t2,
      configVersion: 1,
      targetDate: DateTime.utc(2026, 6, 11),
      horizon: RiskHorizon.today,
    ));

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);
    addTearDown(db.close);
    final last = await container.read(lastRefreshAtProvider.future);
    expect(last, t2);
  });
}
```

- [ ] **Step 3: Run — expect FAIL**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/state/last_refresh_provider_test.dart
```

- [ ] **Step 4: Implement provider + repo method**

Add to `lib/data/repos/assessment_repository.dart` (alongside the existing methods):

```dart
Future<DateTime?> latestComputedAt() async {
  final rows = await (_db.select(_db.riskAssessments)
        ..orderBy([(t) => OrderingTerm.desc(t.computedAt)])
        ..limit(1))
      .get();
  return rows.isEmpty ? null : rows.first.computedAt;
}
```

Create `lib/state/last_refresh_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

final lastRefreshAtProvider = FutureProvider<DateTime?>((ref) async {
  return ref.watch(assessmentRepoProvider).latestComputedAt();
});
```

- [ ] **Step 5: Wire `app.dart` to use the new provider**

Edit `lib/app/app.dart`. Find the `_observer = AppLifecycleObserver(...)` block. Replace the `lastRefreshAt` callback:

```dart
lastRefreshAt: () async => null,
```

with:

```dart
lastRefreshAt: () async {
  return ref.read(assessmentRepoProvider).latestComputedAt();
},
```

This requires `assessmentRepoProvider` to be imported. Add the import:

```dart
import '../state/providers.dart';
```

- [ ] **Step 6: Run**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test 2>&1 | tail -3
```

Expected: all green.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "carry-overs: stamp attacks with active assessment id; real lastRefreshAt"
```

---

## Task 6: Copy rules config to documents dir at startup

**Files:**
- Modify: `lib/main.dart` (copy step before `runApp`)
- Modify: `lib/services/background_scheduler.dart` (`_loadConfigText` reads from docs dir)

- [ ] **Step 1: Implement the copy step**

Edit `lib/main.dart`. Add an import:

```dart
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
```

Add a helper near the top of the file (above `main()`):

```dart
Future<void> _exportRulesConfigToDocs() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'rules_config_v1.json'));
    final bundled = await rootBundle.loadString('assets/rules_config_v1.json');
    await file.writeAsString(bundled);
  } catch (_) {
    // Web / unsupported — background scheduler is also unsupported, so
    // skipping silently is fine.
  }
}
```

Call it from `main()` after `WidgetsFlutterBinding.ensureInitialized()`:

```dart
await _exportRulesConfigToDocs();
```

- [ ] **Step 2: Update the background scheduler's `_loadConfigText`**

Edit `lib/services/background_scheduler.dart`. The current `_loadConfigText` tries `Directory.current.path`. Replace with:

```dart
Future<String> _loadConfigText() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'rules_config_v1.json'));
    if (await file.exists()) return file.readAsStringSync();
  } catch (_) {/* fall through */}
  return ''; // parseOrFallback yields minimal default
}
```

Add imports:

```dart
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
```

- [ ] **Step 3: Smoke test main compile + suite**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter analyze 2>&1 | tail -3
cd /Users/amansur/projects/migraine-weatherr && flutter test 2>&1 | tail -3
```

Expected: no errors; all tests green.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "background: copy rules_config to docs dir at startup; isolate reads from there"
```

---

## Task 7: Insights providers + eligibility gating

**Files:**
- Create: `lib/state/correlation_provider.dart`
- Create: `lib/state/insights_eligibility_provider.dart`
- Create: `lib/state/suggestions_provider.dart`

- [ ] **Step 1: Eligibility provider**

Create `lib/state/insights_eligibility_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// True once the user has logged ≥3 attacks. Used by router/UI to gate the
/// Insights tab.
final insightsEligibleProvider = FutureProvider<bool>((ref) async {
  final journal = ref.watch(journalSourceProvider);
  final attacks = await journal.recentAttacks(const Duration(days: 365), now: DateTime.now().toUtc());
  return attacks.length >= 3;
});

final attackCountProvider = FutureProvider<int>((ref) async {
  final journal = ref.watch(journalSourceProvider);
  final attacks = await journal.recentAttacks(const Duration(days: 365), now: DateTime.now().toUtc());
  return attacks.length;
});
```

- [ ] **Step 2: Correlation provider**

Create `lib/state/correlation_provider.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repos/correlation_repo.dart';
import 'providers.dart';

const _moduleIds = [
  'pressure_drop',
  'humidity_temp_swing',
  'air_quality',
  'sleep_deficit',
  'hrv_letdown',
  'menstrual_phase',
  'refractory',
  'alcohol',
  'caffeine',
  'stress',
  'hydration',
];

final correlationRepoProvider = Provider<CorrelationRepo>((ref) {
  return CorrelationRepo(ref.watch(databaseProvider));
});

final correlationResultsProvider = FutureProvider<List<CorrelationResult>>((ref) async {
  final repo = ref.watch(correlationRepoProvider);
  final now = DateTime.now().toUtc();
  final cohorts = await repo.buildCohorts(
    windowStart: now.subtract(const Duration(days: 90)),
    windowEnd: now.add(const Duration(days: 1)),
    moduleIds: _moduleIds,
  );
  return cohorts.map((c) => const CorrelationAnalyzer().analyze(c)).toList();
});
```

- [ ] **Step 3: Suggestions provider**

Create `lib/state/suggestions_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/suggestion_engine.dart';
import 'correlation_provider.dart';
import 'providers.dart';
import 'trigger_flags_provider.dart';

final suggestionEngineProvider = Provider<SuggestionEngine>((_) => const SuggestionEngine());

final suggestionsProvider = FutureProvider<List<WeightSuggestion>>((ref) async {
  final results = await ref.watch(correlationResultsProvider.future);
  final flags = await ref.watch(triggerFlagsProvider.future);
  // For v1 we don't persist per-trigger dismissal timestamps — leave the map
  // empty so all eligible suggestions surface. Plan 6 (post-v1) can add a
  // dismissal table.
  final engine = ref.watch(suggestionEngineProvider);
  return engine.suggestionsFor(
    results: results,
    currentOverrides: flags.weightOverrides,
    dismissedAt: const {},
    now: DateTime.now().toUtc(),
  );
});
```

- [ ] **Step 4: Quick compile-check**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter analyze lib/state/ 2>&1 | tail -5
```

Expected: no errors.

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test 2>&1 | tail -3
```

Expected: still green.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "state: Insights eligibility + correlation + suggestions providers"
```

---

## Task 8: Insights screen UI (calendar heatmap, correlation cards, suggestion cards)

**Files:**
- Create: `lib/ui/insights/insights_screen.dart`
- Create: `lib/ui/insights/calendar_heatmap.dart`
- Create: `lib/ui/insights/correlation_card.dart`
- Create: `lib/ui/insights/suggestion_card.dart`
- Test: `test/ui/insights/insights_screen_test.dart`

- [ ] **Step 1: Implement CalendarHeatmap widget**

Create `lib/ui/insights/calendar_heatmap.dart`:

```dart
import 'package:flutter/material.dart';

import '../../app/theme.dart';

class CalendarHeatmap extends StatelessWidget {
  /// Days (UTC midnight) on which an attack occurred.
  final Set<DateTime> attackDays;
  /// First day to show (inclusive).
  final DateTime windowStart;
  /// Last day to show (inclusive).
  final DateTime windowEnd;
  const CalendarHeatmap({
    super.key,
    required this.attackDays,
    required this.windowStart,
    required this.windowEnd,
  });

  @override
  Widget build(BuildContext context) {
    final days = <DateTime>[];
    var d = DateTime.utc(windowStart.year, windowStart.month, windowStart.day);
    final end = DateTime.utc(windowEnd.year, windowEnd.month, windowEnd.day);
    while (!d.isAfter(end)) {
      days.add(d);
      d = d.add(const Duration(days: 1));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = 14;
        final cellSize = (constraints.maxWidth - (cols - 1) * 4) / cols;
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: days.map((day) {
            final hit = attackDays.contains(day);
            return Container(
              width: cellSize,
              height: cellSize,
              decoration: BoxDecoration(
                color: hit ? BrandColors.bandVeryHigh : BrandColors.sage.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
```

- [ ] **Step 2: Correlation card**

Create `lib/ui/insights/correlation_card.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';

const _moduleLabels = <String, String>{
  'pressure_drop': 'Pressure changes',
  'humidity_temp_swing': 'Humidity + temp swing',
  'air_quality': 'Air quality',
  'sleep_deficit': 'Sleep',
  'hrv_letdown': 'HRV / stress let-down',
  'menstrual_phase': 'Menstrual cycle',
  'refractory': 'Recent attack',
  'alcohol': 'Alcohol',
  'caffeine': 'Caffeine',
  'stress': 'Stress',
  'hydration': 'Hydration',
};

class CorrelationCard extends StatelessWidget {
  final CorrelationResult result;
  const CorrelationCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final label = _moduleLabels[result.moduleId] ?? result.moduleId;
    final fired = result.firedAttackRate;
    final notFired = result.notFiredAttackRate;
    final classification = result.classification;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ClassificationBadge(classification: classification),
                const SizedBox(width: 8),
                Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${(fired.point * 100).round()}% attack rate when this fired '
              '(${fired.trials} days) — '
              'vs ${(notFired.point * 100).round()}% baseline (${notFired.trials} days).',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassificationBadge extends StatelessWidget {
  final CorrelationClassification classification;
  const _ClassificationBadge({required this.classification});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (classification) {
      CorrelationClassification.personalHit =>
        ('Personal hit', BrandColors.bandHigh),
      CorrelationClassification.personalMiss =>
        ('Personal miss', BrandColors.bandLow),
      CorrelationClassification.inconclusive =>
        ('Unclear', BrandColors.sage),
      CorrelationClassification.insufficientData =>
        ('Calibrating', BrandColors.sage),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}
```

- [ ] **Step 3: Suggestion card**

Create `lib/ui/insights/suggestion_card.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/suggestion_engine.dart';
import '../../state/trigger_flags_provider.dart';

const _moduleLabels = <String, String>{
  'pressure_drop': 'Pressure changes',
  'humidity_temp_swing': 'Humidity + temp swing',
  'air_quality': 'Air quality',
  'sleep_deficit': 'Sleep',
  'hrv_letdown': 'HRV / stress let-down',
  'menstrual_phase': 'Menstrual cycle',
  'refractory': 'Recent attack',
  'alcohol': 'Alcohol',
  'caffeine': 'Caffeine',
  'stress': 'Stress',
  'hydration': 'Hydration',
};

class SuggestionCard extends ConsumerWidget {
  final WeightSuggestion suggestion;
  final VoidCallback onDismiss;
  const SuggestionCard({super.key, required this.suggestion, required this.onDismiss});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = _moduleLabels[suggestion.moduleId] ?? suggestion.moduleId;
    final increase = suggestion.recommendedOverride > 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(increase ? Icons.trending_up : Icons.trending_down,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
              ],
            ),
            const SizedBox(height: 8),
            Text(suggestion.rationale, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(
                  onPressed: () => _accept(ref),
                  child: Text(increase ? 'Increase weight' : 'Decrease weight'),
                ),
                const SizedBox(width: 12),
                TextButton(onPressed: onDismiss, child: const Text('Not now')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _accept(WidgetRef ref) async {
    final flags = await ref.read(triggerFlagsProvider.future);
    final overrides = Map<String, double>.from(flags.weightOverrides);
    overrides[suggestion.moduleId] = suggestion.recommendedOverride;
    await ref.read(saveTriggerFlagsProvider)(UserTriggerFlags(
      flaggedModuleIds: flags.flaggedModuleIds,
      weightOverrides: overrides,
    ));
  }
}
```

- [ ] **Step 4: Insights screen**

Create `lib/ui/insights/insights_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/correlation_provider.dart';
import '../../state/insights_eligibility_provider.dart';
import '../../state/providers.dart';
import '../../state/suggestions_provider.dart';
import 'calendar_heatmap.dart';
import 'correlation_card.dart';
import 'suggestion_card.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eligible = ref.watch(insightsEligibleProvider);
    final attackCount = ref.watch(attackCountProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: eligible.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (ok) {
          if (!ok) {
            final count = attackCount.asData?.value ?? 0;
            return _NotEligible(count: count);
          }
          return _Body();
        },
      ),
    );
  }
}

class _NotEligible extends StatelessWidget {
  final int count;
  const _NotEligible({required this.count});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Calibrating', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Insights unlock after you\'ve logged 3 migraines. '
              'You\'ve logged $count so far.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journal = ref.watch(journalSourceProvider);
    final correlations = ref.watch(correlationResultsProvider);
    final suggestions = ref.watch(suggestionsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Last 90 days', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        FutureBuilder(
          future: journal.recentAttacks(const Duration(days: 90), now: DateTime.now().toUtc()),
          builder: (context, snap) {
            final attacks = snap.data ?? const [];
            final days = attacks
                .map((a) => DateTime.utc(a.startedAt.year, a.startedAt.month, a.startedAt.day))
                .toSet();
            final now = DateTime.now().toUtc();
            return CalendarHeatmap(
              attackDays: days,
              windowStart: now.subtract(const Duration(days: 89)),
              windowEnd: now,
            );
          },
        ),
        const SizedBox(height: 24),
        Text('Trigger correlations', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        correlations.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (results) {
            final shown = results.where((r) =>
                r.classification == CorrelationClassification.personalHit ||
                r.classification == CorrelationClassification.personalMiss).toList();
            if (shown.isEmpty) {
              return const Text('No clear correlations yet — keep logging.');
            }
            return Column(
              children: shown.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CorrelationCard(result: r),
              )).toList(),
            );
          },
        ),
        const SizedBox(height: 24),
        Text('Suggested adjustments', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        suggestions.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => Text('Error: $e'),
          data: (list) {
            if (list.isEmpty) {
              return const Text('No suggestions right now.');
            }
            return Column(
              children: list.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SuggestionCard(suggestion: s, onDismiss: () {}),
              )).toList(),
            );
          },
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: Smoke widget test**

Create `test/ui/insights/insights_screen_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:migraine_weatherr/state/insights_eligibility_provider.dart';
import 'package:migraine_weatherr/ui/insights/insights_screen.dart';

void main() {
  testWidgets('shows calibrating state when ineligible', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          insightsEligibleProvider.overrideWith((ref) async => false),
          attackCountProvider.overrideWith((ref) async => 1),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const InsightsScreen()),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Calibrating'), findsOneWidget);
    expect(find.textContaining('logged 1 so far'), findsOneWidget);
  });
}
```

- [ ] **Step 6: Run**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/ui/insights/
```

Expected: 1 passing.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "ui: Insights screen with calendar heatmap, correlation + suggestion cards"
```

---

## Task 9: Router + Today nav link

**Files:**
- Modify: `lib/app/router.dart` (add `/insights`)
- Modify: `lib/ui/today/today_screen.dart` (add nav button to Insights when eligible)

- [ ] **Step 1: Add route**

Edit `lib/app/router.dart`. Add the import:

```dart
import '../ui/insights/insights_screen.dart';
```

Add a new `GoRoute` inside `routes:`:

```dart
GoRoute(path: '/insights', builder: (_, __) => const InsightsScreen()),
```

- [ ] **Step 2: Add nav button on Today**

Edit `lib/ui/today/today_screen.dart`. In the `AppBar` `actions:` list, before the existing Settings IconButton, add:

```dart
Consumer(builder: (context, ref, _) {
  final eligible = ref.watch(insightsEligibleProvider).asData?.value ?? false;
  if (!eligible) return const SizedBox.shrink();
  return IconButton(
    onPressed: () => context.push('/insights'),
    icon: const Icon(Icons.insights_outlined),
  );
}),
```

Add imports at the top:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/insights_eligibility_provider.dart';
```

(`flutter_riverpod` is already imported transitively but make sure `Consumer` is available.)

- [ ] **Step 3: Run**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test 2>&1 | tail -3
```

Expected: all green.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "ui: Insights route + Today nav link (eligibility-gated)"
```

---

## Task 10: Docs + CI sanity + Plan 5 wrap-up

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update README**

Edit `README.md`. In the Status block, change:

```markdown
- **Plan 5** — Insights screen + correlation-driven personalization — not started
```

to:

```markdown
- **Plan 5** — Insights screen + correlation-driven personalization ✓
```

Add a short Insights section after the existing Architecture section:

```markdown
## Personalization

After you've logged 3 migraines, the Insights tab unlocks:

- **Calendar heatmap** of the last 90 days, with attack days highlighted.
- **Trigger correlation cards** showing per-trigger attack rate when that trigger was active vs not, with classification (personal hit / personal miss / unclear).
- **Suggested weight adjustments** — when a trigger correlates strongly enough (90% Wilson CI excludes zero, ≥2× baseline rate, ≥3 attacks in the fired cohort), the app surfaces a one-tap card to bump that trigger's weight in your personal model. Every change is explicit, reversible, and based on a citeable cohort — no silent ML drift.
```

- [ ] **Step 2: Full sanity sweep**

```bash
cd /Users/amansur/projects/migraine-weatherr
flutter analyze 2>&1 | tail -3
flutter test 2>&1 | tail -3
flutter build web 2>&1 | tail -3
cd packages/domain && dart test 2>&1 | tail -3
```

Expected:
- `flutter analyze` — exit 0 (infos OK).
- `flutter test` — all green (Plan 4 baseline was 56; should be ~62 now).
- `flutter build web` — "✓ Built build/web".
- Domain tests — 78 passing (Plan 4 baseline 69 + 9 correlation tests).

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "docs: Plan 5 status; v1 feature-complete"
```

---

## Done

After Task 10, you have a v1-feature-complete app:

- **Insights screen** unlocks after 3 logged attacks. Calendar heatmap of attack history. Per-trigger correlation cards with personal-hit / personal-miss classifications grounded in 90% Wilson CI math. User-in-the-loop suggested weight adjustments.
- **Wilson-CI correlation engine** in the pure-Dart domain — fully testable, no Flutter, derivable from cohort counts. Used by `CorrelationRepo` + `SuggestionEngine` to produce explainable recommendations.
- **Carry-overs from Plan 4 resolved**: foreground-resume catch-up reads real `lastRefreshAt` from `AssessmentRepository`. Background isolate loads the rules config from the documents dir (copied at app startup), no more silent fallback to the minimal default.
- **Attack stamping** — every new attack records the active `RiskAssessment.id` so the correlation engine can reconstruct ground truth for past-attack analyses.

What's deliberately deferred past v1 (post-launch items):
- Per-suggestion dismissal cooldown is wired in `SuggestionEngine` but not persisted — `Dismissed` table is a Plan 6 candidate.
- Calendar heatmap is a flat last-90-days grid — week-headers, month labels, and tap-to-see-attack drill-in are polish items.
- Push notifications use only local notifications — server-side push (e.g., for a "your friend is sharing risk with you" feature) is out of scope.
- The model still doesn't use logged attacks for direct prediction — only for *user-accepted* weight adjustments. The deliberate "no silent ML" stance remains.

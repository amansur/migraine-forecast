# Plan 1 — Foundation + Domain Core

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Scaffold the Flutter project and build the pure-Dart `domain/` package — `RiskEngine`, all 11 `TriggerModule`s, `BaselineStore`, rules-config loader, and a CLI driver — fully tested, with no Flutter or IO dependencies.

**Architecture:** Monorepo with `migraine_weatherr/` as the Flutter app shell at the project root and `packages/domain/` as a pure-Dart subpackage (no Flutter imports). Engine is callable from a `bin/score_cli.dart` so it can be exercised end-to-end before any UI exists. Subsequent plans depend on the types and interfaces defined here.

**Tech Stack:** Dart 3.4+, Flutter 3.22+, `package:test`, `package:equatable` (value equality in domain types). Pure Dart only — no Flutter, `dart:io`, or HTTP.

---

## File Structure

```
/Users/amansur/projects/migraine-weatherr/
├── pubspec.yaml                              # Flutter app shell (created by flutter create)
├── lib/main.dart                             # placeholder (real UI in Plan 3)
├── analysis_options.yaml                     # lints
├── .github/workflows/ci.yaml                 # CI for domain tests
├── assets/rules_config_v1.json               # bundled default config
├── packages/domain/
│   ├── pubspec.yaml                          # pure-Dart package
│   ├── analysis_options.yaml                 # forbids package:flutter imports
│   ├── lib/
│   │   ├── domain.dart                       # barrel export
│   │   └── src/
│   │       ├── types/
│   │       │   ├── data_requirement.dart
│   │       │   ├── trigger_signal.dart
│   │       │   ├── risk_assessment.dart
│   │       │   ├── evaluation_context.dart
│   │       │   ├── weather.dart              # WeatherSample, WeatherSeries, AirQualitySample
│   │       │   ├── health.dart               # SleepRecord, HrvSample, MenstrualEvent, etc.
│   │       │   ├── journal.dart              # JournalEntry, Attack
│   │       │   └── user_flags.dart
│   │       ├── config/
│   │       │   ├── rules_config.dart         # RulesConfig + ModuleParams + ScoreBands
│   │       │   └── rules_config_loader.dart  # parses JSON, validates, fallback
│   │       ├── baselines/
│   │       │   └── baseline_store.dart
│   │       ├── engine/
│   │       │   ├── trigger_module.dart       # interface + helpers
│   │       │   └── risk_engine.dart
│   │       └── modules/
│   │           ├── pressure_drop.dart
│   │           ├── humidity_temp_swing.dart
│   │           ├── air_quality.dart
│   │           ├── sleep_deficit.dart
│   │           ├── hrv_letdown.dart
│   │           ├── menstrual_phase.dart
│   │           ├── refractory.dart
│   │           ├── alcohol.dart
│   │           ├── caffeine.dart
│   │           ├── stress.dart
│   │           └── hydration.dart
│   ├── test/                                 # mirrors lib/src/ structure
│   └── bin/score_cli.dart                    # CLI driver
```

---

## Task 1: Scaffold the Flutter project

**Files:**
- Create: `pubspec.yaml`, `lib/main.dart`, `analysis_options.yaml`, `.gitignore`
- Create: `packages/domain/pubspec.yaml`, `packages/domain/analysis_options.yaml`, `packages/domain/lib/domain.dart`

- [ ] **Step 1: Run `flutter create` in the project root**

```bash
cd /Users/amansur/projects/migraine-weatherr
flutter create --project-name migraine_weatherr --org com.migraineweatherr --platforms ios,android,web .
```

Expected: project files generated; existing `docs/` directory preserved.

- [ ] **Step 2: Create the domain subpackage**

```bash
mkdir -p packages/domain/lib/src
mkdir -p packages/domain/test
mkdir -p packages/domain/bin
```

Write `packages/domain/pubspec.yaml`:

```yaml
name: domain
description: Pure-Dart migraine-risk engine. No Flutter or IO dependencies.
version: 0.1.0
publish_to: none

environment:
  sdk: ^3.4.0

dependencies:
  equatable: ^2.0.5

dev_dependencies:
  test: ^1.25.0
  lints: ^4.0.0
```

Write `packages/domain/analysis_options.yaml`:

```yaml
include: package:lints/recommended.yaml

analyzer:
  errors:
    # Disallow Flutter imports in the pure-Dart domain package.
    depend_on_referenced_packages: error
  exclude:
    - test/fixtures/**

linter:
  rules:
    avoid_print: true
    prefer_const_constructors: true
    prefer_final_locals: true
```

Write `packages/domain/lib/domain.dart` (placeholder barrel):

```dart
// Barrel export. Each subsequent task adds to this file.
```

- [ ] **Step 3: Wire domain as a path dependency in the root pubspec**

Edit `pubspec.yaml` (root) — add under `dependencies:`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  domain:
    path: packages/domain
```

- [ ] **Step 4: Resolve dependencies**

```bash
cd packages/domain && dart pub get
cd /Users/amansur/projects/migraine-weatherr && flutter pub get
```

Expected: both succeed with no errors.

- [ ] **Step 5: Verify the empty domain test runner works**

Create `packages/domain/test/smoke_test.dart`:

```dart
import 'package:test/test.dart';

void main() {
  test('domain package is wired', () {
    expect(1 + 1, 2);
  });
}
```

Run:

```bash
cd packages/domain && dart test
```

Expected: 1 passing test.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "Scaffold Flutter app + pure-Dart domain package"
```

---

## Task 2: Core type — TriggerSignal

**Files:**
- Create: `packages/domain/lib/src/types/trigger_signal.dart`
- Create: `packages/domain/lib/src/types/data_requirement.dart`
- Test: `packages/domain/test/types/trigger_signal_test.dart`
- Modify: `packages/domain/lib/domain.dart`

- [ ] **Step 1: Write failing test**

Create `packages/domain/test/types/trigger_signal_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('TriggerSignal', () {
    test('clamps weight and confidence into valid ranges', () {
      final s = TriggerSignal(
        moduleId: 'x',
        weight: 100,
        confidence: 2,
        explanation: 'oversaturated',
      );
      expect(s.weight, 100);          // unclamped at construction; engine clamps the sum
      expect(s.confidence, 1.0);      // confidence MUST be clamped to [0,1] at construction
    });

    test('zero() factory produces a zero-contribution signal', () {
      final s = TriggerSignal.zero(
        moduleId: 'sleep_deficit',
        reason: 'no data',
        missing: DataRequirement.healthSleep,
      );
      expect(s.weight, 0);
      expect(s.confidence, 0);
      expect(s.explanation, 'no data');
      expect(s.missing, DataRequirement.healthSleep);
    });

    test('zero() without missing produces null missing', () {
      final s = TriggerSignal.zero(moduleId: 'x', reason: 'unspecified');
      expect(s.missing, isNull);
    });

    test('value equality', () {
      final a = TriggerSignal(moduleId: 'x', weight: 5, confidence: 0.5, explanation: 'a');
      final b = TriggerSignal(moduleId: 'x', weight: 5, confidence: 0.5, explanation: 'a');
      expect(a, equals(b));
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd packages/domain && dart test test/types/trigger_signal_test.dart
```

Expected: compile error (`TriggerSignal` undefined).

- [ ] **Step 3: Implement DataRequirement**

Create `packages/domain/lib/src/types/data_requirement.dart`:

```dart
import 'package:equatable/equatable.dart';

/// Identifies a class of input the engine needs for a given module.
class DataRequirement extends Equatable {
  final String id;     // e.g., "weather.pressure", "health.sleep"
  final String label;  // human-readable label for UI
  const DataRequirement({required this.id, required this.label});

  static const weatherPressure   = DataRequirement(id: 'weather.pressure',   label: 'Weather (pressure)');
  static const weatherHumidity   = DataRequirement(id: 'weather.humidity',   label: 'Weather (humidity)');
  static const weatherAirQuality = DataRequirement(id: 'weather.air_quality', label: 'Air quality');
  static const healthSleep       = DataRequirement(id: 'health.sleep',       label: 'Sleep data');
  static const healthHrv         = DataRequirement(id: 'health.hrv',         label: 'HRV data');
  static const healthMenstrual   = DataRequirement(id: 'health.menstrual',   label: 'Menstrual data');
  static const journalAlcohol    = DataRequirement(id: 'journal.alcohol',    label: 'Alcohol log');
  static const journalCaffeine   = DataRequirement(id: 'journal.caffeine',   label: 'Caffeine log');
  static const journalStress     = DataRequirement(id: 'journal.stress',     label: 'Stress log');
  static const journalHydration  = DataRequirement(id: 'journal.hydration',  label: 'Hydration log');
  static const attackHistory     = DataRequirement(id: 'attacks.history',    label: 'Attack history');

  @override
  List<Object?> get props => [id];
}
```

- [ ] **Step 4: Implement TriggerSignal**

Create `packages/domain/lib/src/types/trigger_signal.dart`:

```dart
import 'package:equatable/equatable.dart';
import 'data_requirement.dart';

class TriggerSignal extends Equatable {
  final String moduleId;
  final double weight;
  final double confidence;
  final String explanation;
  final DataRequirement? missing; // non-null when zero confidence due to missing data

  TriggerSignal({
    required this.moduleId,
    required this.weight,
    required double confidence,
    required this.explanation,
    this.missing,
  }) : confidence = confidence.clamp(0.0, 1.0).toDouble();

  factory TriggerSignal.zero({
    required String moduleId,
    required String reason,
    DataRequirement? missing,
  }) =>
      TriggerSignal(
        moduleId: moduleId,
        weight: 0,
        confidence: 0,
        explanation: reason,
        missing: missing,
      );

  double get contribution => weight * confidence;

  @override
  List<Object?> get props => [moduleId, weight, confidence, explanation, missing];
}
```

- [ ] **Step 5: Update barrel**

Replace `packages/domain/lib/domain.dart`:

```dart
export 'src/types/data_requirement.dart';
export 'src/types/trigger_signal.dart';
```

- [ ] **Step 6: Run — expect PASS**

```bash
cd packages/domain && dart test test/types/trigger_signal_test.dart
```

Expected: 3 passing tests.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "domain: add TriggerSignal and DataRequirement"
```

---

## Task 3: Weather, Health, and Journal input types

**Files:**
- Create: `packages/domain/lib/src/types/weather.dart`
- Create: `packages/domain/lib/src/types/health.dart`
- Create: `packages/domain/lib/src/types/journal.dart`
- Test: `packages/domain/test/types/weather_test.dart`
- Modify: `packages/domain/lib/domain.dart`

These are plain value types used by `EvaluationContext`. Adapters in Plan 2 will produce them.

- [ ] **Step 1: Write failing test**

Create `packages/domain/test/types/weather_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('WeatherSeries', () {
    test('returns null delta for empty series', () {
      final s = WeatherSeries(samples: const []);
      expect(s.maxPressureDropOver(Duration(hours: 24)), isNull);
    });

    test('computes max 24h pressure drop within window', () {
      final start = DateTime.utc(2026, 6, 10, 0);
      final samples = [
        WeatherSample(at: start, pressureMsl: 1015, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: start.add(Duration(hours: 12)), pressureMsl: 1012, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: start.add(Duration(hours: 24)), pressureMsl: 1008, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: start.add(Duration(hours: 36)), pressureMsl: 1005, temperatureC: 20, humidityPct: 50),
      ];
      final s = WeatherSeries(samples: samples);
      // Largest 24h drop ends at hour 36: 1012 -> 1005 = 7 hPa
      expect(s.maxPressureDropOver(Duration(hours: 24)), closeTo(7.0, 0.01));
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd packages/domain && dart test test/types/weather_test.dart
```

Expected: compile error.

- [ ] **Step 3: Implement weather types**

Create `packages/domain/lib/src/types/weather.dart`:

```dart
import 'package:equatable/equatable.dart';

class WeatherSample extends Equatable {
  final DateTime at;
  final double pressureMsl;     // hPa
  final double temperatureC;
  final double humidityPct;
  const WeatherSample({
    required this.at,
    required this.pressureMsl,
    required this.temperatureC,
    required this.humidityPct,
  });
  @override
  List<Object?> get props => [at, pressureMsl, temperatureC, humidityPct];
}

class WeatherSeries extends Equatable {
  /// Hourly samples, sorted ascending by `at`. May include historical + forecast.
  final List<WeatherSample> samples;
  const WeatherSeries({required this.samples});

  /// Returns the maximum drop in pressure within any [window]-sized sliding pair.
  /// Returns null if the series is empty or has only one sample.
  double? maxPressureDropOver(Duration window) {
    if (samples.length < 2) return null;
    double maxDrop = 0;
    int j = 0;
    for (int i = 0; i < samples.length; i++) {
      while (j < samples.length && samples[j].at.difference(samples[i].at) < window) {
        j++;
      }
      for (int k = i + 1; k < j; k++) {
        final drop = samples[i].pressureMsl - samples[k].pressureMsl;
        if (drop > maxDrop) maxDrop = drop;
      }
    }
    return maxDrop;
  }

  /// Returns the max minus min temperature within [window] of the latest sample.
  double? tempSwingInLast(Duration window) {
    if (samples.isEmpty) return null;
    final cutoff = samples.last.at.subtract(window);
    final inWindow = samples.where((s) => !s.at.isBefore(cutoff)).toList();
    if (inWindow.isEmpty) return null;
    final max = inWindow.map((s) => s.temperatureC).reduce((a, b) => a > b ? a : b);
    final min = inWindow.map((s) => s.temperatureC).reduce((a, b) => a < b ? a : b);
    return max - min;
  }

  /// Maximum humidity value across the next [window] starting from [from].
  double? maxHumidityFrom(DateTime from, Duration window) {
    final inWindow = samples.where(
      (s) => !s.at.isBefore(from) && s.at.isBefore(from.add(window)),
    );
    if (inWindow.isEmpty) return null;
    return inWindow.map((s) => s.humidityPct).reduce((a, b) => a > b ? a : b);
  }

  @override
  List<Object?> get props => [samples];
}

class AirQualitySample extends Equatable {
  final DateTime at;
  final double pm25;      // µg/m³
  const AirQualitySample({required this.at, required this.pm25});
  @override
  List<Object?> get props => [at, pm25];
}

class AirQualitySeries extends Equatable {
  final List<AirQualitySample> samples;
  const AirQualitySeries({required this.samples});

  double? maxPm25From(DateTime from, Duration window) {
    final inWindow = samples.where(
      (s) => !s.at.isBefore(from) && s.at.isBefore(from.add(window)),
    );
    if (inWindow.isEmpty) return null;
    return inWindow.map((s) => s.pm25).reduce((a, b) => a > b ? a : b);
  }

  @override
  List<Object?> get props => [samples];
}
```

- [ ] **Step 4: Implement health types**

Create `packages/domain/lib/src/types/health.dart`:

```dart
import 'package:equatable/equatable.dart';

class SleepRecord extends Equatable {
  final DateTime night;            // local "night" the sleep belongs to (date-only at UTC midnight)
  final Duration totalSleep;
  final double efficiency;         // 0..1, fraction of in-bed time asleep
  final DateTime sleepStart;       // when the user fell asleep
  const SleepRecord({
    required this.night,
    required this.totalSleep,
    required this.efficiency,
    required this.sleepStart,
  });
  @override
  List<Object?> get props => [night, totalSleep, efficiency, sleepStart];
}

class HrvSample extends Equatable {
  final DateTime at;
  final double rmssdMs;
  const HrvSample({required this.at, required this.rmssdMs});
  @override
  List<Object?> get props => [at, rmssdMs];
}

class MenstrualEvent extends Equatable {
  final DateTime onsetDate;  // UTC midnight of cycle day 1
  const MenstrualEvent({required this.onsetDate});
  @override
  List<Object?> get props => [onsetDate];
}

class HealthMetrics extends Equatable {
  final List<SleepRecord> recentSleep;    // descending by night, most recent first
  final List<HrvSample> recentHrv;        // descending by at
  final List<MenstrualEvent> menstrualHistory; // descending by onsetDate
  const HealthMetrics({
    this.recentSleep = const [],
    this.recentHrv = const [],
    this.menstrualHistory = const [],
  });
  @override
  List<Object?> get props => [recentSleep, recentHrv, menstrualHistory];
}
```

- [ ] **Step 5: Implement journal types**

Create `packages/domain/lib/src/types/journal.dart`:

```dart
import 'package:equatable/equatable.dart';

enum JournalKind { alcohol, caffeine, stress, hydration }

class JournalEntry extends Equatable {
  final DateTime at;
  final JournalKind kind;
  /// Free-form payload. By convention:
  /// - alcohol: {"units": double}
  /// - caffeine: {"mg": double}
  /// - stress: {"rating": int 1..5}
  /// - hydration: {"liters": double}
  final Map<String, Object?> payload;
  const JournalEntry({required this.at, required this.kind, required this.payload});
  @override
  List<Object?> get props => [at, kind, payload];
}

class Attack extends Equatable {
  final DateTime startedAt;
  final DateTime? endedAt;
  final int severity; // 1..10
  const Attack({required this.startedAt, this.endedAt, required this.severity});
  @override
  List<Object?> get props => [startedAt, endedAt, severity];
}
```

- [ ] **Step 6: Update barrel**

Edit `packages/domain/lib/domain.dart`:

```dart
export 'src/types/data_requirement.dart';
export 'src/types/trigger_signal.dart';
export 'src/types/weather.dart';
export 'src/types/health.dart';
export 'src/types/journal.dart';
```

- [ ] **Step 7: Run — expect PASS**

```bash
cd packages/domain && dart test test/types/weather_test.dart
```

Expected: 2 passing tests.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "domain: add weather, health, journal input types"
```

---

## Task 4: EvaluationContext, UserTriggerFlags, RiskAssessment

**Files:**
- Create: `packages/domain/lib/src/types/evaluation_context.dart`
- Create: `packages/domain/lib/src/types/user_flags.dart`
- Create: `packages/domain/lib/src/types/risk_assessment.dart`
- Test: `packages/domain/test/types/risk_assessment_test.dart`
- Modify: `packages/domain/lib/domain.dart`

- [ ] **Step 1: Write failing test**

Create `packages/domain/test/types/risk_assessment_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('RiskAssessment', () {
    test('bands map score to band correctly', () {
      const bands = ScoreBands(low: 25, moderate: 50, high: 75);
      expect(bands.bandFor(10), RiskBand.low);
      expect(bands.bandFor(30), RiskBand.moderate);
      expect(bands.bandFor(60), RiskBand.high);
      expect(bands.bandFor(90), RiskBand.veryHigh);
      expect(bands.bandFor(25), RiskBand.moderate); // boundary inclusive on lower
    });

    test('isOnboarding when all contributors have zero confidence', () {
      final ass = RiskAssessment(
        score: 0,
        band: RiskBand.low,
        contributors: [
          TriggerSignal.zero(moduleId: 'x', reason: 'no data'),
          TriggerSignal.zero(moduleId: 'y', reason: 'no data'),
        ],
        computedAt: DateTime.utc(2026, 6, 10),
        configVersion: 1,
        targetDate: DateTime.utc(2026, 6, 10),
        horizon: RiskHorizon.today,
      );
      expect(ass.isOnboarding, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd packages/domain && dart test test/types/risk_assessment_test.dart
```

Expected: compile error.

- [ ] **Step 3: Implement UserTriggerFlags**

Create `packages/domain/lib/src/types/user_flags.dart`:

```dart
import 'package:equatable/equatable.dart';

class UserTriggerFlags extends Equatable {
  /// Module IDs the user flagged during onboarding as suspected triggers.
  final Set<String> flaggedModuleIds;
  /// Per-module weight override in [-2.0, +2.0]. Missing key = 0 (no override).
  final Map<String, double> weightOverrides;
  const UserTriggerFlags({
    this.flaggedModuleIds = const {},
    this.weightOverrides = const {},
  });

  bool isFlagged(String moduleId) => flaggedModuleIds.contains(moduleId);
  double overrideFor(String moduleId) =>
      (weightOverrides[moduleId] ?? 0.0).clamp(-2.0, 2.0).toDouble();

  @override
  List<Object?> get props => [flaggedModuleIds, weightOverrides];
}
```

- [ ] **Step 4: Implement EvaluationContext**

Create `packages/domain/lib/src/types/evaluation_context.dart`:

```dart
import 'package:equatable/equatable.dart';
import 'health.dart';
import 'journal.dart';
import 'user_flags.dart';
import 'weather.dart';

class EvaluationContext extends Equatable {
  final DateTime now;
  final DateTime targetDate;          // UTC midnight of the day being scored
  final WeatherSeries? weather;
  final AirQualitySeries? airQuality;
  final HealthMetrics? health;
  final List<JournalEntry> recentJournal;
  final List<Attack> recentAttacks;
  final UserTriggerFlags userFlags;
  final BaselineSnapshot baselines;

  const EvaluationContext({
    required this.now,
    required this.targetDate,
    this.weather,
    this.airQuality,
    this.health,
    this.recentJournal = const [],
    this.recentAttacks = const [],
    this.userFlags = const UserTriggerFlags(),
    required this.baselines,
  });

  @override
  List<Object?> get props => [
        now,
        targetDate,
        weather,
        airQuality,
        health,
        recentJournal,
        recentAttacks,
        userFlags,
        baselines,
      ];
}

/// Snapshot of rolling per-user baselines. Defined fully in Task 6.
/// Forward-declared here so EvaluationContext can reference it.
class BaselineSnapshot extends Equatable {
  final Duration? sleepMedian7d;
  final double? hrvRmssdBaseline14d;
  final double? pressureBaseline;
  final double? caffeineDailyMg;
  const BaselineSnapshot({
    this.sleepMedian7d,
    this.hrvRmssdBaseline14d,
    this.pressureBaseline,
    this.caffeineDailyMg,
  });
  static const empty = BaselineSnapshot();
  @override
  List<Object?> get props =>
      [sleepMedian7d, hrvRmssdBaseline14d, pressureBaseline, caffeineDailyMg];
}
```

- [ ] **Step 5: Implement RiskAssessment + bands**

Create `packages/domain/lib/src/types/risk_assessment.dart`:

```dart
import 'package:equatable/equatable.dart';
import 'trigger_signal.dart';

enum RiskBand { low, moderate, high, veryHigh }
enum RiskHorizon { today, tomorrow }

class ScoreBands extends Equatable {
  /// Lower bound (inclusive) of each band above 'low'.
  final int low;        // values < low -> low (so this is actually the upper bound of low)
  final int moderate;
  final int high;
  const ScoreBands({required this.low, required this.moderate, required this.high});

  /// `low` is the boundary BETWEEN low and moderate.
  /// A score equal to a boundary falls into the higher band.
  RiskBand bandFor(int score) {
    if (score >= high) return RiskBand.veryHigh;
    if (score >= moderate) return RiskBand.high;
    if (score >= low) return RiskBand.moderate;
    return RiskBand.low;
  }

  @override
  List<Object?> get props => [low, moderate, high];
}

class RiskAssessment extends Equatable {
  final int score;                       // 0..100
  final RiskBand band;
  final List<TriggerSignal> contributors; // sorted by contribution desc
  final DateTime computedAt;
  final int configVersion;
  final DateTime targetDate;
  final RiskHorizon horizon;

  const RiskAssessment({
    required this.score,
    required this.band,
    required this.contributors,
    required this.computedAt,
    required this.configVersion,
    required this.targetDate,
    required this.horizon,
  });

  bool get isOnboarding =>
      contributors.isNotEmpty && contributors.every((c) => c.confidence == 0);

  @override
  List<Object?> get props =>
      [score, band, contributors, computedAt, configVersion, targetDate, horizon];
}
```

- [ ] **Step 6: Update barrel**

Edit `packages/domain/lib/domain.dart`:

```dart
export 'src/types/data_requirement.dart';
export 'src/types/trigger_signal.dart';
export 'src/types/weather.dart';
export 'src/types/health.dart';
export 'src/types/journal.dart';
export 'src/types/user_flags.dart';
export 'src/types/evaluation_context.dart';
export 'src/types/risk_assessment.dart';
```

- [ ] **Step 7: Run — expect PASS**

```bash
cd packages/domain && dart test test/types/risk_assessment_test.dart
```

Expected: 2 passing tests.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "domain: add EvaluationContext, UserTriggerFlags, RiskAssessment"
```

---

## Task 5: RulesConfig + loader

**Files:**
- Create: `packages/domain/lib/src/config/rules_config.dart`
- Create: `packages/domain/lib/src/config/rules_config_loader.dart`
- Test: `packages/domain/test/config/rules_config_loader_test.dart`
- Modify: `packages/domain/lib/domain.dart`

- [ ] **Step 1: Write failing test**

Create `packages/domain/test/config/rules_config_loader_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('RulesConfigLoader', () {
    const validJson = '''
    {
      "version": 1,
      "modules": {
        "pressure_drop": { "enabled": true, "weight_max": 18, "params": {"threshold_hpa": 5} }
      },
      "score_bands": { "low": 25, "moderate": 50, "high": 75 },
      "unflagged_trigger_confidence_multiplier": 0.6
    }
    ''';

    test('parses a valid config', () {
      final cfg = RulesConfigLoader.parse(validJson);
      expect(cfg.version, 1);
      expect(cfg.modules['pressure_drop']!.enabled, isTrue);
      expect(cfg.modules['pressure_drop']!.weightMax, 18);
      expect(cfg.modules['pressure_drop']!.params['threshold_hpa'], 5);
      expect(cfg.bands.low, 25);
      expect(cfg.unflaggedConfidenceMultiplier, 0.6);
    });

    test('rejects missing version', () {
      expect(
        () => RulesConfigLoader.parse('{"modules": {}, "score_bands": {"low": 25, "moderate": 50, "high": 75}}'),
        throwsA(isA<RulesConfigException>()),
      );
    });

    test('rejects bad band ordering', () {
      const bad = '''
      {"version": 1, "modules": {}, "score_bands": {"low": 50, "moderate": 25, "high": 75}, "unflagged_trigger_confidence_multiplier": 0.6}
      ''';
      expect(() => RulesConfigLoader.parse(bad), throwsA(isA<RulesConfigException>()));
    });

    test('parseOrFallback returns fallback on bad input', () {
      final fb = RulesConfig.minimalDefault();
      final cfg = RulesConfigLoader.parseOrFallback('not json', fallback: fb);
      expect(cfg, equals(fb));
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd packages/domain && dart test test/config/rules_config_loader_test.dart
```

Expected: compile error.

- [ ] **Step 3: Implement RulesConfig**

Create `packages/domain/lib/src/config/rules_config.dart`:

```dart
import 'package:equatable/equatable.dart';
import '../types/risk_assessment.dart';

class ModuleParams extends Equatable {
  final bool enabled;
  final double weightMax;
  final Map<String, Object?> params;
  const ModuleParams({
    required this.enabled,
    required this.weightMax,
    this.params = const {},
  });

  T get<T>(String key, T fallback) {
    final v = params[key];
    return v is T ? v : fallback;
  }

  double getDouble(String key, double fallback) {
    final v = params[key];
    if (v is num) return v.toDouble();
    return fallback;
  }

  int getInt(String key, int fallback) {
    final v = params[key];
    if (v is num) return v.toInt();
    return fallback;
  }

  @override
  List<Object?> get props => [enabled, weightMax, params];
}

class RulesConfig extends Equatable {
  final int version;
  final Map<String, ModuleParams> modules;
  final ScoreBands bands;
  final double unflaggedConfidenceMultiplier;

  const RulesConfig({
    required this.version,
    required this.modules,
    required this.bands,
    required this.unflaggedConfidenceMultiplier,
  });

  /// Minimal fallback used when bundled config is unreadable.
  /// All modules disabled — the engine will produce an onboarding signal.
  factory RulesConfig.minimalDefault() => const RulesConfig(
        version: 0,
        modules: {},
        bands: ScoreBands(low: 25, moderate: 50, high: 75),
        unflaggedConfidenceMultiplier: 0.6,
      );

  @override
  List<Object?> get props => [version, modules, bands, unflaggedConfidenceMultiplier];
}
```

- [ ] **Step 4: Implement RulesConfigLoader**

Create `packages/domain/lib/src/config/rules_config_loader.dart`:

```dart
import 'dart:convert';
import '../types/risk_assessment.dart';
import 'rules_config.dart';

class RulesConfigException implements Exception {
  final String message;
  RulesConfigException(this.message);
  @override
  String toString() => 'RulesConfigException: $message';
}

class RulesConfigLoader {
  /// Parses JSON text and validates the config. Throws RulesConfigException on bad input.
  static RulesConfig parse(String jsonText) {
    final Map<String, Object?> root;
    try {
      root = jsonDecode(jsonText) as Map<String, Object?>;
    } catch (_) {
      throw RulesConfigException('invalid JSON');
    }

    final version = root['version'];
    if (version is! int) throw RulesConfigException('missing or non-integer "version"');

    final modulesRaw = root['modules'];
    if (modulesRaw is! Map) throw RulesConfigException('missing "modules" map');

    final modules = <String, ModuleParams>{};
    modulesRaw.forEach((key, value) {
      if (value is! Map) {
        throw RulesConfigException('module "$key" is not an object');
      }
      final enabled = value['enabled'];
      final weightMax = value['weight_max'];
      if (enabled is! bool) throw RulesConfigException('module "$key" missing bool "enabled"');
      if (weightMax is! num) throw RulesConfigException('module "$key" missing numeric "weight_max"');
      final params = (value['params'] is Map)
          ? Map<String, Object?>.from(value['params'] as Map)
          : <String, Object?>{};
      modules[key.toString()] = ModuleParams(
        enabled: enabled,
        weightMax: weightMax.toDouble(),
        params: params,
      );
    });

    final bandsRaw = root['score_bands'];
    if (bandsRaw is! Map) throw RulesConfigException('missing "score_bands"');
    final low = bandsRaw['low'];
    final mod = bandsRaw['moderate'];
    final high = bandsRaw['high'];
    if (low is! num || mod is! num || high is! num) {
      throw RulesConfigException('score_bands must have numeric low/moderate/high');
    }
    if (!(low < mod && mod < high && high < 100)) {
      throw RulesConfigException('score_bands must satisfy low < moderate < high < 100');
    }
    final bands = ScoreBands(low: low.toInt(), moderate: mod.toInt(), high: high.toInt());

    final mult = root['unflagged_trigger_confidence_multiplier'];
    if (mult is! num) {
      throw RulesConfigException('missing numeric "unflagged_trigger_confidence_multiplier"');
    }
    final multD = mult.toDouble();
    if (multD < 0 || multD > 1) {
      throw RulesConfigException('unflagged multiplier must be in [0, 1]');
    }

    return RulesConfig(
      version: version,
      modules: modules,
      bands: bands,
      unflaggedConfidenceMultiplier: multD,
    );
  }

  static RulesConfig parseOrFallback(String jsonText, {required RulesConfig fallback}) {
    try {
      return parse(jsonText);
    } catch (_) {
      return fallback;
    }
  }
}
```

- [ ] **Step 5: Update barrel**

Append to `packages/domain/lib/domain.dart`:

```dart
export 'src/config/rules_config.dart';
export 'src/config/rules_config_loader.dart';
```

- [ ] **Step 6: Run — expect PASS**

```bash
cd packages/domain && dart test test/config/rules_config_loader_test.dart
```

Expected: 4 passing tests.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "domain: add RulesConfig + JSON loader with validation"
```

---

## Task 6: BaselineStore

**Files:**
- Create: `packages/domain/lib/src/baselines/baseline_store.dart`
- Test: `packages/domain/test/baselines/baseline_store_test.dart`
- Modify: `packages/domain/lib/domain.dart`

- [ ] **Step 1: Write failing test**

Create `packages/domain/test/baselines/baseline_store_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('BaselineStore', () {
    test('sleep median over 7 days', () {
      final hours = [7.0, 6.5, 8.0, 5.5, 7.5, 6.0, 7.0];
      final store = BaselineStore();
      final median = store.medianSleepHours(hours);
      expect(median, 7.0);
    });

    test('returns null when fewer than `minSamples` data points', () {
      final store = BaselineStore();
      expect(store.hrvRmssdBaseline([50.0, 52.0], minSamples: 10), isNull);
    });

    test('hrv baseline is a median over the trailing window', () {
      final store = BaselineStore();
      final values = List.generate(14, (i) => (40 + i).toDouble());
      final baseline = store.hrvRmssdBaseline(values, minSamples: 10);
      expect(baseline, 46.5); // median of 40..53 = (46+47)/2
    });

    test('pressure baseline uses recent samples median', () {
      final store = BaselineStore();
      final pressures = [1015.0, 1014.5, 1016.0, 1013.0, 1015.5];
      expect(store.pressureBaseline(pressures), 1015.0);
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd packages/domain && dart test test/baselines/baseline_store_test.dart
```

Expected: compile error.

- [ ] **Step 3: Implement BaselineStore**

Create `packages/domain/lib/src/baselines/baseline_store.dart`:

```dart
class BaselineStore {
  const BaselineStore();

  double _median(List<double> values) {
    if (values.isEmpty) return double.nan;
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2.0;
  }

  double? medianSleepHours(List<double> hours, {int minSamples = 3}) {
    if (hours.length < minSamples) return null;
    return _median(hours);
  }

  double? hrvRmssdBaseline(List<double> rmssdValues, {int minSamples = 10}) {
    if (rmssdValues.length < minSamples) return null;
    return _median(rmssdValues);
  }

  double? pressureBaseline(List<double> pressures, {int minSamples = 3}) {
    if (pressures.length < minSamples) return null;
    return _median(pressures);
  }

  double? caffeineBaselineMg(List<double> dailyMg, {int minSamples = 7}) {
    if (dailyMg.length < minSamples) return null;
    return _median(dailyMg);
  }
}
```

- [ ] **Step 4: Update barrel**

Append to `packages/domain/lib/domain.dart`:

```dart
export 'src/baselines/baseline_store.dart';
```

- [ ] **Step 5: Run — expect PASS**

```bash
cd packages/domain && dart test test/baselines/baseline_store_test.dart
```

Expected: 4 passing tests.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "domain: add BaselineStore"
```

---

## Task 7: TriggerModule interface

**Files:**
- Create: `packages/domain/lib/src/engine/trigger_module.dart`
- Modify: `packages/domain/lib/domain.dart`

Pure interface — tested indirectly via the engine and the modules. No test file.

- [ ] **Step 1: Implement**

Create `packages/domain/lib/src/engine/trigger_module.dart`:

```dart
import '../config/rules_config.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/trigger_signal.dart';

abstract class TriggerModule {
  String get id;
  Set<DataRequirement> get requires;
  Duration get leadTime;

  /// Evaluate this trigger against the given context using the module's params.
  /// Must not throw — return a zero-confidence signal on missing data.
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params);
}
```

- [ ] **Step 2: Update barrel**

Append to `packages/domain/lib/domain.dart`:

```dart
export 'src/engine/trigger_module.dart';
```

- [ ] **Step 3: Verify it compiles**

```bash
cd packages/domain && dart analyze
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "domain: add TriggerModule interface"
```

---

## Task 8: RiskEngine

**Files:**
- Create: `packages/domain/lib/src/engine/risk_engine.dart`
- Test: `packages/domain/test/engine/risk_engine_test.dart`
- Modify: `packages/domain/lib/domain.dart`

- [ ] **Step 1: Write failing test**

Create `packages/domain/test/engine/risk_engine_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:test/test.dart';

/// Helper module: returns a fixed signal regardless of context.
class _FixedModule implements TriggerModule {
  @override
  final String id;
  final TriggerSignal signal;
  _FixedModule(this.id, this.signal);
  @override
  Set<DataRequirement> get requires => const {};
  @override
  Duration get leadTime => const Duration(hours: 24);
  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) => signal;
}

class _ThrowingModule implements TriggerModule {
  @override
  final String id = 'oops';
  @override
  Set<DataRequirement> get requires => const {};
  @override
  Duration get leadTime => const Duration(hours: 24);
  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    throw StateError('boom');
  }
}

EvaluationContext _ctx({UserTriggerFlags flags = const UserTriggerFlags()}) =>
    EvaluationContext(
      now: DateTime.utc(2026, 6, 10, 6),
      targetDate: DateTime.utc(2026, 6, 10),
      userFlags: flags,
      baselines: BaselineSnapshot.empty,
    );

RulesConfig _cfg(Map<String, ModuleParams> modules) => RulesConfig(
      version: 1,
      modules: modules,
      bands: const ScoreBands(low: 25, moderate: 50, high: 75),
      unflaggedConfidenceMultiplier: 0.6,
    );

void main() {
  group('RiskEngine', () {
    test('sums contributions and clamps score to 0..100', () {
      final modules = [
        _FixedModule('a', TriggerSignal(moduleId: 'a', weight: 40, confidence: 1.0, explanation: 'a')),
        _FixedModule('b', TriggerSignal(moduleId: 'b', weight: 80, confidence: 1.0, explanation: 'b')),
      ];
      final cfg = _cfg({
        'a': const ModuleParams(enabled: true, weightMax: 40),
        'b': const ModuleParams(enabled: true, weightMax: 80),
      });
      final engine = RiskEngine(modules: modules);
      final ass = engine.evaluate(
        _ctx(),
        cfg,
        horizon: RiskHorizon.today,
      );
      expect(ass.score, 100); // 40 + 80 = 120, clamped
      expect(ass.band, RiskBand.veryHigh);
      expect(ass.contributors.first.moduleId, 'b'); // sorted by contribution
    });

    test('disabled modules contribute nothing', () {
      final modules = [
        _FixedModule('a', TriggerSignal(moduleId: 'a', weight: 30, confidence: 1.0, explanation: 'a')),
      ];
      final cfg = _cfg({
        'a': const ModuleParams(enabled: false, weightMax: 30),
      });
      final engine = RiskEngine(modules: modules);
      final ass = engine.evaluate(_ctx(), cfg, horizon: RiskHorizon.today);
      expect(ass.score, 0);
    });

    test('unflagged trigger gets confidence multiplier', () {
      final modules = [
        _FixedModule('a', TriggerSignal(moduleId: 'a', weight: 50, confidence: 1.0, explanation: 'a')),
      ];
      final cfg = _cfg({
        'a': const ModuleParams(enabled: true, weightMax: 50),
      });
      final engine = RiskEngine(modules: modules);
      // No flags: confidence multiplied by 0.6 -> contribution 30
      final ass = engine.evaluate(_ctx(), cfg, horizon: RiskHorizon.today);
      expect(ass.score, 30);
      // Flagged: full 50
      final ass2 = engine.evaluate(
        _ctx(flags: const UserTriggerFlags(flaggedModuleIds: {'a'})),
        cfg,
        horizon: RiskHorizon.today,
      );
      expect(ass2.score, 50);
    });

    test('weight override adjusts contribution (+1 -> +10%)', () {
      // Override semantics: each +1 adds 10% of weight_max, clamped to weight_max bounds.
      final modules = [
        _FixedModule('a', TriggerSignal(moduleId: 'a', weight: 20, confidence: 1.0, explanation: 'a')),
      ];
      final cfg = _cfg({
        'a': const ModuleParams(enabled: true, weightMax: 20),
      });
      final engine = RiskEngine(modules: modules);
      final flags = const UserTriggerFlags(
        flaggedModuleIds: {'a'},
        weightOverrides: {'a': 2.0},
      );
      // Module reports weight 20 already; override scales by (1 + 0.1 * 2) = 1.2 -> 24,
      // then clamped to weight_max * (1 + 0.1*2) = 24.
      final ass = engine.evaluate(_ctx(flags: flags), cfg, horizon: RiskHorizon.today);
      expect(ass.score, 24);
    });

    test('isolated module failures do not break refresh', () {
      final modules = [
        _ThrowingModule(),
        _FixedModule('b', TriggerSignal(moduleId: 'b', weight: 30, confidence: 1.0, explanation: 'b')),
      ];
      final cfg = _cfg({
        'oops': const ModuleParams(enabled: true, weightMax: 10),
        'b': const ModuleParams(enabled: true, weightMax: 30),
      });
      final engine = RiskEngine(modules: modules);
      final ass = engine.evaluate(_ctx(flags: const UserTriggerFlags(flaggedModuleIds: {'oops', 'b'})), cfg, horizon: RiskHorizon.today);
      // 'oops' contributes zero (caught); 'b' contributes 30.
      expect(ass.score, 30);
      // The failed module is recorded as a zero-confidence contributor.
      expect(ass.contributors.any((c) => c.moduleId == 'oops' && c.confidence == 0), isTrue);
    });

    test('all-zero confidence flags the assessment as onboarding', () {
      final modules = [
        _FixedModule('a', TriggerSignal.zero(moduleId: 'a', reason: 'no data')),
        _FixedModule('b', TriggerSignal.zero(moduleId: 'b', reason: 'no data')),
      ];
      final cfg = _cfg({
        'a': const ModuleParams(enabled: true, weightMax: 10),
        'b': const ModuleParams(enabled: true, weightMax: 10),
      });
      final engine = RiskEngine(modules: modules);
      final ass = engine.evaluate(_ctx(), cfg, horizon: RiskHorizon.today);
      expect(ass.isOnboarding, isTrue);
      expect(ass.score, 0);
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd packages/domain && dart test test/engine/risk_engine_test.dart
```

Expected: compile errors.

- [ ] **Step 3: Implement RiskEngine**

Create `packages/domain/lib/src/engine/risk_engine.dart`:

```dart
import '../config/rules_config.dart';
import '../types/evaluation_context.dart';
import '../types/risk_assessment.dart';
import '../types/trigger_signal.dart';
import 'trigger_module.dart';

class RiskEngine {
  final List<TriggerModule> modules;
  final DateTime Function() clock;

  RiskEngine({required this.modules, DateTime Function()? clock})
      : clock = clock ?? DateTime.now;

  RiskAssessment evaluate(
    EvaluationContext ctx,
    RulesConfig config, {
    required RiskHorizon horizon,
  }) {
    final signals = <TriggerSignal>[];
    for (final m in modules) {
      final params = config.modules[m.id];
      if (params == null || !params.enabled) continue;

      TriggerSignal raw;
      try {
        raw = m.evaluate(ctx, params);
      } catch (_) {
        signals.add(TriggerSignal.zero(moduleId: m.id, reason: 'module error'));
        continue;
      }

      // Apply user flags + weight override.
      final flagged = ctx.userFlags.isFlagged(m.id);
      final flagMultiplier = flagged ? 1.0 : config.unflaggedConfidenceMultiplier;
      final override = ctx.userFlags.overrideFor(m.id); // -2..+2
      final weightScale = (1.0 + 0.1 * override).clamp(0.5, 1.5);

      signals.add(
        TriggerSignal(
          moduleId: raw.moduleId,
          weight: raw.weight * weightScale,
          confidence: raw.confidence * flagMultiplier,
          explanation: raw.explanation,
          missing: raw.missing,
        ),
      );
    }

    // Sum contributions, clamp to 0..100.
    final total = signals.fold<double>(0, (acc, s) => acc + s.contribution);
    final score = total.clamp(0.0, 100.0).round();

    // Sort contributors by contribution desc for the UI.
    final sorted = [...signals]
      ..sort((a, b) => b.contribution.compareTo(a.contribution));

    return RiskAssessment(
      score: score,
      band: config.bands.bandFor(score),
      contributors: sorted,
      computedAt: clock(),
      configVersion: config.version,
      targetDate: ctx.targetDate,
      horizon: horizon,
    );
  }
}
```

- [ ] **Step 4: Update barrel**

Append to `packages/domain/lib/domain.dart`:

```dart
export 'src/engine/risk_engine.dart';
```

- [ ] **Step 5: Run — expect PASS**

```bash
cd packages/domain && dart test test/engine/risk_engine_test.dart
```

Expected: 6 passing tests.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "domain: add RiskEngine with weight/confidence/override semantics"
```

---

## Task 9: Module — pressure_drop

**Files:**
- Create: `packages/domain/lib/src/modules/pressure_drop.dart`
- Test: `packages/domain/test/modules/pressure_drop_test.dart`
- Modify: `packages/domain/lib/domain.dart`

- [ ] **Step 1: Write failing test**

Create `packages/domain/test/modules/pressure_drop_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PressureDropModule', () {
    final module = PressureDropModule();
    const params = ModuleParams(
      enabled: true,
      weightMax: 18,
      params: {'threshold_hpa': 5, 'lookahead_hours': 48},
    );
    final now = DateTime.utc(2026, 6, 10, 6);
    final targetDate = DateTime.utc(2026, 6, 10);

    EvaluationContext withWeather(List<WeatherSample> samples) => EvaluationContext(
          now: now,
          targetDate: targetDate,
          weather: WeatherSeries(samples: samples),
          baselines: BaselineSnapshot.empty,
        );

    test('zero confidence when no weather', () {
      final ctx = EvaluationContext(
        now: now,
        targetDate: targetDate,
        baselines: BaselineSnapshot.empty,
      );
      final s = module.evaluate(ctx, params);
      expect(s.confidence, 0);
      expect(s.missing, DataRequirement.weatherPressure);
    });

    test('no signal when drop below threshold', () {
      final samples = [
        WeatherSample(at: now, pressureMsl: 1015, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: now.add(Duration(hours: 24)), pressureMsl: 1013, temperatureC: 20, humidityPct: 50),
      ];
      final s = module.evaluate(withWeather(samples), params);
      expect(s.weight, 0);
      expect(s.confidence, 1.0);
    });

    test('proportional weight at threshold', () {
      final samples = [
        WeatherSample(at: now, pressureMsl: 1015, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: now.add(Duration(hours: 24)), pressureMsl: 1010, temperatureC: 20, humidityPct: 50),
      ];
      // 5 hPa drop = threshold = half of "saturation" (10 hPa) -> weight ~ weight_max * 0.5
      final s = module.evaluate(withWeather(samples), params);
      expect(s.weight, closeTo(9.0, 0.5));
    });

    test('saturates at weight_max for large drops', () {
      final samples = [
        WeatherSample(at: now, pressureMsl: 1020, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: now.add(Duration(hours: 18)), pressureMsl: 1005, temperatureC: 20, humidityPct: 50),
      ];
      final s = module.evaluate(withWeather(samples), params);
      expect(s.weight, 18);
      expect(s.explanation, contains('hPa'));
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd packages/domain && dart test test/modules/pressure_drop_test.dart
```

Expected: compile error.

- [ ] **Step 3: Implement**

Create `packages/domain/lib/src/modules/pressure_drop.dart`:

```dart
import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/trigger_signal.dart';

class PressureDropModule implements TriggerModule {
  @override
  String get id => 'pressure_drop';

  @override
  Set<DataRequirement> get requires => {DataRequirement.weatherPressure};

  @override
  Duration get leadTime => const Duration(hours: 48);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    if (ctx.weather == null || ctx.weather!.samples.length < 2) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'No weather data',
        missing: DataRequirement.weatherPressure,
      );
    }
    final thresholdHpa = params.getDouble('threshold_hpa', 5);
    final lookahead = Duration(hours: params.getInt('lookahead_hours', 48));
    final drop = ctx.weather!.maxPressureDropOver(const Duration(hours: 24));
    if (drop == null || drop <= 0) {
      return TriggerSignal(
        moduleId: id,
        weight: 0,
        confidence: 1.0,
        explanation: 'Pressure stable',
      );
    }
    // Linear ramp from threshold to 2x threshold; saturates at weight_max.
    final saturationHpa = thresholdHpa * 2.0;
    final t = ((drop - thresholdHpa) / (saturationHpa - thresholdHpa)).clamp(0.0, 1.0);
    // Below threshold: half-weight ramp to handle borderline cases.
    final rampedT = drop < thresholdHpa
        ? (drop / thresholdHpa) * 0.5
        : 0.5 + t * 0.5;
    final weight = (params.weightMax * rampedT).clamp(0.0, params.weightMax);
    return TriggerSignal(
      moduleId: id,
      weight: weight,
      confidence: 1.0,
      explanation: 'Pressure dropping ${drop.toStringAsFixed(1)} hPa over next ${lookahead.inHours}h',
    );
  }
}
```

- [ ] **Step 4: Update barrel**

Append to `packages/domain/lib/domain.dart`:

```dart
export 'src/modules/pressure_drop.dart';
```

- [ ] **Step 5: Run — expect PASS**

```bash
cd packages/domain && dart test test/modules/pressure_drop_test.dart
```

Expected: 4 passing tests.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "domain: add pressure_drop module"
```

---

## Task 10: Module — humidity_temp_swing

**Files:**
- Create: `packages/domain/lib/src/modules/humidity_temp_swing.dart`
- Test: `packages/domain/test/modules/humidity_temp_swing_test.dart`
- Modify: `packages/domain/lib/domain.dart`

- [ ] **Step 1: Write failing test**

Create `packages/domain/test/modules/humidity_temp_swing_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('HumidityTempSwingModule', () {
    final module = HumidityTempSwingModule();
    const params = ModuleParams(
      enabled: true,
      weightMax: 10,
      params: {'humidity_pct': 60, 'temp_delta_c': 5},
    );
    final now = DateTime.utc(2026, 6, 10, 6);
    final targetDate = DateTime.utc(2026, 6, 10);

    EvaluationContext withSamples(List<WeatherSample> samples) => EvaluationContext(
          now: now,
          targetDate: targetDate,
          weather: WeatherSeries(samples: samples),
          baselines: BaselineSnapshot.empty,
        );

    test('no weather -> zero confidence', () {
      final s = module.evaluate(
        EvaluationContext(now: now, targetDate: targetDate, baselines: BaselineSnapshot.empty),
        params,
      );
      expect(s.confidence, 0);
    });

    test('full weight when both conditions met', () {
      final samples = [
        WeatherSample(at: now.subtract(Duration(hours: 23)), pressureMsl: 1015, temperatureC: 15, humidityPct: 70),
        WeatherSample(at: now, pressureMsl: 1015, temperatureC: 22, humidityPct: 70),
      ];
      final s = module.evaluate(withSamples(samples), params);
      expect(s.weight, 10);
    });

    test('no weight if humidity below threshold', () {
      final samples = [
        WeatherSample(at: now.subtract(Duration(hours: 23)), pressureMsl: 1015, temperatureC: 15, humidityPct: 40),
        WeatherSample(at: now, pressureMsl: 1015, temperatureC: 22, humidityPct: 40),
      ];
      final s = module.evaluate(withSamples(samples), params);
      expect(s.weight, 0);
    });

    test('no weight if temp swing below threshold', () {
      final samples = [
        WeatherSample(at: now.subtract(Duration(hours: 23)), pressureMsl: 1015, temperatureC: 20, humidityPct: 70),
        WeatherSample(at: now, pressureMsl: 1015, temperatureC: 22, humidityPct: 70),
      ];
      final s = module.evaluate(withSamples(samples), params);
      expect(s.weight, 0);
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd packages/domain && dart test test/modules/humidity_temp_swing_test.dart
```

- [ ] **Step 3: Implement**

Create `packages/domain/lib/src/modules/humidity_temp_swing.dart`:

```dart
import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/trigger_signal.dart';

class HumidityTempSwingModule implements TriggerModule {
  @override
  String get id => 'humidity_temp_swing';
  @override
  Set<DataRequirement> get requires =>
      {DataRequirement.weatherHumidity};
  @override
  Duration get leadTime => const Duration(hours: 24);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    if (ctx.weather == null || ctx.weather!.samples.isEmpty) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'No weather data',
        missing: DataRequirement.weatherHumidity,
      );
    }
    final humidityPct = params.getDouble('humidity_pct', 60);
    final tempDeltaC = params.getDouble('temp_delta_c', 5);
    final maxHumidity = ctx.weather!.maxHumidityFrom(
      ctx.now.subtract(const Duration(hours: 24)),
      const Duration(hours: 48),
    );
    final swing = ctx.weather!.tempSwingInLast(const Duration(hours: 24));
    if (maxHumidity == null || swing == null) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'Insufficient weather samples',
        missing: DataRequirement.weatherHumidity,
      );
    }
    final humidOk = maxHumidity > humidityPct;
    final swingOk = swing >= tempDeltaC;
    if (!humidOk || !swingOk) {
      return TriggerSignal(
        moduleId: id,
        weight: 0,
        confidence: 1.0,
        explanation: 'Humidity ${maxHumidity.toStringAsFixed(0)}%, swing ${swing.toStringAsFixed(1)}°C',
      );
    }
    return TriggerSignal(
      moduleId: id,
      weight: params.weightMax,
      confidence: 1.0,
      explanation:
          'Humid (${maxHumidity.toStringAsFixed(0)}%) with ${swing.toStringAsFixed(1)}°C swing',
    );
  }
}
```

- [ ] **Step 4: Update barrel**

```dart
export 'src/modules/humidity_temp_swing.dart';
```

- [ ] **Step 5: Run — expect PASS**

```bash
cd packages/domain && dart test test/modules/humidity_temp_swing_test.dart
```

Expected: 4 passing.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "domain: add humidity_temp_swing module"
```

---

## Task 11: Module — air_quality

**Files:**
- Create: `packages/domain/lib/src/modules/air_quality.dart`
- Test: `packages/domain/test/modules/air_quality_test.dart`
- Modify: `packages/domain/lib/domain.dart`

- [ ] **Step 1: Write failing test**

Create `packages/domain/test/modules/air_quality_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('AirQualityModule', () {
    final module = AirQualityModule();
    const params = ModuleParams(
      enabled: true,
      weightMax: 10,
      params: {'pm25_threshold': 35.0},
    );
    final now = DateTime.utc(2026, 6, 10, 6);
    final target = DateTime.utc(2026, 6, 10);

    EvaluationContext withAQ(List<AirQualitySample> samples) => EvaluationContext(
          now: now,
          targetDate: target,
          airQuality: AirQualitySeries(samples: samples),
          baselines: BaselineSnapshot.empty,
        );

    test('no AQ data -> zero confidence', () {
      final s = module.evaluate(
        EvaluationContext(now: now, targetDate: target, baselines: BaselineSnapshot.empty),
        params,
      );
      expect(s.confidence, 0);
    });

    test('below threshold -> no weight', () {
      final s = module.evaluate(
        withAQ([AirQualitySample(at: now, pm25: 20)]),
        params,
      );
      expect(s.weight, 0);
    });

    test('above threshold -> proportional weight, saturating at 2x', () {
      final s = module.evaluate(
        withAQ([AirQualitySample(at: now, pm25: 70)]), // 2x threshold
        params,
      );
      expect(s.weight, 10);
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd packages/domain && dart test test/modules/air_quality_test.dart
```

- [ ] **Step 3: Implement**

Create `packages/domain/lib/src/modules/air_quality.dart`:

```dart
import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/trigger_signal.dart';

class AirQualityModule implements TriggerModule {
  @override
  String get id => 'air_quality';
  @override
  Set<DataRequirement> get requires => {DataRequirement.weatherAirQuality};
  @override
  Duration get leadTime => const Duration(hours: 24);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    final aq = ctx.airQuality;
    if (aq == null || aq.samples.isEmpty) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'No air quality data',
        missing: DataRequirement.weatherAirQuality,
      );
    }
    final threshold = params.getDouble('pm25_threshold', 35);
    final maxPm25 = aq.maxPm25From(ctx.now, const Duration(hours: 24));
    if (maxPm25 == null) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'No upcoming AQ samples',
        missing: DataRequirement.weatherAirQuality,
      );
    }
    if (maxPm25 < threshold) {
      return TriggerSignal(
        moduleId: id,
        weight: 0,
        confidence: 1.0,
        explanation: 'Air quality OK (PM2.5 ${maxPm25.toStringAsFixed(0)})',
      );
    }
    final saturation = threshold * 2;
    final t = ((maxPm25 - threshold) / (saturation - threshold)).clamp(0.0, 1.0);
    return TriggerSignal(
      moduleId: id,
      weight: params.weightMax * t,
      confidence: 1.0,
      explanation: 'High PM2.5 (${maxPm25.toStringAsFixed(0)} µg/m³)',
    );
  }
}
```

- [ ] **Step 4: Update barrel**

```dart
export 'src/modules/air_quality.dart';
```

- [ ] **Step 5: Run — expect PASS**

```bash
cd packages/domain && dart test test/modules/air_quality_test.dart
```

Expected: 3 passing.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "domain: add air_quality module"
```

---

## Task 12: Module — sleep_deficit

**Files:**
- Create: `packages/domain/lib/src/modules/sleep_deficit.dart`
- Test: `packages/domain/test/modules/sleep_deficit_test.dart`
- Modify: `packages/domain/lib/domain.dart`

- [ ] **Step 1: Write failing test**

Create `packages/domain/test/modules/sleep_deficit_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('SleepDeficitModule', () {
    final module = SleepDeficitModule();
    const params = ModuleParams(
      enabled: true,
      weightMax: 20,
      params: {'hours_threshold': 6, 'efficiency_threshold': 0.85, 'baseline_days': 7},
    );
    final now = DateTime.utc(2026, 6, 10, 6);
    final target = DateTime.utc(2026, 6, 10);
    final lastNight = DateTime.utc(2026, 6, 9);

    EvaluationContext withSleep(List<SleepRecord> recent, {Duration? baseline}) => EvaluationContext(
          now: now,
          targetDate: target,
          health: HealthMetrics(recentSleep: recent),
          baselines: BaselineSnapshot(sleepMedian7d: baseline),
        );

    test('no health -> zero confidence', () {
      final s = module.evaluate(
        EvaluationContext(now: now, targetDate: target, baselines: BaselineSnapshot.empty),
        params,
      );
      expect(s.confidence, 0);
      expect(s.missing, DataRequirement.healthSleep);
    });

    test('low total sleep triggers weight', () {
      final s = module.evaluate(
        withSleep([
          SleepRecord(
            night: lastNight,
            totalSleep: Duration(hours: 4, minutes: 30),
            efficiency: 0.9,
            sleepStart: lastNight.add(Duration(hours: 22)),
          ),
        ], baseline: Duration(hours: 7)),
        params,
      );
      expect(s.weight, greaterThan(10));
      expect(s.confidence, 1.0);
    });

    test('low efficiency contributes', () {
      final s = module.evaluate(
        withSleep([
          SleepRecord(
            night: lastNight,
            totalSleep: Duration(hours: 7),
            efficiency: 0.7,
            sleepStart: lastNight.add(Duration(hours: 22)),
          ),
        ], baseline: Duration(hours: 7)),
        params,
      );
      expect(s.weight, greaterThan(0));
    });

    test('schedule shift >2h contributes', () {
      final s = module.evaluate(
        withSleep([
          SleepRecord(
            night: lastNight,
            totalSleep: Duration(hours: 7),
            efficiency: 0.9,
            sleepStart: lastNight.add(Duration(hours: 25)), // 1am vs typical 10pm = 3h shift
          ),
        ], baseline: Duration(hours: 7)),
        ModuleParams(
          enabled: true,
          weightMax: 20,
          params: {
            'hours_threshold': 6,
            'efficiency_threshold': 0.85,
            'baseline_days': 7,
            'typical_sleep_start_hour': 22,
          },
        ),
      );
      expect(s.weight, greaterThan(0));
    });

    test('cold-start confidence when no baseline', () {
      final s = module.evaluate(
        withSleep([
          SleepRecord(
            night: lastNight,
            totalSleep: Duration(hours: 5),
            efficiency: 0.9,
            sleepStart: lastNight.add(Duration(hours: 22)),
          ),
        ]),
        params,
      );
      expect(s.confidence, 0.5);
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd packages/domain && dart test test/modules/sleep_deficit_test.dart
```

- [ ] **Step 3: Implement**

Create `packages/domain/lib/src/modules/sleep_deficit.dart`:

```dart
import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/trigger_signal.dart';

class SleepDeficitModule implements TriggerModule {
  @override
  String get id => 'sleep_deficit';
  @override
  Set<DataRequirement> get requires => {DataRequirement.healthSleep};
  @override
  Duration get leadTime => const Duration(hours: 24);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    final health = ctx.health;
    if (health == null || health.recentSleep.isEmpty) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'No sleep data',
        missing: DataRequirement.healthSleep,
      );
    }
    final hoursThreshold = params.getDouble('hours_threshold', 6);
    final efficiencyThreshold = params.getDouble('efficiency_threshold', 0.85);
    final typicalHour = params.getDouble('typical_sleep_start_hour', 22);

    final last = health.recentSleep.first;
    final hours = last.totalSleep.inMinutes / 60.0;

    double weight = 0;
    final reasons = <String>[];

    // 1. Hours deficit
    if (hours < hoursThreshold) {
      final deficitT =
          ((hoursThreshold - hours) / hoursThreshold).clamp(0.0, 1.0);
      weight += params.weightMax * 0.5 * deficitT;
      reasons.add('${hours.toStringAsFixed(1)}h sleep');
    }

    // 2. Efficiency deficit
    if (last.efficiency < efficiencyThreshold) {
      final effT = ((efficiencyThreshold - last.efficiency) / efficiencyThreshold)
          .clamp(0.0, 1.0);
      weight += params.weightMax * 0.25 * effT;
      reasons.add('${(last.efficiency * 100).round()}% efficiency');
    }

    // 3. Schedule shift
    final startHour = last.sleepStart.toUtc().hour.toDouble();
    final shift = (startHour - typicalHour).abs();
    if (shift > 2) {
      weight += params.weightMax * 0.25 * ((shift - 2) / 4).clamp(0.0, 1.0);
      reasons.add('schedule shift ${shift.toStringAsFixed(0)}h');
    }

    final hasBaseline = ctx.baselines.sleepMedian7d != null;
    return TriggerSignal(
      moduleId: id,
      weight: weight.clamp(0.0, params.weightMax),
      confidence: hasBaseline ? 1.0 : 0.5,
      explanation: reasons.isEmpty ? 'Sleep on track' : reasons.join(', '),
    );
  }
}
```

- [ ] **Step 4: Update barrel**

```dart
export 'src/modules/sleep_deficit.dart';
```

- [ ] **Step 5: Run — expect PASS**

```bash
cd packages/domain && dart test test/modules/sleep_deficit_test.dart
```

Expected: 5 passing.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "domain: add sleep_deficit module"
```

---

## Task 13: Module — hrv_letdown

**Files:**
- Create: `packages/domain/lib/src/modules/hrv_letdown.dart`
- Test: `packages/domain/test/modules/hrv_letdown_test.dart`
- Modify: `packages/domain/lib/domain.dart`

- [ ] **Step 1: Write failing test**

Create `packages/domain/test/modules/hrv_letdown_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('HrvLetdownModule', () {
    final module = HrvLetdownModule();
    const params = ModuleParams(
      enabled: true,
      weightMax: 12,
      params: {'drop_pct': 20, 'baseline_days': 14},
    );
    final now = DateTime.utc(2026, 6, 10, 6);
    final target = DateTime.utc(2026, 6, 10);

    EvaluationContext withHrv(List<HrvSample> recent, {double? baseline}) => EvaluationContext(
          now: now,
          targetDate: target,
          health: HealthMetrics(recentHrv: recent),
          baselines: BaselineSnapshot(hrvRmssdBaseline14d: baseline),
        );

    test('no HRV -> zero confidence', () {
      final s = module.evaluate(
        EvaluationContext(now: now, targetDate: target, baselines: BaselineSnapshot.empty),
        params,
      );
      expect(s.confidence, 0);
    });

    test('no baseline yet -> cold start confidence', () {
      final s = module.evaluate(
        withHrv([HrvSample(at: now, rmssdMs: 40)]),
        params,
      );
      expect(s.confidence, 0.5);
    });

    test('drop ≥ threshold triggers weight', () {
      final s = module.evaluate(
        withHrv([HrvSample(at: now, rmssdMs: 35)], baseline: 50),
        params,
      );
      // 30% drop, threshold 20%, saturate at 40%. t=(30-20)/(40-20)=0.5 -> weight=6
      expect(s.weight, closeTo(6.0, 0.1));
    });

    test('no signal when recent ≥ baseline', () {
      final s = module.evaluate(
        withHrv([HrvSample(at: now, rmssdMs: 55)], baseline: 50),
        params,
      );
      expect(s.weight, 0);
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd packages/domain && dart test test/modules/hrv_letdown_test.dart
```

- [ ] **Step 3: Implement**

Create `packages/domain/lib/src/modules/hrv_letdown.dart`:

```dart
import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/trigger_signal.dart';

class HrvLetdownModule implements TriggerModule {
  @override
  String get id => 'hrv_letdown';
  @override
  Set<DataRequirement> get requires => {DataRequirement.healthHrv};
  @override
  Duration get leadTime => const Duration(hours: 18);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    final health = ctx.health;
    if (health == null || health.recentHrv.isEmpty) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'No HRV data',
        missing: DataRequirement.healthHrv,
      );
    }
    final dropPct = params.getDouble('drop_pct', 20);
    final baseline = ctx.baselines.hrvRmssdBaseline14d;
    final recent = health.recentHrv.first.rmssdMs;
    if (baseline == null) {
      return TriggerSignal(
        moduleId: id,
        weight: 0,
        confidence: 0.5,
        explanation: 'HRV baseline still calibrating',
      );
    }
    if (recent >= baseline) {
      return TriggerSignal(
        moduleId: id,
        weight: 0,
        confidence: 1.0,
        explanation: 'HRV within range',
      );
    }
    final pctDrop = ((baseline - recent) / baseline) * 100;
    if (pctDrop < dropPct) {
      return TriggerSignal(
        moduleId: id,
        weight: 0,
        confidence: 1.0,
        explanation: 'HRV ${recent.toStringAsFixed(0)} vs baseline ${baseline.toStringAsFixed(0)}',
      );
    }
    final saturation = dropPct * 2;
    final t = ((pctDrop - dropPct) / (saturation - dropPct)).clamp(0.0, 1.0);
    return TriggerSignal(
      moduleId: id,
      weight: params.weightMax * t,
      confidence: 1.0,
      explanation: 'HRV down ${pctDrop.toStringAsFixed(0)}% from baseline',
    );
  }
}
```

- [ ] **Step 4: Update barrel**

```dart
export 'src/modules/hrv_letdown.dart';
```

- [ ] **Step 5: Run — expect PASS**

```bash
cd packages/domain && dart test test/modules/hrv_letdown_test.dart
```

Expected: 4 passing.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "domain: add hrv_letdown module"
```

---

## Task 14: Module — menstrual_phase

**Files:**
- Create: `packages/domain/lib/src/modules/menstrual_phase.dart`
- Test: `packages/domain/test/modules/menstrual_phase_test.dart`
- Modify: `packages/domain/lib/domain.dart`

- [ ] **Step 1: Write failing test**

Create `packages/domain/test/modules/menstrual_phase_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('MenstrualPhaseModule', () {
    final module = MenstrualPhaseModule();
    const params = ModuleParams(
      enabled: true,
      weightMax: 20,
      params: {'window_days': [-2, 3]},
    );
    final target = DateTime.utc(2026, 6, 10);

    EvaluationContext withCycles(List<MenstrualEvent> history) => EvaluationContext(
          now: target,
          targetDate: target,
          health: HealthMetrics(menstrualHistory: history),
          baselines: BaselineSnapshot.empty,
        );

    test('no history -> zero confidence', () {
      final s = module.evaluate(
        EvaluationContext(now: target, targetDate: target, baselines: BaselineSnapshot.empty),
        params,
      );
      expect(s.confidence, 0);
    });

    test('inside perimenstrual window -> full weight', () {
      // Cycle onset two days from target -> day -2
      final history = [
        MenstrualEvent(onsetDate: target.add(Duration(days: 2))),
        MenstrualEvent(onsetDate: target.subtract(Duration(days: 26))),
        MenstrualEvent(onsetDate: target.subtract(Duration(days: 54))),
      ];
      final s = module.evaluate(withCycles(history), params);
      expect(s.weight, 20);
    });

    test('outside window -> no weight', () {
      final history = [
        MenstrualEvent(onsetDate: target.add(Duration(days: 14))),
        MenstrualEvent(onsetDate: target.subtract(Duration(days: 14))),
      ];
      final s = module.evaluate(withCycles(history), params);
      expect(s.weight, 0);
    });

    test('irregular cycles reduce confidence', () {
      final history = [
        MenstrualEvent(onsetDate: target.subtract(Duration(days: 2))),
        MenstrualEvent(onsetDate: target.subtract(Duration(days: 26))),
        MenstrualEvent(onsetDate: target.subtract(Duration(days: 60))), // long gap
        MenstrualEvent(onsetDate: target.subtract(Duration(days: 85))),
        MenstrualEvent(onsetDate: target.subtract(Duration(days: 115))),
        MenstrualEvent(onsetDate: target.subtract(Duration(days: 140))),
        MenstrualEvent(onsetDate: target.subtract(Duration(days: 200))),
      ];
      final s = module.evaluate(withCycles(history), params);
      expect(s.confidence, lessThan(1.0));
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd packages/domain && dart test test/modules/menstrual_phase_test.dart
```

- [ ] **Step 3: Implement**

Create `packages/domain/lib/src/modules/menstrual_phase.dart`:

```dart
import 'dart:math';
import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/trigger_signal.dart';

class MenstrualPhaseModule implements TriggerModule {
  @override
  String get id => 'menstrual_phase';
  @override
  Set<DataRequirement> get requires => {DataRequirement.healthMenstrual};
  @override
  Duration get leadTime => const Duration(days: 5);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    final history = ctx.health?.menstrualHistory ?? const [];
    if (history.isEmpty) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'No cycle data',
        missing: DataRequirement.healthMenstrual,
      );
    }
    final windowRaw = params.params['window_days'];
    final List<int> window = (windowRaw is List)
        ? windowRaw.map((e) => (e as num).toInt()).toList()
        : const [-2, 3];

    // Predict next/most-recent onset.
    final sortedOnsets = [...history.map((e) => e.onsetDate)]..sort();
    int? avgCycleDays;
    double cycleStdDev = 0;
    if (sortedOnsets.length >= 2) {
      final diffs = <int>[];
      for (var i = 1; i < sortedOnsets.length; i++) {
        diffs.add(sortedOnsets[i].difference(sortedOnsets[i - 1]).inDays);
      }
      avgCycleDays = (diffs.reduce((a, b) => a + b) / diffs.length).round();
      final mean = avgCycleDays.toDouble();
      final variance = diffs.map((d) => pow(d - mean, 2)).reduce((a, b) => a + b) / diffs.length;
      cycleStdDev = sqrt(variance);
    }

    // Nearest predicted onset to targetDate.
    DateTime predictedOnset = sortedOnsets.last;
    if (avgCycleDays != null) {
      while (predictedOnset.isBefore(ctx.targetDate.subtract(const Duration(days: 14)))) {
        predictedOnset = predictedOnset.add(Duration(days: avgCycleDays));
      }
    }

    final dayOffset = ctx.targetDate.difference(predictedOnset).inDays;
    final inWindow = dayOffset >= window[0] && dayOffset <= window[1];

    double confidence = 1.0;
    if (sortedOnsets.length < 3) {
      confidence = 0.6;
    } else if (cycleStdDev > 5) {
      confidence = 0.5;
    }

    return TriggerSignal(
      moduleId: id,
      weight: inWindow ? params.weightMax : 0,
      confidence: confidence,
      explanation: inWindow
          ? 'Perimenstrual window (day ${dayOffset >= 0 ? '+' : ''}$dayOffset)'
          : 'Outside perimenstrual window',
    );
  }
}
```

- [ ] **Step 4: Update barrel**

```dart
export 'src/modules/menstrual_phase.dart';
```

- [ ] **Step 5: Run — expect PASS**

```bash
cd packages/domain && dart test test/modules/menstrual_phase_test.dart
```

Expected: 4 passing.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "domain: add menstrual_phase module"
```

---

## Task 15: Module — refractory (days since last attack)

**Files:**
- Create: `packages/domain/lib/src/modules/refractory.dart`
- Test: `packages/domain/test/modules/refractory_test.dart`
- Modify: `packages/domain/lib/domain.dart`

- [ ] **Step 1: Write failing test**

Create `packages/domain/test/modules/refractory_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('RefractoryModule', () {
    final module = RefractoryModule();
    const params = ModuleParams(
      enabled: true,
      weightMax: 6,
      params: {'suppression_hours': 48},
    );
    final now = DateTime.utc(2026, 6, 10, 6);
    final target = DateTime.utc(2026, 6, 10);

    EvaluationContext withAttacks(List<Attack> attacks) => EvaluationContext(
          now: now,
          targetDate: target,
          recentAttacks: attacks,
          baselines: BaselineSnapshot.empty,
        );

    test('no attacks -> no contribution, full confidence', () {
      final s = module.evaluate(withAttacks(const []), params);
      expect(s.weight, 0);
      expect(s.confidence, 1.0);
    });

    test('attack within suppression window -> negative-ish nothing (weight 0)', () {
      // Refractory means risk is LOWER right after an attack. We model that as 0 contribution.
      final s = module.evaluate(
        withAttacks([Attack(startedAt: now.subtract(Duration(hours: 12)), severity: 6)]),
        params,
      );
      expect(s.weight, 0);
      expect(s.explanation, contains('Refractory'));
    });

    test('attack just outside window -> small positive (rebound)', () {
      final s = module.evaluate(
        withAttacks([Attack(startedAt: now.subtract(Duration(hours: 60)), severity: 6)]),
        params,
      );
      expect(s.weight, greaterThan(0));
      expect(s.weight, lessThanOrEqualTo(6));
    });

    test('attack long ago -> no contribution', () {
      final s = module.evaluate(
        withAttacks([Attack(startedAt: now.subtract(Duration(days: 30)), severity: 6)]),
        params,
      );
      expect(s.weight, 0);
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd packages/domain && dart test test/modules/refractory_test.dart
```

- [ ] **Step 3: Implement**

Create `packages/domain/lib/src/modules/refractory.dart`:

```dart
import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/trigger_signal.dart';

class RefractoryModule implements TriggerModule {
  @override
  String get id => 'refractory';
  @override
  Set<DataRequirement> get requires => {DataRequirement.attackHistory};
  @override
  Duration get leadTime => const Duration(hours: 24);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    if (ctx.recentAttacks.isEmpty) {
      return TriggerSignal(
        moduleId: id,
        weight: 0,
        confidence: 1.0,
        explanation: 'No recent attacks',
      );
    }
    final suppressionHours = params.getInt('suppression_hours', 48);
    final reboundUntilHours = suppressionHours + 48;

    // Most recent attack
    final sorted = [...ctx.recentAttacks]
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final last = sorted.first;
    final hoursSince = ctx.now.difference(last.startedAt).inHours;

    if (hoursSince < suppressionHours) {
      return TriggerSignal(
        moduleId: id,
        weight: 0,
        confidence: 1.0,
        explanation: 'Refractory after recent attack',
      );
    }
    if (hoursSince < reboundUntilHours) {
      // Small rebound bump centered between suppression and rebound end.
      final t = ((hoursSince - suppressionHours) / 48).clamp(0.0, 1.0);
      final bell = 4 * t * (1 - t); // peak at t=0.5
      return TriggerSignal(
        moduleId: id,
        weight: params.weightMax * bell,
        confidence: 1.0,
        explanation: 'Post-attack rebound window',
      );
    }
    return TriggerSignal(
      moduleId: id,
      weight: 0,
      confidence: 1.0,
      explanation: 'No recent attacks',
    );
  }
}
```

- [ ] **Step 4: Update barrel**

```dart
export 'src/modules/refractory.dart';
```

- [ ] **Step 5: Run — expect PASS**

```bash
cd packages/domain && dart test test/modules/refractory_test.dart
```

Expected: 4 passing.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "domain: add refractory (days-since-attack) module"
```

---

## Task 16: Module — alcohol

**Files:**
- Create: `packages/domain/lib/src/modules/alcohol.dart`
- Test: `packages/domain/test/modules/alcohol_test.dart`
- Modify: `packages/domain/lib/domain.dart`

- [ ] **Step 1: Write failing test**

Create `packages/domain/test/modules/alcohol_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('AlcoholModule', () {
    final module = AlcoholModule();
    const params = ModuleParams(
      enabled: true,
      weightMax: 12,
      params: {'lookback_hours': 24},
    );
    final now = DateTime.utc(2026, 6, 10, 6);
    final target = DateTime.utc(2026, 6, 10);

    EvaluationContext withJournal(List<JournalEntry> entries) => EvaluationContext(
          now: now,
          targetDate: target,
          recentJournal: entries,
          baselines: BaselineSnapshot.empty,
        );

    test('no journal entries -> zero confidence (missing data)', () {
      final s = module.evaluate(withJournal(const []), params);
      expect(s.confidence, 0);
      expect(s.missing, DataRequirement.journalAlcohol);
    });

    test('alcohol entry within lookback -> proportional to units', () {
      final s = module.evaluate(
        withJournal([
          JournalEntry(
            at: now.subtract(Duration(hours: 6)),
            kind: JournalKind.alcohol,
            payload: {'units': 2.0},
          ),
        ]),
        params,
      );
      expect(s.weight, greaterThan(0));
      expect(s.confidence, 1.0);
    });

    test('alcohol older than lookback -> zero weight, full confidence', () {
      final s = module.evaluate(
        withJournal([
          JournalEntry(
            at: now.subtract(Duration(hours: 36)),
            kind: JournalKind.alcohol,
            payload: {'units': 4.0},
          ),
        ]),
        params,
      );
      expect(s.weight, 0);
      expect(s.confidence, 1.0);
    });

    test('explicit "none" entry within lookback -> zero, full confidence', () {
      final s = module.evaluate(
        withJournal([
          JournalEntry(
            at: now.subtract(Duration(hours: 6)),
            kind: JournalKind.alcohol,
            payload: {'units': 0.0},
          ),
        ]),
        params,
      );
      expect(s.weight, 0);
      expect(s.confidence, 1.0);
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd packages/domain && dart test test/modules/alcohol_test.dart
```

- [ ] **Step 3: Implement**

Create `packages/domain/lib/src/modules/alcohol.dart`:

```dart
import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/journal.dart';
import '../types/trigger_signal.dart';

class AlcoholModule implements TriggerModule {
  @override
  String get id => 'alcohol';
  @override
  Set<DataRequirement> get requires => {DataRequirement.journalAlcohol};
  @override
  Duration get leadTime => const Duration(hours: 12);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    final lookback = Duration(hours: params.getInt('lookback_hours', 24));
    final earliest = ctx.now.subtract(lookback);
    final relevant = ctx.recentJournal
        .where((e) => e.kind == JournalKind.alcohol && !e.at.isBefore(earliest))
        .toList();
    if (relevant.isEmpty) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'No alcohol log',
        missing: DataRequirement.journalAlcohol,
      );
    }
    final totalUnits = relevant.fold<double>(
      0,
      (acc, e) => acc + ((e.payload['units'] as num?)?.toDouble() ?? 0),
    );
    if (totalUnits <= 0) {
      return TriggerSignal(
        moduleId: id,
        weight: 0,
        confidence: 1.0,
        explanation: 'No alcohol in last ${lookback.inHours}h',
      );
    }
    // 1 unit = ramp start; 3 units = saturation.
    final t = ((totalUnits - 1) / 2).clamp(0.0, 1.0);
    final weight = params.weightMax * (0.4 + 0.6 * t);
    return TriggerSignal(
      moduleId: id,
      weight: weight,
      confidence: 1.0,
      explanation: '${totalUnits.toStringAsFixed(1)} units in last ${lookback.inHours}h',
    );
  }
}
```

- [ ] **Step 4: Update barrel**

```dart
export 'src/modules/alcohol.dart';
```

- [ ] **Step 5: Run — expect PASS**

```bash
cd packages/domain && dart test test/modules/alcohol_test.dart
```

Expected: 4 passing.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "domain: add alcohol module"
```

---

## Task 17: Module — caffeine

**Files:**
- Create: `packages/domain/lib/src/modules/caffeine.dart`
- Test: `packages/domain/test/modules/caffeine_test.dart`
- Modify: `packages/domain/lib/domain.dart`

- [ ] **Step 1: Write failing test**

Create `packages/domain/test/modules/caffeine_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('CaffeineModule', () {
    final module = CaffeineModule();
    const params = ModuleParams(
      enabled: true,
      weightMax: 8,
      params: {'delta_mg_threshold': 100},
    );
    final now = DateTime.utc(2026, 6, 10, 6);
    final target = DateTime.utc(2026, 6, 10);

    EvaluationContext build({
      required List<JournalEntry> entries,
      double? baselineMg,
    }) =>
        EvaluationContext(
          now: now,
          targetDate: target,
          recentJournal: entries,
          baselines: BaselineSnapshot(caffeineDailyMg: baselineMg),
        );

    test('no caffeine baseline AND no log -> zero confidence', () {
      final s = module.evaluate(build(entries: const []), params);
      expect(s.confidence, 0);
    });

    test('today caffeine well below baseline (withdrawal) -> weight', () {
      final s = module.evaluate(
        build(
          entries: [
            JournalEntry(
              at: now.subtract(Duration(hours: 3)),
              kind: JournalKind.caffeine,
              payload: {'mg': 50},
            ),
          ],
          baselineMg: 200,
        ),
        params,
      );
      expect(s.weight, greaterThan(0));
    });

    test('today caffeine near baseline -> no weight', () {
      final s = module.evaluate(
        build(
          entries: [
            JournalEntry(
              at: now.subtract(Duration(hours: 3)),
              kind: JournalKind.caffeine,
              payload: {'mg': 180},
            ),
          ],
          baselineMg: 200,
        ),
        params,
      );
      expect(s.weight, 0);
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd packages/domain && dart test test/modules/caffeine_test.dart
```

- [ ] **Step 3: Implement**

Create `packages/domain/lib/src/modules/caffeine.dart`:

```dart
import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/journal.dart';
import '../types/trigger_signal.dart';

class CaffeineModule implements TriggerModule {
  @override
  String get id => 'caffeine';
  @override
  Set<DataRequirement> get requires => {DataRequirement.journalCaffeine};
  @override
  Duration get leadTime => const Duration(hours: 24);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    final baseline = ctx.baselines.caffeineDailyMg;
    final caffEntries = ctx.recentJournal.where((e) => e.kind == JournalKind.caffeine);
    if (baseline == null && caffEntries.isEmpty) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'No caffeine baseline yet',
        missing: DataRequirement.journalCaffeine,
      );
    }
    if (baseline == null) {
      // Have some entries but no baseline yet.
      return TriggerSignal(
        moduleId: id,
        weight: 0,
        confidence: 0.5,
        explanation: 'Caffeine baseline calibrating',
      );
    }
    final todayStart = DateTime.utc(ctx.now.year, ctx.now.month, ctx.now.day);
    final todayMg = caffEntries
        .where((e) => !e.at.isBefore(todayStart))
        .fold<double>(0, (acc, e) => acc + ((e.payload['mg'] as num?)?.toDouble() ?? 0));
    final delta = baseline - todayMg; // positive = withdrawal
    final threshold = params.getDouble('delta_mg_threshold', 100);
    if (delta < threshold) {
      return TriggerSignal(
        moduleId: id,
        weight: 0,
        confidence: 1.0,
        explanation: 'Caffeine ${todayMg.round()}mg vs baseline ${baseline.round()}mg',
      );
    }
    final saturation = threshold * 2;
    final t = ((delta - threshold) / (saturation - threshold)).clamp(0.0, 1.0);
    return TriggerSignal(
      moduleId: id,
      weight: params.weightMax * t,
      confidence: 1.0,
      explanation: 'Caffeine ${delta.round()}mg below baseline',
    );
  }
}
```

- [ ] **Step 4: Update barrel**

```dart
export 'src/modules/caffeine.dart';
```

- [ ] **Step 5: Run — expect PASS**

```bash
cd packages/domain && dart test test/modules/caffeine_test.dart
```

Expected: 3 passing.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "domain: add caffeine module"
```

---

## Task 18: Module — stress

**Files:**
- Create: `packages/domain/lib/src/modules/stress.dart`
- Test: `packages/domain/test/modules/stress_test.dart`
- Modify: `packages/domain/lib/domain.dart`

- [ ] **Step 1: Write failing test**

Create `packages/domain/test/modules/stress_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('StressModule', () {
    final module = StressModule();
    const params = ModuleParams(enabled: true, weightMax: 12);
    final now = DateTime.utc(2026, 6, 10, 6);
    final target = DateTime.utc(2026, 6, 10);

    EvaluationContext withEntries(List<JournalEntry> entries) => EvaluationContext(
          now: now,
          targetDate: target,
          recentJournal: entries,
          baselines: BaselineSnapshot.empty,
        );

    test('no stress entries -> zero confidence', () {
      expect(module.evaluate(withEntries(const []), params).confidence, 0);
    });

    test('high stress rating -> high weight', () {
      final s = module.evaluate(
        withEntries([
          JournalEntry(
            at: now.subtract(Duration(hours: 4)),
            kind: JournalKind.stress,
            payload: {'rating': 5},
          ),
        ]),
        params,
      );
      expect(s.weight, 12);
    });

    test('low stress rating -> no weight', () {
      final s = module.evaluate(
        withEntries([
          JournalEntry(
            at: now.subtract(Duration(hours: 4)),
            kind: JournalKind.stress,
            payload: {'rating': 1},
          ),
        ]),
        params,
      );
      expect(s.weight, 0);
    });

    test('let-down: sudden drop from high to low yields weight', () {
      final s = module.evaluate(
        withEntries([
          // ordered earliest first; module sorts internally
          JournalEntry(at: now.subtract(Duration(hours: 30)), kind: JournalKind.stress, payload: {'rating': 5}),
          JournalEntry(at: now.subtract(Duration(hours: 24)), kind: JournalKind.stress, payload: {'rating': 5}),
          JournalEntry(at: now.subtract(Duration(hours: 4)), kind: JournalKind.stress, payload: {'rating': 2}),
        ]),
        params,
      );
      // Current low (2) overrides direct contribution, but let-down adds.
      expect(s.weight, greaterThan(0));
      expect(s.explanation.toLowerCase(), contains('let-down'));
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd packages/domain && dart test test/modules/stress_test.dart
```

- [ ] **Step 3: Implement**

Create `packages/domain/lib/src/modules/stress.dart`:

```dart
import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/journal.dart';
import '../types/trigger_signal.dart';

class StressModule implements TriggerModule {
  @override
  String get id => 'stress';
  @override
  Set<DataRequirement> get requires => {DataRequirement.journalStress};
  @override
  Duration get leadTime => const Duration(hours: 12);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    final stress = ctx.recentJournal
        .where((e) => e.kind == JournalKind.stress)
        .toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    if (stress.isEmpty) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'No stress log',
        missing: DataRequirement.journalStress,
      );
    }
    final last = stress.last;
    final rating = ((last.payload['rating'] as num?)?.toInt() ?? 0).clamp(1, 5);
    // Direct contribution: linear from rating 3 to 5.
    final directT = ((rating - 3) / 2).clamp(0.0, 1.0).toDouble();
    double weight = params.weightMax * 0.7 * directT;
    final reasons = <String>[];
    if (rating >= 4) reasons.add('high stress');

    // Let-down detection: prior 24-48h had high stress (≥4) AND current ≤2.
    final cutoff = ctx.now.subtract(const Duration(hours: 48));
    final earlier = stress
        .where((e) => e.at.isBefore(ctx.now.subtract(const Duration(hours: 6))) &&
            !e.at.isBefore(cutoff))
        .toList();
    final earlierWasHigh = earlier.any(
      (e) => ((e.payload['rating'] as num?)?.toInt() ?? 0) >= 4,
    );
    if (rating <= 2 && earlierWasHigh) {
      weight += params.weightMax * 0.3;
      reasons.add('let-down');
    }
    return TriggerSignal(
      moduleId: id,
      weight: weight.clamp(0.0, params.weightMax),
      confidence: 1.0,
      explanation: reasons.isEmpty ? 'Stress rating $rating/5' : reasons.join(', '),
    );
  }
}
```

- [ ] **Step 4: Update barrel**

```dart
export 'src/modules/stress.dart';
```

- [ ] **Step 5: Run — expect PASS**

```bash
cd packages/domain && dart test test/modules/stress_test.dart
```

Expected: 4 passing.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "domain: add stress module with let-down detection"
```

---

## Task 19: Module — hydration

**Files:**
- Create: `packages/domain/lib/src/modules/hydration.dart`
- Test: `packages/domain/test/modules/hydration_test.dart`
- Modify: `packages/domain/lib/domain.dart`

- [ ] **Step 1: Write failing test**

Create `packages/domain/test/modules/hydration_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('HydrationModule', () {
    final module = HydrationModule();
    const params = ModuleParams(
      enabled: true,
      weightMax: 8,
      params: {'min_liters': 1.5},
    );
    final now = DateTime.utc(2026, 6, 10, 18);
    final target = DateTime.utc(2026, 6, 10);

    EvaluationContext build({
      required List<JournalEntry> entries,
      WeatherSeries? weather,
    }) =>
        EvaluationContext(
          now: now,
          targetDate: target,
          recentJournal: entries,
          weather: weather,
          baselines: BaselineSnapshot.empty,
        );

    test('no entries -> zero confidence', () {
      final s = module.evaluate(build(entries: const []), params);
      expect(s.confidence, 0);
    });

    test('entries meeting threshold -> no weight', () {
      final s = module.evaluate(
        build(entries: [
          JournalEntry(
            at: now.subtract(Duration(hours: 2)),
            kind: JournalKind.hydration,
            payload: {'liters': 2.0},
          ),
        ]),
        params,
      );
      expect(s.weight, 0);
    });

    test('low intake -> proportional weight', () {
      final s = module.evaluate(
        build(entries: [
          JournalEntry(
            at: now.subtract(Duration(hours: 2)),
            kind: JournalKind.hydration,
            payload: {'liters': 0.5},
          ),
        ]),
        params,
      );
      expect(s.weight, greaterThan(0));
    });

    test('hot weather amplifies signal', () {
      final hotSamples = [
        WeatherSample(at: now.subtract(Duration(hours: 6)), pressureMsl: 1015, temperatureC: 32, humidityPct: 30),
        WeatherSample(at: now, pressureMsl: 1015, temperatureC: 33, humidityPct: 30),
      ];
      final mildSamples = [
        WeatherSample(at: now.subtract(Duration(hours: 6)), pressureMsl: 1015, temperatureC: 18, humidityPct: 50),
        WeatherSample(at: now, pressureMsl: 1015, temperatureC: 19, humidityPct: 50),
      ];
      final hot = module.evaluate(
        build(
          entries: [
            JournalEntry(at: now.subtract(Duration(hours: 2)), kind: JournalKind.hydration, payload: {'liters': 1.0}),
          ],
          weather: WeatherSeries(samples: hotSamples),
        ),
        params,
      );
      final mild = module.evaluate(
        build(
          entries: [
            JournalEntry(at: now.subtract(Duration(hours: 2)), kind: JournalKind.hydration, payload: {'liters': 1.0}),
          ],
          weather: WeatherSeries(samples: mildSamples),
        ),
        params,
      );
      expect(hot.weight, greaterThan(mild.weight));
    });
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd packages/domain && dart test test/modules/hydration_test.dart
```

- [ ] **Step 3: Implement**

Create `packages/domain/lib/src/modules/hydration.dart`:

```dart
import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/journal.dart';
import '../types/trigger_signal.dart';

class HydrationModule implements TriggerModule {
  @override
  String get id => 'hydration';
  @override
  Set<DataRequirement> get requires => {DataRequirement.journalHydration};
  @override
  Duration get leadTime => const Duration(hours: 6);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    final todayStart = DateTime.utc(ctx.now.year, ctx.now.month, ctx.now.day);
    final entries = ctx.recentJournal
        .where((e) => e.kind == JournalKind.hydration && !e.at.isBefore(todayStart))
        .toList();
    if (entries.isEmpty) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'No hydration log today',
        missing: DataRequirement.journalHydration,
      );
    }
    final totalLiters = entries.fold<double>(
      0,
      (acc, e) => acc + ((e.payload['liters'] as num?)?.toDouble() ?? 0),
    );
    final minLiters = params.getDouble('min_liters', 1.5);
    if (totalLiters >= minLiters) {
      return TriggerSignal(
        moduleId: id,
        weight: 0,
        confidence: 1.0,
        explanation: 'Hydration ${totalLiters.toStringAsFixed(1)} L',
      );
    }
    final deficitT = ((minLiters - totalLiters) / minLiters).clamp(0.0, 1.0);
    double weight = params.weightMax * deficitT;
    // Amplify in hot weather (>28°C max temp last 24h).
    double tempMax = 0;
    if (ctx.weather != null && ctx.weather!.samples.isNotEmpty) {
      tempMax = ctx.weather!.samples
          .where((s) => !s.at.isBefore(ctx.now.subtract(const Duration(hours: 24))))
          .map((s) => s.temperatureC)
          .fold<double>(0, (a, b) => a > b ? a : b);
    }
    if (tempMax > 28) {
      weight *= 1.25;
    }
    return TriggerSignal(
      moduleId: id,
      weight: weight.clamp(0.0, params.weightMax),
      confidence: 1.0,
      explanation: 'Low hydration (${totalLiters.toStringAsFixed(1)} L)',
    );
  }
}
```

- [ ] **Step 4: Update barrel**

```dart
export 'src/modules/hydration.dart';
```

- [ ] **Step 5: Run — expect PASS**

```bash
cd packages/domain && dart test test/modules/hydration_test.dart
```

Expected: 4 passing.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "domain: add hydration module"
```

---

## Task 20: Bundled rules_config_v1.json

**Files:**
- Create: `assets/rules_config_v1.json`
- Modify: `pubspec.yaml` (add assets entry)

- [ ] **Step 1: Write the bundled config**

Create `assets/rules_config_v1.json`:

```json
{
  "version": 1,
  "modules": {
    "pressure_drop":        { "enabled": true, "weight_max": 18, "params": { "threshold_hpa": 5, "lookahead_hours": 48 } },
    "humidity_temp_swing":  { "enabled": true, "weight_max": 10, "params": { "humidity_pct": 60, "temp_delta_c": 5 } },
    "air_quality":          { "enabled": true, "weight_max": 10, "params": { "pm25_threshold": 35 } },
    "sleep_deficit":        { "enabled": true, "weight_max": 20, "params": { "hours_threshold": 6, "efficiency_threshold": 0.85, "baseline_days": 7, "typical_sleep_start_hour": 22 } },
    "hrv_letdown":          { "enabled": true, "weight_max": 12, "params": { "drop_pct": 20, "baseline_days": 14 } },
    "menstrual_phase":      { "enabled": false, "weight_max": 20, "params": { "window_days": [-2, 3] } },
    "refractory":           { "enabled": true, "weight_max": 6,  "params": { "suppression_hours": 48 } },
    "alcohol":              { "enabled": true, "weight_max": 12, "params": { "lookback_hours": 24 } },
    "caffeine":             { "enabled": true, "weight_max": 8,  "params": { "delta_mg_threshold": 100 } },
    "stress":               { "enabled": true, "weight_max": 12, "params": {} },
    "hydration":            { "enabled": true, "weight_max": 8,  "params": { "min_liters": 1.5 } }
  },
  "score_bands": { "low": 25, "moderate": 50, "high": 75 },
  "unflagged_trigger_confidence_multiplier": 0.6
}
```

- [ ] **Step 2: Wire as a Flutter asset**

Edit the root `pubspec.yaml`, in the `flutter:` section add:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/rules_config_v1.json
```

- [ ] **Step 3: Verify**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter pub get
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "Bundle rules_config_v1.json with the app"
```

---

## Task 21: Integration test — engine wired with all modules

**Files:**
- Test: `packages/domain/test/engine/engine_integration_test.dart`

- [ ] **Step 1: Write test exercising the full module list**

Create `packages/domain/test/engine/engine_integration_test.dart`:

```dart
import 'dart:io';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  test('engine produces a sensible high-risk assessment from bundled config + realistic context', () {
    // Load the bundled config from the repo (test relative path).
    final cfgText = File('../../assets/rules_config_v1.json').readAsStringSync();
    final cfg = RulesConfigLoader.parse(cfgText);

    final engine = RiskEngine(modules: [
      PressureDropModule(),
      HumidityTempSwingModule(),
      AirQualityModule(),
      SleepDeficitModule(),
      HrvLetdownModule(),
      MenstrualPhaseModule(),
      RefractoryModule(),
      AlcoholModule(),
      CaffeineModule(),
      StressModule(),
      HydrationModule(),
    ]);

    final now = DateTime.utc(2026, 6, 10, 6);
    final target = DateTime.utc(2026, 6, 10);
    final lastNight = DateTime.utc(2026, 6, 9);

    // Big pressure drop + bad sleep + alcohol last night = should be high.
    final ctx = EvaluationContext(
      now: now,
      targetDate: target,
      weather: WeatherSeries(samples: [
        WeatherSample(at: now, pressureMsl: 1020, temperatureC: 18, humidityPct: 50),
        WeatherSample(at: now.add(Duration(hours: 24)), pressureMsl: 1008, temperatureC: 19, humidityPct: 55),
      ]),
      health: HealthMetrics(
        recentSleep: [
          SleepRecord(
            night: lastNight,
            totalSleep: Duration(hours: 4, minutes: 30),
            efficiency: 0.78,
            sleepStart: lastNight.add(Duration(hours: 25)),
          ),
        ],
        recentHrv: [HrvSample(at: now, rmssdMs: 30)],
      ),
      recentJournal: [
        JournalEntry(at: now.subtract(Duration(hours: 8)), kind: JournalKind.alcohol, payload: {'units': 3.0}),
        JournalEntry(at: now.subtract(Duration(hours: 4)), kind: JournalKind.stress, payload: {'rating': 5}),
      ],
      baselines: BaselineSnapshot(
        sleepMedian7d: Duration(hours: 7),
        hrvRmssdBaseline14d: 50,
      ),
      userFlags: UserTriggerFlags(
        flaggedModuleIds: {'pressure_drop', 'sleep_deficit', 'alcohol', 'stress', 'hrv_letdown'},
      ),
    );

    final ass = engine.evaluate(ctx, cfg, horizon: RiskHorizon.today);
    expect(ass.score, greaterThan(60));
    expect(ass.band, anyOf(RiskBand.high, RiskBand.veryHigh));
    expect(ass.contributors.first.contribution, greaterThan(0));
    expect(ass.configVersion, 1);
  });

  test('empty context with no permissions yields onboarding assessment', () {
    final cfgText = File('../../assets/rules_config_v1.json').readAsStringSync();
    final cfg = RulesConfigLoader.parse(cfgText);

    final engine = RiskEngine(modules: [
      PressureDropModule(),
      SleepDeficitModule(),
      HrvLetdownModule(),
      AlcoholModule(),
      CaffeineModule(),
      StressModule(),
      HydrationModule(),
    ]);

    final now = DateTime.utc(2026, 6, 10);
    final ass = engine.evaluate(
      EvaluationContext(now: now, targetDate: now, baselines: BaselineSnapshot.empty),
      cfg,
      horizon: RiskHorizon.today,
    );
    expect(ass.isOnboarding, isTrue);
    expect(ass.score, 0);
  });
}
```

- [ ] **Step 2: Run**

```bash
cd packages/domain && dart test test/engine/engine_integration_test.dart
```

Expected: 2 passing.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "domain: integration test for engine + all 11 modules"
```

---

## Task 22: CLI driver — bin/score_cli.dart

**Files:**
- Create: `packages/domain/bin/score_cli.dart`
- Create: `packages/domain/test/cli/score_cli_test.dart`

- [ ] **Step 1: Implement the CLI driver**

The CLI reads an `EvaluationContext` JSON from stdin (or a file path arg) plus a config path, and prints the resulting `RiskAssessment` as JSON. Useful for end-to-end smoke testing without the app.

Create `packages/domain/bin/score_cli.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:domain/domain.dart';

List<TriggerModule> _buildModules() => [
      PressureDropModule(),
      HumidityTempSwingModule(),
      AirQualityModule(),
      SleepDeficitModule(),
      HrvLetdownModule(),
      MenstrualPhaseModule(),
      RefractoryModule(),
      AlcoholModule(),
      CaffeineModule(),
      StressModule(),
      HydrationModule(),
    ];

EvaluationContext _ctxFromJson(Map<String, Object?> json) {
  DateTime parse(String key) => DateTime.parse(json[key] as String);

  WeatherSeries? weather;
  if (json['weather'] is List) {
    weather = WeatherSeries(
      samples: (json['weather'] as List).map((e) {
        final m = e as Map<String, Object?>;
        return WeatherSample(
          at: DateTime.parse(m['at'] as String),
          pressureMsl: (m['pressureMsl'] as num).toDouble(),
          temperatureC: (m['temperatureC'] as num).toDouble(),
          humidityPct: (m['humidityPct'] as num).toDouble(),
        );
      }).toList(),
    );
  }

  AirQualitySeries? aq;
  if (json['airQuality'] is List) {
    aq = AirQualitySeries(
      samples: (json['airQuality'] as List).map((e) {
        final m = e as Map<String, Object?>;
        return AirQualitySample(
          at: DateTime.parse(m['at'] as String),
          pm25: (m['pm25'] as num).toDouble(),
        );
      }).toList(),
    );
  }

  HealthMetrics? health;
  if (json['health'] is Map) {
    final h = json['health'] as Map<String, Object?>;
    health = HealthMetrics(
      recentSleep: ((h['sleep'] as List?) ?? [])
          .map((e) {
            final m = e as Map<String, Object?>;
            return SleepRecord(
              night: DateTime.parse(m['night'] as String),
              totalSleep: Duration(minutes: (m['totalMinutes'] as num).toInt()),
              efficiency: (m['efficiency'] as num).toDouble(),
              sleepStart: DateTime.parse(m['sleepStart'] as String),
            );
          })
          .toList(),
      recentHrv: ((h['hrv'] as List?) ?? [])
          .map((e) => HrvSample(
                at: DateTime.parse((e as Map)['at'] as String),
                rmssdMs: ((e)['rmssdMs'] as num).toDouble(),
              ))
          .toList(),
      menstrualHistory: ((h['menstrual'] as List?) ?? [])
          .map((e) => MenstrualEvent(onsetDate: DateTime.parse((e as Map)['onsetDate'] as String)))
          .toList(),
    );
  }

  final journal = ((json['journal'] as List?) ?? []).map((e) {
    final m = e as Map<String, Object?>;
    return JournalEntry(
      at: DateTime.parse(m['at'] as String),
      kind: JournalKind.values.firstWhere((k) => k.name == m['kind']),
      payload: Map<String, Object?>.from(m['payload'] as Map),
    );
  }).toList();

  final attacks = ((json['attacks'] as List?) ?? []).map((e) {
    final m = e as Map<String, Object?>;
    return Attack(
      startedAt: DateTime.parse(m['startedAt'] as String),
      endedAt: m['endedAt'] == null ? null : DateTime.parse(m['endedAt'] as String),
      severity: (m['severity'] as num).toInt(),
    );
  }).toList();

  final flagsRaw = (json['userFlags'] as Map<String, Object?>?) ?? {};
  final flags = UserTriggerFlags(
    flaggedModuleIds:
        ((flagsRaw['flagged'] as List?) ?? []).map((e) => e.toString()).toSet(),
    weightOverrides: ((flagsRaw['overrides'] as Map?) ?? {}).map(
      (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
    ),
  );

  final baselinesRaw = (json['baselines'] as Map<String, Object?>?) ?? {};
  final baselines = BaselineSnapshot(
    sleepMedian7d: baselinesRaw['sleepMedianMinutes'] == null
        ? null
        : Duration(minutes: (baselinesRaw['sleepMedianMinutes'] as num).toInt()),
    hrvRmssdBaseline14d: (baselinesRaw['hrvRmssd'] as num?)?.toDouble(),
    pressureBaseline: (baselinesRaw['pressure'] as num?)?.toDouble(),
    caffeineDailyMg: (baselinesRaw['caffeineDailyMg'] as num?)?.toDouble(),
  );

  return EvaluationContext(
    now: parse('now'),
    targetDate: parse('targetDate'),
    weather: weather,
    airQuality: aq,
    health: health,
    recentJournal: journal,
    recentAttacks: attacks,
    userFlags: flags,
    baselines: baselines,
  );
}

Map<String, Object?> _assessmentToJson(RiskAssessment a) => {
      'score': a.score,
      'band': a.band.name,
      'isOnboarding': a.isOnboarding,
      'configVersion': a.configVersion,
      'targetDate': a.targetDate.toIso8601String(),
      'horizon': a.horizon.name,
      'computedAt': a.computedAt.toIso8601String(),
      'contributors': a.contributors
          .map((c) => {
                'moduleId': c.moduleId,
                'weight': c.weight,
                'confidence': c.confidence,
                'contribution': c.contribution,
                'explanation': c.explanation,
              })
          .toList(),
    };

Future<int> _run(List<String> args, Stream<List<int>> stdinStream) async {
  if (args.length < 1) {
    stderr.writeln('usage: score_cli <config.json> [context.json]');
    return 2;
  }
  final cfg = RulesConfigLoader.parse(File(args[0]).readAsStringSync());
  final String ctxText = args.length >= 2
      ? File(args[1]).readAsStringSync()
      : await utf8.decoder.bind(stdinStream).join();
  final ctxJson = jsonDecode(ctxText) as Map<String, Object?>;
  final ctx = _ctxFromJson(ctxJson);
  final engine = RiskEngine(modules: _buildModules());
  final horizon = ctxJson['horizon'] == 'tomorrow' ? RiskHorizon.tomorrow : RiskHorizon.today;
  final ass = engine.evaluate(ctx, cfg, horizon: horizon);
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(_assessmentToJson(ass)));
  return 0;
}

Future<void> main(List<String> args) async {
  exit(await _run(args, stdin));
}
```

- [ ] **Step 2: Write CLI test (exercising the entry function)**

Create `packages/domain/test/cli/score_cli_test.dart`:

```dart
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('CLI scores a high-risk context against the bundled config', () async {
    final cfgPath = '../../assets/rules_config_v1.json';
    final ctx = {
      'now': '2026-06-10T06:00:00Z',
      'targetDate': '2026-06-10T00:00:00Z',
      'horizon': 'today',
      'weather': [
        {'at': '2026-06-10T06:00:00Z', 'pressureMsl': 1020, 'temperatureC': 18, 'humidityPct': 50},
        {'at': '2026-06-11T06:00:00Z', 'pressureMsl': 1006, 'temperatureC': 19, 'humidityPct': 55},
      ],
      'health': {
        'sleep': [
          {
            'night': '2026-06-09T00:00:00Z',
            'totalMinutes': 270,
            'efficiency': 0.78,
            'sleepStart': '2026-06-10T01:00:00Z',
          },
        ],
        'hrv': [{'at': '2026-06-10T06:00:00Z', 'rmssdMs': 30}],
      },
      'journal': [
        {'at': '2026-06-09T22:00:00Z', 'kind': 'alcohol', 'payload': {'units': 3.0}},
        {'at': '2026-06-10T02:00:00Z', 'kind': 'stress', 'payload': {'rating': 5}},
      ],
      'attacks': [],
      'baselines': {'sleepMedianMinutes': 420, 'hrvRmssd': 50},
      'userFlags': {
        'flagged': ['pressure_drop', 'sleep_deficit', 'alcohol', 'stress', 'hrv_letdown'],
        'overrides': {}
      }
    };

    final tmp = await File('${Directory.systemTemp.path}/ctx.json').create();
    await tmp.writeAsString(jsonEncode(ctx));

    final result = await Process.run('dart', ['run', 'bin/score_cli.dart', cfgPath, tmp.path]);
    expect(result.exitCode, 0, reason: 'stderr: ${result.stderr}');
    final out = jsonDecode(result.stdout as String) as Map<String, Object?>;
    expect((out['score'] as num).toInt(), greaterThan(60));
    expect(out['band'], anyOf('high', 'veryHigh'));
  }, timeout: const Timeout(Duration(seconds: 30)));
}
```

- [ ] **Step 3: Run — expect PASS**

```bash
cd packages/domain && dart test test/cli/score_cli_test.dart
```

Expected: 1 passing test (this spawns a subprocess; may take ~5s).

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "domain: add score_cli driver + end-to-end CLI test"
```

---

## Task 23: CI workflow for domain tests

**Files:**
- Create: `.github/workflows/ci.yaml`

- [ ] **Step 1: Write workflow**

Create `.github/workflows/ci.yaml`:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  domain-tests:
    name: Pure-Dart domain tests
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: packages/domain
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1
        with:
          sdk: '3.4.0'
      - run: dart pub get
      - run: dart analyze --fatal-infos
      - run: dart test

  flutter-build:
    name: Flutter analyze
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
          channel: 'stable'
      - run: flutter pub get
      - run: flutter analyze
```

- [ ] **Step 2: Run the full domain test suite locally to sanity-check**

```bash
cd packages/domain && dart analyze --fatal-infos && dart test
```

Expected: no analyzer errors; all tests pass.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "ci: pure-Dart domain tests + Flutter analyze on push/PR"
```

---

## Done

After Task 23, you have:

- A scaffolded Flutter project + a tested pure-Dart `domain/` package.
- All 11 trigger modules implementing the `TriggerModule` interface, each unit-tested and exercised by an end-to-end integration test against the bundled `rules_config_v1.json`.
- A CLI driver (`bin/score_cli.dart`) you can pipe arbitrary context JSON to without touching Flutter — useful for sanity-checking new fixtures.
- A CI workflow running pure-Dart tests + `flutter analyze` on every push.

Plan 2 (Adapters + Storage) builds on top of these interfaces: it will produce real `WeatherSeries`, `HealthMetrics`, `JournalEntry` instances from Open-Meteo, the `health` package, and Drift respectively, and persist `RiskAssessment` to SQLite.

# Location UX + Per-Day Coordinate Storage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make location legible everywhere it matters — remove the misleading "San Francisco" default in Settings, show the current location on Today, and label each History day with the actual place its metrics came from — by explicitly storing the resolved coordinates on every assessment.

**Architecture:** Locations are currently stored as raw lat/lon and the resolved location dies inside `ContextBuilder.build`. We (1) add nullable `resolvedLat`/`resolvedLon`/`locationName` columns to `RiskAssessments`, thread the resolved location from `ContextBuilder` → `EvaluationContext` → `RiskAssessment` → persistence, and backfill existing rows from the weather cache; (2) persist the geocoder's display name for manual locations; (3) add a reverse-geocoder so GPS coordinates render as "City, Region"; (4) surface a shared "effective location" across Settings, Today, and History day-detail.

**Tech Stack:** Flutter, Riverpod, Drift (SQLite), `geolocator` (existing), `geocoding` (new), the `domain` package (pure Dart engine/types).

## Global Constraints

- Drift `schemaVersion` moves from **15 → 16**. New columns are **nullable** with no default.
- New `EvaluationContext` / `RiskAssessment` fields are **nullable and defaulted** so existing construction sites and tests keep compiling.
- Reverse geocoding must **degrade gracefully**: any failure/empty result falls back to formatted raw coordinates. Never throw from display code.
- Follow existing patterns: providers in `lib/state/`, Drift tables/migrations in `lib/data/database.dart`, domain types in `packages/domain/lib/src/types/`.
- After any change to `lib/data/database.dart` tables, regenerate Drift code with `dart run build_runner build --delete-conflicting-outputs`.
- Run the full suite with `flutter test` from the repo root.
- Coordinate display format everywhere: `lat.toStringAsFixed(4), lon.toStringAsFixed(4)` (matches existing Settings/day-detail code).

---

### Task 1: Add per-day location columns + migration + backfill

**Files:**
- Modify: `lib/data/database.dart` (RiskAssessments table ~62-77; `schemaVersion` line 178; migration `onUpgrade` ~183-322)
- Regenerate: `lib/data/database.g.dart` (via build_runner — do not hand-edit)
- Test: `test/data/database_migration_test.dart`

**Interfaces:**
- Produces: `RiskAssessments.resolvedLat` (RealColumn nullable), `.resolvedLon` (RealColumn nullable), `.locationName` (TextColumn nullable); `AppDatabase.backfillAssessmentLocations()` → `Future<int>` (number of rows updated).

- [ ] **Step 1: Write the failing test for the new columns on a fresh DB**

Add to `test/data/database_migration_test.dart`:

```dart
  test('v16: risk_assessments has nullable resolved location columns', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 16);

    final id = await db.into(db.riskAssessments).insert(
          RiskAssessmentsCompanion.insert(
            targetDate: DateTime.utc(2026, 7, 20),
            horizon: 'today',
            score: 30,
            band: 'moderate',
            computedAt: DateTime.utc(2026, 7, 20, 23),
            configVersion: 1,
            contributorsJson: '[]',
            resolvedLat: const Value(37.8044),
            resolvedLon: const Value(-122.2712),
            locationName: const Value('Oakland, California'),
          ),
        );
    final row = await (db.select(db.riskAssessments)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    expect(row.resolvedLat, closeTo(37.8044, 0.0001));
    expect(row.resolvedLon, closeTo(-122.2712, 0.0001));
    expect(row.locationName, 'Oakland, California');
  });

  test('v16: resolved location columns default to null', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await db.into(db.riskAssessments).insert(
          RiskAssessmentsCompanion.insert(
            targetDate: DateTime.utc(2026, 7, 21),
            horizon: 'today',
            score: 10,
            band: 'low',
            computedAt: DateTime.utc(2026, 7, 21, 23),
            configVersion: 1,
            contributorsJson: '[]',
          ),
        );
    final row = await (db.select(db.riskAssessments)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    expect(row.resolvedLat, isNull);
    expect(row.resolvedLon, isNull);
    expect(row.locationName, isNull);
  });
```

Also update the three existing `expect(db.schemaVersion, 15)` assertions (lines 10, 29, 47, 132, 169, 185) to `16` — grep for `schemaVersion, 15` to catch all.

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/data/database_migration_test.dart`
Expected: FAIL — `resolvedLat` is not defined on the companion / `schemaVersion` is 15.

- [ ] **Step 3: Add the columns and bump schemaVersion**

In `lib/data/database.dart`, add to the `RiskAssessments` table (after `backfilled`, before the `uniqueKeys` override):

```dart
  // Resolved location the assessment was scored at. Nullable: not every day has
  // a location-driven score, and pre-v16 rows are backfilled from the weather
  // cache (locationName stays null there — reverse-geocoded lazily at display).
  RealColumn get resolvedLat => real().nullable()();
  RealColumn get resolvedLon => real().nullable()();
  TextColumn get locationName => text().nullable()();
```

Change `int get schemaVersion => 15;` to `=> 16;`.

- [ ] **Step 4: Add the migration block + backfill helper**

In the `onUpgrade` closure, after the `if (from < 15)` block, add:

```dart
          if (from < 16) {
            await m.addColumn(riskAssessments, riskAssessments.resolvedLat);
            await m.addColumn(riskAssessments, riskAssessments.resolvedLon);
            await m.addColumn(riskAssessments, riskAssessments.locationName);
            await backfillAssessmentLocations();
          }
```

Add this method to `AppDatabase` (near `extractForecastTimes`):

```dart
  /// Populates resolvedLat/resolvedLon on assessment rows that lack them by
  /// matching each assessment's targetDate against the coverage window of a
  /// cached weather snapshot. Prefers the snapshot whose fetchedAt is closest
  /// to the assessment's computedAt. locationName is left null (historical name
  /// unknown; reverse-geocoded lazily at display). Returns rows updated.
  Future<int> backfillAssessmentLocations() async {
    final snaps = await (select(weatherSnapshots)
          ..where((t) =>
              t.coverageStart.isNotNull() & t.coverageEnd.isNotNull()))
        .get();
    if (snaps.isEmpty) return 0;
    final assessments = await (select(riskAssessments)
          ..where((t) => t.resolvedLat.isNull()))
        .get();
    var updated = 0;
    for (final a in assessments) {
      final day = a.targetDate;
      final covering = snaps.where((s) =>
          !s.coverageStart!.isAfter(day) && !s.coverageEnd!.isBefore(day));
      if (covering.isEmpty) continue;
      final best = covering.reduce((x, y) =>
          (x.fetchedAt.difference(a.computedAt).abs() <=
                  y.fetchedAt.difference(a.computedAt).abs())
              ? x
              : y);
      await (update(riskAssessments)..where((t) => t.id.equals(a.id)))
          .write(RiskAssessmentsCompanion(
        resolvedLat: Value(best.lat),
        resolvedLon: Value(best.lon),
      ));
      updated++;
    }
    return updated;
  }
```

Ensure `Value` is available — `database.dart` already imports `package:drift/drift.dart`.

- [ ] **Step 5: Regenerate Drift code**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `database.g.dart` updates; `RiskAssessmentsCompanion.insert` now accepts the three new optional fields.

- [ ] **Step 6: Write the failing backfill test**

Add to `test/data/database_migration_test.dart`:

```dart
  test('backfillAssessmentLocations copies coords from covering snapshot', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // Snapshot covering 2026-07-20, fetched close to the assessment's compute.
    await db.into(db.weatherSnapshots).insert(WeatherSnapshotsCompanion.insert(
          fetchedAt: DateTime.utc(2026, 7, 20, 22),
          lat: 40.7128,
          lon: -74.0060,
          forecastJson: '{}',
          coverageStart: Value(DateTime.utc(2026, 7, 18)),
          coverageEnd: Value(DateTime.utc(2026, 7, 22)),
        ));
    // Far snapshot that also covers the day but fetched days earlier.
    await db.into(db.weatherSnapshots).insert(WeatherSnapshotsCompanion.insert(
          fetchedAt: DateTime.utc(2026, 7, 10, 0),
          lat: 1.0,
          lon: 2.0,
          forecastJson: '{}',
          coverageStart: Value(DateTime.utc(2026, 7, 5)),
          coverageEnd: Value(DateTime.utc(2026, 7, 25)),
        ));

    final id = await db.into(db.riskAssessments).insert(
          RiskAssessmentsCompanion.insert(
            targetDate: DateTime.utc(2026, 7, 20),
            horizon: 'today',
            score: 22,
            band: 'low',
            computedAt: DateTime.utc(2026, 7, 20, 23),
            configVersion: 1,
            contributorsJson: '[]',
          ),
        );

    final updated = await db.backfillAssessmentLocations();
    expect(updated, 1);

    final row = await (db.select(db.riskAssessments)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    expect(row.resolvedLat, closeTo(40.7128, 0.0001)); // closest-fetch wins
    expect(row.locationName, isNull);
  });

  test('backfillAssessmentLocations leaves uncovered days null', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await db.into(db.riskAssessments).insert(
          RiskAssessmentsCompanion.insert(
            targetDate: DateTime.utc(2026, 7, 20),
            horizon: 'today',
            score: 5,
            band: 'low',
            computedAt: DateTime.utc(2026, 7, 20, 23),
            configVersion: 1,
            contributorsJson: '[]',
          ),
        );
    final updated = await db.backfillAssessmentLocations();
    expect(updated, 0);
    final row = await (db.select(db.riskAssessments)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    expect(row.resolvedLat, isNull);
  });
```

- [ ] **Step 7: Run tests to verify they pass**

Run: `flutter test test/data/database_migration_test.dart`
Expected: PASS (all, including the schemaVersion==16 checks).

- [ ] **Step 8: Commit**

```bash
git add lib/data/database.dart lib/data/database.g.dart test/data/database_migration_test.dart
git commit -m "feat: store resolved location on assessments (schema v16) + weather-cache backfill"
```

---

### Task 2: Thread resolved location through domain + persistence

**Files:**
- Modify: `packages/domain/lib/src/types/evaluation_context.dart`
- Modify: `packages/domain/lib/src/types/risk_assessment.dart`
- Modify: `packages/domain/lib/src/engine/risk_engine.dart:57-65`
- Modify: `lib/data/context_builder.dart:39-80`
- Modify: `lib/data/repos/assessment_repository.dart:20-45`
- Test: `test/data/context_builder_test.dart`, `test/data/repos/` (new `assessment_repository_location_test.dart`)

**Interfaces:**
- Consumes: `RiskAssessments.resolvedLat/resolvedLon/locationName` columns (Task 1).
- Produces: `EvaluationContext.resolvedLat/resolvedLon/locationName` (all `double?`/`String?`, defaulted null); identical trio on `RiskAssessment`; `AssessmentRepository.save` persists them.

- [ ] **Step 1: Add nullable fields to EvaluationContext**

In `evaluation_context.dart`, add fields (after `baselines`), constructor params (optional), and props entries:

```dart
  final double? resolvedLat;
  final double? resolvedLon;
  final String? locationName;
```

Constructor: add `this.resolvedLat, this.resolvedLon, this.locationName,` (optional, no `required`). Add all three to the `props` list.

- [ ] **Step 2: Add matching fields to RiskAssessment**

In `risk_assessment.dart`, add the same three nullable fields, add them as optional constructor params, and append to `props`.

- [ ] **Step 3: Copy fields in the engine**

In `risk_engine.dart`, the `return RiskAssessment(...)` (line 57): add

```dart
      resolvedLat: ctx.resolvedLat,
      resolvedLon: ctx.resolvedLon,
      locationName: ctx.locationName,
```

- [ ] **Step 4: Write failing ContextBuilder test**

In `test/data/context_builder_test.dart`, add a test asserting the resolved location is carried onto the context. Use the existing fakes in that file (a manual location with a label, or a per-day override). Example shape:

```dart
  test('build carries resolved lat/lon and name onto the context', () async {
    // ... arrange builder with a location source returning
    //     UserLocation(lat: 37.8, lon: -122.27, label: 'Oakland, California')
    final ctx = await builder.build(
      now: DateTime.utc(2026, 7, 20, 23),
      target: DateTime.utc(2026, 7, 20),
    );
    expect(ctx.resolvedLat, closeTo(37.8, 0.001));
    expect(ctx.resolvedLon, closeTo(-122.27, 0.001));
    expect(ctx.locationName, 'Oakland, California');
  });
```

Match the existing test file's fake/setup conventions (read the top of the file first).

- [ ] **Step 5: Run it to verify it fails**

Run: `flutter test test/data/context_builder_test.dart`
Expected: FAIL — `resolvedLat` is null (ContextBuilder not yet setting it).

- [ ] **Step 6: Set the fields in ContextBuilder.build**

In `context_builder.dart`, after resolving `loc` (line 42), and in the returned `EvaluationContext`, add:

```dart
      resolvedLat: loc?.lat,
      resolvedLon: loc?.lon,
      // Name is known only when it came from a per-day override or a labelled
      // manual location; GPS coords are reverse-geocoded lazily at display.
      locationName: overrideLoc?.label ?? loc?.label,
```

Note: `LocationOverridesRepo.forDay` currently returns `UserLocation(lat, lon)` without a label — update it to include `label: row.displayName` so overrides carry their name. (`location_overrides_repo.dart:24`.)

- [ ] **Step 7: Persist in AssessmentRepository.save**

In `assessment_repository.dart`, add to the `RiskAssessmentsCompanion.insert(...)`:

```dart
      resolvedLat: Value(ass.resolvedLat),
      resolvedLon: Value(ass.resolvedLon),
      locationName: Value(ass.locationName),
```

`Value` is already imported (`package:drift/drift.dart`).

- [ ] **Step 8: Write failing save/round-trip test**

Create `test/data/repos/assessment_repository_location_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart'
    hide RiskAssessment;
import 'package:migraine_forecast/data/repos/assessment_repository.dart';

void main() {
  test('save persists resolved location and reload returns it', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = AssessmentRepository(db);

    await repo.save(RiskAssessment(
      score: 22,
      band: RiskBand.low,
      contributors: const [],
      computedAt: DateTime.utc(2026, 7, 20, 23),
      configVersion: 1,
      targetDate: DateTime.utc(2026, 7, 20),
      horizon: RiskHorizon.today,
      resolvedLat: 37.8044,
      resolvedLon: -122.2712,
      locationName: 'Oakland, California',
    ));

    final row = await db.select(db.riskAssessments).getSingle();
    expect(row.resolvedLat, closeTo(37.8044, 0.0001));
    expect(row.locationName, 'Oakland, California');
  });
}
```

- [ ] **Step 9: Run domain + repo tests to verify pass**

Run: `flutter test test/data/context_builder_test.dart test/data/repos/assessment_repository_location_test.dart`
Expected: PASS.

- [ ] **Step 10: Run the full suite to catch construction-site breakage**

Run: `flutter test`
Expected: PASS. (Optional fields mean no existing call site should break; fix any that do.)

- [ ] **Step 11: Commit**

```bash
git add packages/domain lib/data/context_builder.dart lib/data/repos/assessment_repository.dart lib/data/repos/location_overrides_repo.dart test/data/context_builder_test.dart test/data/repos/assessment_repository_location_test.dart
git commit -m "feat: thread resolved location through context, engine, and assessment persistence"
```

---

### Task 3: Persist a name for the manual location

**Files:**
- Modify: `lib/data/sources/persisted_manual_location_source.dart`
- Modify: `lib/state/settings_provider.dart:145-153`
- Modify: `lib/ui/settings/settings_screen.dart:671-684` (`_showLocationDialog` / `onPick`)
- Test: `test/data/sources/manual_location_source_test.dart` (or a new persisted-source test if this file targets the in-memory source)

**Interfaces:**
- Consumes: `UserLocation.label` (already exists).
- Produces: `PersistedManualLocationSource.set({required double lat, required double lon, String? label})`; `setManualLocationProvider` callable signature `(double lat, double lon, String? label)`.

- [ ] **Step 1: Write the failing persistence test**

Find the test that covers `PersistedManualLocationSource` (grep `PersistedManualLocationSource` under `test/`). Add:

```dart
  test('set persists label and current() returns it', () async {
    final source = PersistedManualLocationSource(settingsRepo); // per file's setup
    await source.set(lat: 37.8044, lon: -122.2712, label: 'Oakland, California');
    final loc = await source.current();
    expect(loc!.label, 'Oakland, California');
    expect(loc.lat, closeTo(37.8044, 0.0001));
  });
```

If no persisted-source test file exists, create `test/data/sources/persisted_manual_location_source_test.dart` using an in-memory `AppDatabase` + `SettingsRepo` (mirror how other data-source tests build a `SettingsRepo`).

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/data/sources/persisted_manual_location_source_test.dart` (or the existing file)
Expected: FAIL — `set` has no `label` parameter.

- [ ] **Step 3: Persist the label**

In `persisted_manual_location_source.dart`:

```dart
  Future<void> set({required double lat, required double lon, String? label}) async {
    _cached = UserLocation(lat: lat, lon: lon, label: label);
    await _settings.setString('manual_lat', lat.toString());
    await _settings.setString('manual_lon', lon.toString());
    await _settings.setString('manual_label', label ?? '');
  }
```

In `clear()`, also clear the label:

```dart
    await _settings.setString('manual_label', '');
```

In `current()`, read the label after parsing lat/lon:

```dart
    final label = await _settings.getString('manual_label');
    _cached = UserLocation(
      lat: lat,
      lon: lon,
      label: (label == null || label.isEmpty) ? null : label,
    );
    return _cached;
```

- [ ] **Step 4: Update the provider signature**

In `settings_provider.dart`:

```dart
final setManualLocationProvider =
    Provider<Future<void> Function(double lat, double lon, String? label)>((ref) {
  return (lat, lon, label) async {
    await ref.read(manualLocationSourceProvider).set(lat: lat, lon: lon, label: label);
    ref.invalidate(manualLocationProvider);
    ref.invalidate(riskAssessmentProvider);
    ref.invalidate(tomorrowRiskAssessmentProvider);
    ref.invalidate(outlookProvider);
  };
});
```

- [ ] **Step 5: Pass the display name from the Settings dialog**

In `settings_screen.dart` `_showLocationDialog`, update `onPick`:

```dart
        onPick: (result) => ref
            .read(setManualLocationProvider)(result.lat, result.lon, result.displayName),
```

- [ ] **Step 6: Run tests to verify pass**

Run: `flutter test test/data/sources/persisted_manual_location_source_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/data/sources/persisted_manual_location_source.dart lib/state/settings_provider.dart lib/ui/settings/settings_screen.dart test/data/sources/
git commit -m "feat: persist display name for manual location"
```

---

### Task 4: ReverseGeocoder service + provider

**Files:**
- Modify: `pubspec.yaml` (add `geocoding`)
- Create: `lib/data/sources/reverse_geocoder.dart`
- Modify: `lib/state/providers.dart` (add `reverseGeocoderProvider`)
- Test: `test/data/sources/reverse_geocoder_test.dart`

**Interfaces:**
- Produces:
  - `abstract class ReverseGeocoder { Future<String> label(double lat, double lon); }`
  - `String formatCoords(double lat, double lon)` → `"37.8044, -122.2712"`.
  - `PlatformReverseGeocoder implements ReverseGeocoder` (wraps the `geocoding` package, caches by rounded coord, falls back to `formatCoords`).
  - `reverseGeocoderProvider` → `Provider<ReverseGeocoder>`.

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml` under dependencies (near `geolocator: ^13.0.0`):

```yaml
  geocoding: ^3.0.0
```

Run: `flutter pub get`

- [ ] **Step 2: Write the failing test (interface + fallback + cache)**

Create `test/data/sources/reverse_geocoder_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/sources/reverse_geocoder.dart';

class _FakeGeocoder extends ReverseGeocoder {
  final String? Function(double, double) resolve;
  int calls = 0;
  _FakeGeocoder(this.resolve);

  @override
  Future<String> label(double lat, double lon) async {
    calls++;
    final name = resolve(lat, lon);
    return name ?? formatCoords(lat, lon);
  }
}

void main() {
  test('formatCoords renders 4dp lat, lon', () {
    expect(formatCoords(37.80442, -122.27119), '37.8044, -122.2712');
  });

  test('fake falls back to coords when name is null', () async {
    final g = _FakeGeocoder((_, __) => null);
    expect(await g.label(37.8044, -122.2712), '37.8044, -122.2712');
  });
}
```

(The `geocoding` package makes native OS calls, so the *real* `PlatformReverseGeocoder` is not unit-tested here; its fallback path is covered structurally and via consumers using fakes.)

- [ ] **Step 3: Run it to verify it fails**

Run: `flutter test test/data/sources/reverse_geocoder_test.dart`
Expected: FAIL — `reverse_geocoder.dart` does not exist.

- [ ] **Step 4: Implement the service**

Create `lib/data/sources/reverse_geocoder.dart`:

```dart
import 'package:geocoding/geocoding.dart' as geo;

String formatCoords(double lat, double lon) =>
    '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';

/// Turns coordinates into a short human-readable "City, Region" label.
abstract class ReverseGeocoder {
  Future<String> label(double lat, double lon);
}

/// Real implementation backed by the OS geocoder. Caches by coarse coordinate
/// key and always falls back to [formatCoords] on failure/empty results.
class PlatformReverseGeocoder implements ReverseGeocoder {
  final _cache = <String, String>{};

  @override
  Future<String> label(double lat, double lon) async {
    final key = '${lat.toStringAsFixed(3)},${lon.toStringAsFixed(3)}';
    final cached = _cache[key];
    if (cached != null) return cached;

    String result = formatCoords(lat, lon);
    try {
      final marks = await geo.placemarkFromCoordinates(lat, lon);
      if (marks.isNotEmpty) {
        final m = marks.first;
        final city = (m.locality?.isNotEmpty ?? false)
            ? m.locality!
            : (m.subAdministrativeArea ?? '');
        final region = m.administrativeArea ?? '';
        final parts = [city, region].where((s) => s.isNotEmpty).toList();
        if (parts.isNotEmpty) result = parts.join(', ');
      }
    } catch (_) {
      // Keep the coordinate fallback.
    }
    _cache[key] = result;
    return result;
  }
}
```

- [ ] **Step 5: Add the provider**

In `lib/state/providers.dart` (near `geocoderProvider`):

```dart
final reverseGeocoderProvider =
    Provider<ReverseGeocoder>((_) => PlatformReverseGeocoder());
```

Add the import: `import '../data/sources/reverse_geocoder.dart';`

- [ ] **Step 6: Run tests to verify pass**

Run: `flutter test test/data/sources/reverse_geocoder_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/data/sources/reverse_geocoder.dart lib/state/providers.dart test/data/sources/reverse_geocoder_test.dart
git commit -m "feat: add reverse geocoder for lat/lon to city labels"
```

---

### Task 5: Shared effective-location display provider

**Files:**
- Create: `lib/state/location_display_provider.dart`
- Test: `test/state/location_display_provider_test.dart`

**Interfaces:**
- Consumes: `manualLocationSourceProvider`, `locationSourceProvider`, `reverseGeocoderProvider`.
- Produces:
  - `class LocationDisplay { final String name; final String? coords; final bool isAuto; final bool isSet; }`
  - `effectiveLocationProvider` → `FutureProvider<LocationDisplay>`.

- [ ] **Step 1: Write the failing test**

Create `test/state/location_display_provider_test.dart`. Override the source providers with fakes and assert:
- manual location with label → `name == label`, `isAuto == false`, `isSet == true`;
- no manual + GPS returns coords → `name == reverse-geocoded`, `isAuto == true`;
- no manual + no GPS (null) → `isSet == false`, `name == 'Location not set'`.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:migraine_forecast/data/sources/location_source.dart';
import 'package:migraine_forecast/data/sources/reverse_geocoder.dart';
import 'package:migraine_forecast/state/providers.dart';
import 'package:migraine_forecast/state/location_display_provider.dart';

class _FixedLocation implements LocationSource {
  final UserLocation? loc;
  _FixedLocation(this.loc);
  @override
  Future<UserLocation?> current() async => loc;
}

class _FakeReverse implements ReverseGeocoder {
  @override
  Future<String> label(double lat, double lon) async => 'Oakland, California';
}

void main() {
  Future<LocationDisplay> resolve(ProviderContainer c) =>
      c.read(effectiveLocationProvider.future);

  test('manual with label is used verbatim, not auto', () async {
    final c = ProviderContainer(overrides: [
      manualLocationSourceProvider.overrideWith((_) =>
          throw UnimplementedError()), // not used; see note below
    ]);
    addTearDown(c.dispose);
    // NOTE: adjust overrides to match the provider's actual reads (see Step 3).
  });
}
```

Because `manualLocationSourceProvider` returns a concrete `PersistedManualLocationSource`, prefer to have `effectiveLocationProvider` read `manualLocationProvider` (the `FutureProvider<UserLocation?>`) and `locationSourceProvider`. Override `manualLocationProvider` with `AsyncValue.data(...)` and `locationSourceProvider` with a `_FixedLocation`, and `reverseGeocoderProvider` with `_FakeReverse`. Write the three cases concretely against that shape.

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/state/location_display_provider_test.dart`
Expected: FAIL — provider/class not defined.

- [ ] **Step 3: Implement the provider**

Create `lib/state/location_display_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sources/reverse_geocoder.dart';
import 'providers.dart';
import 'settings_provider.dart';

class LocationDisplay {
  final String name;
  final String? coords;
  final bool isAuto;
  final bool isSet;
  const LocationDisplay({
    required this.name,
    required this.coords,
    required this.isAuto,
    required this.isSet,
  });
}

/// Resolves the *current* effective location into a display model:
/// manual label if set, else reverse-geocoded live GPS, else "Location not set".
final effectiveLocationProvider = FutureProvider<LocationDisplay>((ref) async {
  final manual = await ref.watch(manualLocationProvider.future);
  if (manual != null) {
    return LocationDisplay(
      name: manual.label ?? formatCoords(manual.lat, manual.lon),
      coords: formatCoords(manual.lat, manual.lon),
      isAuto: false,
      isSet: true,
    );
  }
  final gps = await ref.watch(locationSourceProvider).current();
  if (gps == null) {
    return const LocationDisplay(
      name: 'Location not set',
      coords: null,
      isAuto: true,
      isSet: false,
    );
  }
  final name = await ref.watch(reverseGeocoderProvider).label(gps.lat, gps.lon);
  return LocationDisplay(
    name: name,
    coords: formatCoords(gps.lat, gps.lon),
    isAuto: true,
    isSet: true,
  );
});
```

- [ ] **Step 4: Run tests to verify pass**

Run: `flutter test test/state/location_display_provider_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/state/location_display_provider.dart test/state/location_display_provider_test.dart
git commit -m "feat: shared effective-location display provider"
```

---

### Task 6: Settings screen — remove SF hint, pre-fill, show name

**Files:**
- Modify: `lib/ui/common/location_search_dialog.dart:81-87` (hint + optional initial value)
- Modify: `lib/ui/settings/settings_screen.dart:276-306` (row subtitle), `671-684` (pass initial value)
- Test: `test/ui/settings/` (new `settings_location_test.dart`)

**Interfaces:**
- Consumes: `manualLocationProvider` (existing), `LocationSearchDialog`.
- Produces: `LocationSearchDialog` gains `final String? initialQuery;` used as the field's initial text.

- [ ] **Step 1: Write the failing widget test**

Create `test/ui/settings/settings_location_test.dart`. Pump the `LocationSearchDialog` directly and assert:
- the field hint is **not** `San Francisco, CA` and is the neutral hint;
- when `initialQuery: 'Oakland, California'` is passed, the field shows that text.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/sources/open_meteo/open_meteo_geocoder.dart';
import 'package:migraine_forecast/ui/common/location_search_dialog.dart';
import 'package:http/http.dart' as http;

void main() {
  testWidgets('dialog has neutral hint and honors initialQuery', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LocationSearchDialog(
        geocoder: OpenMeteoGeocoder(http.Client()),
        initialQuery: 'Oakland, California',
        onPick: (_) {},
      ),
    ));
    expect(find.text('Oakland, California'), findsOneWidget);
    expect(find.text('San Francisco, CA'), findsNothing);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/ui/settings/settings_location_test.dart`
Expected: FAIL — `initialQuery` not defined / SF hint still present.

- [ ] **Step 3: Update the dialog**

In `location_search_dialog.dart`: add `final String? initialQuery;` to the widget + constructor. In `initState` (add one) set `_ctrl.text = widget.initialQuery ?? '';`. Change the decoration:

```dart
                    decoration: const InputDecoration(
                      labelText: 'City, state, country or postal code',
                      hintText: 'e.g. city, ZIP, or country',
                    ),
```

- [ ] **Step 4: Pre-fill from Settings and show the name in the row**

In `settings_screen.dart` `_showLocationDialog`, pass `initialQuery: current?.label` to `LocationSearchDialog`.

Update the location row subtitle (lines ~286-290) to prefer the name:

```dart
                      subtitle: loc != null
                          ? Text(loc.label ?? '${loc.lat.toStringAsFixed(4)}, ${loc.lon.toStringAsFixed(4)}')
                          : const Text('Auto (GPS)'),
```

- [ ] **Step 5: Run tests to verify pass**

Run: `flutter test test/ui/settings/settings_location_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/ui/common/location_search_dialog.dart lib/ui/settings/settings_screen.dart test/ui/settings/settings_location_test.dart
git commit -m "feat: settings location — neutral hint, prefill current name, show place name"
```

---

### Task 7: Today screen — current location line

**Files:**
- Modify: `lib/ui/today/today_screen.dart` (add a location line near the header, after `build` header area ~line 60+)
- Test: `test/ui/today/` (new `today_location_line_test.dart`)

**Interfaces:**
- Consumes: `effectiveLocationProvider` (Task 5).
- Produces: a private `_CurrentLocationLine` widget (or inline `Consumer`) that renders `📍 <name> · Current location` and navigates to Settings location on tap.

- [ ] **Step 1: Write the failing widget test**

Create `test/ui/today/today_location_line_test.dart`. Override `effectiveLocationProvider` with `AsyncValue.data(LocationDisplay(name: 'Oakland, California', coords: '37.8044, -122.2712', isAuto: true, isSet: true))`, pump the Today screen (follow the existing Today widget-test harness — grep `test/ui/today/` for setup), and assert `find.textContaining('Oakland, California')` is present.

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/ui/today/today_location_line_test.dart`
Expected: FAIL — no location text on Today.

- [ ] **Step 3: Add the location line**

In `today_screen.dart`, add near the top of the scrollable content:

```dart
Consumer(
  builder: (context, ref, _) {
    final loc = ref.watch(effectiveLocationProvider).asData?.value;
    if (loc == null) return const SizedBox.shrink();
    final suffix = loc.isSet && loc.isAuto ? ' · Current location' : '';
    return InkWell(
      onTap: () => context.push('/settings'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            const SizedBox(width: 6),
            Flexible(
              child: Text('${loc.name}$suffix',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  },
),
```

Add the import for `effectiveLocationProvider` (`../../state/location_display_provider.dart`). Confirm the Settings route path — grep `GoRoute` in `lib/app/router.dart` and use the actual path (adjust `/settings` if different).

- [ ] **Step 4: Run tests to verify pass**

Run: `flutter test test/ui/today/today_location_line_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/ui/today/today_screen.dart test/ui/today/today_location_line_test.dart
git commit -m "feat: show current location on the Today screen"
```

---

### Task 8: History day-detail — label from stored coordinates

**Files:**
- Modify: `lib/ui/insights/insights_screen.dart:425-513` (`_LocationOverrideRow`)
- Test: `test/ui/insights/` (new `day_detail_location_label_test.dart`; existing `day_detail_location_override_test.dart` for regression)

**Interfaces:**
- Consumes: `RiskAssessments.resolvedLat/resolvedLon/locationName` for the day, `reverseGeocoderProvider`, existing `_locationOverrideForDayProvider`.
- Produces: a `FutureProvider.family<String, DateTime>` `_dayLocationLabelProvider` that yields the display label for a day (override name → stored `locationName` → reverse-geocoded stored coords → "Location not recorded").

- [ ] **Step 1: Add a repo/query to fetch the stored location for a day**

In `AssessmentRepository`, add (choose the `today` horizon row for the day):

```dart
  /// Returns (lat, lon, name) for the day's stored assessment, or null.
  Future<({double? lat, double? lon, String? name})?> resolvedLocationForDay(
      DateTime day) async {
    final d = day.toUtc();
    final key = DateTime.utc(d.year, d.month, d.day);
    final row = await (_db.select(_db.riskAssessments)
          ..where((t) =>
              t.targetDate.equals(key) & t.horizon.equals('today'))
          ..orderBy([(t) => OrderingTerm.desc(t.computedAt)])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return (lat: row.resolvedLat, lon: row.resolvedLon, name: row.locationName);
  }
```

- [ ] **Step 2: Write the failing widget test**

Create `test/ui/insights/day_detail_location_label_test.dart`. Seed an in-memory DB with a `today` assessment carrying `resolvedLat/resolvedLon` and null `locationName`, override `reverseGeocoderProvider` with a fake returning `'Oakland, California'`, pump the day-detail sheet for that day (mirror `day_detail_location_override_test.dart` setup), and assert:
- with **no** override → label shows `Oakland, California (37.8044, -122.2712)`;
- with an override present → override `displayName` still wins (regression).

Also add a case: assessment with null coords → `Location not recorded`.

- [ ] **Step 3: Run it to verify it fails**

Run: `flutter test test/ui/insights/day_detail_location_label_test.dart`
Expected: FAIL — still shows `Auto (GPS)`.

- [ ] **Step 4: Implement the label provider + wire into the row**

In `insights_screen.dart`, add:

```dart
final _dayLocationLabelProvider =
    FutureProvider.autoDispose.family<String, DateTime>((ref, day) async {
  final override = ref.watch(_locationOverrideForDayProvider(day)).asData?.value;
  if (override != null) return override.displayName;
  final stored = await ref.watch(assessmentRepoProvider).resolvedLocationForDay(day);
  if (stored?.lat == null || stored?.lon == null) return 'Location not recorded';
  final name = stored!.name ??
      await ref.watch(reverseGeocoderProvider).label(stored.lat!, stored.lon!);
  return '$name (${stored.lat!.toStringAsFixed(4)}, ${stored.lon!.toStringAsFixed(4)})';
});
```

In `_LocationOverrideRow.build`, replace `final label = hasOverride ? override.displayName : 'Auto (GPS)';` with a watch on `_dayLocationLabelProvider(day)`:

```dart
    final label = ref.watch(_dayLocationLabelProvider(day)).asData?.value ??
        (hasOverride ? override!.displayName : '…');
```

Keep the existing icon/underline/"Use auto"/search affordances unchanged.

- [ ] **Step 5: Run the day-detail tests to verify pass (incl. regression)**

Run: `flutter test test/ui/insights/day_detail_location_label_test.dart test/ui/insights/day_detail_location_override_test.dart`
Expected: PASS.

- [ ] **Step 6: Run the full suite**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/ui/insights/insights_screen.dart lib/data/repos/assessment_repository.dart test/ui/insights/day_detail_location_label_test.dart
git commit -m "feat: history day-detail shows the actual stored location"
```

---

## Self-Review

**Spec coverage:**
- Spec A (store coords per assessment + migration + backfill) → Tasks 1 & 2. ✓
- Spec B (persist manual name) → Task 3. ✓
- Spec C (reverse geocoder) → Task 4. ✓
- Spec D Settings → Task 6; Today → Task 7; History → Task 8. ✓
- Spec E (shared effective-location provider) → Task 5. ✓
- Edge cases (offline fallback, denied/unset, null stored coords) → Task 4 fallback, Task 5 "Location not set", Task 8 "Location not recorded". ✓
- Testing section → per-task tests cover migration/backfill, manual-label round-trip, reverse-geocoder fallback, effective-location states, and the three screens. ✓

**Placeholder scan:** Task 5 Step 1 intentionally describes the override shape rather than pinning exact override symbols because the concrete override depends on the final provider reads chosen in Step 3; the three assertion cases and the provider implementation (Step 3) are fully specified. All other steps carry runnable code.

**Type consistency:** `set({lat, lon, label})`, `setManualLocationProvider(lat, lon, label)`, `ReverseGeocoder.label(lat, lon)`, `formatCoords`, `LocationDisplay{name, coords, isAuto, isSet}`, `effectiveLocationProvider`, `resolvedLocationForDay` → `({lat, lon, name})`, and `_dayLocationLabelProvider` are used consistently across tasks.

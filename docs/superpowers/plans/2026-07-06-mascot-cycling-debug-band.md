# Mascot Cycling, Per-Mascot Wiggle & Debug Band Override Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the user tap the Today-screen mascot to cycle through the current band's pool (today-only), give each mascot its own wiggle style, and add a debug-build-only Settings control to override the displayed risk band.

**Architecture:** `mascot_pool.dart` gains an `offset` on `mascotAssetFor` plus a `WiggleStyle` map keyed by icon name. A new `lib/state/mascot_overrides.dart` holds two in-memory `StateProvider`s (cycle state, debug band). `MascotWidget` gains a pass-through `cycleOffset` and per-style one-shot wiggle math. TodayScreen wires the tap to increment the cycle and reads the debug override; Settings gets a `kDebugMode`-gated Developer section.

**Tech Stack:** Flutter, Riverpod. No new dependencies, no persistence.

**Spec:** `docs/superpowers/specs/2026-07-06-mascot-cycling-debug-band-design.md`

## Global Constraints

- The cycle choice is in-memory and today-only: it applies only when its stored `dateKey` equals today's local date AND its stored band equals the band being rendered; otherwise ignored. No persisted settings key.
- The debug override is presentation-only: never modify the stored `RiskAssessment`; it must be impossible to reach in release builds (`kDebugMode` gate).
- Seed logic stays isolated in `mascotAssetFor`; behavior unchanged when `offset == 0`.
- Wiggle style constants (verbatim from spec): squish amplitude 0.18 (current); flutter ≈3 sine oscillations of ±4° (0.07 rad), damped; stretch amplitude 0.15 with 650ms action duration; bob 6px dip with 0.08 squash. Wave unchanged. Reduced motion: t=1 ⇒ identity transform for every style. `onWiggle` fires on completion regardless of style.
- App package import prefix is `migraine_forecast`.
- Run tests with `flutter test <path>`; full suite `flutter test`.
- Commit after every task. Work in the main repo at `/Users/amansur/projects/migraine-forecast` (NOT a worktree — user preference).

---

### Task 1: Pool offset, wiggle-style map, override providers

**Files:**
- Modify: `lib/state/mascot_pool.dart`
- Create: `lib/state/mascot_overrides.dart`
- Modify: `test/state/mascot_pool_test.dart`

**Interfaces:**
- Consumes: existing `kMascotPool`, `mascotAssetFor(RiskBand band, {DateTime? date})`.
- Produces (relied on by Tasks 2–4):
  - `String mascotAssetFor(RiskBand band, {DateTime? date, int offset = 0})`
  - `enum WiggleStyle { squish, flutter, stretch, bob }`
  - `WiggleStyle wiggleStyleFor(String assetPath)` — defaults to `WiggleStyle.squish` for unmapped names
  - In `mascot_overrides.dart`: `typedef MascotCycle = ({String dateKey, RiskBand band, int offset});`, `String mascotDateKey(DateTime d)`, `final mascotCycleProvider = StateProvider<MascotCycle?>`, `final debugBandOverrideProvider = StateProvider<RiskBand?>`

- [ ] **Step 1: Add failing tests**

Append to the existing `main()` in `test/state/mascot_pool_test.dart`:

```dart
  test('offset cycles within the band pool and wraps', () {
    final d = DateTime(2026, 7, 6);
    for (final band in RiskBand.values) {
      final pool = kMascotPool[band]!;
      final seen = <String>{
        for (var i = 0; i < pool.length; i++)
          mascotAssetFor(band, date: d, offset: i),
      };
      expect(seen.length, pool.length, reason: '$band: offsets must cover pool');
      expect(
        mascotAssetFor(band, date: d, offset: pool.length),
        mascotAssetFor(band, date: d),
        reason: '$band: offset == pool.length wraps to offset 0',
      );
    }
  });

  test('offset 0 matches the parameterless pick', () {
    final d = DateTime(2026, 7, 6);
    for (final band in RiskBand.values) {
      expect(mascotAssetFor(band, date: d, offset: 0),
          mascotAssetFor(band, date: d));
    }
  });

  test('wiggleStyleFor maps icons and defaults to squish', () {
    expect(wiggleStyleFor('assets/mascots/butterfly.png'), WiggleStyle.flutter);
    expect(wiggleStyleFor('assets/mascots/snail.png'), WiggleStyle.stretch);
    expect(wiggleStyleFor('assets/mascots/teacup.png'), WiggleStyle.bob);
    expect(wiggleStyleFor('assets/mascots/sun.png'), WiggleStyle.squish);
    expect(wiggleStyleFor('assets/mascots/unknown_thing.png'), WiggleStyle.squish);
  });

  test('every pooled icon resolves to a wiggle style without throwing', () {
    for (final p in allMascotAssetPaths()) {
      expect(() => wiggleStyleFor(p), returnsNormally);
    }
  });
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/state/mascot_pool_test.dart`
Expected: FAIL — `offset` named parameter and `wiggleStyleFor` undefined.

- [ ] **Step 3: Implement pool changes**

In `lib/state/mascot_pool.dart`, replace `mascotAssetFor` with:

```dart
/// Picks today's mascot for [band]: deterministic for a given local
/// calendar date + band, changes daily. Cadence is intentionally isolated
/// here — to change it (per-launch, manual shuffle), swap the seed.
/// [offset] advances within the pool (tap-to-cycle); 0 = the daily pick.
String mascotAssetFor(RiskBand band, {DateTime? date, int offset = 0}) {
  final d = date ?? DateTime.now();
  final pool = kMascotPool[band]!;
  assert(pool.isNotEmpty);
  final seed = d.year * 10000 + d.month * 100 + d.day + band.index * 31;
  return pool[(seed + offset) % pool.length];
}
```

And append at the end of the file:

```dart
/// How a mascot wiggles when tapped. All styles are one-shot transforms in
/// MascotWidget; the mapping lives here, next to the roster.
enum WiggleStyle { squish, flutter, stretch, bob }

/// Keyed by icon name (asset filename stem). Unmapped icons → squish.
const Map<String, WiggleStyle> kMascotWiggle = {
  'butterfly': WiggleStyle.flutter,
  'fish': WiggleStyle.flutter,
  'big_star': WiggleStyle.flutter,
  'snail': WiggleStyle.stretch,
  'sprout': WiggleStyle.stretch,
  'cat': WiggleStyle.stretch,
  'sleepy_cloud': WiggleStyle.bob,
  'raining_cloud': WiggleStyle.bob,
  'teacup': WiggleStyle.bob,
  // squish (default): sun, small_flower, berry_pot, notebook,
  // potted_plant, sad_flower
};

/// Resolves the wiggle style for a pooled asset path.
WiggleStyle wiggleStyleFor(String assetPath) {
  final stem = assetPath.split('/').last.replaceAll('.png', '');
  return kMascotWiggle[stem] ?? WiggleStyle.squish;
}
```

- [ ] **Step 4: Create `lib/state/mascot_overrides.dart`**

```dart
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A today-only manual mascot pick: tap-to-cycle state on the Today screen.
/// Applies only while [dateKey] is today's local date and [band] matches the
/// band being rendered; stale state is inert (treated as offset 0).
typedef MascotCycle = ({String dateKey, RiskBand band, int offset});

/// Local-date key used to expire the cycle at midnight.
String mascotDateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

/// In-memory only: resets on app restart. Null = daily seeded pick.
final mascotCycleProvider = StateProvider<MascotCycle?>((_) => null);

/// Debug-only presentation override for the displayed risk band.
/// Null = auto (real assessment). Never persisted; set from the Settings
/// Developer section, which is compiled out of release builds.
final debugBandOverrideProvider = StateProvider<RiskBand?>((_) => null);
```

- [ ] **Step 5: Run tests, analyze**

Run: `flutter test test/state/mascot_pool_test.dart` → PASS (10 tests).
Run: `flutter analyze` → no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/state/mascot_pool.dart lib/state/mascot_overrides.dart test/state/mascot_pool_test.dart
git commit -m "feat(mascot): pool offset, wiggle-style map, cycle/debug providers"
```

---

### Task 2: MascotWidget cycleOffset + per-style wiggle

**Files:**
- Modify: `lib/ui/shared/mascot/mascot_widget.dart`
- Modify: `test/ui/shared/mascot/mascot_widget_test.dart`

**Interfaces:**
- Consumes: `mascotAssetFor(band, {offset})`, `wiggleStyleFor`, `WiggleStyle` from Task 1.
- Produces (relied on by Task 3): `MascotWidget` gains `final int cycleOffset;` constructor param `this.cycleOffset = 0`. Everything else about the widget's public API is unchanged.

- [ ] **Step 1: Add failing tests**

Append to `main()` in `test/ui/shared/mascot/mascot_widget_test.dart` (the file already defines `Widget _host(Widget child)`):

```dart
  testWidgets('cycleOffset changes the rendered asset within the band pool',
      (tester) async {
    final pool = kMascotPool[RiskBand.moderate]!;
    final seen = <String>{};
    for (var i = 0; i < pool.length; i++) {
      await tester.pumpWidget(_host(
          MascotWidget(band: RiskBand.moderate, size: 80, cycleOffset: i)));
      await tester.pumpAndSettle();
      final img = tester.widget<Image>(find.byType(Image));
      final asset = (img.image as AssetImage).assetName;
      expect(pool, contains(asset));
      seen.add(asset);
    }
    expect(seen.length, pool.length,
        reason: 'each offset shows a different pool member');
  });

  testWidgets('every wiggle style plays to completion and fires onWiggle',
      (tester) async {
    // Sweep every band x offset: collectively covers all pooled icons and
    // therefore all four WiggleStyles.
    for (final band in RiskBand.values) {
      final pool = kMascotPool[band]!;
      for (var i = 0; i < pool.length; i++) {
        final controller = MascotController();
        var wiggled = false;
        await tester.pumpWidget(_host(MascotWidget(
          band: band,
          size: 80,
          cycleOffset: i,
          controller: controller,
          onWiggle: () => wiggled = true,
        )));
        controller.wiggle();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expect(tester.takeException(), isNull, reason: '$band offset $i');
        expect(wiggled, isTrue, reason: '$band offset $i');
        controller.dispose();
      }
    }
  });
```

Add the import at the top of the test file:

```dart
import 'package:migraine_forecast/state/mascot_pool.dart';
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/ui/shared/mascot/mascot_widget_test.dart`
Expected: FAIL — `cycleOffset` is not a parameter of `MascotWidget`.

- [ ] **Step 3: Implement in `mascot_widget.dart`**

3a. Add the field and constructor param to `MascotWidget`:

```dart
  final MascotIdle idle;
  /// Tap-to-cycle offset within the band pool; 0 = the daily seeded pick.
  final int cycleOffset;

  const MascotWidget({
    super.key,
    required this.band,
    this.size = 160,
    this.controller,
    this.onWiggle,
    this.idle = MascotIdle.float,
    this.cycleOffset = 0,
  });
```

3b. In `_MascotWidgetState`, add an asset/style getter and use it in `_playAction` (the stretch style runs longer):

```dart
  String get _assetPath =>
      mascotAssetFor(widget.band, offset: widget.cycleOffset);

  void _playAction(MascotAction action) {
    _activeAction = action;
    _action.duration = (action == MascotAction.wiggle &&
            wiggleStyleFor(_assetPath) == WiggleStyle.stretch)
        ? const Duration(milliseconds: 650)
        : const Duration(milliseconds: 500);
    _action
      ..reset()
      ..forward();
  }
```

3c. In `build`, replace the one-shot action math block (the lines from `final t = reduce ? 1.0 : _action.value;` through the closing brace of `if (playing) { ... }`) with:

```dart
    // One-shot action math (instant under reduced motion -> t jumps to 1).
    // pulse traces 0 -> 1 -> 0 over the action; every style resolves to the
    // identity transform at t = 0 and t = 1.
    final t = reduce ? 1.0 : _action.value;
    final pulse = 1 - (2 * t - 1).abs();
    double squish = 0; // horizontal squish (squish/bob styles)
    double stretch = 0; // vertical stretch (stretch style)
    double sway = 0; // wave: gentle rotation
    double flick = 0; // flutter: fast damped rotation
    double bobY = 0; // bob: downward dip in px
    final playing =
        _action.isAnimating || (!reduce && _action.value > 0 && _action.value < 1);
    if (playing) {
      switch (_activeAction) {
        case MascotAction.wiggle:
          switch (wiggleStyleFor(_assetPath)) {
            case WiggleStyle.squish:
              squish = 0.18 * pulse;
            case WiggleStyle.flutter:
              // ~3 oscillations of +/-4deg (0.07 rad), damped to zero.
              flick = math.sin(t * math.pi * 6) * 0.07 * (1 - t);
            case WiggleStyle.stretch:
              stretch = 0.15 * pulse;
            case WiggleStyle.bob:
              bobY = 6.0 * pulse;
              squish = 0.08 * pulse;
          }
        case MascotAction.wave:
          sway = pulse;
      }
    }

    final assetPath = _assetPath;
```

(Also delete the old standalone `final assetPath = mascotAssetFor(widget.band);` line — the block above now ends with the replacement.)

3d. In the `AnimatedBuilder` builder, update the transform lines:

```dart
        // Wave = gentle rotation (+/-5deg); flutter adds its own flicks.
        final rotation = sway * 0.0873 + flick;
        final netSquish = squish + idleSquish - stretch;
        final scaleX = breathe * (1 + netSquish * 0.5);
        final scaleY = breathe * (1 - netSquish * 0.5);

        return Transform.translate(
          offset: Offset(0, floatY + bobY),
```

(Only `rotation`, the `netSquish` lines replacing `totalSquish`, and the `Offset(0, floatY + bobY)` change; the rest of the builder is untouched.)

- [ ] **Step 4: Run the widget tests**

Run: `flutter test test/ui/shared/mascot/mascot_widget_test.dart`
Expected: PASS (6 tests). The 4 pre-existing tests must still pass — `cycleOffset` defaults to 0 and squish math is numerically identical to before.

- [ ] **Step 5: Commit**

```bash
git add lib/ui/shared/mascot/mascot_widget.dart test/ui/shared/mascot/mascot_widget_test.dart
git commit -m "feat(mascot): per-style wiggles and cycleOffset pass-through"
```

---

### Task 3: TodayScreen tap-to-cycle + debug band consumption

**Files:**
- Modify: `lib/ui/today/today_screen.dart`
- Modify: `test/ui/today/today_screen_mascot_test.dart`

**Interfaces:**
- Consumes: `mascotCycleProvider`, `debugBandOverrideProvider`, `mascotDateKey` from Task 1; `MascotWidget.cycleOffset` from Task 2.
- Produces: nothing new for later tasks (Task 4 only reads `debugBandOverrideProvider`).

- [ ] **Step 1: Add failing tests**

Append to `main()` in `test/ui/today/today_screen_mascot_test.dart`. The file already defines `_FakeNotifier`, `_FakeTomorrowNotifier`, and `_ass`; reuse its pump pattern:

```dart
  testWidgets('tapping the mascot cycles to another pool member of the same band',
      (tester) async {
    final today = _ass(RiskBand.moderate);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const TodayScreen()),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        riskAssessmentProvider.overrideWith(() => _FakeNotifier(today)),
        tomorrowRiskAssessmentProvider.overrideWith(() => _FakeTomorrowNotifier(_ass(RiskBand.low))),
      ],
      child: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp.router(routerConfig: router),
      ),
    ));
    await tester.pump();

    String asset() {
      final img = tester.widget<Image>(find.descendant(
          of: find.byType(MascotWidget), matching: find.byType(Image)));
      return (img.image as AssetImage).assetName;
    }

    final pool = kMascotPool[RiskBand.moderate]!;
    final first = asset();
    expect(pool, contains(first));

    await tester.tap(find.byKey(const Key('mascot-tap-target')));
    await tester.pumpAndSettle();
    final second = asset();
    expect(pool, contains(second));
    expect(second, isNot(first), reason: 'tap advances within the pool');

    await tester.tap(find.byKey(const Key('mascot-tap-target')));
    await tester.pumpAndSettle();
    expect(asset(), isNot(second), reason: 'second tap advances again');
  });

  testWidgets('debug band override changes the mascot band', (tester) async {
    final today = _ass(RiskBand.low);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const TodayScreen()),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        riskAssessmentProvider.overrideWith(() => _FakeNotifier(today)),
        tomorrowRiskAssessmentProvider.overrideWith(() => _FakeTomorrowNotifier(_ass(RiskBand.low))),
        debugBandOverrideProvider.overrideWith((_) => RiskBand.veryHigh),
      ],
      child: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp.router(routerConfig: router),
      ),
    ));
    await tester.pump();

    final mascot = tester.widget<MascotWidget>(find.byType(MascotWidget));
    expect(mascot.band, RiskBand.veryHigh);
  });
```

Add imports at the top of the test file:

```dart
import 'package:migraine_forecast/state/mascot_overrides.dart';
import 'package:migraine_forecast/state/mascot_pool.dart';
```

Note: the moderate pool has 6 members, so two consecutive taps always land on distinct assets — the `isNot` assertions are deterministic regardless of the seeded start.

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/ui/today/today_screen_mascot_test.dart`
Expected: FAIL — tap does not change the asset; `debugBandOverrideProvider` unused by the screen (band stays `low`).

- [ ] **Step 3: Implement in `today_screen.dart`**

3a. Add the import:

```dart
import '../../state/mascot_overrides.dart';
```

3b. In `build`, where the assessment `a` is available (inside the data branch, before the widget tree that uses `a.band`), compute the effective band and offset:

```dart
    final debugBand = ref.watch(debugBandOverrideProvider);
    final band = debugBand ?? a.band;
    final cycle = ref.watch(mascotCycleProvider);
    final todayKey = mascotDateKey(DateTime.now());
    final cycleOffset =
        (cycle != null && cycle.dateKey == todayKey && cycle.band == band)
            ? cycle.offset
            : 0;
```

3c. Replace the mascot `InkWell` `onTap` and `MascotWidget` (currently `onTap: () => _mascot.wiggle(),` / `band: a.band,`):

```dart
                                  onTap: () {
                                    final prev = ref.read(mascotCycleProvider);
                                    final key = mascotDateKey(DateTime.now());
                                    final next = (prev != null &&
                                            prev.dateKey == key &&
                                            prev.band == band)
                                        ? prev.offset + 1
                                        : 1;
                                    ref.read(mascotCycleProvider.notifier).state =
                                        (dateKey: key, band: band, offset: next);
                                    _mascot.wiggle();
                                  },
                                  child: MascotWidget(
                                    band: band,
                                    size: 84,
                                    controller: _mascot,
                                    idle: MascotIdle.hop,
                                    cycleOffset: cycleOffset,
                                  ),
```

Also update the comment above from "Tap for a wiggle." to "Tap to cycle today's mascot (with a wiggle)."

- [ ] **Step 4: Run the tests**

Run: `flutter test test/ui/today/today_screen_mascot_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/ui/today/today_screen.dart test/ui/today/today_screen_mascot_test.dart
git commit -m "feat(mascot): tap-to-cycle today's mascot; debug band consumption"
```

---

### Task 4: Settings Developer section + full suite

**Files:**
- Modify: `lib/ui/settings/settings_screen.dart`
- Create: `test/ui/settings/debug_band_override_test.dart`

**Interfaces:**
- Consumes: `debugBandOverrideProvider` from Task 1.
- Produces: Settings row `Key('debug-band-override-row')`, visible only when `kDebugMode`.

- [ ] **Step 1: Write the failing test**

Create `test/ui/settings/debug_band_override_test.dart`. First read `test/ui/settings/dark_palette_picker_test.dart` and copy its provider-override scaffold for pumping `SettingsScreen` (it already fakes the settings/repo providers this screen needs); inside that scaffold the test bodies are:

```dart
  testWidgets('Developer section shows the band override row in debug mode',
      (tester) async {
    // flutter test runs in debug mode, so kDebugMode is true here.
    await pumpSettings(tester); // the scaffold helper adapted from dark_palette_picker_test
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
        find.byKey(const Key('debug-band-override-row')), 300);
    expect(find.byKey(const Key('debug-band-override-row')), findsOneWidget);
    expect(find.text('Developer'), findsOneWidget);
  });

  testWidgets('selecting a band writes the override; Auto clears it',
      (tester) async {
    late ProviderContainer container;
    await pumpSettings(tester, onContainer: (c) => container = c);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
        find.byKey(const Key('debug-band-override-row')), 300);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Very High'));
    await tester.pumpAndSettle();
    expect(container.read(debugBandOverrideProvider), RiskBand.veryHigh);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Auto'));
    await tester.pumpAndSettle();
    expect(container.read(debugBandOverrideProvider), isNull);
  });
```

Expose the container from the scaffold via `ProviderScope`'s key or by constructing `ProviderContainer`/`UncontrolledProviderScope` — follow whichever pattern `dark_palette_picker_test.dart` uses; if it uses a plain `ProviderScope`, obtain the container with:

```dart
final container = ProviderScope.containerOf(
    tester.element(find.byType(SettingsScreen)));
```

(and drop the `onContainer` parameter idea — read it after pumping instead).

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/ui/settings/debug_band_override_test.dart`
Expected: FAIL — `debug-band-override-row` not found.

- [ ] **Step 3: Implement in `settings_screen.dart`**

Add imports:

```dart
import 'package:flutter/foundation.dart' show kDebugMode;
import '../../state/mascot_overrides.dart';
```

(If `package:domain/domain.dart` is not already imported for `RiskBand`, add it.)

At the end of the main `ListView` children (after the Danger Zone section's last entry), append:

```dart
          if (kDebugMode) ...[
            const Divider(),
            Text('Developer', style: Theme.of(context).textTheme.titleSmall),
            ListTile(
              key: const Key('debug-band-override-row'),
              title: const Text('Risk band override'),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(
                      label: const Text('Auto'),
                      selected: ref.watch(debugBandOverrideProvider) == null,
                      onSelected: (_) => ref
                          .read(debugBandOverrideProvider.notifier)
                          .state = null,
                    ),
                    for (final b in RiskBand.values)
                      ChoiceChip(
                        label: Text(_bandLabel(b)),
                        selected: ref.watch(debugBandOverrideProvider) == b,
                        onSelected: (_) => ref
                            .read(debugBandOverrideProvider.notifier)
                            .state = b,
                      ),
                  ],
                ),
              ),
            ),
          ],
```

And add the label helper to the same class as the other private helpers:

```dart
  String _bandLabel(RiskBand b) => switch (b) {
        RiskBand.low => 'Low',
        RiskBand.moderate => 'Moderate',
        RiskBand.high => 'High',
        RiskBand.veryHigh => 'Very High',
      };
```

(The screen is a `ConsumerStatefulWidget`, so `ref` is available directly in `build`; no extra `Consumer` needed.)

- [ ] **Step 4: Run the new test**

Run: `flutter test test/ui/settings/debug_band_override_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Full suite + analyze**

Run: `flutter test` → ALL PASS (305+ tests, 4 pre-existing skips).
Run: `flutter analyze` → no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/ui/settings/settings_screen.dart test/ui/settings/debug_band_override_test.dart
git commit -m "feat(settings): debug-only risk band override section"
```

- [ ] **Step 7: Manual review handoff**

Tell the user: tap the Today mascot to cycle today's mascot within the band (resets tomorrow/restart); in a debug build, Settings → Developer → Risk band override switches the displayed band to test each band's mascots and wiggle styles (flutter/stretch/bob/squish per icon).

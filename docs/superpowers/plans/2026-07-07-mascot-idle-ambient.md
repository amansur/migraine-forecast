# Mascot Per-Icon Idle Styles + Ambient Wiggles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Each mascot idles with its own personality style, and occasionally wiggles on its own (ambient) at 60 % tap amplitude.

**Architecture:** A new `MascotIdleStyle` enum + name-keyed map lives in `lib/state/mascot_pool.dart` (mirroring `WiggleStyle`/`kMascotWiggle`). `MascotWidget` derives the idle style from the displayed asset each build and renders per-style motion in the existing `_idle` AnimationController's builder; the old host-chosen `MascotIdle` enum/param is deleted. A randomized 6–12 s `Timer` in `_MascotWidgetState` fires the mascot's own wiggle via the existing one-shot path with a 0.6 amplitude factor.

**Tech Stack:** Flutter, flutter_test. No new dependencies.

**Spec:** `docs/superpowers/specs/2026-07-07-mascot-idle-ambient-design.md`

## Global Constraints

- All idle styles resolve to identity under reduced motion (`MediaQuery.disableAnimations`).
- Idle motion is multiplied by the existing `idleMute` (`1 - pulse`) while a one-shot action plays.
- Ambient wiggles never call `onWiggle` and never call `controller.ackConsumed()`.
- Ambient amplitude factor is exactly 0.6, applied to the wiggle style constants.
- Work in `/Users/amansur/projects/migraine-forecast` on branch `main` (NOT a worktree).
- Run `flutter analyze` before every commit; no new warnings/errors (19 pre-existing infos are OK).
- Commit after every task.

---

### Task 1: `MascotIdleStyle` enum, mapping, and resolver in mascot_pool

**Files:**
- Modify: `lib/state/mascot_pool.dart` (append at end of file)
- Test: `test/state/mascot_pool_test.dart` (append a new group)

**Interfaces:**
- Consumes: nothing new.
- Produces: `enum MascotIdleStyle { hover, drift, sway, still, bounce }`, `const Map<String, MascotIdleStyle> kMascotIdle`, and `MascotIdleStyle idleStyleFor(String assetPath)` — Task 2 imports all three from `package:migraine_forecast/state/mascot_pool.dart`.

- [ ] **Step 1: Write the failing tests**

Append inside `main()` in `test/state/mascot_pool_test.dart`:

```dart
  group('idle styles', () {
    test('idleStyleFor maps known icons', () {
      expect(idleStyleFor('assets/mascots/butterfly.png'), MascotIdleStyle.hover);
      expect(idleStyleFor('assets/mascots/big_star.png'), MascotIdleStyle.hover);
      expect(idleStyleFor('assets/mascots/sleepy_cloud.png'), MascotIdleStyle.drift);
      expect(idleStyleFor('assets/mascots/raining_cloud.png'), MascotIdleStyle.drift);
      expect(idleStyleFor('assets/mascots/small_flower.png'), MascotIdleStyle.sway);
      expect(idleStyleFor('assets/mascots/sad_flower.png'), MascotIdleStyle.sway);
      expect(idleStyleFor('assets/mascots/sprout.png'), MascotIdleStyle.sway);
      expect(idleStyleFor('assets/mascots/potted_plant.png'), MascotIdleStyle.sway);
      expect(idleStyleFor('assets/mascots/berry_pot.png'), MascotIdleStyle.sway);
      expect(idleStyleFor('assets/mascots/snail.png'), MascotIdleStyle.still);
      expect(idleStyleFor('assets/mascots/teacup.png'), MascotIdleStyle.still);
    });

    test('unmapped icons default to bounce', () {
      expect(idleStyleFor('assets/mascots/sun.png'), MascotIdleStyle.bounce);
      expect(idleStyleFor('assets/mascots/fish.png'), MascotIdleStyle.bounce);
      expect(idleStyleFor('assets/mascots/cat.png'), MascotIdleStyle.bounce);
      expect(idleStyleFor('assets/mascots/notebook.png'), MascotIdleStyle.bounce);
    });

    test('every pooled asset resolves to some idle style', () {
      for (final path in allMascotAssetPaths()) {
        expect(() => idleStyleFor(path), returnsNormally, reason: path);
      }
    });
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/state/mascot_pool_test.dart`
Expected: compile error — `MascotIdleStyle`/`idleStyleFor` undefined.

- [ ] **Step 3: Write the implementation**

Append at the end of `lib/state/mascot_pool.dart`:

```dart
/// How a mascot idles when nothing else is happening. Motion math lives in
/// MascotWidget; the mapping lives here, next to the roster.
enum MascotIdleStyle { hover, drift, sway, still, bounce }

/// Keyed by icon name (asset filename stem). Unmapped icons → bounce.
const Map<String, MascotIdleStyle> kMascotIdle = {
  'butterfly': MascotIdleStyle.hover,
  'big_star': MascotIdleStyle.hover,
  'sleepy_cloud': MascotIdleStyle.drift,
  'raining_cloud': MascotIdleStyle.drift,
  'small_flower': MascotIdleStyle.sway,
  'sad_flower': MascotIdleStyle.sway,
  'sprout': MascotIdleStyle.sway,
  'potted_plant': MascotIdleStyle.sway,
  'berry_pot': MascotIdleStyle.sway,
  'snail': MascotIdleStyle.still,
  'teacup': MascotIdleStyle.still,
  // bounce (default): sun, fish, cat, notebook
};

/// Resolves the idle style for a pooled asset path.
MascotIdleStyle idleStyleFor(String assetPath) {
  final stem = assetPath.split('/').last.replaceAll('.png', '');
  return kMascotIdle[stem] ?? MascotIdleStyle.bounce;
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/state/mascot_pool_test.dart`
Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/state/mascot_pool.dart test/state/mascot_pool_test.dart
git commit -m "feat(mascot): MascotIdleStyle enum and per-icon idle mapping"
```

---

### Task 2: Per-style idle motion in MascotWidget; delete MascotIdle

**Files:**
- Modify: `lib/ui/shared/mascot/mascot_widget.dart`
- Modify: `lib/ui/today/today_screen.dart` (remove one line, ~line 188)
- Test: `test/ui/shared/mascot/mascot_widget_test.dart` (append a group)

**Interfaces:**
- Consumes: `MascotIdleStyle`, `idleStyleFor(String)` from Task 1.
- Produces: `MascotWidget` no longer has an `idle:` parameter; the `MascotIdle` enum no longer exists. Idle motion is fully derived from the displayed asset. Task 3 builds on this file unchanged in shape (same `_playAction`, `build`).

- [ ] **Step 1: Write the failing tests**

Append inside `main()` in `test/ui/shared/mascot/mascot_widget_test.dart`. The tests read the accumulated transform of the mascot subtree by walking `Transform` ancestors of the `Image` and multiplying their matrices, then compare against identity. `_bandOffsetFor` pins a specific icon by asset name so each style is exercised deterministically.

```dart
  /// Finds band+offset that displays [stem] today (pools are date-seeded).
  (RiskBand, int) _bandOffsetFor(String stem) {
    for (final band in RiskBand.values) {
      final pool = kMascotPool[band]!;
      for (var i = 0; i < pool.length; i++) {
        if (mascotAssetFor(band, offset: i) == 'assets/mascots/$stem.png') {
          return (band, i);
        }
      }
    }
    fail('no band/offset shows $stem');
  }

  Matrix4 _netTransform(WidgetTester tester) {
    var m = Matrix4.identity();
    final imageEl = tester.element(find.byType(Image));
    imageEl.visitAncestorElements((el) {
      final w = el.widget;
      if (w is Transform) m = w.transform.clone()..multiply(m);
      return w is! MascotWidget;
    });
    return m;
  }

  group('per-mascot idle styles', () {
    Future<void> pumpMascot(WidgetTester tester, String stem,
        {bool reduce = false}) async {
      final (band, offset) = _bandOffsetFor(stem);
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduce),
          child: Scaffold(
            body: Center(
              child: MascotWidget(band: band, size: 80, cycleOffset: offset),
            ),
          ),
        ),
      ));
      await tester.pump();
      // Mid idle phase (idle period is 2600 ms).
      await tester.pump(const Duration(milliseconds: 1300));
    }

    testWidgets('hover translates the mascot', (tester) async {
      await pumpMascot(tester, 'butterfly');
      final m = _netTransform(tester);
      expect(m.getTranslation().length, greaterThan(0.5));
    });

    testWidgets('drift translates the mascot horizontally', (tester) async {
      await pumpMascot(tester, 'sleepy_cloud');
      final m = _netTransform(tester);
      expect(m.getTranslation().x.abs() + m.getTranslation().y.abs(),
          greaterThan(0.5));
    });

    testWidgets('sway rotates the mascot', (tester) async {
      await pumpMascot(tester, 'sprout');
      final m = _netTransform(tester);
      // Rotation shows up as a nonzero off-diagonal term.
      expect(m.entry(0, 1).abs() + m.entry(1, 0).abs(), greaterThan(0.001));
    });

    testWidgets('still does not translate or rotate', (tester) async {
      await pumpMascot(tester, 'snail');
      final m = _netTransform(tester);
      expect(m.getTranslation().length, lessThan(0.01));
      expect(m.entry(0, 1).abs() + m.entry(1, 0).abs(), lessThan(0.0001));
    });

    testWidgets('bounce translates the mascot vertically', (tester) async {
      await pumpMascot(tester, 'cat');
      final m = _netTransform(tester);
      expect(m.getTranslation().y.abs(), greaterThan(0.5));
    });

    testWidgets('reduced motion: idle is identity for every style',
        (tester) async {
      for (final stem in ['butterfly', 'sleepy_cloud', 'sprout', 'snail', 'cat']) {
        await pumpMascot(tester, stem, reduce: true);
        final m = _netTransform(tester);
        expect(m.isIdentity(), isTrue, reason: stem);
      }
    });
  });
```

Also add to the imports if missing: `import 'package:migraine_forecast/state/mascot_pool.dart';` (already present) — `Matrix4` comes via `package:flutter/material.dart` (already imported).

- [ ] **Step 2: Run tests to verify the new group fails**

Run: `flutter test test/ui/shared/mascot/mascot_widget_test.dart`
Expected: new tests FAIL (e.g. `still` currently floats; `sway` never rotates; `reduce` case may pass — fine). If any unexpected compile error, fix the test code, not the widget.

- [ ] **Step 3: Implement per-style idle in the widget**

In `lib/ui/shared/mascot/mascot_widget.dart`:

3a. Delete the `MascotIdle` enum (lines 10–13) and the `idle` field + constructor param (`final MascotIdle idle;` and `this.idle = MascotIdle.float,`).

3b. Replace the idle-motion block inside the `AnimatedBuilder` builder. Current code (from `final phase = ...` through the `breathe` line) becomes:

```dart
        final phase = reduce ? 0.0 : _idle.value;
        final idleStyle = idleStyleFor(assetPath);
        double floatY = 0;
        double idleDx = 0;
        double idleSquish = 0;
        double idleRot = 0;
        // Mute idle motion while an action is playing so the action reads
        // clearly. pulse is 0 at action start/end → no jump at boundaries.
        final idleMute = playing ? (1.0 - pulse) : 1.0;
        if (!reduce) {
          switch (idleStyle) {
            case MascotIdleStyle.hover:
              // Airborne: constant lift + bob, with a lateral figure-8.
              floatY = (-4.0 - 4.0 * math.sin(phase * math.pi)) * idleMute;
              idleDx = 3.0 * math.sin(phase * math.pi * 2) * idleMute;
            case MascotIdleStyle.drift:
              idleDx = (-6.0 + 12.0 * phase) * idleMute;
              floatY = -2.0 * math.sin(phase * math.pi) * idleMute;
            case MascotIdleStyle.sway:
              idleRot = (-1.0 + 2.0 * phase) * 0.035 * idleMute;
            case MascotIdleStyle.still:
              break;
            case MascotIdleStyle.bounce:
              // sin(phase*pi) traces a single 0->1->0 arc per half-cycle:
              // a leap up and a landing, squashing a touch near the ground.
              final hop = math.sin(phase * math.pi);
              floatY = -10.0 * hop * idleMute;
              idleSquish = 0.06 * (1 - hop) * idleMute;
          }
        }
        final breathe = reduce ? 1.0 : (1.0 + 0.015 * (phase - 0.5).abs() * 2);
```

3c. Update the transform stack: translation gains `idleDx`, and sway gets its own bottom-center rotation wrapper (actions keep the center-aligned rotate):

```dart
        return Transform.translate(
          offset: Offset(idleDx, floatY + bobY),
          child: Transform.rotate(
            angle: idleRot,
            alignment: Alignment.bottomCenter,
            child: Transform.rotate(
              angle: rotation,
              child: Transform(
                // ... unchanged inner subtree ...
```

(Close the extra widget: the inner subtree down to `AnimatedSwitcher` is unchanged; add one closing paren for the new `Transform.rotate`.)

3d. In `lib/ui/today/today_screen.dart`, delete the line `idle: MascotIdle.hop,` (~line 188). No other hosts pass `idle:`.

3e. Remove the now-unused `MascotIdle` references anywhere else (there are none besides the two above; verify with `grep -rn "MascotIdle\b" lib test`).

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/ui/shared/mascot/mascot_widget_test.dart test/state/mascot_pool_test.dart test/ui/today/today_screen_mascot_test.dart`
Expected: all PASS (old idle-agnostic tests keep passing).

- [ ] **Step 5: Run analyze + full suite**

Run: `flutter analyze` (no new issues beyond the 19 pre-existing infos) and `flutter test`
Expected: 0 failures (4 pre-existing skips OK).

- [ ] **Step 6: Commit**

```bash
git add lib/ui/shared/mascot/mascot_widget.dart lib/ui/today/today_screen.dart test/ui/shared/mascot/mascot_widget_test.dart
git commit -m "feat(mascot): per-icon idle styles replace shared float/hop idle"
```

---

### Task 3: Ambient wiggle timer

**Files:**
- Modify: `lib/ui/shared/mascot/mascot_widget.dart`
- Test: `test/ui/shared/mascot/mascot_widget_test.dart` (append a group)

**Interfaces:**
- Consumes: `_playAction`, `_action`, lifecycle observer from Task 2's file state; `wiggleStyleFor` (existing).
- Produces: `@visibleForTesting static Duration? MascotWidget.debugAmbientInterval` — a fixed override for the random 6–12 s interval, used only by tests. Ambient wiggles at 0.6 amplitude, no `onWiggle`, no `ackConsumed`.

- [ ] **Step 1: Write the failing tests**

Append inside `main()` in `test/ui/shared/mascot/mascot_widget_test.dart`:

```dart
  group('ambient wiggle', () {
    tearDown(() => MascotWidget.debugAmbientInterval = null);

    testWidgets('fires after the interval and does not call onWiggle',
        (tester) async {
      MascotWidget.debugAmbientInterval = const Duration(milliseconds: 100);
      var wiggled = false;
      await tester.pumpWidget(_host(MascotWidget(
        band: RiskBand.low,
        size: 80,
        onWiggle: () => wiggled = true,
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150)); // timer fires
      await tester.pump(const Duration(milliseconds: 250)); // mid-action
      // The action controller is animating: net transform differs from the
      // pure-idle transform channel (one-shot styles add squish/rotation),
      // and crucially onWiggle stays false for ambient wiggles.
      expect(wiggled, isFalse);
      await tester.pump(const Duration(milliseconds: 800)); // completes
      expect(wiggled, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox()); // dispose cancels the timer
    });

    testWidgets('suppressed under reduced motion', (tester) async {
      MascotWidget.debugAmbientInterval = const Duration(milliseconds: 100);
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Center(child: MascotWidget(band: RiskBand.low, size: 80)),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.takeException(), isNull);
      // Under reduced motion nothing may move: identity transform.
      final m = _netTransform(tester);
      expect(m.isIdentity(), isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('does not restart an in-flight tap wiggle', (tester) async {
      MascotWidget.debugAmbientInterval = const Duration(milliseconds: 200);
      final controller = MascotController();
      var wiggles = 0;
      await tester.pumpWidget(_host(MascotWidget(
        band: RiskBand.low,
        size: 80,
        controller: controller,
        onWiggle: () => wiggles++,
      )));
      await tester.pump();
      controller.wiggle(); // tap wiggle also reschedules the ambient timer
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250)); // ambient due mid-flight
      await tester.pump(const Duration(milliseconds: 800));
      expect(wiggles, 1, reason: 'tap wiggle completed exactly once');
      expect(tester.takeException(), isNull);
      controller.dispose();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('timer is cancelled on dispose (no pending-timer failure)',
        (tester) async {
      MascotWidget.debugAmbientInterval = const Duration(seconds: 30);
      await tester.pumpWidget(_host(MascotWidget(band: RiskBand.low, size: 80)));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      // flutter_test fails the test automatically if a Timer is left pending.
    });
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/ui/shared/mascot/mascot_widget_test.dart`
Expected: compile error — `debugAmbientInterval` undefined.

- [ ] **Step 3: Implement the ambient timer**

In `lib/ui/shared/mascot/mascot_widget.dart`:

3a. Add imports at the top: `import 'dart:async';` and to the foundation import add `visibleForTesting` (or `import 'package:flutter/foundation.dart' show visibleForTesting;`).

3b. On `MascotWidget` (the widget class), add:

```dart
  /// Test-only override for the ambient wiggle interval (normally random
  /// 6–12 s). Null in production.
  @visibleForTesting
  static Duration? debugAmbientInterval;
```

3c. In `_MascotWidgetState`, add fields:

```dart
  Timer? _ambient;
  final math.Random _rand = math.Random();
  bool _resumed = true;
  // 1.0 for tap/host actions, 0.6 for ambient wiggles.
  double _actionAmplitude = 1.0;
  bool _ambientInFlight = false;
```

3d. Scheduling + firing:

```dart
  void _scheduleAmbient() {
    _ambient?.cancel();
    final interval = MascotWidget.debugAmbientInterval ??
        Duration(milliseconds: 6000 + _rand.nextInt(6000));
    _ambient = Timer(interval, _onAmbientTimer);
  }

  void _onAmbientTimer() {
    if (!mounted) return;
    final reduce = MediaQuery.of(context).disableAnimations;
    if (!reduce && _resumed && !_action.isAnimating) {
      _playAction(MascotAction.wiggle, ambient: true);
    }
    _scheduleAmbient();
  }
```

3e. Change `_playAction` signature and body:

```dart
  void _playAction(MascotAction action, {bool ambient = false}) {
    _activeAction = action;
    _ambientInFlight = ambient;
    _actionAmplitude = ambient ? 0.6 : 1.0;
    // A user/host action resets the ambient clock so they don't stack.
    if (!ambient) _scheduleAmbient();
    // Resolve the style once here so the in-flight animation is pinned to the
    // mascot that was showing when the action started.
    _activeStyle = (action == MascotAction.wiggle)
        ? wiggleStyleFor(_assetPath)
        : WiggleStyle.squish;
    _action.duration = (_activeStyle == WiggleStyle.stretch)
        ? const Duration(milliseconds: 700)
        : const Duration(milliseconds: 500);
    _action
      ..reset()
      ..forward();
  }
```

3f. In the `_action` status listener, guard callbacks:

```dart
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_ambientInFlight) {
          if (_activeAction == MascotAction.wiggle) widget.onWiggle?.call();
          widget.controller?.ackConsumed();
        }
      });
```

3g. In `initState`, after `_idle.repeat(reverse: true);` add `_scheduleAmbient();`.

3h. In `didChangeAppLifecycleState`:

```dart
    if (state == AppLifecycleState.resumed) {
      _resumed = true;
      if (!_idle.isAnimating) _idle.repeat(reverse: true);
      _scheduleAmbient();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _resumed = false;
      _idle.stop();
      _ambient?.cancel();
    }
```

3i. In `dispose`, before `_idle.dispose();` add `_ambient?.cancel();`.

3j. Apply the amplitude factor in `build`'s action switch (multiply each constant by `_actionAmplitude`):

```dart
        case MascotAction.wiggle:
          switch (_activeStyle) {
            case WiggleStyle.squish:
              squish = 0.22 * _actionAmplitude * pulse;
            case WiggleStyle.flutter:
              // ~3 oscillations of ±12° (0.21 rad), damped to zero.
              flick = math.sin(t * math.pi * 6) * 0.21 * _actionAmplitude * (1 - t);
            case WiggleStyle.stretch:
              stretch = 0.30 * _actionAmplitude * pulse;
            case WiggleStyle.bob:
              bobY = 14.0 * _actionAmplitude * pulse;
              squish = 0.12 * _actionAmplitude * pulse;
          }
        case MascotAction.wave:
          sway = pulse;
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/ui/shared/mascot/mascot_widget_test.dart`
Expected: all PASS, including the pre-existing groups (their pumps stay under the 6 s minimum random interval, and end-of-test disposal cancels the timer).

- [ ] **Step 5: Run analyze + full suite**

Run: `flutter analyze` (no new issues) and `flutter test`
Expected: 0 failures. If an unrelated test now trips on a pending ambient timer (long-pumping tests that keep a mascot mounted), fix by pumping past disposal (`await tester.pumpWidget(const SizedBox())`) in that test — do not weaken the widget's cancellation logic.

- [ ] **Step 6: Commit**

```bash
git add lib/ui/shared/mascot/mascot_widget.dart test/ui/shared/mascot/mascot_widget_test.dart
git commit -m "feat(mascot): ambient wiggles every 6-12s at 60% amplitude"
```

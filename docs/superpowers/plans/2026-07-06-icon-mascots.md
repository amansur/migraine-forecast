# Icon-Based Random Mascots Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the 4-character SVG mascot system with a pool of hand-drawn PNG icons (sliced from `assets/icons.png`), picked randomly per risk band, stable per day.

**Architecture:** A slicing script produces transparent PNGs in `assets/mascots/`. A new `lib/state/mascot_pool.dart` maps each `RiskBand` to a list of asset paths and picks one seeded by `(local date, band)`. `MascotWidget` loses its `character` param and face-overlay/blink system, rendering `Image.asset` with the existing float/hop/wiggle/wave transforms. The character picker, providers, and SVG machinery are deleted.

**Tech Stack:** Flutter, Riverpod, Python 3 + Pillow (slicing only, dev-time), ImageMagick available if needed.

**Spec:** `docs/superpowers/specs/2026-07-06-icon-mascots-design.md`

## Global Constraints

- Icon → band baseline mapping (executor finalizes after visually inspecting slices; icons may repeat across bands):
  - low: sun, berry_pot, big_star, butterfly, fish
  - moderate: potted_plant, teacup, notebook, small_flower, snail, cat
  - high: sad_flower, sleepy_cloud, sprout
  - veryHigh: raining_cloud, sleepy_cloud, sad_flower
- Random pick must be deterministic for a given `(local calendar date, band)`. Keep seed logic in one function (cadence may change later — user flagged).
- Keep idle animations (float/hop) and wiggle/wave. Remove blink and all face-overlay painting.
- Run tests with `flutter test <path>`; full suite is `flutter test`.
- Commit after every task. Work in the main repo at `/Users/amansur/projects/migraine-forecast` (NOT a worktree — user preference).

---

### Task 1: Slice sprite sheet into transparent PNGs

**Files:**
- Create: `tool/slice_mascots.py`
- Create: `assets/mascots/<name>.png` (~15 files)
- Delete: `assets/mascots/*_low.svg` etc. (all 16 SVGs) — do this in this task; the app won't compile against them again after Task 3, and `pubspec.yaml` already registers the whole `assets/mascots/` directory so no pubspec change is needed here.

**Interfaces:**
- Produces: PNG files at `assets/mascots/{sun,berry_pot,big_star,butterfly,fish,potted_plant,teacup,notebook,small_flower,snail,cat,sad_flower,sleepy_cloud,sprout,raining_cloud}.png`, transparent background, each tightly cropped with ~6% padding. Later tasks hard-code these exact names.

- [ ] **Step 1: Write the slicing script**

`assets/icons.png` is 2048×2048, blue art on black. **The icons themselves contain black outlines and facial features that are the same color as the background**, so a global brightness threshold would erase the linework (verified experimentally on the sun icon). Background is instead identified by flood-fill: BFS from the image border over dark pixels — dark pixels *enclosed by* an icon (outlines, eyes, mouths) are unreachable from the border and stay opaque. Components are found by connected labeling, then boxes within `GAP` px are merged (teacup+steam, notebook+pencil, berry pot+berries must merge; big star must NOT merge with the small stars — tune `GAP` if the montage in Step 3 looks wrong).

```python
#!/usr/bin/env python3
"""Slice assets/icons.png into individual transparent-PNG mascots."""
from PIL import Image
import numpy as np
import os
from collections import deque

SRC = "assets/icons.png"
OUT = "assets/mascots"
THRESH = 40      # brightness below this = "dark" (candidate background)
GAP = 36         # merge boxes closer than this many px (at full res)
PAD = 0.06       # padding around each crop, fraction of box size
MIN_AREA = 3000  # drop specks/sparkles smaller than this (px^2)

im = Image.open(SRC).convert("RGB")
a = np.asarray(im).astype(int)
bright = a.max(axis=2)
dark = bright <= THRESH
H, W = dark.shape

# Background = dark pixels reachable from the border (flood fill).
# Dark pixels enclosed by an icon (outlines, eyes) are NOT background.
bg = np.zeros_like(dark)
q = deque()
for x in range(W):
    for y in (0, H - 1):
        if dark[y, x] and not bg[y, x]:
            bg[y, x] = True; q.append((y, x))
for y in range(H):
    for x in (0, W - 1):
        if dark[y, x] and not bg[y, x]:
            bg[y, x] = True; q.append((y, x))
while q:
    y, x = q.popleft()
    for ny, nx in ((y-1,x),(y+1,x),(y,x-1),(y,x+1)):
        if 0 <= ny < H and 0 <= nx < W and dark[ny, nx] and not bg[ny, nx]:
            bg[ny, nx] = True
            q.append((ny, nx))

mask = ~bg  # icon pixels (including their black linework)
alpha = np.where(bg, 0, 255).astype(np.uint8)
rgba = np.dstack([a.astype(np.uint8), alpha])

# connected components (4-neighbour) on the mask, iterative flood fill
lbl = np.zeros(mask.shape, dtype=int)
cur = 0
boxes = []
H, W = mask.shape
for y0 in range(H):
    for x0 in range(W):
        if mask[y0, x0] and lbl[y0, x0] == 0:
            cur += 1
            stack = [(y0, x0)]
            lbl[y0, x0] = cur
            ys, xs = [y0], [x0]
            while stack:
                y, x = stack.pop()
                for ny, nx in ((y-1,x),(y+1,x),(y,x-1),(y,x+1)):
                    if 0 <= ny < H and 0 <= nx < W and mask[ny, nx] and lbl[ny, nx] == 0:
                        lbl[ny, nx] = cur
                        ys.append(ny); xs.append(nx)
                        stack.append((ny, nx))
            boxes.append([min(xs), min(ys), max(xs), max(ys)])

def close(b1, b2):
    dx = max(b1[0] - b2[2], b2[0] - b1[2], 0)
    dy = max(b1[1] - b2[3], b2[1] - b1[3], 0)
    return dx < GAP and dy < GAP

merged = True
while merged:
    merged = False
    out = []
    while boxes:
        b = boxes.pop()
        for o in out:
            if close(b, o):
                o[0] = min(o[0], b[0]); o[1] = min(o[1], b[1])
                o[2] = max(o[2], b[2]); o[3] = max(o[3], b[3])
                merged = True
                break
        else:
            out.append(b)
    boxes = out

boxes = [b for b in boxes if (b[2]-b[0])*(b[3]-b[1]) >= MIN_AREA]
boxes.sort(key=lambda b: (b[1] // 300, b[0]))  # rough reading order

os.makedirs(OUT, exist_ok=True)
for i, (x1, y1, x2, y2) in enumerate(boxes):
    pw = int((x2-x1) * PAD); ph = int((y2-y1) * PAD)
    crop = rgba[max(0,y1-ph):min(H,y2+ph), max(0,x1-pw):min(W,x2+pw)]
    Image.fromarray(crop, "RGBA").save(f"{OUT}/slice_{i:02d}.png")
    print(f"slice_{i:02d}.png  box=({x1},{y1},{x2},{y2}) size={x2-x1}x{y2-y1}")
print(f"{len(boxes)} slices")
```

- [ ] **Step 2: Run it in a venv**

```bash
python3 -m venv "$CLAUDE_JOB_DIR/tmp/venv" && "$CLAUDE_JOB_DIR/tmp/venv/bin/pip" -q install pillow numpy
"$CLAUDE_JOB_DIR/tmp/venv/bin/python" tool/slice_mascots.py
```

Expected: ~15–18 slices printed. If sparkle/small stars survive, that's fine — they get deleted in Step 4.

- [ ] **Step 3: Visually review every slice**

Build a labeled contact sheet and read it (checkerboard background exposes transparency):

```bash
magick montage assets/mascots/slice_*.png -background 'pattern:checkerboard' -tile 5x -geometry 200x200+8+8 -label '%f' "$CLAUDE_JOB_DIR/tmp/slices_review.png"
```

Read `$CLAUDE_JOB_DIR/tmp/slices_review.png` with the Read tool. Verify: no icon split in two (e.g., steam separated from teacup), no two icons merged (e.g., big star + small star), backgrounds transparent, edges clean. If wrong, adjust `GAP`/`THRESH`/`MIN_AREA`, delete slices, re-run Steps 2–3.

- [ ] **Step 4: Rename slices and finalize mapping**

Match each slice to its icon by looking at the contact sheet, then `mv` each `slice_NN.png` to its name from the Produces list (e.g., `mv assets/mascots/slice_03.png assets/mascots/sun.png`). Delete leftovers not in the mapping (sparkle, tiny stars): `rm assets/mascots/slice_*.png` after renaming. While inspecting, decide any mapping adjustments (executor's discretion per spec — e.g., if the "sprout" reads happy, move it to moderate) and note them for Task 2's pool constants.

- [ ] **Step 5: Delete the old SVGs and commit**

```bash
rm assets/mascots/*.svg
ls assets/mascots   # expect exactly the ~15 named PNGs
git add -A assets/mascots tool/slice_mascots.py
git commit -m "feat(mascot): slice icons.png into transparent PNG mascots"
```

---

### Task 2: Mascot pool + daily-seeded selection

**Files:**
- Create: `lib/state/mascot_pool.dart`
- Test: `test/state/mascot_pool_test.dart`

**Interfaces:**
- Consumes: PNG names from Task 1; `RiskBand` from `package:domain/domain.dart` (values: `low`, `moderate`, `high`, `veryHigh`).
- Produces:
  - `const Map<RiskBand, List<String>> kMascotPool`
  - `String mascotAssetFor(RiskBand band, {DateTime? date})` — deterministic for a given local date + band; `date` defaults to `DateTime.now()`.
  - `List<String> allMascotAssetPaths()` — deduped list of every pooled path (for pre-caching).

- [ ] **Step 1: Write the failing test**

```dart
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/state/mascot_pool.dart';

void main() {
  test('every band has at least one mascot', () {
    for (final band in RiskBand.values) {
      expect(kMascotPool[band], isNotEmpty, reason: '$band pool empty');
    }
  });

  test('all pooled paths look like mascot PNG assets', () {
    for (final paths in kMascotPool.values) {
      for (final p in paths) {
        expect(p, startsWith('assets/mascots/'));
        expect(p, endsWith('.png'));
      }
    }
  });

  test('same date and band always picks the same asset', () {
    final d = DateTime(2026, 7, 6, 9, 30);
    final later = DateTime(2026, 7, 6, 23, 59);
    for (final band in RiskBand.values) {
      expect(mascotAssetFor(band, date: d), mascotAssetFor(band, date: later));
    }
  });

  test('pick is always a member of the band pool', () {
    for (final band in RiskBand.values) {
      for (var day = 1; day <= 28; day++) {
        final pick = mascotAssetFor(band, date: DateTime(2026, 7, day));
        expect(kMascotPool[band], contains(pick));
      }
    }
  });

  test('picks vary across dates for bands with multiple options', () {
    final picks = <String>{
      for (var day = 1; day <= 28; day++)
        mascotAssetFor(RiskBand.low, date: DateTime(2026, 7, day)),
    };
    expect(picks.length, greaterThan(1));
  });

  test('allMascotAssetPaths is deduped and covers every pool entry', () {
    final all = allMascotAssetPaths();
    expect(all.toSet().length, all.length);
    for (final paths in kMascotPool.values) {
      for (final p in paths) {
        expect(all, contains(p));
      }
    }
  });
}
```

Note: check the app's package name in `pubspec.yaml` `name:` field and fix the import prefix if it isn't `migraine_forecast` (existing tests, e.g. `test/state/mascot_character_provider_test.dart`, show the correct prefix).

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/state/mascot_pool_test.dart`
Expected: FAIL — `mascot_pool.dart` does not exist.

- [ ] **Step 3: Implement**

Adjust pool contents per the finalized Task 1 mapping if it deviated from baseline.

```dart
import 'package:domain/domain.dart';

String _p(String name) => 'assets/mascots/$name.png';

/// Mood-matched mascot pool per risk band. Icons may appear in several
/// bands. Sliced from assets/icons.png (see tool/slice_mascots.py).
final Map<RiskBand, List<String>> kMascotPool = {
  RiskBand.low: [
    _p('sun'), _p('berry_pot'), _p('big_star'), _p('butterfly'), _p('fish'),
  ],
  RiskBand.moderate: [
    _p('potted_plant'), _p('teacup'), _p('notebook'),
    _p('small_flower'), _p('snail'), _p('cat'),
  ],
  RiskBand.high: [
    _p('sad_flower'), _p('sleepy_cloud'), _p('sprout'),
  ],
  RiskBand.veryHigh: [
    _p('raining_cloud'), _p('sleepy_cloud'), _p('sad_flower'),
  ],
};

/// Picks today's mascot for [band]: deterministic for a given local
/// calendar date + band, changes daily. Cadence is intentionally isolated
/// here — to change it (per-launch, manual shuffle), swap the seed.
String mascotAssetFor(RiskBand band, {DateTime? date}) {
  final d = date ?? DateTime.now();
  final pool = kMascotPool[band]!;
  assert(pool.isNotEmpty);
  final seed = d.year * 10000 + d.month * 100 + d.day + band.index * 31;
  return pool[seed % pool.length];
}

/// Every pooled asset path, deduped — used for startup pre-caching.
List<String> allMascotAssetPaths() =>
    {for (final paths in kMascotPool.values) ...paths}.toList();
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/state/mascot_pool_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/state/mascot_pool.dart test/state/mascot_pool_test.dart
git commit -m "feat(mascot): band-pooled mascot selection, seeded per day"
```

---

### Task 3: Rework MascotWidget for PNG rendering

**Files:**
- Modify: `lib/ui/shared/mascot/mascot_widget.dart` (full rewrite below)
- Delete: `lib/ui/shared/mascot/mascot_face_painter.dart`, `lib/ui/shared/mascot/blob_painter.dart`, `lib/ui/shared/mascot/mascot_accessories.dart`
- Delete: `test/ui/shared/mascot/mascot_face_painter_test.dart`, `test/ui/shared/mascot/blob_painter_test.dart`, `test/ui/shared/mascot/blob_painter_golden_test.dart`, `test/ui/shared/mascot/mascot_golden_test.dart`, `test/ui/shared/mascot/mascot_assets_test.dart`, `test/ui/shared/mascot/mascot_character_test.dart`
- Rewrite: `test/ui/shared/mascot/mascot_widget_test.dart`

**Interfaces:**
- Consumes: `mascotAssetFor`, `allMascotAssetPaths` from Task 2.
- Produces (relied on by Task 4):
  - `enum MascotAction { wiggle, wave }` (blink removed)
  - `enum MascotIdle { float, hop }` (unchanged)
  - `class MascotController extends ChangeNotifier` with `wiggle()`, `wave()`, `ackConsumed()`, `pending` (blink() removed)
  - `MascotWidget({required RiskBand band, double size = 160, MascotController? controller, VoidCallback? onWiggle, MascotIdle idle = MascotIdle.float})` — NO `character` param
  - `Future<void> precacheMascots(BuildContext context)` — now needs a context (uses `precacheImage`)

This task leaves callers (`main.dart`, screens, `celebration_overlay.dart`) temporarily broken — Task 4 fixes them. Only the widget test must pass here.

- [ ] **Step 1: Rewrite the widget test (failing first)**

Replace `test/ui/shared/mascot/mascot_widget_test.dart` with:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_widget.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('renders an Image for every band', (tester) async {
    for (final band in RiskBand.values) {
      await tester.pumpWidget(_host(MascotWidget(band: band, size: 80)));
      await tester.pump();
      expect(find.byType(Image), findsOneWidget, reason: '$band');
    }
  });

  testWidgets('wiggle action fires onWiggle', (tester) async {
    final controller = MascotController();
    var wiggled = false;
    await tester.pumpWidget(_host(MascotWidget(
      band: RiskBand.low,
      size: 80,
      controller: controller,
      onWiggle: () => wiggled = true,
    )));
    controller.wiggle();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(wiggled, isTrue);
    controller.dispose();
  });

  testWidgets('wave action completes without error', (tester) async {
    final controller = MascotController();
    await tester.pumpWidget(_host(MascotWidget(
      band: RiskBand.moderate,
      size: 80,
      controller: controller,
    )));
    controller.wave();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets('dropping to a lower band plays a wiggle', (tester) async {
    var wiggled = false;
    Widget build(RiskBand b) => _host(MascotWidget(
        band: b, size: 80, onWiggle: () => wiggled = true));
    await tester.pumpWidget(build(RiskBand.high));
    await tester.pump();
    await tester.pumpWidget(build(RiskBand.low));
    await tester.pump(const Duration(milliseconds: 600));
    expect(wiggled, isTrue);
  });
}
```

(Fix the package import prefix as in Task 2 if needed.)

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/ui/shared/mascot/mascot_widget_test.dart`
Expected: FAIL — `MascotWidget` still requires `character` / renders SvgPicture.

- [ ] **Step 3: Rewrite `mascot_widget.dart`**

Full replacement. This is the existing file minus: `character` param, blink, `MascotFace`/`_MascotFaceTween`/face `CustomPaint`, flutter_svg; plus `Image.asset` and context-based pre-cache.

```dart
import 'dart:math' as math;

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../../state/mascot_pool.dart';

enum MascotAction { wiggle, wave }

/// How the mascot idles when nothing else is happening.
/// [float] is a calm vertical drift; [hop] is a livelier bounce with a little
/// squash on landing — for casual, off-to-the-side placements.
enum MascotIdle { float, hop }

/// Pre-caches all pooled mascot PNGs so the first render does not flash.
/// Call once from the first frame with a mounted context.
Future<void> precacheMascots(BuildContext context) async {
  for (final path in allMascotAssetPaths()) {
    if (!context.mounted) return;
    await precacheImage(AssetImage(path), context);
  }
}

/// Drives one-shot mascot animations from outside the widget tree.
/// Hosts (TodayScreen, log sheets, onboarding, settings) call [wiggle] or
/// [wave]; a listening [MascotWidget] plays the matching action.
class MascotController extends ChangeNotifier {
  MascotAction? _pending;
  MascotAction? get pending => _pending;

  void wiggle() => _emit(MascotAction.wiggle);
  void wave() => _emit(MascotAction.wave);

  void _emit(MascotAction action) {
    _pending = action;
    notifyListeners();
  }

  /// Called by the widget once it has consumed the pending action.
  void ackConsumed() => _pending = null;
}

class MascotWidget extends StatefulWidget {
  final RiskBand band;
  final double size;
  final MascotController? controller;
  final VoidCallback? onWiggle;
  final MascotIdle idle;

  const MascotWidget({
    super.key,
    required this.band,
    this.size = 160,
    this.controller,
    this.onWiggle,
    this.idle = MascotIdle.float,
  });

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _idle;
  late final AnimationController _action; // wiggle / wave one-shots
  MascotAction _activeAction = MascotAction.wiggle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _action = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (_activeAction == MascotAction.wiggle) widget.onWiggle?.call();
          widget.controller?.ackConsumed();
        }
      });

    widget.controller?.addListener(_onControllerAction);
    _idle.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant MascotWidget old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_onControllerAction);
      widget.controller?.addListener(_onControllerAction);
    }
    if (old.band != widget.band && widget.band.index < old.band.index) {
      _playAction(MascotAction.wiggle);
    }
  }

  void _onControllerAction() {
    final pending = widget.controller?.pending;
    if (pending != null) _playAction(pending);
  }

  void _playAction(MascotAction action) {
    _activeAction = action;
    _action
      ..reset()
      ..forward();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_idle.isAnimating) _idle.repeat(reverse: true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _idle.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller?.removeListener(_onControllerAction);
    _idle.dispose();
    _action.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;

    if (reduce && _idle.isAnimating) {
      _idle.stop();
    }

    // One-shot action math (instant under reduced motion -> t jumps to 1).
    final t = reduce ? 1.0 : _action.value;
    double squish = 0; // wiggle: scaleX up, scaleY down
    double sway = 0; // wave: gentle rotation
    final playing =
        _action.isAnimating || (!reduce && _action.value > 0 && _action.value < 1);
    if (playing) {
      switch (_activeAction) {
        case MascotAction.wiggle:
          squish = 0.18 * (1 - (2 * t - 1).abs());
        case MascotAction.wave:
          sway = (1 - (2 * t - 1).abs());
      }
    }

    final assetPath = mascotAssetFor(widget.band);

    return AnimatedBuilder(
      animation: _idle,
      builder: (context, _) {
        final phase = reduce ? 0.0 : _idle.value;
        double floatY;
        double idleSquish = 0;
        if (widget.idle == MascotIdle.hop) {
          // sin(phase*pi) traces a single 0->1->0 arc per half-cycle: a leap
          // up and a landing. Squash a touch when near the ground.
          final hop = reduce ? 0.0 : math.sin(phase * math.pi);
          floatY = -16.0 * hop;
          idleSquish = 0.10 * (1 - hop);
        } else {
          floatY = reduce ? 0.0 : (-3.0 + 6.0 * phase);
        }
        final breathe = reduce ? 1.0 : (1.0 + 0.015 * (phase - 0.5).abs() * 2);

        // Wave = gentle rotation (+/-5deg). Wiggle = horizontal squish.
        final rotation = sway * 0.0873; // ~5 degrees in radians
        final totalSquish = squish + idleSquish;
        final scaleX = breathe * (1 + totalSquish * 0.5);
        final scaleY = breathe * (1 - totalSquish * 0.5);

        return Transform.translate(
          offset: Offset(0, floatY),
          child: Transform.rotate(
            angle: rotation,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(scaleX, scaleY, 1),
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: AnimatedSwitcher(
                  duration:
                      reduce ? Duration.zero : const Duration(milliseconds: 200),
                  child: Image.asset(
                    assetPath,
                    key: ValueKey(assetPath),
                    width: widget.size,
                    height: widget.size,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 4: Delete dead files**

```bash
rm lib/ui/shared/mascot/mascot_face_painter.dart \
   lib/ui/shared/mascot/blob_painter.dart \
   lib/ui/shared/mascot/mascot_accessories.dart \
   test/ui/shared/mascot/mascot_face_painter_test.dart \
   test/ui/shared/mascot/blob_painter_test.dart \
   test/ui/shared/mascot/blob_painter_golden_test.dart \
   test/ui/shared/mascot/mascot_golden_test.dart \
   test/ui/shared/mascot/mascot_assets_test.dart \
   test/ui/shared/mascot/mascot_character_test.dart
```

(If any of these test files also test things that survive, port those cases into `mascot_widget_test.dart` instead of deleting blindly — read them first.)

- [ ] **Step 5: Run the widget test**

Run: `flutter test test/ui/shared/mascot/mascot_widget_test.dart`
Expected: PASS (4 tests). Other suites still broken — that's Task 4.

- [ ] **Step 6: Commit**

```bash
git add -A lib/ui/shared/mascot test/ui/shared/mascot
git commit -m "refactor(mascot): render pooled PNGs; drop character/blink/face overlays"
```

---

### Task 4: Update callers, remove picker + providers + flutter_svg

**Files:**
- Modify: `lib/main.dart`, `lib/ui/today/today_screen.dart`, `lib/ui/settings/settings_screen.dart`, `lib/ui/onboarding/onboarding_screen.dart`, `lib/ui/shared/animations/celebration_overlay.dart`, `lib/state/settings_provider.dart`, `pubspec.yaml`
- Delete: `lib/ui/shared/mascot/mascot_picker_sheet.dart`, `lib/state/mascot_character.dart`, `test/ui/shared/mascot/mascot_picker_sheet_test.dart`, `test/state/mascot_character_provider_test.dart`

**Interfaces:**
- Consumes: Task 3's `MascotWidget` (no `character`), `MascotController` (no `blink`), `precacheMascots(BuildContext)`.

- [ ] **Step 1: main.dart** — `precacheMascots()` is currently awaited in `main()` before `runApp` (line ~36). It now needs a `BuildContext`. Remove the call (and its import if now unused) from `main()`; instead call it after first frame from the root widget. In the root app widget's build/init path add:

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  precacheMascots(context);
});
```

Read `lib/main.dart` fully first and place this in the root `State`'s `initState` (or a `Builder` inside the app) so `context` is under `MaterialApp`.

- [ ] **Step 2: today_screen.dart** — remove the imports of `mascot_character.dart` and `mascot_picker_sheet.dart`; delete the `character` variable (lines ~61–62). Give the state class a `final _mascot = MascotController();` (dispose it in `dispose()`). The mascot tap used to open the picker; make it wiggle instead. Replace the `InkWell`'s `onTap` and the `MascotWidget`:

```dart
onTap: () => _mascot.wiggle(),
child: MascotWidget(
  band: a.band,
  size: 84,
  controller: _mascot,
  idle: MascotIdle.hop,
),
```

Also update the stale comment "Tap to switch characters." → "Tap for a wiggle."

- [ ] **Step 3: settings_screen.dart** — remove imports of `mascot_character.dart` / `mascot_picker_sheet.dart`; drop `character:` from the `MascotWidget` call; delete the whole `ref.watch(mascotCharacterProvider).when(...)` Mascot `ListTile` block (the row keyed `settings-mascot-row`) and the `_mascotLabel` helper (lines ~540–546). Keep the 'Appearance' section header (the palette rows under it remain).

- [ ] **Step 4: onboarding_screen.dart** — remove `mascot_character.dart` import; drop the `character:` argument from its `MascotWidget`.

- [ ] **Step 5: celebration_overlay.dart** — `showCheckmark` calls `controller.blink()`, which no longer exists. Change to `controller.wiggle();` and update the doc comment ("mascot blink + a small checkmark particle" → "mascot wiggle + a small checkmark particle").

- [ ] **Step 6: settings_provider.dart** — remove the `mascot_character.dart` import and delete `mascotCharacterProvider` and `setMascotCharacterProvider` (lines ~183–196). The persisted `mascot_character` settings key becomes orphaned — that's fine, no migration needed.

- [ ] **Step 7: Delete picker + enum + their tests; drop flutter_svg**

```bash
rm lib/ui/shared/mascot/mascot_picker_sheet.dart \
   lib/state/mascot_character.dart \
   test/ui/shared/mascot/mascot_picker_sheet_test.dart \
   test/state/mascot_character_provider_test.dart
grep -rn "flutter_svg\|SvgPicture" lib test   # expect no hits
```

If the grep is clean, remove the `flutter_svg: ^2.0.17` line from `pubspec.yaml` and run `flutter pub get`.

- [ ] **Step 8: Analyze**

Run: `flutter analyze`
Expected: no errors (warnings unrelated to this change are acceptable if pre-existing).

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "refactor(mascot): remove character picker, providers, and flutter_svg"
```

---

### Task 5: Fix remaining tests, full suite green

**Files:**
- Modify (as needed): `test/widget_test.dart`, `test/app/app_smoke_test.dart`, `test/ui/today/today_screen_mascot_test.dart`, `test/ui/onboarding/onboarding_mascot_test.dart`, `test/ui/settings/dark_palette_picker_test.dart`, `test/ui/settings/settings_celebration_test.dart`, `test/ui/shared/animations/celebration_overlay_test.dart`

**Interfaces:**
- Consumes: everything above. No new interfaces.

- [ ] **Step 1: Run the full suite**

Run: `flutter test`
Expected: failures concentrated in the files above (references to `MascotCharacter`, `mascotCharacterProvider`, picker-sheet expectations, blink, `settings-mascot-row`).

- [ ] **Step 2: Fix each failing test to match the new behavior**

Guidance per file (read each before editing):
- `today_screen_mascot_test.dart`: taps on `Key('mascot-tap-target')` should now expect a wiggle (no bottom sheet). If it asserted the picker sheet opens, assert instead that no bottom sheet appears and no exception is thrown.
- `onboarding_mascot_test.dart` / `widget_test.dart` / `app_smoke_test.dart`: drop `MascotCharacter`/provider overrides; mascot renders regardless.
- `settings_celebration_test.dart` / `celebration_overlay_test.dart`: blink → wiggle.
- `dark_palette_picker_test.dart`: likely only touches mascot via settings screen scaffolding; remove references to the deleted mascot row (`settings-mascot-row`) if present.

Delete a test only if the feature it covers is gone (character picking); otherwise adapt it.

- [ ] **Step 3: Full suite green**

Run: `flutter test`
Expected: ALL PASS.

- [ ] **Step 4: Commit**

```bash
git add -A test
git commit -m "test: adapt suites to pooled PNG mascots"
```

- [ ] **Step 5: Manual review handoff**

Tell the user the mapping chosen in Task 1 (icon → band, with any deviations from baseline) and ask them to run the app to review the mascots in-app, per the spec's manual-review requirement.

---

## Extension (not scheduled): Two-layer potrace SVG mascots

Approved direction for a follow-up, validated experimentally on the sun icon
(see `mascot_vector_experiment.png`, 2026-07-06). Produces flat "kawaii
stamp" SVGs (~13 KB each): a body silhouette in one fill color plus a dark
linework/face layer stacked on top. Loses the watercolor wash but is
**runtime-tintable** — the body fill can be swapped to match the active
palette (Midnight Sage etc.). Do NOT start this without user say-so; PNG is
the shipping format for now.

**Pipeline** (per sliced PNG from Task 1; requires `brew install potrace`,
already installed 2026-07-06):

```bash
# 1. Body mask: every opaque pixel -> black, transparent -> white
magick sun.png -alpha extract -threshold 50% -negate body.pbm
# 2. Linework mask: opaque AND dark pixels -> black
magick sun.png \( +clone -alpha extract -threshold 50% \) \
  \( sun.png -alpha off -colorspace gray -threshold 35% -negate \) \
  -delete 0 -compose multiply -composite -negate lines.pbm
# 3. Trace both layers
potrace body.pbm  -s --color '#4A7FB5' -o body.svg
potrace lines.pbm -s --color '#1a1a1a' -o lines.svg
```

Then merge: take `body.svg`, insert `lines.svg`'s `<g>…</g>` before
`</svg>` (both share the source pixel coordinate system, so they align).
Script this as `tool/vectorize_mascots.py` over all pooled PNGs.

**App integration sketch:**
- Re-add `flutter_svg`; render via `SvgPicture.asset` in `MascotWidget`.
- Tinting: emit the body path with `fill="currentColor"` instead of a
  hard-coded hex, and pass `theme.colorScheme.primary` (or a dedicated
  mascot color per palette) via flutter_svg's `ColorMapper`/theme `currentColor`.
- Keep `mascot_pool.dart` unchanged except `.png` → `.svg` paths; revert
  `precacheMascots` to the flutter_svg picture cache (see git history of
  `mascot_widget.dart` for the original implementation).
- Verify each traced SVG visually (contact sheet, as in Task 1 Step 3) —
  fine features like the snail's spiral and butterfly wing hearts are the
  likely casualties of `-threshold 35%`; tune per icon if needed.

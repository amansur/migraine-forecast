# Cute Mascot & Animations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a soft expressive blob mascot and lightweight UI animations to the migraine forecast Flutter app.

**Architecture:** A self-contained `lib/ui/shared/mascot/` package draws an abstract blob via `CustomPainter` (`BlobPainter` body + `MascotAccessoriesPainter` per-band accessories), wrapped in a `MascotWidget` `StatefulWidget` that owns the idle float/breathe loop, band-change morphing, and one-shot wiggle/wave/blink actions driven by an external `MascotController`. A parallel `lib/ui/shared/animations/` package provides a reusable `AnimatedEntry` slide+fade wrapper and a `CelebrationOverlay` confetti burst built on `OverlayEntry`. Every animated entry point short-circuits to a static render when `MediaQuery.disableAnimations` is true.

**Tech Stack:** Flutter, Dart, CustomPainter, TweenAnimationBuilder, OverlayEntry — no new packages.

## Global Constraints

- No new third-party packages. PNG fallback (if ever needed) uses `Image.asset` only.
- No Lottie files or external animation assets.
- No changes to risk calculation logic or the data layer.
- The mascot does not replace existing display modes (gauge/numeric/weather icon); it sits above `RiskDisplay`.
- `risk_display.dart` is **not** modified — band-change detection lives in `MascotWidget.didUpdateWidget`.
- Body fill is the band color (`bandLow` → `bandVeryHigh`) at ~60% opacity; must read well in both light (ivory) and comfort (dark) themes.
- Today-screen mascot is ~160×160px; cameos are ~80px.
- Reduced motion (`MediaQuery.disableAnimations == true`): mascot renders static at the correct band state (no idle loop, no morph); `AnimatedEntry` shows children instantly; celebrations skip confetti but still update/animate the mascot expression (blink/wave/wiggle one-shots run as instant state changes, never infinite loops).
- Confetti: 20–30 circles drawn from the `BrandColors` palette (sage, ivory, band colors), launched from center-bottom with random velocities + gravity, fading over 1.2s.
- Tests must set `tester.binding.disableAnimations = true` (or pump finite durations) so the infinite idle `RepeatAnimation` never hangs `pumpAndSettle`.

---

## Conventions used by every task

- Run analysis + tests from the repo root: `/Users/amansur/projects/migraine-forecast`.
- `RiskBand` is `enum RiskBand { low, moderate, high, veryHigh }` from `package:domain/domain.dart`.
- Band color helper `colorForBand(String bandName)` and `BrandColors` live in `lib/app/theme.dart`.
- Golden files for this feature live under `test/ui/shared/mascot/goldens/`.

---

## Task 1 — BlobPainter + MascotAccessories (static)

**Files:**
- Create `lib/ui/shared/mascot/blob_painter.dart`
- Create `lib/ui/shared/mascot/mascot_accessories.dart`
- Create (test) `test/ui/shared/mascot/blob_painter_test.dart`
- Create (test) `test/ui/shared/mascot/blob_painter_golden_test.dart`

**Interfaces:**
- Produces:
  - `class BlobShape { final double topBulge, rightBulge, bottomBulge, leftBulge; const BlobShape(...); static BlobShape forBand(RiskBand); static BlobShape lerp(BlobShape a, BlobShape b, double t); }`
  - `class MascotFace { final double browAngle, mouthOpen, blush; final bool sweat; const MascotFace(...); static MascotFace forBand(RiskBand); static MascotFace lerp(MascotFace a, MascotFace b, double t); }`
  - `class BlobPainter extends CustomPainter { BlobPainter({required BlobShape shape, required Color color, required MascotFace face, double squish = 0.0, double eyeOpen = 1.0}); }`
  - `class MascotAccessoriesPainter extends CustomPainter { MascotAccessoriesPainter({required RiskBand band, required Color color, double sway = 0.0, double quiver = 0.0}); }`
- Consumes: `RiskBand` (domain), `BrandColors`/`colorForBand` (theme).

### Steps

- [ ] **Create `lib/ui/shared/mascot/blob_painter.dart`** with the full body painter and shared value types:

```dart
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

/// Bezier blob silhouette, described by how far each of the four cardinal
/// control handles bulges outward (0..1, fraction of the radius).
class BlobShape {
  final double topBulge;
  final double rightBulge;
  final double bottomBulge;
  final double leftBulge;

  const BlobShape({
    required this.topBulge,
    required this.rightBulge,
    required this.bottomBulge,
    required this.leftBulge,
  });

  static BlobShape forBand(RiskBand band) {
    switch (band) {
      case RiskBand.low:
        return const BlobShape(topBulge: 0.92, rightBulge: 0.95, bottomBulge: 0.98, leftBulge: 0.95);
      case RiskBand.moderate:
        return const BlobShape(topBulge: 0.90, rightBulge: 0.92, bottomBulge: 0.94, leftBulge: 0.92);
      case RiskBand.high:
        return const BlobShape(topBulge: 0.86, rightBulge: 0.88, bottomBulge: 0.90, leftBulge: 0.88);
      case RiskBand.veryHigh:
        return const BlobShape(topBulge: 0.82, rightBulge: 0.96, bottomBulge: 0.84, leftBulge: 0.96);
    }
  }

  static BlobShape lerp(BlobShape a, BlobShape b, double t) => BlobShape(
        topBulge: ui.lerpDouble(a.topBulge, b.topBulge, t)!,
        rightBulge: ui.lerpDouble(a.rightBulge, b.rightBulge, t)!,
        bottomBulge: ui.lerpDouble(a.bottomBulge, b.bottomBulge, t)!,
        leftBulge: ui.lerpDouble(a.leftBulge, b.leftBulge, t)!,
      );
}

/// Facial expression parameters, all 0..1 so they interpolate cleanly.
class MascotFace {
  /// 0 = flat happy brow, 1 = steep worried brow.
  final double browAngle;

  /// 0 = closed smile, 1 = wide open mouth.
  final double mouthOpen;

  /// 0 = no cheek blush, 1 = full rosy/flushed cheeks.
  final double blush;

  /// Whether a small sweat drop is shown.
  final bool sweat;

  const MascotFace({
    required this.browAngle,
    required this.mouthOpen,
    required this.blush,
    required this.sweat,
  });

  static MascotFace forBand(RiskBand band) {
    switch (band) {
      case RiskBand.low:
        return const MascotFace(browAngle: 0.0, mouthOpen: 0.15, blush: 0.6, sweat: false);
      case RiskBand.moderate:
        return const MascotFace(browAngle: 0.2, mouthOpen: 0.1, blush: 0.2, sweat: false);
      case RiskBand.high:
        return const MascotFace(browAngle: 0.7, mouthOpen: 0.2, blush: 0.1, sweat: true);
      case RiskBand.veryHigh:
        return const MascotFace(browAngle: 1.0, mouthOpen: 0.8, blush: 0.9, sweat: true);
    }
  }

  static MascotFace lerp(MascotFace a, MascotFace b, double t) => MascotFace(
        browAngle: ui.lerpDouble(a.browAngle, b.browAngle, t)!,
        mouthOpen: ui.lerpDouble(a.mouthOpen, b.mouthOpen, t)!,
        blush: ui.lerpDouble(a.blush, b.blush, t)!,
        sweat: t < 0.5 ? a.sweat : b.sweat,
      );
}

/// Paints the soft blob body + face. Accessories are painted separately by
/// [MascotAccessoriesPainter] so they can animate independently.
class BlobPainter extends CustomPainter {
  final BlobShape shape;
  final Color color;
  final MascotFace face;

  /// Vertical squish for the happy wiggle: 0 = round, positive = squashed.
  final double squish;

  /// Eye openness for blink: 1 = fully open, 0 = closed line.
  final double eyeOpen;

  BlobPainter({
    required this.shape,
    required this.color,
    required this.face,
    this.squish = 0.0,
    this.eyeOpen = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(size.width, size.height) / 2;

    // Squish: widen horizontally, shorten vertically, keep area-ish constant.
    final rx = r * (1 + squish * 0.5);
    final ry = r * (1 - squish * 0.5);

    final top = Offset(cx, cy - ry * shape.topBulge);
    final right = Offset(cx + rx * shape.rightBulge, cy);
    final bottom = Offset(cx, cy + ry * shape.bottomBulge);
    final left = Offset(cx - rx * shape.leftBulge, cy);

    // Control handle length — ~0.55 of radius gives a smooth near-circle.
    final hx = rx * 0.55;
    final hy = ry * 0.55;

    final path = Path()
      ..moveTo(top.dx, top.dy)
      ..cubicTo(top.dx + hx, top.dy, right.dx, right.dy - hy, right.dx, right.dy)
      ..cubicTo(right.dx, right.dy + hy, bottom.dx + hx, bottom.dy, bottom.dx, bottom.dy)
      ..cubicTo(bottom.dx - hx, bottom.dy, left.dx, left.dy + hy, left.dx, left.dy)
      ..cubicTo(left.dx, left.dy - hy, top.dx - hx, top.dy, top.dx, top.dy)
      ..close();

    final bodyPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bodyPaint);

    _paintFace(canvas, Offset(cx, cy), rx, ry);
  }

  void _paintFace(Canvas canvas, Offset c, double rx, double ry) {
    final eyeDx = rx * 0.32;
    final eyeY = c.dy - ry * 0.08;
    final eyeR = rx * 0.11;
    final eyeColor = const Color(0xFF2E3A2E); // BrandColors.ink

    final eyePaint = Paint()..color = eyeColor;
    for (final sign in [-1.0, 1.0]) {
      final center = Offset(c.dx + sign * eyeDx, eyeY);
      if (eyeOpen <= 0.05) {
        // Closed: short horizontal line.
        final p = Paint()
          ..color = eyeColor
          ..strokeWidth = eyeR * 0.8
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(center.dx - eyeR, center.dy),
          Offset(center.dx + eyeR, center.dy),
          p,
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(center: center, width: eyeR * 2, height: eyeR * 2 * eyeOpen),
          eyePaint,
        );
      }
    }

    // Brow: tilts inward/up as browAngle grows.
    if (face.browAngle > 0.05) {
      final browPaint = Paint()
        ..color = eyeColor
        ..strokeWidth = rx * 0.05
        ..strokeCap = StrokeCap.round;
      final lift = ry * 0.18 * face.browAngle;
      final browY = eyeY - eyeR * 1.8;
      for (final sign in [-1.0, 1.0]) {
        final inner = Offset(c.dx + sign * eyeDx * 0.5, browY - lift);
        final outer = Offset(c.dx + sign * eyeDx * 1.4, browY);
        canvas.drawLine(inner, outer, browPaint);
      }
    }

    // Cheeks / blush.
    if (face.blush > 0.05) {
      final blushPaint = Paint()..color = const Color(0xFFD89B7A).withValues(alpha: 0.5 * face.blush);
      for (final sign in [-1.0, 1.0]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(c.dx + sign * eyeDx * 1.25, eyeY + ry * 0.16),
            width: rx * 0.28,
            height: ry * 0.18,
          ),
          blushPaint,
        );
      }
    }

    // Mouth: small smile or open "o".
    final mouthY = c.dy + ry * 0.28;
    final mouthPaint = Paint()
      ..color = eyeColor
      ..style = face.mouthOpen > 0.4 ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = rx * 0.045
      ..strokeCap = StrokeCap.round;
    if (face.mouthOpen > 0.4) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(c.dx, mouthY), width: rx * 0.3, height: ry * 0.32 * face.mouthOpen),
        mouthPaint,
      );
    } else {
      final mouth = Path()
        ..moveTo(c.dx - rx * 0.18, mouthY)
        ..quadraticBezierTo(c.dx, mouthY + ry * 0.14, c.dx + rx * 0.18, mouthY);
      canvas.drawPath(mouth, mouthPaint);
    }

    // Sweat drop near the right brow.
    if (face.sweat) {
      final dropPaint = Paint()..color = const Color(0xFF6FA8DC).withValues(alpha: 0.8);
      final dropCenter = Offset(c.dx + eyeDx * 1.6, eyeY - ry * 0.05);
      final drop = Path()
        ..moveTo(dropCenter.dx, dropCenter.dy - ry * 0.1)
        ..quadraticBezierTo(dropCenter.dx + rx * 0.08, dropCenter.dy, dropCenter.dx, dropCenter.dy + ry * 0.04)
        ..quadraticBezierTo(dropCenter.dx - rx * 0.08, dropCenter.dy, dropCenter.dx, dropCenter.dy - ry * 0.1)
        ..close();
      canvas.drawPath(drop, dropPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BlobPainter old) =>
      old.shape.topBulge != shape.topBulge ||
      old.shape.rightBulge != shape.rightBulge ||
      old.shape.bottomBulge != shape.bottomBulge ||
      old.shape.leftBulge != shape.leftBulge ||
      old.color != color ||
      old.face.browAngle != face.browAngle ||
      old.face.mouthOpen != face.mouthOpen ||
      old.face.blush != face.blush ||
      old.face.sweat != face.sweat ||
      old.squish != squish ||
      old.eyeOpen != eyeOpen;
}
```

- [ ] **Create `lib/ui/shared/mascot/mascot_accessories.dart`** with the per-band accessory painter:

```dart
import 'dart:math' as math;

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

/// Paints the "cute hint" accessory that varies by risk band:
/// low = flower petals, moderate = cat ears, high = drooped bunny ears,
/// veryHigh = bee antennae. [sway] swings petals/ears for the wave animation;
/// [quiver] jitters the bee antennae.
class MascotAccessoriesPainter extends CustomPainter {
  final RiskBand band;
  final Color color;
  final double sway;
  final double quiver;

  MascotAccessoriesPainter({
    required this.band,
    required this.color,
    this.sway = 0.0,
    this.quiver = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(size.width, size.height) / 2;
    switch (band) {
      case RiskBand.low:
        _petals(canvas, cx, cy, r);
      case RiskBand.moderate:
        _catEars(canvas, cx, cy, r);
      case RiskBand.high:
        _bunnyEars(canvas, cx, cy, r);
      case RiskBand.veryHigh:
        _beeAntennae(canvas, cx, cy, r);
    }
  }

  void _petals(Canvas canvas, double cx, double cy, double r) {
    final paint = Paint()..color = color.withValues(alpha: 0.85);
    const count = 6;
    final swingRad = sway * 0.25;
    for (var i = 0; i < count; i++) {
      final a = (math.pi * 2 / count) * i - math.pi / 2 + swingRad;
      final px = cx + math.cos(a) * r * 0.92;
      final py = cy + math.sin(a) * r * 0.92;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(px, py), width: r * 0.32, height: r * 0.5),
        paint,
      );
    }
  }

  void _catEars(Canvas canvas, double cx, double cy, double r) {
    final paint = Paint()..color = color.withValues(alpha: 0.85);
    final tilt = sway * r * 0.15;
    for (final sign in [-1.0, 1.0]) {
      final baseX = cx + sign * r * 0.55;
      final baseY = cy - r * 0.75;
      final path = Path()
        ..moveTo(baseX - r * 0.18, baseY + r * 0.1)
        ..lineTo(baseX + sign * tilt, baseY - r * 0.45)
        ..lineTo(baseX + r * 0.18, baseY + r * 0.1)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  void _bunnyEars(Canvas canvas, double cx, double cy, double r) {
    final paint = Paint()..color = color.withValues(alpha: 0.85);
    // Drooped: ears lean outward and down.
    final droop = r * 0.12;
    final swing = sway * r * 0.12;
    for (final sign in [-1.0, 1.0]) {
      final baseX = cx + sign * r * 0.35;
      final baseY = cy - r * 0.7;
      final tipX = baseX + sign * (r * 0.35 + swing);
      final tipY = baseY - r * 0.35 + droop;
      final path = Path()
        ..moveTo(baseX, baseY)
        ..quadraticBezierTo(baseX + sign * r * 0.3, baseY - r * 0.5, tipX, tipY)
        ..quadraticBezierTo(baseX + sign * r * 0.45, baseY - r * 0.2, baseX + sign * r * 0.12, baseY)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  void _beeAntennae(Canvas canvas, double cx, double cy, double r) {
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.05
      ..strokeCap = StrokeCap.round;
    final tipPaint = Paint()..color = color.withValues(alpha: 0.9);
    final jitter = quiver * r * 0.08;
    for (final sign in [-1.0, 1.0]) {
      final baseX = cx + sign * r * 0.2;
      final baseY = cy - r * 0.78;
      final tipX = baseX + sign * r * 0.28 + jitter * sign;
      final tipY = baseY - r * 0.4;
      final path = Path()
        ..moveTo(baseX, baseY)
        ..quadraticBezierTo(baseX + sign * r * 0.1, baseY - r * 0.3, tipX, tipY);
      canvas.drawPath(path, stroke);
      canvas.drawCircle(Offset(tipX, tipY), r * 0.07, tipPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MascotAccessoriesPainter old) =>
      old.band != band || old.color != color || old.sway != sway || old.quiver != quiver;
}
```

- [ ] **Create `test/ui/shared/mascot/blob_painter_test.dart`** verifying the painters construct and paint without error for every band, and that `shouldRepaint` reacts to changes:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/app/theme.dart';
import 'package:migraine_forecast/ui/shared/mascot/blob_painter.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_accessories.dart';

void main() {
  for (final band in RiskBand.values) {
    testWidgets('BlobPainter + accessories paint for $band', (tester) async {
      tester.binding.disableAnimations = true;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: CustomPaint(
                painter: BlobPainter(
                  shape: BlobShape.forBand(band),
                  color: colorForBand(band.name),
                  face: MascotFace.forBand(band),
                ),
                foregroundPainter: MascotAccessoriesPainter(
                  band: band,
                  color: colorForBand(band.name),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });
  }

  test('BlobShape.lerp interpolates endpoints', () {
    final a = BlobShape.forBand(RiskBand.low);
    final b = BlobShape.forBand(RiskBand.veryHigh);
    final mid = BlobShape.lerp(a, b, 0.5);
    expect(mid.topBulge, closeTo((a.topBulge + b.topBulge) / 2, 1e-9));
  });

  test('MascotFace.lerp switches sweat at midpoint', () {
    final calm = MascotFace.forBand(RiskBand.low); // sweat false
    final worried = MascotFace.forBand(RiskBand.high); // sweat true
    expect(MascotFace.lerp(calm, worried, 0.49).sweat, isFalse);
    expect(MascotFace.lerp(calm, worried, 0.51).sweat, isTrue);
  });

  test('BlobPainter.shouldRepaint reacts to squish change', () {
    final base = BlobPainter(
      shape: BlobShape.forBand(RiskBand.low),
      color: colorForBand('low'),
      face: MascotFace.forBand(RiskBand.low),
    );
    final squished = BlobPainter(
      shape: BlobShape.forBand(RiskBand.low),
      color: colorForBand('low'),
      face: MascotFace.forBand(RiskBand.low),
      squish: 0.3,
    );
    expect(squished.shouldRepaint(base), isTrue);
  });
}
```

- [ ] **Create `test/ui/shared/mascot/blob_painter_golden_test.dart`** with one golden per band (light theme background):

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/app/theme.dart';
import 'package:migraine_forecast/ui/shared/mascot/blob_painter.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_accessories.dart';

void main() {
  for (final band in RiskBand.values) {
    testWidgets('mascot_${band.name}', (tester) async {
      tester.binding.disableAnimations = true;
      await tester.pumpWidget(MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              child: SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: BlobPainter(
                    shape: BlobShape.forBand(band),
                    color: colorForBand(band.name),
                    face: MascotFace.forBand(band),
                  ),
                  foregroundPainter: MascotAccessoriesPainter(
                    band: band,
                    color: colorForBand(band.name),
                  ),
                ),
              ),
            ),
          ),
        ),
      ));
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('goldens/mascot_${band.name}.png'),
      );
    });
  }
}
```

- [ ] **Run analyzer:** `flutter analyze lib/ui/shared/mascot test/ui/shared/mascot`
  - Expected: `No issues found!`
- [ ] **Generate goldens:** `flutter test --update-goldens test/ui/shared/mascot/blob_painter_golden_test.dart`
  - Expected: `All tests passed!` and four PNGs created under `test/ui/shared/mascot/goldens/`.
- [ ] **Run the task's tests:** `flutter test test/ui/shared/mascot/`
  - Expected: `All tests passed!`
- [ ] **Commit:**
```bash
cd /Users/amansur/projects/migraine-forecast
git add lib/ui/shared/mascot/blob_painter.dart lib/ui/shared/mascot/mascot_accessories.dart test/ui/shared/mascot/
git commit -m "feat(mascot): static BlobPainter + accessories per risk band with goldens"
```

---

## Task 2 — MascotWidget (idle, morph, actions, reduced motion)

**Files:**
- Create `lib/ui/shared/mascot/mascot_widget.dart`
- Create (test) `test/ui/shared/mascot/mascot_widget_test.dart`

**Interfaces:**
- Consumes: `BlobShape`, `MascotFace`, `BlobPainter` (Task 1), `MascotAccessoriesPainter` (Task 1), `RiskBand`, `colorForBand`.
- Produces:
  - `enum MascotAction { wiggle, wave, blink }`
  - `class MascotController extends ChangeNotifier { MascotAction? get pending; void wiggle(); void wave(); void blink(); }`
  - `class MascotWidget extends StatefulWidget { const MascotWidget({super.key, required RiskBand band, double size = 160, MascotController? controller, VoidCallback? onWiggle}); }`
  - Reconciliation with the spec: the spec's external `onWiggle` trigger is realised two ways — `controller.wiggle()` (imperative inbound trigger used by Tasks 5–7) and the `onWiggle` callback, which fires *outbound* whenever the mascot completes a wiggle (so callers can chain). Band-change detection lives entirely inside `didUpdateWidget`.

### Steps

- [ ] **Create `lib/ui/shared/mascot/mascot_widget.dart`:**

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import 'blob_painter.dart';
import 'mascot_accessories.dart';

enum MascotAction { wiggle, wave, blink }

/// Drives one-shot mascot animations from outside the widget tree.
/// Hosts (TodayScreen, log sheets, onboarding, settings) call [wiggle],
/// [wave], or [blink]; a listening [MascotWidget] plays the matching action.
class MascotController extends ChangeNotifier {
  MascotAction? _pending;
  MascotAction? get pending => _pending;

  void wiggle() => _emit(MascotAction.wiggle);
  void wave() => _emit(MascotAction.wave);
  void blink() => _emit(MascotAction.blink);

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

  const MascotWidget({
    super.key,
    required this.band,
    this.size = 160,
    this.controller,
    this.onWiggle,
  });

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _idle;
  late final AnimationController _action; // wiggle / wave / blink one-shots
  MascotAction _activeAction = MascotAction.wiggle;

  // Morph target — band-change detection lives here, not in RiskDisplay.
  late BlobShape _targetShape;
  late MascotFace _targetFace;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _targetShape = BlobShape.forBand(widget.band);
    _targetFace = MascotFace.forBand(widget.band);

    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _action = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() => setState(() {}))
     ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (_activeAction == MascotAction.wiggle) widget.onWiggle?.call();
          widget.controller?.ackConsumed();
        }
      });

    widget.controller?.addListener(_onControllerAction);
    // Start the idle loop unless reduced motion is on (decided in build()).
    _idle.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant MascotWidget old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_onControllerAction);
      widget.controller?.addListener(_onControllerAction);
    }
    if (old.band != widget.band) {
      // Band changed: update morph targets (TweenAnimationBuilder animates),
      // and auto-wiggle when risk improves.
      _targetShape = BlobShape.forBand(widget.band);
      _targetFace = MascotFace.forBand(widget.band);
      if (widget.band.index < old.band.index) {
        _playAction(MascotAction.wiggle);
      }
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
    final color = colorForBand(widget.band.name);

    if (reduce && _idle.isAnimating) {
      // Don't run the infinite loop under reduced motion.
      _idle.stop();
    }

    // One-shot action math (instant under reduced motion → t jumps to 1).
    final t = reduce ? 1.0 : _action.value;
    double squish = 0;
    double eyeOpen = 1;
    double sway = 0;
    double quiver = widget.band == RiskBand.veryHigh ? 0.4 : 0;
    if (_action.isAnimating || (!reduce && _action.value > 0 && _action.value < 1)) {
      switch (_activeAction) {
        case MascotAction.wiggle:
          squish = 0.18 * (1 - (2 * t - 1).abs()); // up then back
        case MascotAction.wave:
          sway = (1 - (2 * t - 1).abs()); // swing out and back
        case MascotAction.blink:
          eyeOpen = (2 * t - 1).abs(); // 1 → 0 → 1
      }
    }

    return AnimatedBuilder(
      animation: _idle,
      builder: (context, _) {
        // Idle float (vertical translate) + breathe (scale).
        final phase = reduce ? 0.0 : _idle.value;
        final floatY = reduce ? 0.0 : (-3.0 + 6.0 * phase);
        final breathe = reduce ? 1.0 : (1.0 + 0.015 * (phase - 0.5).abs() * 2);

        return Transform.translate(
          offset: Offset(0, floatY),
          child: Transform.scale(
            scale: breathe,
            child: TweenAnimationBuilder<BlobShape>(
              tween: _BlobShapeTween(end: _targetShape),
              duration: reduce ? Duration.zero : const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              builder: (context, shape, __) {
                return TweenAnimationBuilder<MascotFace>(
                  tween: _MascotFaceTween(end: _targetFace),
                  duration: reduce ? Duration.zero : const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                  builder: (context, face, ___) {
                    return SizedBox(
                      width: widget.size,
                      height: widget.size,
                      child: CustomPaint(
                        painter: BlobPainter(
                          shape: shape,
                          color: color,
                          face: face,
                          squish: squish,
                          eyeOpen: eyeOpen,
                        ),
                        foregroundPainter: MascotAccessoriesPainter(
                          band: widget.band,
                          color: color,
                          sway: sway,
                          quiver: reduce ? 0 : quiver,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _BlobShapeTween extends Tween<BlobShape> {
  _BlobShapeTween({required BlobShape end}) : super(end: end);
  @override
  BlobShape lerp(double t) => BlobShape.lerp(begin ?? end!, end!, t);
}

class _MascotFaceTween extends Tween<MascotFace> {
  _MascotFaceTween({required MascotFace end}) : super(end: end);
  @override
  MascotFace lerp(double t) => MascotFace.lerp(begin ?? end!, end!, t);
}
```

- [ ] **Create `test/ui/shared/mascot/mascot_widget_test.dart`:**

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/app/theme.dart';
import 'package:migraine_forecast/ui/shared/mascot/blob_painter.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_accessories.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_widget.dart';

MascotAccessoriesPainter _accessories(WidgetTester tester) {
  final cp = tester.widget<CustomPaint>(
    find.descendant(of: find.byType(MascotWidget), matching: find.byType(CustomPaint)).first,
  );
  return cp.foregroundPainter! as MascotAccessoriesPainter;
}

void main() {
  Widget host(RiskBand band, {MascotController? controller}) => MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: Center(child: MascotWidget(band: band, controller: controller)),
        ),
      );

  for (final band in RiskBand.values) {
    testWidgets('renders correct accessory for $band', (tester) async {
      tester.binding.disableAnimations = true;
      await tester.pumpWidget(host(band));
      await tester.pump();
      expect(_accessories(tester).band, band);
    });
  }

  testWidgets('idle loop does not hang pumpAndSettle under reduced motion', (tester) async {
    tester.binding.disableAnimations = true;
    await tester.pumpWidget(host(RiskBand.low));
    await tester.pumpAndSettle(); // would time out if idle loop ran
    expect(find.byType(MascotWidget), findsOneWidget);
  });

  testWidgets('controller.blink runs and acks', (tester) async {
    tester.binding.disableAnimations = true;
    final controller = MascotController();
    await tester.pumpWidget(host(RiskBand.low, controller: controller));
    controller.blink();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(controller.pending, isNull); // consumed
  });

  testWidgets('onWiggle fires when wiggle completes', (tester) async {
    var wiggled = false;
    final controller = MascotController();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MascotWidget(
          band: RiskBand.low,
          controller: controller,
          onWiggle: () => wiggled = true,
        ),
      ),
    ));
    controller.wiggle();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(wiggled, isTrue);
    // settle the idle loop so the test can end cleanly
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('band change updates accessory via didUpdateWidget', (tester) async {
    tester.binding.disableAnimations = true;
    final notifier = ValueNotifier<RiskBand>(RiskBand.high);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ValueListenableBuilder<RiskBand>(
          valueListenable: notifier,
          builder: (_, b, __) => MascotWidget(band: b),
        ),
      ),
    ));
    await tester.pump();
    expect(_accessories(tester).band, RiskBand.high);
    notifier.value = RiskBand.low;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(_accessories(tester).band, RiskBand.low);
  });
}
```

- [ ] **Run analyzer:** `flutter analyze lib/ui/shared/mascot test/ui/shared/mascot`
  - Expected: `No issues found!`
- [ ] **Run tests:** `flutter test test/ui/shared/mascot/mascot_widget_test.dart`
  - Expected: `All tests passed!`
- [ ] **Commit:**
```bash
cd /Users/amansur/projects/migraine-forecast
git add lib/ui/shared/mascot/mascot_widget.dart test/ui/shared/mascot/mascot_widget_test.dart
git commit -m "feat(mascot): MascotWidget idle loop, band morph, controller actions, reduced-motion"
```

---

## Task 3 — Wire mascot into TodayScreen

**Files:**
- Modify `lib/ui/today/today_screen.dart`
- Create (test) `test/ui/today/today_screen_mascot_test.dart`

**Interfaces:**
- Consumes: `MascotWidget` (Task 2), `RiskAssessment.band` from the existing `riskAssessmentProvider`.
- Produces: a `MascotWidget` rendered above `RiskDisplay`, using the assessment's `band`.

> **Lifecycle note (deviation from spec):** `MascotWidget` self-registers a `WidgetsBindingObserver` and pauses/resumes its own idle loop (Task 2). The spec suggested reusing `_TodayScreenState`'s existing observer; we keep encapsulation instead so the mascot behaves correctly anywhere it is placed. `_TodayScreenState`'s existing observer is left untouched — no extra wiring is needed.

### Steps

- [ ] **Add the import** to `lib/ui/today/today_screen.dart` (after the existing `import 'risk_display.dart';` block, keep alphabetical-ish with siblings):

```dart
import '../shared/mascot/mascot_widget.dart';
```

- [ ] **Insert the mascot above `RiskDisplay`.** Replace the `Center(child: Padding(... RiskDisplay ...))` block inside the `data: (a) {` return with a mascot + display column. Find:

```dart
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: RiskDisplay(assessment: a, mode: mode),
                      ),
                    ),
```

Replace with:

```dart
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: MascotWidget(band: a.band, size: 160),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: RiskDisplay(assessment: a, mode: mode),
                      ),
                    ),
```

- [ ] **Create `test/ui/today/today_screen_mascot_test.dart`** verifying the mascot appears with the current band. Reuse the fake-notifier pattern from `today_screen_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:migraine_forecast/state/risk_assessment_provider.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_widget.dart';
import 'package:migraine_forecast/ui/today/today_screen.dart';

class _FakeNotifier extends RiskAssessmentNotifier {
  final RiskAssessment fixed;
  _FakeNotifier(this.fixed);
  @override
  Future<RiskAssessment> build() async => fixed;
  @override
  Future<void> refresh() async => state = AsyncValue.data(fixed);
}

class _FakeTomorrowNotifier extends TomorrowRiskAssessmentNotifier {
  final RiskAssessment fixed;
  _FakeTomorrowNotifier(this.fixed);
  @override
  Future<RiskAssessment> build() async => fixed;
  @override
  Future<void> refresh() async => state = AsyncValue.data(fixed);
}

RiskAssessment _ass(RiskBand band) => RiskAssessment(
      score: 58,
      band: band,
      contributors: const [],
      computedAt: DateTime.utc(2026, 6, 10, 6),
      configVersion: 1,
      targetDate: DateTime.utc(2026, 6, 10),
      horizon: RiskHorizon.today,
    );

void main() {
  testWidgets('mascot appears above the risk display with current band', (tester) async {
    tester.binding.disableAnimations = true;
    final today = _ass(RiskBand.high);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const TodayScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const Scaffold(body: Text('SETTINGS'))),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        riskAssessmentProvider.overrideWith(() => _FakeNotifier(today)),
        tomorrowRiskAssessmentProvider.overrideWith(() => _FakeTomorrowNotifier(_ass(RiskBand.moderate))),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();

    expect(find.byType(MascotWidget), findsOneWidget);
    final mascot = tester.widget<MascotWidget>(find.byType(MascotWidget));
    expect(mascot.band, RiskBand.high);
  });
}
```

- [ ] **Run analyzer:** `flutter analyze lib/ui/today/today_screen.dart test/ui/today/today_screen_mascot_test.dart`
  - Expected: `No issues found!`
- [ ] **Run tests:** `flutter test test/ui/today/today_screen_mascot_test.dart test/ui/today/today_screen_test.dart`
  - Expected: `All tests passed!`
- [ ] **Commit:**
```bash
cd /Users/amansur/projects/migraine-forecast
git add lib/ui/today/today_screen.dart test/ui/today/today_screen_mascot_test.dart
git commit -m "feat(mascot): show MascotWidget above RiskDisplay on Today"
```

---

## Task 4 — AnimatedEntry wrapper + apply to cards/chips

**Files:**
- Create `lib/ui/shared/animations/animated_entry.dart`
- Modify `lib/ui/today/tomorrow_tile.dart`
- Modify `lib/ui/common/health_metrics_card.dart`
- Modify `lib/ui/today/why_chips.dart`
- Modify `lib/ui/today/contributor_chip.dart`
- Create (test) `test/ui/shared/animations/animated_entry_test.dart`

**Interfaces:**
- Produces:
  - `class AnimatedEntry extends StatefulWidget { const AnimatedEntry({super.key, required Widget child, Duration delay = Duration.zero, Duration duration = const Duration(milliseconds: 320), AnimatedEntryEffect effect = AnimatedEntryEffect.slideFade}); }`
  - `enum AnimatedEntryEffect { slideFade, scalePop }`
- Consumes: nothing app-specific.

### Steps

- [ ] **Create `lib/ui/shared/animations/animated_entry.dart`:**

```dart
import 'package:flutter/material.dart';

enum AnimatedEntryEffect { slideFade, scalePop }

/// Reusable on-appear animation. Slides up + fades in (cards) or scale-pops
/// (chips), with an optional [delay] for staggering siblings. Renders the
/// child instantly when [MediaQuery.disableAnimations] is true.
class AnimatedEntry extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final AnimatedEntryEffect effect;

  const AnimatedEntry({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 320),
    this.effect = AnimatedEntryEffect.slideFade,
  });

  @override
  State<AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<AnimatedEntry> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  bool _reducedResolved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reducedResolved) return;
    _reducedResolved = true;
    if (MediaQuery.of(context).disableAnimations) {
      _c.value = 1.0; // show instantly, no motion
    } else if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;

    final curved = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    switch (widget.effect) {
      case AnimatedEntryEffect.slideFade:
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
                .animate(curved),
            child: widget.child,
          ),
        );
      case AnimatedEntryEffect.scalePop:
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
            ),
            child: widget.child,
          ),
        );
    }
  }
}
```

- [ ] **Wrap `TomorrowTile`'s `Card`** in `lib/ui/today/tomorrow_tile.dart`. Add the import at the top:

```dart
import '../shared/animations/animated_entry.dart';
```

Then change the `return Card(` to wrap it:

```dart
    return AnimatedEntry(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/tomorrow'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: tomorrow.when(
              loading: () => const Center(child: SizedBox(
                width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2),
              )),
              error: (e, _) => Text('Tomorrow: --', style: Theme.of(context).textTheme.titleSmall),
              data: (ass) {
                final color = colorForBand(ass.band.name);
                return Row(
                  children: [
                    Container(
                      width: 14, height: 14,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Tomorrow: ${_label(ass.band)} (${ass.score})',
                          style: Theme.of(context).textTheme.titleSmall),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
```

- [ ] **Wrap `HealthMetricsCard`'s `Card`** in `lib/ui/common/health_metrics_card.dart`. Add the import:

```dart
import '../shared/animations/animated_entry.dart';
```

Change `return Card(` (the outermost one) to:

```dart
    return AnimatedEntry(
      delay: const Duration(milliseconds: 80),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
```

…and add the matching extra closing `)` for the `AnimatedEntry` at the end of that widget (the existing `return Card(...)` ends with `);` — add one more `)` before the `;`). The closing tail becomes:

```dart
            ],
          ),
        ),
      ),
    );
```

- [ ] **Stagger `WhyChips`** in `lib/ui/today/why_chips.dart`. Add the import:

```dart
import '../shared/animations/animated_entry.dart';
```

Replace the `.map(...).toList()` body of the inner `Column` with an indexed stagger using `scalePop`:

```dart
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < shown.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AnimatedEntry(
                  delay: Duration(milliseconds: 60 * i),
                  effect: AnimatedEntryEffect.scalePop,
                  child: ContributorChip(signal: shown[i]),
                ),
              ),
          ],
        ),
```

- [ ] **Pulse `ContributorChip`** in `lib/ui/today/contributor_chip.dart`. Add the import:

```dart
import '../shared/animations/animated_entry.dart';
```

Wrap the returned `DecoratedBox` with a gentle scale pulse on first appearance:

```dart
    return AnimatedEntry(
      effect: AnimatedEntryEffect.scalePop,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 8),
                child: Icon(_directionIcon(formatted), size: 16),
              ),
              Flexible(child: Text(formatted)),
            ],
          ),
        ),
      ),
    );
```

> Note: `WhyChips` already wraps each `ContributorChip` in a `scalePop` `AnimatedEntry`; the nested `AnimatedEntry` here is harmless (each just runs once) and covers `ContributorChip` used standalone elsewhere. Both short-circuit to the plain child under reduced motion.

- [ ] **Create `test/ui/shared/animations/animated_entry_test.dart`:**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/ui/shared/animations/animated_entry.dart';

void main() {
  testWidgets('renders child instantly under reduced motion (no transitions)', (tester) async {
    tester.binding.disableAnimations = true;
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: AnimatedEntry(child: Text('HELLO')),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('HELLO'), findsOneWidget);
    expect(find.byType(SlideTransition), findsNothing);
    expect(find.byType(FadeTransition), findsNothing);
  });

  testWidgets('animates in with slide+fade when motion enabled', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: AnimatedEntry(child: Text('HELLO')),
      ),
    ));
    expect(find.byType(SlideTransition), findsOneWidget);
    expect(find.byType(FadeTransition), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('HELLO'), findsOneWidget);
  });

  testWidgets('scalePop effect uses ScaleTransition', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: AnimatedEntry(effect: AnimatedEntryEffect.scalePop, child: Text('CHIP')),
      ),
    ));
    expect(find.byType(ScaleTransition), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
```

- [ ] **Run analyzer:** `flutter analyze lib/ui/shared/animations lib/ui/today/tomorrow_tile.dart lib/ui/today/why_chips.dart lib/ui/today/contributor_chip.dart lib/ui/common/health_metrics_card.dart test/ui/shared/animations`
  - Expected: `No issues found!`
- [ ] **Run tests:** `flutter test test/ui/shared/animations/ test/ui/today/tomorrow_tile_test.dart`
  - Expected: `All tests passed!`
- [ ] **Commit:**
```bash
cd /Users/amansur/projects/migraine-forecast
git add lib/ui/shared/animations/animated_entry.dart lib/ui/today/tomorrow_tile.dart lib/ui/common/health_metrics_card.dart lib/ui/today/why_chips.dart lib/ui/today/contributor_chip.dart test/ui/shared/animations/
git commit -m "feat(animations): AnimatedEntry slide/scale wrapper applied to cards and chips"
```

---

## Task 5 — CelebrationOverlay (confetti + mascot trigger)

**Files:**
- Create `lib/ui/shared/animations/celebration_overlay.dart`
- Create (test) `test/ui/shared/animations/celebration_overlay_test.dart`

**Interfaces:**
- Consumes: `MascotController` (Task 2), `BrandColors`/`colorForBand` (theme).
- Produces:
  - `class CelebrationOverlay { static void show(BuildContext context, {required MascotController controller}); static void showCheckmark(BuildContext context, {required MascotController controller}); }`
  - `class ConfettiPainter extends CustomPainter { ConfettiPainter({required List<_Confetto> pieces, required double t}); }` (private pieces, public painter for testability is not required — keep `ConfettiPainter` library-private).

### Steps

- [ ] **Create `lib/ui/shared/animations/celebration_overlay.dart`:**

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../mascot/mascot_widget.dart';

/// Fires a celebratory confetti burst as an [OverlayEntry] and triggers a
/// mascot wiggle. Under reduced motion the confetti is skipped but the mascot
/// still reacts.
class CelebrationOverlay {
  CelebrationOverlay._();

  static void show(BuildContext context, {required MascotController controller}) {
    controller.wiggle();
    if (MediaQuery.of(context).disableAnimations) return;
    _insert(context, checkmark: false);
  }

  /// Settings-style celebration: mascot blink + a small checkmark particle.
  static void showCheckmark(BuildContext context, {required MascotController controller}) {
    controller.blink();
    if (MediaQuery.of(context).disableAnimations) return;
    _insert(context, checkmark: true);
  }

  static void _insert(BuildContext context, {required bool checkmark}) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _CelebrationLayer(
        checkmark: checkmark,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _Confetto {
  final Offset start;
  final Offset velocity; // px/sec
  final Color color;
  final double radius;
  const _Confetto(this.start, this.velocity, this.color, this.radius);
}

class _CelebrationLayer extends StatefulWidget {
  final bool checkmark;
  final VoidCallback onDone;
  const _CelebrationLayer({required this.checkmark, required this.onDone});

  @override
  State<_CelebrationLayer> createState() => _CelebrationLayerState();
}

class _CelebrationLayerState extends State<_CelebrationLayer>
    with SingleTickerProviderStateMixin {
  static const _palette = <Color>[
    BrandColors.sage,
    BrandColors.ivory,
    BrandColors.bandLow,
    BrandColors.bandModerate,
    BrandColors.bandHigh,
    BrandColors.bandVeryHigh,
  ];

  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onDone();
        })
        ..forward();

  late final List<_Confetto> _pieces = _build();

  List<_Confetto> _build() {
    final rng = math.Random();
    final count = widget.checkmark ? 8 : (20 + rng.nextInt(11)); // 20–30
    return List.generate(count, (_) {
      final angle = -math.pi / 2 + (rng.nextDouble() - 0.5) * math.pi * 0.8;
      final speed = 220 + rng.nextDouble() * 260;
      return _Confetto(
        const Offset(0.5, 0.8), // fractional start: center-bottom
        Offset(math.cos(angle) * speed, math.sin(angle) * speed),
        _palette[rng.nextInt(_palette.length)],
        3 + rng.nextDouble() * 4,
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: widget.checkmark
              ? _CheckmarkPainter(t: _c.value)
              : _ConfettiPainter(pieces: _pieces, t: _c.value),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Confetto> pieces;
  final double t; // 0..1 over 1.2s
  _ConfettiPainter({required this.pieces, required this.t});

  static const _gravity = 900.0; // px/sec^2

  @override
  void paint(Canvas canvas, Size size) {
    final seconds = t * 1.2;
    final opacity = (1.0 - t).clamp(0.0, 1.0);
    for (final p in pieces) {
      final ox = p.start.dx * size.width;
      final oy = p.start.dy * size.height;
      final x = ox + p.velocity.dx * seconds;
      final y = oy + p.velocity.dy * seconds + 0.5 * _gravity * seconds * seconds;
      final paint = Paint()..color = p.color.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}

class _CheckmarkPainter extends CustomPainter {
  final double t;
  _CheckmarkPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.35);
    final scale = (t < 0.5 ? t * 2 : 1.0);
    final opacity = (1.0 - t).clamp(0.0, 1.0);
    final r = 26.0 * scale;
    final paint = Paint()
      ..color = BrandColors.sage.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, r, paint);
    final path = Path()
      ..moveTo(center.dx - r * 0.4, center.dy)
      ..lineTo(center.dx - r * 0.1, center.dy + r * 0.35)
      ..lineTo(center.dx + r * 0.45, center.dy - r * 0.35);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter old) => old.t != t;
}
```

- [ ] **Create `test/ui/shared/animations/celebration_overlay_test.dart`:**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/ui/shared/animations/celebration_overlay.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_widget.dart';

void main() {
  testWidgets('show triggers mascot wiggle and inserts a confetti layer', (tester) async {
    final controller = MascotController();
    MascotAction? seen;
    controller.addListener(() => seen = controller.pending);

    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Builder(builder: (c) {
        ctx = c;
        return const SizedBox.expand();
      })),
    ));

    CelebrationOverlay.show(ctx, controller: controller);
    await tester.pump();
    expect(seen, MascotAction.wiggle);
    expect(find.byType(CustomPaint), findsWidgets); // confetti overlay present

    await tester.pump(const Duration(milliseconds: 1300)); // overlay removes itself
  });

  testWidgets('reduced motion: no confetti layer, mascot still wiggles', (tester) async {
    tester.binding.disableAnimations = true;
    final controller = MascotController();
    MascotAction? seen;
    controller.addListener(() => seen = controller.pending);

    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Builder(builder: (c) {
        ctx = c;
        return const SizedBox.expand();
      })),
    ));

    CelebrationOverlay.show(ctx, controller: controller);
    await tester.pump();

    expect(seen, MascotAction.wiggle);
    // No IgnorePointer overlay layer was inserted.
    expect(find.byType(IgnorePointer), findsNothing);
  });

  testWidgets('showCheckmark triggers blink', (tester) async {
    tester.binding.disableAnimations = true; // skip particle, assert blink only
    final controller = MascotController();
    MascotAction? seen;
    controller.addListener(() => seen = controller.pending);

    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Builder(builder: (c) {
        ctx = c;
        return const SizedBox.expand();
      })),
    ));

    CelebrationOverlay.showCheckmark(ctx, controller: controller);
    await tester.pump();
    expect(seen, MascotAction.blink);
  });
}
```

- [ ] **Run analyzer:** `flutter analyze lib/ui/shared/animations/celebration_overlay.dart test/ui/shared/animations/celebration_overlay_test.dart`
  - Expected: `No issues found!`
- [ ] **Run tests:** `flutter test test/ui/shared/animations/celebration_overlay_test.dart`
  - Expected: `All tests passed!`
- [ ] **Commit:**
```bash
cd /Users/amansur/projects/migraine-forecast
git add lib/ui/shared/animations/celebration_overlay.dart test/ui/shared/animations/celebration_overlay_test.dart
git commit -m "feat(animations): CelebrationOverlay confetti + checkmark with reduced-motion"
```

---

## Task 6 — Wire celebrations into log screens

The log sheets/screens don't host a mascot, but `CelebrationOverlay.show` requires a `MascotController`. Each save site creates a short-lived `MascotController` (the wiggle no-ops harmlessly with no listening mascot; the confetti overlay is the visible payoff) and triggers the overlay on success **before** popping.

**Files:**
- Modify `lib/ui/log/journal_entry_sheet.dart`
- Modify `lib/ui/log/sleep_entry_sheet.dart`
- Modify `lib/ui/log/log_attack_screen.dart`
- Create (test) `test/ui/log/celebration_wiring_test.dart`

**Interfaces:**
- Consumes: `CelebrationOverlay.show` (Task 5), `MascotController` (Task 2).

### Steps

- [ ] **`journal_entry_sheet.dart`** — add the import:

```dart
import '../shared/animations/celebration_overlay.dart';
import '../shared/mascot/mascot_widget.dart';
```

Update `_save()` to celebrate before popping. Replace:

```dart
    if (entry.id == null) {
      await journal.addEntry(entry);
    } else {
      await journal.updateEntry(entry);
    }
    if (mounted) Navigator.of(context).pop(true);
```

with:

```dart
    final isNew = entry.id == null;
    if (isNew) {
      await journal.addEntry(entry);
    } else {
      await journal.updateEntry(entry);
    }
    if (!mounted) return;
    if (isNew) {
      CelebrationOverlay.show(context, controller: MascotController());
    }
    Navigator.of(context).pop(true);
```

- [ ] **`sleep_entry_sheet.dart`** — add the import:

```dart
import '../shared/animations/celebration_overlay.dart';
import '../shared/mascot/mascot_widget.dart';
```

Update `_save()`. Replace:

```dart
    await manual.upsert(SleepRecord(
      night: _night,
      sleepStart: _bed.toUtc(),
      totalSleep: _duration,
      efficiency: 1.0,
    ));
    if (mounted) Navigator.of(context).pop(true);
```

with:

```dart
    await manual.upsert(SleepRecord(
      night: _night,
      sleepStart: _bed.toUtc(),
      totalSleep: _duration,
      efficiency: 1.0,
    ));
    if (!mounted) return;
    CelebrationOverlay.show(context, controller: MascotController());
    Navigator.of(context).pop(true);
```

- [ ] **`log_attack_screen.dart`** — add the import:

```dart
import '../shared/animations/celebration_overlay.dart';
import '../shared/mascot/mascot_widget.dart';
```

In `_save()`, fire the celebration right before the `context.pop()`. Replace:

```dart
      if (mounted) {
        try {
          context.pop();
        } catch (_) {
          // No prior route in test environment — ignore
        }
      }
```

with:

```dart
      if (mounted) {
        CelebrationOverlay.show(context, controller: MascotController());
        try {
          context.pop();
        } catch (_) {
          // No prior route in test environment — ignore
        }
      }
```

- [ ] **Create `test/ui/log/celebration_wiring_test.dart`** verifying the journal sheet fires confetti on save. Use a fake journal source via provider override (mirror existing log tests' override style; inspect `test/ui/log/` for the exact provider). A minimal version:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/state/providers.dart';
import 'package:migraine_forecast/ui/log/journal_entry_sheet.dart';

class _FakeJournalSource implements JournalSource {
  final entries = <JournalEntry>[];
  @override
  Future<void> addEntry(JournalEntry e) async => entries.add(e);
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  testWidgets('saving a new journal entry shows a confetti overlay', (tester) async {
    final fake = _FakeJournalSource();
    await tester.pumpWidget(ProviderScope(
      overrides: [journalSourceProvider.overrideWithValue(fake)],
      child: const MaterialApp(
        home: Scaffold(body: JournalEntrySheet(kind: JournalKind.alcohol)),
      ),
    ));

    await tester.tap(find.byKey(const Key('alcohol-inc')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('entry-save')));
    await tester.pump(); // run _save() to the overlay insert

    expect(fake.entries, hasLength(1));
    // Confetti overlay inserted before pop.
    expect(find.byType(IgnorePointer), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1300));
  });
}
```

> If `JournalSource`'s interface makes `noSuchMethod` awkward, follow the exact fake/mock pattern already used in `test/ui/log/` (run `ls test/ui/log` and copy its journal source double). The assertion that matters is `find.byType(IgnorePointer)` (the celebration layer) being present after save.

- [ ] **Run analyzer:** `flutter analyze lib/ui/log test/ui/log/celebration_wiring_test.dart`
  - Expected: `No issues found!`
- [ ] **Run tests:** `flutter test test/ui/log/`
  - Expected: `All tests passed!`
- [ ] **Commit:**
```bash
cd /Users/amansur/projects/migraine-forecast
git add lib/ui/log/journal_entry_sheet.dart lib/ui/log/sleep_entry_sheet.dart lib/ui/log/log_attack_screen.dart test/ui/log/celebration_wiring_test.dart
git commit -m "feat(animations): celebrate on log save in journal, sleep, and attack screens"
```

---

## Task 7 — Wire onboarding + settings celebrations

**Files:**
- Modify `lib/ui/onboarding/onboarding_screen.dart`
- Modify `lib/ui/settings/settings_screen.dart`
- Create (test) `test/ui/onboarding/onboarding_mascot_test.dart`
- Create (test) `test/ui/settings/settings_celebration_test.dart`

**Interfaces:**
- Consumes: `MascotWidget`, `MascotController` (Task 2), `CelebrationOverlay.showCheckmark` (Task 5).

### Steps — Onboarding (mascot wave on completion)

- [ ] **Add imports** to `lib/ui/onboarding/onboarding_screen.dart`:

```dart
import '../shared/mascot/mascot_widget.dart';
```

- [ ] **Hold a controller** in `_OnboardingScreenState`. After `bool _isLoading = false;` add:

```dart
  final _mascot = MascotController();

  @override
  void dispose() {
    _mascot.dispose();
    super.dispose();
  }
```

- [ ] **Show an 80px mascot cameo.** In `build`, immediately after the `'You can change these any time in Settings.'` `Text(...)` widget, insert:

```dart
              const SizedBox(height: 12),
              Center(
                child: MascotWidget(band: RiskBand.low, size: 80, controller: _mascot),
              ),
```

- [ ] **Wave on finish.** In `_finish()`, after `await markDone();` and before the navigation, trigger the wave with a brief settle delay. Replace:

```dart
      // Wait for the provider to resolve before navigating, otherwise the router redirect will bounce us back
      await ref.read(onboardingCompletedProvider.future);
```

with:

```dart
      // Cheerful wave before we navigate away.
      _mascot.wave();
      if (!MediaQuery.of(context).disableAnimations) {
        await Future<void>.delayed(const Duration(milliseconds: 450));
      }

      // Wait for the provider to resolve before navigating, otherwise the router redirect will bounce us back
      await ref.read(onboardingCompletedProvider.future);
```

### Steps — Settings (blink + checkmark on save)

Settings has no single Save button; trigger fires whenever a trigger flag is saved (the `SwitchListTile.onChanged` calling `saveTriggerFlagsProvider`). Convert `SettingsScreen` to a `ConsumerStatefulWidget` to own a `MascotController`, render a small mascot cameo at the top, and celebrate after each successful flag save.

- [ ] **Add imports** to `lib/ui/settings/settings_screen.dart`:

```dart
import '../shared/animations/celebration_overlay.dart';
import '../shared/mascot/mascot_widget.dart';
```

- [ ] **Convert to a stateful widget.** Replace:

```dart
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagsAsync = ref.watch(triggerFlagsProvider);
    final modeAsync = ref.watch(riskDisplayModeProvider);
    final notifAsync = ref.watch(notificationsEnabledProvider);
```

with:

```dart
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _mascot = MascotController();

  @override
  void dispose() {
    _mascot.dispose();
    super.dispose();
  }

  void _celebrateSave() {
    if (!mounted) return;
    CelebrationOverlay.showCheckmark(context, controller: _mascot);
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final flagsAsync = ref.watch(triggerFlagsProvider);
    final modeAsync = ref.watch(riskDisplayModeProvider);
    final notifAsync = ref.watch(notificationsEnabledProvider);
```

> The `final ref = this.ref;` line lets the rest of the existing `build` body (which references a `ref` parameter) compile unchanged.

- [ ] **Add the mascot cameo** as the first child of the settings `ListView`. The current first child is `Text('Display', ...)`. Insert before it:

```dart
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MascotWidget(band: RiskBand.low, size: 80, controller: _mascot),
            ),
          ),
          Text('Display', style: Theme.of(context).textTheme.titleSmall),
```

- [ ] **Celebrate after each flag save.** In the trigger-flags `SwitchListTile.onChanged`, after the `await ref.read(saveTriggerFlagsProvider)(...)` call (the one inside `_moduleLabels.entries.map`), add `_celebrateSave();`. Replace:

```dart
                          await ref.read(saveTriggerFlagsProvider)(UserTriggerFlags(
                            flaggedModuleIds: next,
                            weightOverrides: flags.weightOverrides,
                          ));
                        },
```

with:

```dart
                          await ref.read(saveTriggerFlagsProvider)(UserTriggerFlags(
                            flaggedModuleIds: next,
                            weightOverrides: flags.weightOverrides,
                          ));
                          _celebrateSave();
                        },
```

- [ ] **Create `test/ui/onboarding/onboarding_mascot_test.dart`** verifying the 80px mascot cameo renders:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/ui/onboarding/onboarding_screen.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_widget.dart';

void main() {
  testWidgets('onboarding shows an 80px mascot cameo', (tester) async {
    tester.binding.disableAnimations = true;
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: OnboardingScreen()),
    ));
    await tester.pump();

    expect(find.byType(MascotWidget), findsOneWidget);
    final mascot = tester.widget<MascotWidget>(find.byType(MascotWidget));
    expect(mascot.size, 80);
    expect(mascot.band, RiskBand.low);
  });
}
```

- [ ] **Create `test/ui/settings/settings_celebration_test.dart`** verifying a flag toggle celebrates (blink + checkmark). Override `triggerFlagsProvider` and `saveTriggerFlagsProvider` per the pattern in `test/ui/settings/`. Skeleton:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/state/trigger_flags_provider.dart';
import 'package:migraine_forecast/ui/settings/settings_screen.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_widget.dart';

void main() {
  testWidgets('toggling a trigger flag celebrates (mascot present, no crash)', (tester) async {
    tester.binding.disableAnimations = true; // checkmark particle skipped; blink still fires
    await tester.pumpWidget(ProviderScope(
      overrides: [
        triggerFlagsProvider.overrideWith((ref) async => const UserTriggerFlags(flaggedModuleIds: {})),
        saveTriggerFlagsProvider.overrideWithValue((UserTriggerFlags _) async {}),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(MascotWidget), findsOneWidget);

    // Expand the first trigger ExpansionTile and toggle its switch.
    await tester.tap(find.text('Pressure changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I think this triggers me'));
    await tester.pump();

    // No exception thrown; mascot still present after celebrate.
    expect(find.byType(MascotWidget), findsOneWidget);
  });
}
```

> Match the exact override signatures used in existing `test/ui/settings/` tests (run `ls test/ui/settings` and copy their provider doubles) — `saveTriggerFlagsProvider` may be a function-typed provider; adjust `overrideWithValue` accordingly.

- [ ] **Run analyzer:** `flutter analyze lib/ui/onboarding/onboarding_screen.dart lib/ui/settings/settings_screen.dart test/ui/onboarding/onboarding_mascot_test.dart test/ui/settings/settings_celebration_test.dart`
  - Expected: `No issues found!`
- [ ] **Run tests:** `flutter test test/ui/onboarding/ test/ui/settings/`
  - Expected: `All tests passed!`
- [ ] **Run the whole suite** to confirm nothing regressed: `flutter test`
  - Expected: `All tests passed!`
- [ ] **Commit:**
```bash
cd /Users/amansur/projects/migraine-forecast
git add lib/ui/onboarding/onboarding_screen.dart lib/ui/settings/settings_screen.dart test/ui/onboarding/onboarding_mascot_test.dart test/ui/settings/settings_celebration_test.dart
git commit -m "feat(animations): mascot wave on onboarding complete; blink + checkmark on settings save"
```

---

## Final verification

- [ ] `flutter analyze` → `No issues found!`
- [ ] `flutter test` → `All tests passed!`
- [ ] Manual smoke (optional, per memory note — run in the main repo, not a worktree): launch the app, confirm the mascot idles on Today, morphs on band change, confetti fires on a journal save, and that toggling OS "Reduce Motion" makes the mascot static with no confetti.

---

## Self-Review

**1. Spec coverage**

| Spec requirement | Task |
|---|---|
| Blob body per band (4 bezier points, 60% band color) | 1 |
| Accessories: petals / cat ears / bunny ears / bee antennae | 1 |
| Expressions per band (eyes, brow, cheeks, sweat, mouth) | 1 |
| Golden test per band | 1 |
| Idle float + breathe loop | 2 |
| Pause/resume idle on app background/foreground | 2 |
| Band-change morph via `didUpdateWidget` + TweenAnimationBuilder over bezier points | 2 |
| Happy wiggle, wave, blink one-shots | 2 (controller), 5–7 (triggers) |
| `MascotWidget({band, size=160, onWiggle})` public interface | 2 (plus `controller`) |
| Reduced-motion static render | 2 |
| Mascot above RiskDisplay on Today, current band | 3 |
| Cameos at 80px (onboarding, settings) | 7 |
| `AnimatedEntry` slide+fade, stagger | 4 |
| Applied to TomorrowTile, HealthMetricsCard, WhyChips, ContributorChip | 4 |
| Reduced-motion instant show | 4 |
| `CelebrationOverlay` confetti (20–30, BrandColors, gravity, 1.2s fade) | 5 |
| `CelebrationOverlay.show(context, {required MascotController controller})` | 5 |
| Reduced-motion: skip confetti, still wiggle | 5 |
| Celebrate on journal/sleep/attack save | 6 |
| Onboarding wave; settings blink + checkmark | 7 |
| `risk_display.dart` untouched | confirmed (no task modifies it) |
| No new packages | confirmed (pubspec unchanged) |

**2. Placeholder scan** — Every code-bearing step contains real Dart. Two tasks (6, 7) instruct copying an existing test double's exact override signature where the provider shape isn't visible in this plan's source reads; the load-bearing assertion (`IgnorePointer`/`MascotWidget` present) is concrete. No "TBD", "TODO", or "similar to above" remain.

**3. Type consistency** — `MascotController` (Task 2) `wiggle/wave/blink/pending/ackConsumed` are used exactly as defined in Tasks 5–7. `CelebrationOverlay.show` / `.showCheckmark` signatures match call sites. `BlobShape`/`MascotFace`/`BlobPainter`/`MascotAccessoriesPainter` signatures from Task 1 are used unchanged in Task 2. `AnimatedEntry({child, delay, duration, effect})` and `AnimatedEntryEffect` from Task 4 match all application sites.

**4. Reduced motion** — Covered in Task 2 (`MascotWidget` short-circuits idle/morph/quiver), Task 4 (`AnimatedEntry` returns plain child), and Task 5 (`CelebrationOverlay` skips confetti, still triggers mascot). Tests assert each path.

**Resolved gaps / deviations (flagged inline):**
- The spec's `onWiggle` VoidCallback can't itself be an *inbound* trigger; reconciled by adding `MascotController` for inbound triggers and keeping `onWiggle` as an outbound completion callback (Task 2).
- The spec suggested reusing `_TodayScreenState`'s `WidgetsBindingObserver` for idle pause/resume; we instead made `MascotWidget` self-manage lifecycle for encapsulation (Task 2/3) — documented as an intentional deviation.
- Settings has no single "Save" button, so the celebration fires per successful trigger-flag save and required converting `SettingsScreen` to a `ConsumerStatefulWidget` to host the controller (Task 7).

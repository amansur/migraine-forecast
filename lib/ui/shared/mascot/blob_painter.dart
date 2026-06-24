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
    const handle = 0.55;
    final hx = rx * handle;
    final hy = ry * handle;

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
    const eyeColor = Color(0xFF2E3A2E); // BrandColors.ink

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

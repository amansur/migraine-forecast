import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

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

/// Paints just the kawaii face (eyes, brow, blush, mouth, sweat) centred in the
/// given [Size]. The body is now an SVG drawn beneath this painter, so this
/// painter no longer draws a blob or applies a body tint.
class MascotFacePainter extends CustomPainter {
  final MascotFace face;

  /// Eye openness for blink: 1 = fully open, 0 = closed line.
  final double eyeOpen;

  MascotFacePainter({required this.face, this.eyeOpen = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2;
    final rx = r;
    final ry = r;

    final eyeDx = rx * 0.28;
    final eyeY = c.dy - ry * 0.10;
    final eyeR = rx * 0.14;
    const eyeColor = Color(0xFF2E3A2E);

    for (final sign in [-1.0, 1.0]) {
      final center = Offset(c.dx + sign * eyeDx, eyeY);
      if (eyeOpen <= 0.05) {
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
          Rect.fromCenter(
            center: center,
            width: eyeR * 2,
            height: eyeR * 2.2 * eyeOpen,
          ),
          Paint()..color = eyeColor,
        );
        canvas.drawCircle(
          Offset(center.dx + eyeR * 0.32, center.dy - eyeR * 0.38),
          eyeR * 0.38,
          Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9),
        );
      }
    }

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
  bool shouldRepaint(covariant MascotFacePainter old) =>
      old.face.browAngle != face.browAngle ||
      old.face.mouthOpen != face.mouthOpen ||
      old.face.blush != face.blush ||
      old.face.sweat != face.sweat ||
      old.eyeOpen != eyeOpen;
}

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

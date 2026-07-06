import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../mascot/mascot_widget.dart';

/// Fires a celebratory confetti burst as an [OverlayEntry] and triggers a
/// mascot wiggle. Under reduced motion the confetti is skipped but the mascot
/// still reacts.
class CelebrationOverlay {
  CelebrationOverlay._();

  static void show(BuildContext context, {MascotController? controller}) {
    controller?.wiggle();
    if (MediaQuery.of(context).disableAnimations) return;
    _insert(context, checkmark: false);
  }

  /// Settings-style celebration: mascot wiggle + a small checkmark particle.
  static void showCheckmark(BuildContext context, {required MascotController controller}) {
    controller.wiggle();
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

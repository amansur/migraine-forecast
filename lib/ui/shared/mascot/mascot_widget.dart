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

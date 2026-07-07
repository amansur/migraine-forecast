import 'dart:math' as math;

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../../state/mascot_pool.dart';

enum MascotAction { wiggle, wave }

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
  /// Tap-to-cycle offset within the band pool; 0 = the daily seeded pick.
  final int cycleOffset;

  const MascotWidget({
    super.key,
    required this.band,
    this.size = 160,
    this.controller,
    this.onWiggle,
    this.cycleOffset = 0,
  });

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _idle;
  late final AnimationController _action; // wiggle / wave one-shots
  MascotAction _activeAction = MascotAction.wiggle;
  // Resolved once in _playAction so a mid-flight cycle-tap can't switch style.
  WiggleStyle _activeStyle = WiggleStyle.squish;

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
    // Part 1 fix: if a wiggle is in flight when the displayed mascot changes
    // (cycle tap or band change), re-pin the style to the new asset so the
    // outgoing mascot's style doesn't bleed into the incoming mascot's action.
    if ((old.cycleOffset != widget.cycleOffset || old.band != widget.band) &&
        _action.isAnimating &&
        _activeAction == MascotAction.wiggle) {
      _activeStyle = wiggleStyleFor(_assetPath);
      _action.duration = (_activeStyle == WiggleStyle.stretch)
          ? const Duration(milliseconds: 700)
          : const Duration(milliseconds: 500);
    }
  }

  void _onControllerAction() {
    final pending = widget.controller?.pending;
    if (pending != null) _playAction(pending);
  }

  String get _assetPath =>
      mascotAssetFor(widget.band, offset: widget.cycleOffset);

  void _playAction(MascotAction action) {
    _activeAction = action;
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
          switch (_activeStyle) {
            case WiggleStyle.squish:
              squish = 0.22 * pulse;
            case WiggleStyle.flutter:
              // ~3 oscillations of ±12° (0.21 rad), damped to zero.
              flick = math.sin(t * math.pi * 6) * 0.21 * (1 - t);
            case WiggleStyle.stretch:
              stretch = 0.30 * pulse;
            case WiggleStyle.bob:
              bobY = 14.0 * pulse;
              squish = 0.12 * pulse;
          }
        case MascotAction.wave:
          sway = pulse;
      }
    }

    final assetPath = _assetPath;

    return AnimatedBuilder(
      animation: _idle,
      builder: (context, _) {
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

        // Wave = gentle rotation (+/-5deg); flutter adds its own flicks.
        final rotation = sway * 0.0873 + flick;
        final netSquish = squish + idleSquish - stretch;
        final scaleX = breathe * (1 + netSquish * 0.5);
        final scaleY = breathe * (1 - netSquish * 0.5);

        return Transform.translate(
          offset: Offset(idleDx, floatY + bobY),
          child: Transform.rotate(
            angle: idleRot,
            alignment: Alignment.bottomCenter,
            child: Transform.rotate(
              angle: rotation,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(scaleX, scaleY, 1),
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: AnimatedSwitcher(
                    duration: reduce ? Duration.zero : const Duration(milliseconds: 200),
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
          ),
        );
      },
    );
  }
}

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'mascot_character.dart';
import 'mascot_face_painter.dart';

enum MascotAction { wiggle, wave, blink }

/// Pre-caches all 16 mascot SVGs into the flutter_svg picture cache so the first
/// render does not flash. Call once from `main()` after binding init.
Future<void> precacheMascots() async {
  for (final path in allMascotAssetPaths()) {
    final loader = SvgAssetLoader(path);
    await svg.cache.putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
  }
}

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
  final MascotCharacter character;
  final double size;
  final MascotController? controller;
  final VoidCallback? onWiggle;

  const MascotWidget({
    super.key,
    required this.band,
    this.character = kDefaultMascotCharacter,
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

  late MascotFace _targetFace;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _targetFace = MascotFace.forBand(widget.band);

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
    if (old.band != widget.band) {
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

    if (reduce && _idle.isAnimating) {
      _idle.stop();
    }

    // One-shot action math (instant under reduced motion -> t jumps to 1).
    final t = reduce ? 1.0 : _action.value;
    double squish = 0; // wiggle: scaleX up, scaleY down
    double eyeOpen = 1;
    double sway = 0; // wave: gentle rotation
    final playing = _action.isAnimating || (!reduce && _action.value > 0 && _action.value < 1);
    if (playing) {
      switch (_activeAction) {
        case MascotAction.wiggle:
          squish = 0.18 * (1 - (2 * t - 1).abs());
        case MascotAction.wave:
          sway = (1 - (2 * t - 1).abs());
        case MascotAction.blink:
          eyeOpen = (2 * t - 1).abs();
      }
    }

    final assetPath = mascotAssetPath(widget.character, widget.band);

    return AnimatedBuilder(
      animation: _idle,
      builder: (context, _) {
        final phase = reduce ? 0.0 : _idle.value;
        final floatY = reduce ? 0.0 : (-3.0 + 6.0 * phase);
        final breathe = reduce ? 1.0 : (1.0 + 0.015 * (phase - 0.5).abs() * 2);

        // Wave = gentle rotation (+/-5deg). Wiggle = horizontal squish.
        final rotation = sway * 0.0873; // ~5 degrees in radians
        final scaleX = breathe * (1 + squish * 0.5);
        final scaleY = breathe * (1 - squish * 0.5);

        return Transform.translate(
          offset: Offset(0, floatY),
          child: Transform.rotate(
            angle: rotation,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(scaleX, scaleY, 1),
              child: TweenAnimationBuilder<MascotFace>(
                tween: _MascotFaceTween(end: _targetFace),
                duration: reduce ? Duration.zero : const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                builder: (context, face, __) {
                  return SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AnimatedSwitcher(
                          duration: reduce ? Duration.zero : const Duration(milliseconds: 200),
                          child: SvgPicture.asset(
                            assetPath,
                            key: ValueKey(assetPath),
                            width: widget.size,
                            height: widget.size,
                            fit: BoxFit.contain,
                          ),
                        ),
                        CustomPaint(
                          painter: MascotFacePainter(face: face, eyeOpen: eyeOpen),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MascotFaceTween extends Tween<MascotFace> {
  _MascotFaceTween({required MascotFace end}) : super(end: end);
  @override
  MascotFace lerp(double t) => MascotFace.lerp(begin ?? end!, end!, t);
}

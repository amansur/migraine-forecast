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

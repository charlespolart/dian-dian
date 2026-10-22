import 'package:flutter/material.dart';

import '../theme/motion.dart';

enum AppearStyle {
  /// Fade in while rising 10 px (the list's cascade).
  rise,
  /// Fade in while growing 0.8 → 1 (a card that just appeared).
  pop,
  none,
}

/// One-shot entrance of [child] over [AppMotion.base], after [delay].
/// The decision to animate is the parent's: the widget plays whatever style
/// it is given on its first build and must keep it (change the style and the
/// animation restarts or vanishes).
class Appear extends StatelessWidget {
  final AppearStyle style;
  final Duration delay;
  final Widget child;

  const Appear({super.key, required this.style, this.delay = Duration.zero, required this.child});

  @override
  Widget build(BuildContext context) {
    if (style == AppearStyle.none || AppMotion.reduced(context)) return child;
    final total = delay + AppMotion.base;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(delay.inMilliseconds / total.inMilliseconds, 1, curve: AppMotion.enter),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: style == AppearStyle.rise
            ? Transform.translate(offset: Offset(0, 10 * (1 - t)), child: child)
            : Transform.scale(scale: 0.8 + 0.2 * t, child: child),
      ),
    );
  }
}

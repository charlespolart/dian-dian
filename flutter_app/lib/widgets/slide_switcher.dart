import 'package:flutter/material.dart';

import '../theme/motion.dart';

/// Swaps [child] (which must carry a key, the year or the step) with a short
/// slide: the leaving child moves [distance] px against [direction] and
/// fades, the entering one arrives from the [direction] side. 0 is a plain
/// cross-fade. [expand] sizes the stage to its parent, for a `GridView`.
class SlideSwitcher extends StatelessWidget {
  final Widget child;
  final int direction;
  final double distance;
  final bool expand;

  const SlideSwitcher({
    super.key,
    required this.child,
    required this.direction,
    this.distance = 24,
    this.expand = false,
  });

  /// Where the entering child starts (and the leaving one ends, mirrored).
  static Offset enterFrom(int direction, double distance) => Offset(direction.sign * distance, 0);

  @override
  Widget build(BuildContext context) {
    final from = enterFrom(direction, distance);
    return AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.base),
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      layoutBuilder: (current, previous) => Stack(
        fit: expand ? StackFit.expand : StackFit.loose,
        alignment: Alignment.center,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) {
        // The leaving child's animation runs 1 → 0: the same formula sends it the other way.
        final entering = child.key == this.child.key;
        final start = entering ? from : -from;
        return FadeTransition(
          opacity: animation,
          child: AnimatedBuilder(
            animation: animation,
            child: child,
            builder: (context, child) => Transform.translate(
              offset: start * (1 - animation.value),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

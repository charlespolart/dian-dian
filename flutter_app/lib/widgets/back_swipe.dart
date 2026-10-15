import 'package:flutter/material.dart';

/// iOS-style "swipe from the left edge to go back" for the app's own screen
/// stack (there is no Navigator route per screen). A pointer that lands in
/// the [edgeWidth] band and travels at least [minDistance] to the right,
/// more horizontally than vertically, calls [onBack]. Translucent: taps and
/// the year swipes in the middle of the screen are untouched.
class BackSwipe extends StatefulWidget {
  final Widget child;
  final VoidCallback? onBack;

  static const double edgeWidth = 24;
  static const double minDistance = 60;

  const BackSwipe({super.key, required this.child, required this.onBack});

  @override
  State<BackSwipe> createState() => _BackSwipeState();
}

class _BackSwipeState extends State<BackSwipe> {
  Offset? _start;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _start = e.localPosition.dx <= BackSwipe.edgeWidth ? e.localPosition : null;
      },
      onPointerCancel: (_) => _start = null,
      onPointerUp: (e) {
        final start = _start;
        _start = null;
        if (start == null) return;
        final dx = e.localPosition.dx - start.dx;
        final dy = (e.localPosition.dy - start.dy).abs();
        if (dx >= BackSwipe.minDistance && dx > dy) widget.onBack?.call();
      },
      child: widget.child,
    );
  }
}

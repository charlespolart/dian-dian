import 'package:flutter/material.dart';

/// A navigation row with left/right arrows and a center label.
/// Supports both tap on arrows and horizontal swipe.
///
/// Gesture logic:
/// - Tracks initial touch position
/// - On release: if finger moved >30px horizontally → swipe (prev/next based on direction)
/// - On release: if finger stayed near start → tap (prev/next based on which arrow zone)
/// - Otherwise: nothing
class SwipeNav extends StatefulWidget {
  final Widget center;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final double arrowSize;
  final Color? arrowColor;
  final EdgeInsets arrowPadding;

  const SwipeNav({
    super.key,
    required this.center,
    required this.onPrev,
    required this.onNext,
    this.arrowSize = 16,
    this.arrowColor,
    this.arrowPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  State<SwipeNav> createState() => _SwipeNavState();
}

class _SwipeNavState extends State<SwipeNav> {
  Offset? _start;

  void _onDown(DragDownDetails details) {
    _start = details.localPosition;
  }

  void _onEnd(DragEndDetails details) {
    if (_start == null) return;
    _start = null;

    // Swipe: use velocity
    final v = details.primaryVelocity ?? 0;
    if (v < -50) {
      widget.onNext();
    } else if (v > 50) {
      widget.onPrev();
    }
  }

  void _onCancel() {
    _start = null;
  }

  // For pure taps (no drag detected by the gesture system),
  // we use onTapUp with the tap position.
  void _onTap(TapUpDetails details) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final x = details.localPosition.dx;
    final w = box.size.width;
    if (x < w * 0.35) {
      widget.onPrev();
    } else if (x > w * 0.65) {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Drag handles swipe
      onHorizontalDragDown: _onDown,
      onHorizontalDragEnd: _onEnd,
      onHorizontalDragCancel: _onCancel,
      // Tap handles static press on arrows
      onTapUp: _onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: widget.arrowPadding,
            child: Text('<', style: TextStyle(fontSize: widget.arrowSize, color: widget.arrowColor)),
          ),
          widget.center,
          Padding(
            padding: widget.arrowPadding,
            child: Text('>', style: TextStyle(fontSize: widget.arrowSize, color: widget.arrowColor)),
          ),
        ],
      ),
    );
  }
}

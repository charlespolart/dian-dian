import 'package:flutter/material.dart';

/// A navigation row with left/right arrows and a center label.
/// Supports both tap on arrows and horizontal swipe.
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
  Offset? _downPos;
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _downPos = e.localPosition;
        _handled = false;
      },
      onPointerUp: (e) {
        if (_downPos == null || _handled) return;
        final dx = e.localPosition.dx - _downPos!.dx;
        final dy = (e.localPosition.dy - _downPos!.dy).abs();
        _downPos = null;

        // Horizontal swipe
        if (dx.abs() > 40 && dx.abs() > dy) {
          if (dx < 0) {
            widget.onNext();
          } else {
            widget.onPrev();
          }
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _handled = true;
              widget.onPrev();
            },
            child: Padding(
              padding: widget.arrowPadding,
              child: Text('<', style: TextStyle(fontSize: widget.arrowSize, color: widget.arrowColor)),
            ),
          ),
          widget.center,
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _handled = true;
              widget.onNext();
            },
            child: Padding(
              padding: widget.arrowPadding,
              child: Text('>', style: TextStyle(fontSize: widget.arrowSize, color: widget.arrowColor)),
            ),
          ),
        ],
      ),
    );
  }
}

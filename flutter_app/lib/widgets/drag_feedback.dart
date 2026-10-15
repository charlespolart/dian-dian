import 'package:flutter/material.dart';

/// What follows the finger while reordering (legend rows, tracker cards):
/// a copy of the item, a little smaller, lifted by a soft shadow, sized like
/// the original so it reads as "the thing I picked up".
class DragFeedback extends StatelessWidget {
  final double width;
  final double? height;
  final double radius;
  final Widget child;

  static const double scale = 0.92;

  const DragFeedback({
    super.key,
    required this.width,
    this.height,
    required this.radius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: const [
              BoxShadow(color: Color(0x2A000000), blurRadius: 12, offset: Offset(0, 5)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

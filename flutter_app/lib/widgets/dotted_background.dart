import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DottedBackground extends StatelessWidget {
  final Widget child;

  const DottedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedPainter(),
      child: child,
    );
  }
}

class _DottedPainter extends CustomPainter {
  static const double _spacing = 24.0;
  static const double _radius = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    // Background fill
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppColors.bg,
    );

    // Dots — a dot at the centre of the screen and the grid growing from it,
    // so margins are equal on both sides and the native launch screens, which
    // draw the same grid centred the same way, hand over without a jump.
    final dotPaint = Paint()..color = AppColors.bgDot;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final cols = (cx / _spacing).floor();
    final rows = (cy / _spacing).floor();

    for (int c = -cols; c <= cols; c++) {
      final x = cx + c * _spacing;
      for (int r = -rows; r <= rows; r++) {
        final y = cy + r * _spacing;
        canvas.drawCircle(Offset(x, y), _radius, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

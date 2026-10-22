import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Days in [month] of [year] (Gregorian).
int daysInMonth(int month, int year) {
  if (month == 2) {
    final isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    return isLeap ? 29 : 28;
  }
  if (month == 4 || month == 6 || month == 9 || month == 11) return 30;
  return 31;
}

/// The card preview: 12 columns × 31 rows of dots inside a 3 px pad,
/// stretched to the box (the steps are not square), each dot 0.42 of the
/// smaller step in radius. The one source of truth for the preview painter
/// and for the card → tracker morph.
class MiniGridGeometry {
  static const double pad = 3;

  final double stepX;
  final double stepY;
  final double radius;

  const MiniGridGeometry({required this.stepX, required this.stepY, required this.radius});

  factory MiniGridGeometry.of(Size size) {
    final stepX = (size.width - pad * 2) / 12;
    final stepY = (size.height - pad * 2) / 31;
    return MiniGridGeometry(stepX: stepX, stepY: stepY, radius: math.min(stepX, stepY) * 0.42);
  }

  /// Centre of the dot of (month, day), in the preview's own coordinates.
  Offset center({required int month, required int day}) =>
      Offset(pad + stepX * (month - 1) + stepX / 2, pad + stepY * (day - 1) + stepY / 2);
}

/// The tracker grid: one label column on the left, one header row on top,
/// square cells with a dot of [dotSize]. The one source of truth for
/// `TrackerGrid` and for the card → tracker morph.
class TrackerGridGeometry {
  final double labelColWidth;
  final double cellSize;
  final double rowHeight;
  final double dotSize;

  const TrackerGridGeometry({
    required this.labelColWidth,
    required this.cellSize,
    required this.rowHeight,
    required this.dotSize,
  });

  double get radius => dotSize / 2;

  /// 1 label column + 12 months wide, 1 header row + 31 days tall.
  Size get size => Size(labelColWidth + cellSize * 12, rowHeight * 32);

  /// Centre of the dot of (month, day), in the grid's own coordinates.
  Offset center({required int month, required int day}) =>
      Offset(labelColWidth + cellSize * (month - 1) + cellSize / 2, rowHeight * day + rowHeight / 2);
}

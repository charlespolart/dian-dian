import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/widgets/grid_geometry.dart';

void main() {
  group('MiniGridGeometry', () {
    test('matches the card preview: 3 px pad, 12 × 31 steps, radius 0.42 of the smaller step', () {
      final g = MiniGridGeometry.of(const Size(126, 316)); // 120 × 310 inside the pad
      expect(g.stepX, 10);
      expect(g.stepY, 10);
      expect(g.radius, closeTo(4.2, 1e-9));
      expect(g.center(month: 1, day: 1), const Offset(3 + 5, 3 + 5));
      expect(g.center(month: 12, day: 31), const Offset(3 + 115, 3 + 305));
    });
  });

  group('TrackerGridGeometry', () {
    test('cell centres: one label column on the left, one header row on top', () {
      const g = TrackerGridGeometry(labelColWidth: 20, cellSize: 18, rowHeight: 18, dotSize: 14);
      expect(g.center(month: 1, day: 1), const Offset(20 + 9, 18 + 9));
      expect(g.center(month: 12, day: 31), const Offset(20 + 18 * 11 + 9, 18 * 31 + 9));
      expect(g.size, const Size(20 + 18 * 12, 18 * 32));
      expect(g.radius, 7);
    });
  });
}

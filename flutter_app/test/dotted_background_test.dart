import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/widgets/dotted_background.dart';

void main() {
  // The native launch screens draw the same grid centred on the screen, with
  // a dot at the centre: Flutter's grid must have one there too, whatever the
  // screen size, or the dots jump by half a step when the first frame lands.
  PaintPattern dotAt(double x, double y) =>
      paints..something((method, args) => method == #drawCircle && args[0] == Offset(x, y) && args[1] == 2.0);

  for (final size in const [Size(393, 852), Size(430, 932), Size(375, 812), Size(1032, 1376)]) {
    testWidgets('a dot sits at the centre of a ${size.width.toInt()}×${size.height.toInt()} screen, and the grid grows from it', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const DottedBackground(child: SizedBox.expand()));
      final paint = tester.renderObject(find.byType(CustomPaint));
      final cx = size.width / 2, cy = size.height / 2;
      expect(paint, dotAt(cx, cy));
      expect(paint, dotAt(cx - 24, cy + 24));
      expect(paint, dotAt(cx + 24, cy - 24));
    });
  }
}

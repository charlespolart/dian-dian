import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/widgets/grid_geometry.dart';
import 'package:dian_dian/widgets/morph_layer.dart';

void main() {
  const geo = TrackerGridGeometry(labelColWidth: 20, cellSize: 18, rowHeight: 18, dotSize: 14);
  const ends = MorphEnds(
    card: Rect.fromLTWH(20, 40, 60, 120),
    cardScreen: Rect.fromLTWH(25, 60, 50, 95),
    cardGrid: Rect.fromLTWH(26, 61, 48, 93),
    cardTitle: Rect.fromLTWH(30, 44, 40, 12),
    cardLegends: Rect.fromLTWH(30, 58, 40, 8),
    shell: Rect.fromLTWH(0, 100, 300, 700),
    screen: Rect.fromLTWH(8, 108, 284, 684),
    grid: Rect.fromLTWH(60, 120, 236, 576),
    gridGeometry: geo,
    barTitle: Rect.fromLTWH(40, 10, 200, 20),
  );

  test('dots sit on the preview at g = 0 and on the tracker grid at g = 1', () {
    final mini = MiniGridGeometry.of(ends.cardGrid.size);
    expect(MorphLayer.dotCenter(ends, month: 3, day: 7, g: 0), ends.cardGrid.topLeft + mini.center(month: 3, day: 7));
    expect(MorphLayer.dotCenter(ends, month: 3, day: 7, g: 1), ends.grid.topLeft + geo.center(month: 3, day: 7));
    expect(MorphLayer.dotRadius(ends, g: 0), mini.radius);
    expect(MorphLayer.dotRadius(ends, g: 1), geo.radius);
  });

  test('the frame and the screen go from the card to the tracker', () {
    expect(MorphLayer.frame(ends, g: 0), ends.card);
    expect(MorphLayer.frame(ends, g: 1), ends.shell);
    expect(MorphLayer.screenFrame(ends, g: 0.5), Rect.lerp(ends.cardScreen, ends.screen, 0.5));
  });

  testWidgets('paints the layer and carries the title between its two places', (tester) async {
    const content = MorphContent(title: 'Mood', cells: null, year: 2026, legendColors: [Color(0xFFFF0000)]);
    await tester.pumpWidget(const MaterialApp(
      home: Stack(fit: StackFit.expand, children: [MorphLayer(ends: ends, content: content, g: 0.5, legendsOpacity: 1)]),
    ));
    expect(find.byType(MorphLayer), findsOneWidget);
    expect(find.text('Mood'), findsOneWidget);
    final titleBox = tester.getRect(find.ancestor(of: find.text('Mood'), matching: find.byType(FittedBox)).first);
    expect(titleBox.left, closeTo(Rect.lerp(ends.cardTitle, ends.barTitle, 0.5)!.left, 0.5));
  });
}

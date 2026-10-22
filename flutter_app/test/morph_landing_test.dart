import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/models/page_model.dart';
import 'package:dian_dian/screens/page_list_screen.dart';
import 'package:dian_dian/widgets/morph_anchors.dart';
import 'package:dian_dian/widgets/tracker_grid.dart';

import 'helpers.dart';

/// The morph's "identical at both ends" rests on the anchors the real widgets
/// register: these tests hold the real card and the real grid against them.
void main() {
  testWidgets('the card registers its preview grid exactly inside its 1 px preview frame, and its title', (tester) async {
    final anchors = MorphAnchors();
    final page = PageModel.fromJson(pageJson('p', title: 'Mood'));
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: SizedBox(
          width: 160,
          height: 350,
          child: PageCard(anchors: anchors, page: page, year: 2026, cells: null, legends: const [], onTap: () {}, onDelete: () {}),
        ),
      ),
    ));
    final card = anchors.rect(MorphAnchors.card('p'))!;
    final screen = anchors.rect(MorphAnchors.cardScreen('p'))!;
    final grid = anchors.rect(MorphAnchors.cardGrid('p'))!;
    expect(card.size, const Size(160, 350));
    expect(grid, screen.deflate(1));
    expect(anchors.rect(MorphAnchors.cardTitle('p')), isNotNull);
    expect(anchors.rect(MorphAnchors.cardLegends('p')), isNotNull);
  });

  testWidgets('the grid registers a geometry whose cell centres are the real dots', (tester) async {
    final anchors = MorphAnchors();
    await tester.pumpWidget(MaterialApp(
      home: Center(
        // Loose constraints, as the tracker's Center gives the grid.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260, maxHeight: 640),
          child: TrackerGrid(anchors: anchors, year: 2026, getCellColor: (_, _) => null, onCellPress: (_, _, _) {}),
        ),
      ),
    ));
    final grid = anchors.rect(MorphAnchors.grid)!;
    final geometry = anchors.gridGeometry!;
    expect(grid.size, geometry.size);
    // Dots come in tree order, one row per day, 12 per row: (month 3, day 7) is the 75th.
    final dot = find.byType(GestureDetector).at(6 * 12 + 2);
    final real = tester.getCenter(dot);
    final predicted = grid.topLeft + geometry.center(month: 3, day: 7);
    expect(predicted.dx, closeTo(real.dx, 0.01));
    expect(predicted.dy, closeTo(real.dy, 0.01));
  });
}

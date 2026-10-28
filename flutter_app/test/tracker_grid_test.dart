import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/models/cell_change.dart';
import 'package:dian_dian/theme/app_theme.dart';
import 'package:dian_dian/widgets/tracker_grid.dart';

void main() {
  Widget host({required void Function(int month, int day, Offset at) onPress}) => MaterialApp(
        home: Center(
          child: SizedBox(
            width: 260,
            height: 640,
            child: TrackerGrid(year: 2026, getCellColor: (_, _) => null, onCellPress: onPress),
          ),
        ),
      );

  testWidgets('a tap on a day reports month, day and where the finger was', (tester) async {
    final calls = <(int, int, Offset)>[];
    await tester.pumpWidget(host(onPress: (m, d, at) => calls.add((m, d, at))));
    // The first dot in tree order is January 1st (the header row has no detector).
    final jan1 = find.byType(GestureDetector).first;
    final center = tester.getCenter(jan1);
    await tester.tap(jan1);
    expect(calls, [(1, 1, center)]);
  });

  testWidgets('the labels live in one fading layer, at their places next to the dots, and never take a tap', (tester) async {
    final calls = <(int, int, Offset)>[];
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: SizedBox(
          width: 260,
          height: 640,
          child: TrackerGrid(
            year: 2026,
            getCellColor: (_, _) => null,
            onCellPress: (m, d, at) => calls.add((m, d, at)),
            chrome: const AlwaysStoppedAnimation(0.0),
          ),
        ),
      ),
    ));
    // Dots come in tree order, rows of 12: February 15th is (15 - 1) * 12 + 1.
    final feb15 = find.byType(GestureDetector).at(14 * 12 + 1);
    expect(tester.getCenter(find.text('15')).dy, closeTo(tester.getCenter(feb15).dy, 0.01));
    expect(tester.getCenter(find.text('F')).dx, closeTo(tester.getCenter(feb15).dx, 0.01));
    // One layer for all of them, driven by [chrome].
    FadeTransition fadeOf(String label) =>
        tester.widget<FadeTransition>(find.ancestor(of: find.text(label), matching: find.byType(FadeTransition)).first);
    expect(fadeOf('15').opacity.value, 0);
    expect(identical(fadeOf('15'), fadeOf('F')), isTrue);
    // The layer sits over the dots but never takes their taps.
    await tester.tap(feb15);
    expect(calls, [(2, 15, tester.getCenter(feb15))]);
  });

  group('cellCenter', () {
    test('January 1st and December 31st', () {
      const c = (labelColWidth: 20.0, cellSize: 18.0, rowHeight: 18.0);
      expect(TrackerGrid.cellCenter(month: 1, day: 1, labelColWidth: c.labelColWidth, cellSize: c.cellSize, rowHeight: c.rowHeight),
          const Offset(20 + 9, 18 + 9));
      expect(TrackerGrid.cellCenter(month: 12, day: 31, labelColWidth: c.labelColWidth, cellSize: c.cellSize, rowHeight: c.rowHeight),
          const Offset(20 + 18 * 11 + 9, 18 * 31 + 9));
    });
  });

  testWidgets('a commented cell is drawn as a ring: a hole of the screen colour at its centre, a third of the dot; plain cells have none', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: SizedBox(
          width: 260,
          height: 640,
          child: TrackerGrid(
            year: 2026,
            getCellColor: (m, d) => (m == 2 && d == 5) || (m == 3 && d == 1) ? '#FF0000' : null,
            hasComment: (m, d) => m == 2 && d == 5,
            onCellPress: (_, _, _) {},
          ),
        ),
      ),
    ));
    final holes = find.byKey(const Key('dot.comment'));
    expect(holes, findsOneWidget, reason: 'one commented cell, one hole');
    final dot = find.ancestor(of: holes, matching: find.byType(Container)).first;
    expect(tester.getSize(holes).width, closeTo(tester.getSize(dot).width * 0.34, 0.01));
    expect(tester.getCenter(holes), tester.getCenter(dot));
    final deco = tester.widget<Container>(holes).decoration! as BoxDecoration;
    expect(deco.shape, BoxShape.circle);
    expect(deco.color, Color.alphaBlend(AppColors.screen, AppColors.shell), reason: 'the hole shows the screen behind the dot');
  });

  // The popped cell is filled (a fill pop over an empty cell draws nothing).
  Widget popHost(CellChange? pop) => MaterialApp(
        home: Center(
          child: SizedBox(
            width: 260,
            height: 640,
            child: TrackerGrid(
              year: 2026,
              getCellColor: (m, d) => m == 2 && d == 5 ? '#FF0000' : null,
              onCellPress: (_, _, _) {},
              pop: pop,
            ),
          ),
        ),
      );

  testWidgets('exactly one DotPop for the changed cell, none without a change', (tester) async {
    await tester.pumpWidget(popHost(null));
    expect(find.byType(DotPop), findsNothing);
    await tester.pumpWidget(popHost(const CellChange(pageId: 'a', year: 2026, month: 2, day: 5, color: '#FF0000', erased: false, seq: 1)));
    await tester.pump();
    expect(find.byType(DotPop), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(DotPop), findsOneWidget);
  });

  testWidgets('the pop over a commented cell carries the hole too: it stays over the dot after its bounce and must not hide the ring', (tester) async {
    const pop = CellChange(pageId: 'a', year: 2026, month: 2, day: 5, color: '#FF0000', erased: false, seq: 1);
    Widget host({required bool commented}) => MaterialApp(
          home: Center(
            child: SizedBox(
              width: 260,
              height: 640,
              child: TrackerGrid(
                year: 2026,
                getCellColor: (m, d) => m == 2 && d == 5 ? '#FF0000' : null,
                hasComment: (m, d) => commented && m == 2 && d == 5,
                onCellPress: (_, _, _) {},
                pop: pop,
              ),
            ),
          ),
        );
    final popHole = find.descendant(of: find.byType(DotPop), matching: find.byKey(const Key('dot.comment')));
    await tester.pumpWidget(host(commented: true));
    await tester.pumpAndSettle();
    expect(find.byType(DotPop), findsOneWidget);
    expect(popHole, findsOneWidget, reason: 'the pop is drawn like the dot it covers');
    await tester.pumpWidget(host(commented: false));
    await tester.pumpAndSettle();
    expect(popHole, findsNothing);
  });

  testWidgets('a change on another year draws nothing', (tester) async {
    await tester.pumpWidget(popHost(const CellChange(pageId: 'a', year: 2025, month: 2, day: 5, color: '#FF0000', erased: false, seq: 1)));
    expect(find.byType(DotPop), findsNothing);
  });

  testWidgets('the pop follows the cell\'s current colour (a recolor right after the tap), and vanishes with the cell', (tester) async {
    const pop = CellChange(pageId: 'a', year: 2026, month: 2, day: 5, color: '#FF0000', erased: false, seq: 1);
    Widget host(String? Function(int, int) colorOf) => MaterialApp(
          home: Center(
            child: SizedBox(
              width: 260,
              height: 640,
              child: TrackerGrid(year: 2026, getCellColor: colorOf, onCellPress: (_, _, _) {}, pop: pop),
            ),
          ),
        );
    await tester.pumpWidget(host((m, d) => m == 2 && d == 5 ? '#00FF00' : null));
    await tester.pumpAndSettle();
    expect(tester.widget<DotPop>(find.byType(DotPop)).color, const Color(0xFF00FF00));
    await tester.pumpWidget(host((_, _) => null));
    await tester.pump();
    expect(find.byType(DotPop), findsNothing);
  });
}

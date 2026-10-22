import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/models/cell_change.dart';
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

  group('cellCenter', () {
    test('January 1st and December 31st', () {
      const c = (labelColWidth: 20.0, cellSize: 18.0, rowHeight: 18.0);
      expect(TrackerGrid.cellCenter(month: 1, day: 1, labelColWidth: c.labelColWidth, cellSize: c.cellSize, rowHeight: c.rowHeight),
          const Offset(20 + 9, 18 + 9));
      expect(TrackerGrid.cellCenter(month: 12, day: 31, labelColWidth: c.labelColWidth, cellSize: c.cellSize, rowHeight: c.rowHeight),
          const Offset(20 + 18 * 11 + 9, 18 * 31 + 9));
    });
  });

  Widget popHost(CellChange? pop) => MaterialApp(
        home: Center(
          child: SizedBox(
            width: 260,
            height: 640,
            child: TrackerGrid(year: 2026, getCellColor: (_, _) => null, onCellPress: (_, _, _) {}, pop: pop),
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

  testWidgets('a change on another year draws nothing', (tester) async {
    await tester.pumpWidget(popHost(const CellChange(pageId: 'a', year: 2025, month: 2, day: 5, color: '#FF0000', erased: false, seq: 1)));
    expect(find.byType(DotPop), findsNothing);
  });
}

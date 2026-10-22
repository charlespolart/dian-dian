import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}

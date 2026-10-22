import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/models/page_model.dart';
import 'package:dian_dian/screens/page_list_screen.dart';

void main() {
  test('entranceDelay: 30 ms per card for the first 12, none after', () {
    expect(entranceDelay(0), Duration.zero);
    expect(entranceDelay(3), const Duration(milliseconds: 90));
    expect(entranceDelay(11), const Duration(milliseconds: 330));
    expect(entranceDelay(12), isNull);
  });

  test('gridMetrics matches SliverGridDelegateWithMaxCrossAxisExtent on a phone', () {
    final m = gridMetrics(360);
    expect(m.columns, 2);
    expect(m.rowExtent, closeTo(368.9, 0.1));
  });

  test('revealScrollOffset: 0 for a row already on screen, just enough otherwise', () {
    expect(revealScrollOffset(index: 1, columns: 2, rowExtent: 300, spacing: 12, viewportHeight: 600, topPadding: 8), 0);
    // Row 2 (index 4) spans 8 + 2 × 312 = 632 → 932; a 600 px viewport must scroll 932 − 600 + 12.
    expect(revealScrollOffset(index: 4, columns: 2, rowExtent: 300, spacing: 12, viewportHeight: 600, topPadding: 8), 344);
  });

  testWidgets('PageCard.frozen has no delete cross and ignores taps', (tester) async {
    final page = PageModel.fromJson({
      'id': 'p', 'userId': 'u', 'title': 'T', 'year': 2026, 'position': 0, 'palette': null,
      'createdAt': '', 'recentCells': 0, 'lastCellAt': null, 'keepFree': false,
    });
    await tester.pumpWidget(MaterialApp(
      home: Center(child: SizedBox(width: 160, height: 350, child: PageCard.frozen(page: page, year: 2026, cells: null, legends: const [], isLocked: false))),
    ));
    expect(find.byIcon(Icons.close), findsNothing);
    await tester.tap(find.byType(PageCard));
    await tester.pump();
    expect(find.text('T'), findsOneWidget);
  });
}

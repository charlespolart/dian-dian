import 'package:flutter_test/flutter_test.dart';

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
}

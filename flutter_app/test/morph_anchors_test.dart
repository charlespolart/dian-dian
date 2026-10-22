import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/theme/motion.dart';
import 'package:dian_dian/widgets/grid_geometry.dart';
import 'package:dian_dian/widgets/morph_anchors.dart';
import 'package:dian_dian/widgets/slide_switcher.dart';

void main() {
  testWidgets('rects of mounted anchors by key, null for an unknown key or an unmounted one', (tester) async {
    final anchors = MorphAnchors();
    Widget tree({required bool withCard}) => MaterialApp(
          home: Stack(children: [
            if (withCard)
              Positioned(
                left: 10,
                top: 20,
                child: MorphAnchor(anchors: anchors, anchorKey: 'card:p', child: const SizedBox(width: 30, height: 40)),
              ),
            Positioned(
              left: 100,
              top: 200,
              child: MorphAnchor(anchors: anchors, anchorKey: MorphAnchors.shell, child: const SizedBox(width: 50, height: 60)),
            ),
          ]),
        );
    await tester.pumpWidget(tree(withCard: true));
    expect(anchors.rect('card:p'), const Rect.fromLTWH(10, 20, 30, 40));
    expect(anchors.rect(MorphAnchors.shell), const Rect.fromLTWH(100, 200, 50, 60));
    expect(anchors.rect('absent'), isNull);
    await tester.pumpWidget(tree(withCard: false));
    expect(anchors.rect('card:p'), isNull);
    expect(anchors.rect(MorphAnchors.shell), isNotNull);
  });

  testWidgets('a grid anchor carries its geometry', (tester) async {
    final anchors = MorphAnchors();
    const geometry = TrackerGridGeometry(labelColWidth: 20, cellSize: 18, rowHeight: 18, dotSize: 14);
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: MorphAnchor.grid(anchors: anchors, geometry: geometry, child: const SizedBox(width: 236, height: 576)),
      ),
    ));
    expect(anchors.rect(MorphAnchors.grid)?.size, const Size(236, 576));
    expect(anchors.gridGeometry, same(geometry));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(anchors.gridGeometry, isNull);
  });

  testWidgets('the list year slide keeps both grids whole: no duplicate key, the newest card wins', (tester) async {
    final anchors = MorphAnchors();
    var year = 2025;
    late StateSetter rebuild;
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(builder: (context, setState) {
        rebuild = setState;
        return SlideSwitcher(
          direction: 1,
          expand: true,
          child: KeyedSubtree(
            key: ValueKey(year),
            child: Column(children: [
              MorphAnchor(anchors: anchors, anchorKey: 'card:p', child: Text('card $year')),
            ]),
          ),
        );
      }),
    ));
    rebuild(() => year = 2026);
    await tester.pump();
    await tester.pump(AppMotion.base ~/ 2);
    expect(tester.takeException(), isNull);
    expect(find.text('card 2025'), findsOneWidget);
    expect(find.text('card 2026'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('card 2025'), findsNothing);
    expect(anchors.rect('card:p'), isNotNull);
  });
}

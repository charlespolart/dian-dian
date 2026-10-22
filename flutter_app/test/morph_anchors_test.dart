import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/theme/motion.dart';
import 'package:dian_dian/widgets/morph_anchors.dart';
import 'package:dian_dian/widgets/slide_switcher.dart';

void main() {
  testWidgets('rects of mounted anchors, null for an unknown id or an unmounted one', (tester) async {
    final anchors = MorphAnchors();
    Widget tree({required bool withCard}) => MaterialApp(
          home: Stack(children: [
            if (withCard)
              Positioned(
                left: 10,
                top: 20,
                child: MorphAnchor.card(anchors: anchors, pageId: 'p', child: const SizedBox(width: 30, height: 40)),
              ),
            Positioned(
              left: 100,
              top: 200,
              child: MorphAnchor.shell(anchors: anchors, child: const SizedBox(width: 50, height: 60)),
            ),
          ]),
        );
    await tester.pumpWidget(tree(withCard: true));
    expect(anchors.cardRect('p'), const Rect.fromLTWH(10, 20, 30, 40));
    expect(anchors.shellRect(), const Rect.fromLTWH(100, 200, 50, 60));
    expect(anchors.cardRect('absent'), isNull);
    await tester.pumpWidget(tree(withCard: false));
    expect(anchors.cardRect('p'), isNull);
    expect(anchors.shellRect(), isNotNull);
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
              MorphAnchor.card(anchors: anchors, pageId: 'p', child: Text('card $year')),
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
    expect(anchors.cardRect('p'), isNotNull);
  });
}

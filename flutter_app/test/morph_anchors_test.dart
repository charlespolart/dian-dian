import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/widgets/morph_anchors.dart';

void main() {
  testWidgets('rects of laid-out keys, null for a key with no element', (tester) async {
    final anchors = MorphAnchors();
    await tester.pumpWidget(MaterialApp(
      home: Stack(children: [
        Positioned(left: 10, top: 20, child: SizedBox(key: anchors.cardKey('p'), width: 30, height: 40)),
        Positioned(left: 100, top: 200, child: SizedBox(key: anchors.shell, width: 50, height: 60)),
      ]),
    ));
    expect(anchors.cardRect('p'), const Rect.fromLTWH(10, 20, 30, 40));
    expect(anchors.shellRect(), const Rect.fromLTWH(100, 200, 50, 60));
    expect(anchors.cardRect('absent'), isNull);
    expect(anchors.cardKey('p'), same(anchors.cardKey('p')));
  });
}

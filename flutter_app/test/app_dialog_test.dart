import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/theme/motion.dart';
import 'package:dian_dian/widgets/app_dialog.dart';

void main() {
  group('originAlignment', () {
    const size = Size(400, 800);
    test('centre, corners, and never outside the screen', () {
      expect(originAlignment(const Offset(200, 400), size), Alignment.center);
      expect(originAlignment(Offset.zero, size), Alignment.topLeft);
      expect(originAlignment(const Offset(400, 800), size), Alignment.bottomRight);
      final a = originAlignment(const Offset(399, 1), size);
      expect(a.x, inInclusiveRange(-1, 1));
      expect(a.y, inInclusiveRange(-1, 1));
    });
  });

  Widget host({Offset? origin, bool reduced = false}) => MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAppDialog<void>(
                context: context,
                origin: origin,
                builder: (ctx) => TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('box')),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );

  /// Smallest scale among the Transforms above the dialog's text (1 when settled).
  double scaleAbove(WidgetTester tester, String text) {
    final transforms = find.ancestor(of: find.text(text), matching: find.byType(Transform));
    var scale = 1.0;
    for (final t in tester.widgetList<Transform>(transforms)) {
      final s = t.transform.entry(0, 0);
      if (s < scale) scale = s;
    }
    return scale;
  }

  testWidgets('enters over base (scale under 1 midway, 1 when settled)', (tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(AppMotion.base ~/ 2);
    expect(find.text('box'), findsOneWidget);
    expect(scaleAbove(tester, 'box'), lessThan(1));
    await tester.pumpAndSettle();
    expect(scaleAbove(tester, 'box'), 1);
  });

  testWidgets('leaves over quick, not longer', (tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('box'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('box'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('box'), findsNothing);
  });

  testWidgets('an origin anchors the scale there (not the centre)', (tester) async {
    await tester.pumpWidget(host(origin: const Offset(10, 10)));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(AppMotion.base ~/ 2);
    final transforms = find.ancestor(of: find.text('box'), matching: find.byType(Transform));
    final anchored = tester.widgetList<Transform>(transforms).any((t) => t.alignment != null && t.alignment != Alignment.center);
    expect(anchored, isTrue);
  });

  testWidgets('reduced motion: there at once, gone at once', (tester) async {
    await tester.pumpWidget(host(reduced: true));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump();
    expect(find.text('box'), findsOneWidget);
    expect(scaleAbove(tester, 'box'), 1);
    await tester.tap(find.text('box'));
    await tester.pump();
    await tester.pump();
    expect(find.text('box'), findsNothing);
  });
}

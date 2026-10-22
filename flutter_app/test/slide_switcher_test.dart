import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/theme/motion.dart';
import 'package:dian_dian/widgets/slide_switcher.dart';

class _Host extends StatefulWidget {
  const _Host();
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String label = 'a';
  int direction = 1;

  void show(String next, int dir) => setState(() {
        label = next;
        direction = dir;
      });

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Center(
          child: SlideSwitcher(
            direction: direction,
            child: Text(label, key: ValueKey(label)),
          ),
        ),
      );
}

void main() {
  test('enterFrom has the sign of the direction', () {
    expect(SlideSwitcher.enterFrom(1, 24), const Offset(24, 0));
    expect(SlideSwitcher.enterFrom(-1, 24), const Offset(-24, 0));
    expect(SlideSwitcher.enterFrom(0, 24), Offset.zero);
  });

  double dx(WidgetTester tester, String text) {
    final t = tester.widget<Transform>(find.ancestor(of: find.text(text), matching: find.byType(Transform)).first);
    return t.transform.getTranslation().x;
  }

  testWidgets('the entering child comes from the direction side, the leaving one goes the other way', (tester) async {
    await tester.pumpWidget(const _Host());
    tester.state<_HostState>(find.byType(_Host)).show('b', 1);
    await tester.pump();
    await tester.pump(AppMotion.base ~/ 2);
    expect(dx(tester, 'b'), greaterThan(0));
    expect(dx(tester, 'a'), lessThan(0));
    await tester.pumpAndSettle();
    expect(find.text('a'), findsNothing);
    expect(dx(tester, 'b'), 0);
  });

  testWidgets('direction -1 mirrors it', (tester) async {
    await tester.pumpWidget(const _Host());
    tester.state<_HostState>(find.byType(_Host)).show('b', -1);
    await tester.pump();
    await tester.pump(AppMotion.base ~/ 2);
    expect(dx(tester, 'b'), lessThan(0));
    expect(dx(tester, 'a'), greaterThan(0));
  });
}

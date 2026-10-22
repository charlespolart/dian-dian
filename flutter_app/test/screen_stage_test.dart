import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/theme/motion.dart';
import 'package:dian_dian/widgets/morph_anchors.dart';
import 'package:dian_dian/widgets/screen_stage.dart';

/// Two fake screens: 'list' holds a card anchored as page 'p', 'tracker'
/// holds a shell; anything else is plain text.
class _Host extends StatefulWidget {
  final MorphAnchors anchors;
  final bool reduced;
  const _Host({required this.anchors, this.reduced = false});
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String screen = 'list';
  StageTransition transition = StageTransition.fade;
  int settled = 0;

  void go(String next, StageTransition t) => setState(() {
        screen = next;
        transition = t;
      });

  Widget _screen(String name) => switch (name) {
        'list' => Stack(key: const ValueKey('list'), children: [
            Positioned(left: 20, top: 40, child: SizedBox(key: widget.anchors.cardKey('p'), width: 60, height: 120, child: const Text('list'))),
          ]),
        'tracker' => Center(key: const ValueKey('tracker'), child: SizedBox(key: widget.anchors.shell, width: 200, height: 400, child: const Text('tracker'))),
        'bare' => const Center(key: ValueKey('bare'), child: Text('bare')),
        _ => Center(key: ValueKey(name), child: Text(name)),
      };

  @override
  Widget build(BuildContext context) => MediaQuery(
        data: MediaQueryData(disableAnimations: widget.reduced),
        child: MaterialApp(
          home: ScreenStage(
            transition: transition,
            anchors: widget.anchors,
            morphPageId: 'p',
            morphCard: (_) => const Text('copy'),
            onSettled: () => settled++,
            child: _screen(screen),
          ),
        ),
      );
}

void main() {
  _HostState state(WidgetTester tester) => tester.state<_HostState>(find.byType(_Host));

  testWidgets('fade: both screens midway, only the new one once settled', (tester) async {
    await tester.pumpWidget(_Host(anchors: MorphAnchors()));
    state(tester).go('bare', StageTransition.fade);
    await tester.pump();
    await tester.pump(AppMotion.base ~/ 2);
    expect(find.text('list'), findsOneWidget);
    expect(find.text('bare'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('list'), findsNothing);
    expect(find.text('bare'), findsOneWidget);
    expect(state(tester).settled, 1);
  });

  testWidgets('morphOpen: a shell between the card and the tracker shell, gone at the end', (tester) async {
    await tester.pumpWidget(_Host(anchors: MorphAnchors()));
    state(tester).go('tracker', StageTransition.morphOpen);
    await tester.pump(); // measure frame: tracker laid out invisible
    await tester.pump(); // animation starts
    await tester.pump(AppMotion.screen ~/ 8);
    // Early on, the card's copy is still visible inside the shell.
    expect(find.byType(MorphShell), findsOneWidget);
    expect(find.text('copy'), findsOneWidget);
    await tester.pump(AppMotion.screen ~/ 4);
    final shell = tester.getRect(find.byType(MorphShell));
    expect(shell.width, greaterThan(60));
    expect(shell.width, lessThan(200));
    await tester.pumpAndSettle();
    expect(find.byType(MorphShell), findsNothing);
    expect(find.text('list'), findsNothing);
    expect(find.text('tracker'), findsOneWidget);
  });

  testWidgets('morphClose ends on the list with no shell left', (tester) async {
    await tester.pumpWidget(_Host(anchors: MorphAnchors()));
    state(tester).go('tracker', StageTransition.morphOpen);
    await tester.pumpAndSettle();
    state(tester).go('list', StageTransition.morphClose);
    await tester.pump();
    await tester.pump();
    await tester.pump(AppMotion.screen ~/ 2);
    expect(find.byType(MorphShell), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(MorphShell), findsNothing);
    expect(find.text('tracker'), findsNothing);
    expect(find.text('list'), findsOneWidget);
  });

  testWidgets('morphOpen without a shell to measure falls back to a fade', (tester) async {
    await tester.pumpWidget(_Host(anchors: MorphAnchors()));
    state(tester).go('bare', StageTransition.morphOpen);
    await tester.pump();
    await tester.pump();
    await tester.pump(AppMotion.base ~/ 2);
    expect(find.byType(MorphShell), findsNothing);
    expect(find.text('bare'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('list'), findsNothing);
  });

  testWidgets('a navigation mid-transition ends it and fades to the newest screen', (tester) async {
    await tester.pumpWidget(_Host(anchors: MorphAnchors()));
    state(tester).go('tracker', StageTransition.morphOpen);
    await tester.pump();
    await tester.pump();
    await tester.pump(AppMotion.screen ~/ 3);
    state(tester).go('bare', StageTransition.slideIn);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(MorphShell), findsNothing);
    expect(find.text('bare'), findsOneWidget);
    expect(find.text('tracker'), findsNothing);
    expect(find.text('list'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a resize mid-transition jumps to the end', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_Host(anchors: MorphAnchors()));
    state(tester).go('bare', StageTransition.slideIn);
    await tester.pump();
    await tester.pump(AppMotion.base ~/ 3);
    tester.view.physicalSize = const Size(1200, 800);
    await tester.pump();
    await tester.pump();
    expect(find.text('list'), findsNothing);
    expect(find.text('bare'), findsOneWidget);
  });

  testWidgets('reduced motion: the screen is swapped at once', (tester) async {
    await tester.pumpWidget(_Host(anchors: MorphAnchors(), reduced: true));
    state(tester).go('tracker', StageTransition.morphOpen);
    await tester.pump();
    expect(find.text('list'), findsNothing);
    expect(find.text('tracker'), findsOneWidget);
    expect(find.byType(MorphShell), findsNothing);
  });
}

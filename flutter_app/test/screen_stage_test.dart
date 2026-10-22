import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/theme/motion.dart';
import 'package:dian_dian/widgets/grid_geometry.dart';
import 'package:dian_dian/widgets/morph_anchors.dart';
import 'package:dian_dian/widgets/morph_layer.dart';
import 'package:dian_dian/widgets/screen_stage.dart';

/// How many times each screen's State was created: a screen must keep its
/// element while it moves from current to outgoing.
final Map<String, int> inits = {};

class _Counting extends StatefulWidget {
  final String name;
  final Widget child;
  const _Counting(this.name, {super.key, required this.child});
  @override
  State<_Counting> createState() => _CountingState();
}

class _CountingState extends State<_Counting> {
  @override
  void initState() {
    super.initState();
    inits[widget.name] = (inits[widget.name] ?? 0) + 1;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

const _geometry = TrackerGridGeometry(labelColWidth: 20, cellSize: 10, rowHeight: 10, dotSize: 7.8);
const _content = MorphContent(title: 'T', cells: null, year: 2026, legendColors: []);

/// Two fake screens with every anchor the morph needs: 'list' holds the
/// card of page 'p' (frame, preview frame, preview grid), 'tracker' holds a
/// shell, a screen and a grid with its geometry; 'bare' has no anchor.
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

  Widget _screen(String name) {
    final a = widget.anchors;
    return _Counting(
      name,
      key: ValueKey(name),
      child: switch (name) {
        'list' => Stack(children: [
            Positioned(
              left: 20,
              top: 40,
              child: MorphAnchor(
                anchors: a,
                anchorKey: MorphAnchors.card('p'),
                child: SizedBox(
                  width: 60,
                  height: 120,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: MorphAnchor(
                      anchors: a,
                      anchorKey: MorphAnchors.cardScreen('p'),
                      child: Padding(
                        padding: const EdgeInsets.all(1),
                        child: MorphAnchor(anchors: a, anchorKey: MorphAnchors.cardGrid('p'), child: const SizedBox.expand(child: Text('list'))),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        'tracker' => Center(
            child: MorphAnchor(
              anchors: a,
              anchorKey: MorphAnchors.shell,
              child: SizedBox(
                width: 200,
                height: 400,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: MorphAnchor(
                    anchors: a,
                    anchorKey: MorphAnchors.screen,
                    child: Center(
                      child: MorphAnchor.grid(anchors: a, geometry: _geometry, child: const SizedBox(width: 140, height: 320, child: Text('tracker'))),
                    ),
                  ),
                ),
              ),
            ),
          ),
        _ => Center(child: Text(name)),
      },
    );
  }

  @override
  Widget build(BuildContext context) => MediaQuery(
        data: MediaQueryData(disableAnimations: widget.reduced),
        child: MaterialApp(
          home: ScreenStage(
            transition: transition,
            anchors: widget.anchors,
            morphPageId: 'p',
            morphContent: _content,
            onSettled: () => settled++,
            child: _screen(screen),
          ),
        ),
      );
}

void main() {
  _HostState state(WidgetTester tester) => tester.state<_HostState>(find.byType(_Host));
  double morphG(WidgetTester tester) => tester.widget<MorphLayer>(find.byType(MorphLayer)).g;

  setUp(() {
    inits.clear();
    AppMotion.debugMorphSlowdown = 1; // the inspection knob never shapes a test
  });

  testWidgets('a screen keeps its state through a fade and through a morph (no re-inflation)', (tester) async {
    await tester.pumpWidget(_Host(anchors: MorphAnchors()));
    expect(inits, {'list': 1});
    state(tester).go('bare', StageTransition.fade);
    await tester.pump();
    await tester.pump(AppMotion.base ~/ 2);
    await tester.pumpAndSettle();
    expect(inits, {'list': 1, 'bare': 1});
    state(tester).go('list', StageTransition.fade);
    await tester.pumpAndSettle();
    state(tester).go('tracker', StageTransition.morphOpen);
    await tester.pump(); // measure frame
    await tester.pump();
    await tester.pump(AppMotion.screen ~/ 2);
    await tester.pumpAndSettle();
    expect(inits, {'list': 2, 'bare': 1, 'tracker': 1});
    state(tester).go('list', StageTransition.morphClose);
    await tester.pumpAndSettle();
    expect(inits, {'list': 3, 'bare': 1, 'tracker': 1});
  });

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

  testWidgets('morphOpen: the layer goes from the card (g = 0) to the tracker (g = 1), then leaves', (tester) async {
    await tester.pumpWidget(_Host(anchors: MorphAnchors()));
    state(tester).go('tracker', StageTransition.morphOpen);
    await tester.pump(); // measure frame: tracker laid out invisible
    expect(find.byType(MorphLayer), findsNothing);
    await tester.pump(); // ends known, the layer is drawn
    expect(morphG(tester), closeTo(0, 0.01));
    await tester.pump(AppMotion.screen ~/ 2);
    expect(morphG(tester), closeTo(0.5, 0.05)); // the test binding's frame bookkeeping shifts t by a few ms
    await tester.pumpAndSettle();
    expect(find.byType(MorphLayer), findsNothing);
    expect(find.text('list'), findsNothing);
    expect(find.text('tracker'), findsOneWidget);
  });

  testWidgets('the morph answers the tap on its very next frame: g has moved after two frames', (tester) async {
    await tester.pumpWidget(_Host(anchors: MorphAnchors()));
    state(tester).go('tracker', StageTransition.morphOpen);
    await tester.pump(AppMotion.screen ~/ 4); // the measure frame is already the first animation frame
    await tester.pump(AppMotion.screen ~/ 4);
    expect(morphG(tester), greaterThan(0.05));
    await tester.pumpAndSettle();
    expect(find.byType(MorphLayer), findsNothing);
    expect(find.text('tracker'), findsOneWidget);
  });

  testWidgets('morphClose: the layer goes from the tracker (g = 1) back to the card, then the list is alone', (tester) async {
    await tester.pumpWidget(_Host(anchors: MorphAnchors()));
    state(tester).go('tracker', StageTransition.morphOpen);
    await tester.pumpAndSettle();
    state(tester).go('list', StageTransition.morphClose);
    await tester.pump();
    await tester.pump();
    expect(morphG(tester), closeTo(1, 0.01));
    await tester.pump(AppMotion.screen ~/ 2);
    expect(morphG(tester), closeTo(0.5, 0.05)); // the test binding's frame bookkeeping shifts t by a few ms
    await tester.pumpAndSettle();
    expect(find.byType(MorphLayer), findsNothing);
    expect(find.text('tracker'), findsNothing);
    expect(find.text('list'), findsOneWidget);
  });

  testWidgets('morphOpen towards a screen without anchors falls back to a fade', (tester) async {
    await tester.pumpWidget(_Host(anchors: MorphAnchors()));
    state(tester).go('bare', StageTransition.morphOpen);
    await tester.pump();
    await tester.pump();
    await tester.pump(AppMotion.base ~/ 2);
    expect(find.byType(MorphLayer), findsNothing);
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
    expect(find.byType(MorphLayer), findsNothing);
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
    expect(find.byType(MorphLayer), findsNothing);
  });
}

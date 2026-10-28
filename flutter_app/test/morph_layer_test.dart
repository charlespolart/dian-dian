import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/models/cell_model.dart';
import 'package:dian_dian/models/year_cells.dart';
import 'package:dian_dian/theme/app_theme.dart';
import 'package:dian_dian/widgets/grid_geometry.dart';
import 'package:dian_dian/widgets/morph_layer.dart';

void main() {
  const geo = TrackerGridGeometry(labelColWidth: 20, cellSize: 18, rowHeight: 18, dotSize: 14);
  const ends = MorphEnds(
    card: Rect.fromLTWH(20, 40, 60, 120),
    cardScreen: Rect.fromLTWH(25, 60, 50, 95),
    cardGrid: Rect.fromLTWH(26, 61, 48, 93),
    cardTitle: Rect.fromLTWH(30, 44, 40, 12),
    cardLegends: Rect.fromLTWH(30, 58, 40, 8),
    shell: Rect.fromLTWH(0, 100, 300, 700),
    screen: Rect.fromLTWH(8, 108, 284, 684),
    grid: Rect.fromLTWH(60, 120, 236, 576),
    gridGeometry: geo,
    barTitle: Rect.fromLTWH(40, 10, 200, 20),
  );

  test('dots sit on the preview at g = 0 and on the tracker grid at g = 1', () {
    final mini = MiniGridGeometry.of(ends.cardGrid.size);
    expect(MorphLayer.dotCenter(ends, month: 3, day: 7, g: 0), ends.cardGrid.topLeft + mini.center(month: 3, day: 7));
    expect(MorphLayer.dotCenter(ends, month: 3, day: 7, g: 1), ends.grid.topLeft + geo.center(month: 3, day: 7));
    expect(MorphLayer.dotRadius(ends, g: 0), mini.radius);
    expect(MorphLayer.dotRadius(ends, g: 1), geo.radius);
  });

  test('the frame and the screen go from the card to the tracker', () {
    expect(MorphLayer.frame(ends, g: 0), ends.card);
    expect(MorphLayer.frame(ends, g: 1), ends.shell);
    expect(MorphLayer.screenFrame(ends, g: 0.5), Rect.lerp(ends.cardScreen, ends.screen, 0.5));
  });

  testWidgets('paints the layer and carries the title between its two places', (tester) async {
    const content = MorphContent(title: 'Mood', cells: null, year: 2026, legendColors: [Color(0xFFFF0000)]);
    await tester.pumpWidget(const MaterialApp(
      home: Stack(fit: StackFit.expand, children: [MorphLayer(ends: ends, content: content, g: 0.5, legendsOpacity: 1)]),
    ));
    expect(find.byType(MorphLayer), findsOneWidget);
    expect(find.text('Mood'), findsOneWidget);
    final titleBox = tester.getRect(find.ancestor(of: find.text('Mood'), matching: find.byType(ClipRect)).first);
    expect(titleBox.left, closeTo(Rect.lerp(ends.cardTitle, ends.barTitle, 0.5)!.left, 0.5));
  });

  testWidgets('the title inherits a real text style, never the MaterialApp fallback (the yellow double underline outside a Scaffold)', (tester) async {
    const content = MorphContent(title: 'Mood', cells: null, year: 2026, legendColors: []);
    // The real tree: the layer is a sibling of the screens in the stage's
    // Stack, under MaterialApp but under no Scaffold or Material.
    await tester.pumpWidget(const MaterialApp(
      home: Stack(fit: StackFit.expand, children: [MorphLayer(ends: ends, content: content, g: 0.5, legendsOpacity: 1)]),
    ));
    final rich = tester.widget<RichText>(find.descendant(of: find.byType(MorphLayer), matching: find.byType(RichText)));
    final style = rich.text.style!;
    expect(style.decoration, TextDecoration.none);
    expect(style.debugLabel ?? '', isNot(contains('fallback')));
  });

  testWidgets('a long title keeps its glyph size (11 → 16 px by scale), never squeezed to fit its rect', (tester) async {
    const long = 'Un titre vraiment très long pour un tracker';
    const content = MorphContent(title: long, cells: null, year: 2026, legendColors: []);
    double scaleAt(WidgetTester t) {
      final transforms = find.ancestor(of: find.text(long), matching: find.byType(Transform));
      return t.widgetList<Transform>(transforms).map((w) => w.transform.entry(0, 0)).reduce((a, b) => a < b ? a : b);
    }

    await tester.pumpWidget(const MaterialApp(
      home: Stack(fit: StackFit.expand, children: [MorphLayer(ends: ends, content: content, g: 0, legendsOpacity: 1)]),
    ));
    expect(find.byType(FittedBox), findsNothing);
    expect(scaleAt(tester), closeTo(11 / 16, 0.001));
    await tester.pumpWidget(const MaterialApp(
      home: Stack(fit: StackFit.expand, children: [MorphLayer(ends: ends, content: content, g: 1, legendsOpacity: 0)]),
    ));
    expect(scaleAt(tester), closeTo(1, 0.001));
  });

  testWidgets('at g = 0 the glyph run fills the card title rect exactly: a title at its natural width is never cut', (tester) async {
    const title = 'Lecture du soir';
    // The card's MarqueeText is laid out under its Scaffold's Material: the
    // theme's bodyMedium (line height, letter spacing) merged with the 11 px
    // pixel style. Its viewport is exactly that run when it fits.
    late TextStyle inherited;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder: (context) {
      inherited = DefaultTextStyle.of(context).style;
      return const SizedBox();
    }))));
    final painter = TextPainter(
      text: TextSpan(text: title, style: inherited.merge(AppFonts.pixel(fontSize: 11))),
      textDirection: TextDirection.ltr,
    )..layout();
    final cardTitle = Rect.fromLTWH(30, 44, painter.width, painter.height);
    final atCard = MorphEnds(
      card: ends.card,
      cardScreen: ends.cardScreen,
      cardGrid: ends.cardGrid,
      cardTitle: cardTitle,
      cardLegends: ends.cardLegends,
      shell: ends.shell,
      screen: ends.screen,
      grid: ends.grid,
      gridGeometry: geo,
      barTitle: ends.barTitle,
    );
    const content = MorphContent(title: title, cells: null, year: 2026, legendColors: []);
    await tester.pumpWidget(MaterialApp(
      home: Stack(fit: StackFit.expand, children: [MorphLayer(ends: atCard, content: content, g: 0, legendsOpacity: 1)]),
    ));
    final run = tester.renderObject<RenderParagraph>(find.text(title));
    final topLeft = run.localToGlobal(Offset.zero);
    final bottomRight = run.localToGlobal(Offset(run.textSize.width, run.textSize.height));
    expect(topLeft.dx, closeTo(cardTitle.left, 0.5));
    expect(topLeft.dy, closeTo(cardTitle.top, 0.5));
    expect(bottomRight.dx, closeTo(cardTitle.right, 0.5));
    expect(bottomRight.dy, closeTo(cardTitle.bottom, 0.5));
  });

  testWidgets('a commented cell is painted as a ring once the dots have landed (g = 1), plain on the card (g = 0)', (tester) async {
    final cells = YearCells.fromList('p', 2026, const [
      CellModel(pageId: 'p', year: 2026, month: 2, day: 5, color: '#FF0000', comment: 'note', updatedAt: ''),
      CellModel(pageId: 'p', year: 2026, month: 3, day: 1, color: '#00FF00', updatedAt: ''),
    ]);
    final content = MorphContent(title: 'Mood', cells: cells, year: 2026, legendColors: const []);
    final hole = Color.alphaBlend(AppColors.screen, AppColors.shell).toARGB32();
    final accent = AppColors.accent.toARGB32();
    PaintPattern ringAt(double g, {required int month, required int day}) {
      final centre = MorphLayer.dotCenter(ends, month: month, day: day, g: g);
      final r = MorphLayer.dotRadius(ends, g: g) * 0.34;
      // The hole, then its 1 px accent line just outside it.
      return paints
        ..something((m, a) =>
            m == #drawCircle && a[0] == centre && ((a[1] as double) - r).abs() < 0.01 && (a[2] as Paint).color.toARGB32() == hole)
        ..something((m, a) =>
            m == #drawCircle &&
            a[0] == centre &&
            ((a[1] as double) - (r + 0.5)).abs() < 0.01 &&
            (a[2] as Paint).style == PaintingStyle.stroke &&
            (a[2] as Paint).color.toARGB32() == accent);
    }

    await tester.pumpWidget(MaterialApp(
      home: Stack(fit: StackFit.expand, children: [MorphLayer(ends: ends, content: content, g: 1, legendsOpacity: 0)]),
    ));
    final landed = tester.renderObject(find.byType(CustomPaint).first);
    expect(landed, ringAt(1, month: 2, day: 5));
    expect(landed, isNot(ringAt(1, month: 3, day: 1)), reason: 'no comment, no hole');
    await tester.pumpWidget(MaterialApp(
      home: Stack(fit: StackFit.expand, children: [MorphLayer(ends: ends, content: content, g: 0, legendsOpacity: 1)]),
    ));
    expect(tester.renderObject(find.byType(CustomPaint).first), isNot(ringAt(0, month: 2, day: 5)), reason: 'the card preview shows no comments');
  });
}

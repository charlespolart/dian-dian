import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../models/year_cells.dart';
import '../theme/app_theme.dart';
import 'grid_geometry.dart';

/// The two ends of the card → tracker morph, in the stage's coordinates:
/// the card's frame, preview frame, preview grid, title and legend dots;
/// the tracker's shell, screen, grid (with its layout) and bar title.
class MorphEnds {
  final Rect card;
  final Rect cardScreen;
  final Rect cardGrid;
  final Rect? cardTitle;
  final Rect? cardLegends;
  final Rect shell;
  final Rect screen;
  final Rect grid;
  final TrackerGridGeometry gridGeometry;
  final Rect? barTitle;

  const MorphEnds({
    required this.card,
    required this.cardScreen,
    required this.cardGrid,
    required this.cardTitle,
    required this.cardLegends,
    required this.shell,
    required this.screen,
    required this.grid,
    required this.gridGeometry,
    required this.barTitle,
  });

  MiniGridGeometry get miniGeometry => MiniGridGeometry.of(cardGrid.size);
}

/// What the morph draws inside the geometry: the tracker's title, its cells
/// for the year shown, and the colours of its legends (the card's dot row).
class MorphContent {
  final String title;
  final YearCells? cells;
  final int year;
  final List<Color> legendColors;

  const MorphContent({required this.title, required this.cells, required this.year, required this.legendColors});
}

/// The shared element of the card → tracker transition: frame, inner
/// screen, every dot and the title, drawn at a geometry interpolated by [g]
/// (0 = exactly the card, 1 = exactly the tracker). The legend dots of the
/// card are drawn at [legendsOpacity]; the labels, sidebar and top bar are
/// the real tracker's, faded in by the stage once the dots have landed.
class MorphLayer extends StatelessWidget {
  final MorphEnds ends;
  final MorphContent content;
  final double g;
  final double legendsOpacity;

  const MorphLayer({
    super.key,
    required this.ends,
    required this.content,
    required this.g,
    required this.legendsOpacity,
  });

  static Rect frame(MorphEnds ends, {required double g}) => Rect.lerp(ends.card, ends.shell, g)!;
  static Rect screenFrame(MorphEnds ends, {required double g}) => Rect.lerp(ends.cardScreen, ends.screen, g)!;

  static Offset dotCenter(MorphEnds ends, {required int month, required int day, required double g}) {
    final from = ends.cardGrid.topLeft + ends.miniGeometry.center(month: month, day: day);
    final to = ends.grid.topLeft + ends.gridGeometry.center(month: month, day: day);
    return Offset.lerp(from, to, g)!;
  }

  static double dotRadius(MorphEnds ends, {required double g}) =>
      lerpDouble(ends.miniGeometry.radius, ends.gridGeometry.radius, g)!;

  @override
  Widget build(BuildContext context) {
    final cardTitle = ends.cardTitle;
    final barTitle = ends.barTitle;
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: _MorphPainter(
            ends: ends,
            content: content,
            g: g,
            legendsOpacity: legendsOpacity,
            shell: AppColors.shell,
            shellBorder: AppColors.shellBorder,
            screen: AppColors.screen,
            screenBorder: AppColors.screenBorder,
            dotEmpty: AppColors.dotEmpty,
            dotBorder: AppColors.dotBorder,
          ),
        ),
        // The title keeps its glyph size (pixel 11 on the card, 16 in the bar,
        // by scale) at its natural size, clipped to its rect: a long title
        // is cut like the real marquee shows it, never squeezed to fit.
        // Both rects are MarqueeText viewports, which start their text at
        // their left edge (and are exactly as wide as a title that fits), so
        // the run is laid out unconstrained and pinned to the left, with the
        // scale pivoting there too: a bounded box would centre the pivot on
        // the box, not on the glyphs, and push the end of the run out of the
        // clip.
        if (cardTitle != null && barTitle != null)
          Positioned.fromRect(
            rect: Rect.lerp(cardTitle, barTitle, g)!,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: 0,
                maxWidth: double.infinity,
                minHeight: 0,
                maxHeight: double.infinity,
                child: Transform.scale(
                  scale: lerpDouble(11 / 16, 1, g)!,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    content.title,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: AppFonts.pixel(fontSize: 16, color: Color.lerp(AppColors.text, AppColors.title, g)!),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MorphPainter extends CustomPainter {
  final MorphEnds ends;
  final MorphContent content;
  final double g;
  final double legendsOpacity;
  final Color shell;
  final Color shellBorder;
  final Color screen;
  final Color screenBorder;
  final Color dotEmpty;
  final Color dotBorder;

  const _MorphPainter({
    required this.ends,
    required this.content,
    required this.g,
    required this.legendsOpacity,
    required this.shell,
    required this.shellBorder,
    required this.screen,
    required this.screenBorder,
    required this.dotEmpty,
    required this.dotBorder,
  });

  static Color _hex(String hex) => Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));

  @override
  void paint(Canvas canvas, Size size) {
    // Frame: the card (radius 10) becoming the shell (radius 14).
    final frame = RRect.fromRectAndRadius(MorphLayer.frame(ends, g: g), Radius.circular(lerpDouble(10, 14, g)!));
    canvas.drawRRect(frame, Paint()..color = shell);
    canvas.drawRRect(frame.deflate(0.5), Paint()
      ..color = shellBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);

    // Inner screen: the preview's frame (radius 6, solid border) becoming
    // the tracker's screen (radius 10, whose dashed border is the tracker's
    // own, faded in by the stage); the solid stroke thins out on the way.
    final inner = RRect.fromRectAndRadius(MorphLayer.screenFrame(ends, g: g), Radius.circular(lerpDouble(6, 10, g)!));
    canvas.drawRRect(inner, Paint()..color = screen);
    canvas.drawRRect(inner.deflate(0.5), Paint()
      ..color = screenBorder.withValues(alpha: screenBorder.a * (1 - g))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);

    // Dots: centre, radius and colour between the preview and the grid; the
    // empty dots gain the grid's thin border on the way.
    final radius = MorphLayer.dotRadius(ends, g: g);
    final emptyFill = Paint()..color = dotEmpty;
    final emptyStroke = Paint()
      ..color = dotBorder.withValues(alpha: dotBorder.a * g)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    final cells = content.cells;
    for (var month = 1; month <= 12; month++) {
      final maxDays = daysInMonth(month, content.year);
      for (var day = 1; day <= maxDays; day++) {
        final c = MorphLayer.dotCenter(ends, month: month, day: day, g: g);
        final cell = cells?.get(month, day);
        if (cell != null) {
          canvas.drawCircle(c, radius, Paint()..color = _hex(cell.color));
        } else {
          canvas.drawCircle(c, radius, emptyFill);
          if (g > 0) canvas.drawCircle(c, radius, emptyStroke);
        }
      }
    }

    // The card's row of legend dots (8 px, 4 px apart, centred), fading.
    final legends = ends.cardLegends;
    if (legends != null && legendsOpacity > 0 && content.legendColors.isNotEmpty) {
      final n = content.legendColors.length;
      final total = n * 8 + (n - 1) * 4;
      var x = legends.center.dx - total / 2 + 4;
      for (final color in content.legendColors) {
        canvas.drawCircle(Offset(x, legends.center.dy), 4, Paint()..color = color.withValues(alpha: color.a * legendsOpacity));
        x += 12;
      }
    }
  }

  @override
  bool shouldRepaint(_MorphPainter old) =>
      old.g != g || old.legendsOpacity != legendsOpacity || old.ends != ends || old.content != content;
}

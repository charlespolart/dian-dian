import 'package:flutter/material.dart';

import '../models/cell_change.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import 'grid_geometry.dart';
import 'morph_anchors.dart';

/// The year grid widget: 12 months x 31 days of colored dots.
///
/// Fills all available space, using the constraining axis (width or height)
/// to determine the cell size.
class TrackerGrid extends StatelessWidget {
  final int year;
  final String? Function(int month, int day) getCellColor;

  /// Whether the cell carries a comment: such a dot is drawn as a ring (a
  /// hole of the screen's colour at its centre, a third of the dot), the
  /// hint that there is something to read behind it.
  final bool Function(int month, int day) hasComment;
  /// Called with the global position of the tap, so the editor can be born
  /// from the dot.
  final void Function(int month, int day, Offset globalPosition) onCellPress;
  /// The cell that just changed on this device, drawn once as a [DotPop]
  /// over the grid (null: nothing to pop).
  final CellChange? pop;
  /// When set, the grid registers its box and layout for the card → tracker morph.
  final MorphAnchors? anchors;
  /// Opacity of the grid's chrome — month letters, day numbers, the ring
  /// around today — for the tracker's reveal after the morph. Null: visible.
  final Animation<double>? chrome;

  const TrackerGrid({
    super.key,
    required this.year,
    required this.getCellColor,
    this.hasComment = _never,
    required this.onCellPress,
    this.pop,
    this.anchors,
    this.chrome,
  });

  static bool _never(int month, int day) => false;

  /// Centre of the dot of (month, day) in the grid's own coordinates: one
  /// label column on the left, one header row on top.
  static Offset cellCenter({
    required int month,
    required int day,
    required double labelColWidth,
    required double cellSize,
    required double rowHeight,
  }) =>
      TrackerGridGeometry(labelColWidth: labelColWidth, cellSize: cellSize, rowHeight: rowHeight, dotSize: cellSize * 0.78)
          .center(month: month, day: day);

  static const List<String> _monthLabels = [
    'J', 'F', 'M', 'A', 'M', 'J',
    'J', 'A', 'S', 'O', 'N', 'D',
  ];

  static const int _cols = 13; // 1 label + 12 months
  static const int _rows = 32; // 1 header + 31 days

  static int getDaysInMonth(int month, int year) => daysInMonth(month, year);

  Color _parseColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final showToday = year == today.year;

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasW = constraints.maxWidth.isFinite;
        final hasH = constraints.maxHeight.isFinite;

        // First pass: estimate cell size from raw constraints, ignoring text scale.
        final estCellW = hasW ? constraints.maxWidth / _cols : 30.0;
        final estCellH = hasH ? constraints.maxHeight / _rows : 30.0;
        final estCellSize = estCellW < estCellH ? estCellW : estCellH;
        final labelSize = (estCellSize * 0.78 * 0.65).clamp(6.0, 12.0);

        // Measure how big the widest day label ("30") actually renders at the
        // user's iOS Dynamic Type scale. Pixel font is proportional, so a
        // scaled "30" (or any wide-digit pair) can overflow a fixed cell.
        final textScaler = MediaQuery.textScalerOf(context);
        final dayPainter = TextPainter(
          text: TextSpan(
            text: '30',
            style: AppFonts.pixel(fontSize: labelSize),
          ),
          textDirection: TextDirection.ltr,
          textScaler: textScaler,
        )..layout();

        // Label column / row height grow to fit the scaled label.
        // The dot columns then absorb whatever width is left.
        final labelColWidth = dayPainter.width + 4 > estCellSize
            ? dayPainter.width + 4
            : estCellSize;
        final rowHeight = dayPainter.height + 2 > estCellSize
            ? dayPainter.height + 2
            : estCellSize;

        final dotColW = hasW
            ? (constraints.maxWidth - labelColWidth) / 12
            : estCellSize;
        // Dots stay square — pick the smaller of width-budget and row-height.
        final cellSize = dotColW < rowHeight ? dotColW : rowHeight;
        final geometry = TrackerGridGeometry(
          labelColWidth: labelColWidth,
          cellSize: cellSize,
          rowHeight: rowHeight,
          dotSize: cellSize * 0.78,
        );
        final dotSize = geometry.dotSize;
        // The hole shows what lies behind the dot: the screen over the shell.
        final holeColor = Color.alphaBlend(AppColors.screen, AppColors.shell);
        final gridW = geometry.size.width;
        final gridH = geometry.size.height;

        // A fill pops at the cell's *current* colour (a recolor or a remote
        // edit right after the tap must show), and vanishes with the cell;
        // an erase shrinks the colour that was there.
        final pop = this.pop;
        final popColor = pop == null ? null : pop.erased ? pop.color : getCellColor(pop.month, pop.day);
        final popCenter = pop != null && pop.year == year && (pop.erased || popColor != null)
            ? geometry.center(month: pop.month, day: pop.day)
            : null;

        final anchors = this.anchors;
        final box = SizedBox(
          width: gridW,
          height: gridH,
          child: Stack(
            children: [
              // The dots. The header row and the label column are blank
              // here, drawn by the chrome layer above; a repaint boundary so
              // a fading label or a pop never repaints the 372 cells.
              RepaintBoundary(
                child: Column(
                  children: [
                    SizedBox(height: rowHeight),
                    ...List.generate(31, (dayIdx) {
                      final day = dayIdx + 1;
                      return SizedBox(
                        height: rowHeight,
                        child: Row(
                          children: [
                            SizedBox(width: labelColWidth),
                            ...List.generate(12, (mIdx) {
                              final month = mIdx + 1;
                              final maxDays = getDaysInMonth(month, year);
                              final valid = day <= maxDays;
                              final color = valid ? getCellColor(month, day) : null;
                              return SizedBox(
                                width: cellSize,
                                child: Center(
                                  child: GestureDetector(
                                    onTapUp: valid ? (d) => onCellPress(month, day, d.globalPosition) : null,
                                    child: valid
                                        ? Container(
                                            width: dotSize,
                                            height: dotSize,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: color != null ? _parseColor(color) : AppColors.dotEmpty,
                                              border: color == null
                                                  ? Border.all(color: AppColors.dotBorder, width: 0.5)
                                                  : null,
                                            ),
                                            child: color != null && hasComment(month, day)
                                                ? Center(child: _commentHole(dotSize, holeColor))
                                                : null,
                                          )
                                        : SizedBox(width: dotSize, height: dotSize),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              // Month letters, day numbers and the ring around today: one
              // layer, so the reveal fades them together; never a tap target.
              IgnorePointer(
                child: FadeTransition(
                  opacity: chrome ?? kAlwaysCompleteAnimation,
                  child: _GridChrome(
                    geometry: geometry,
                    labelSize: labelSize,
                    today: showToday ? today : null,
                  ),
                ),
              ),
              if (popCenter != null)
                Positioned(
                  left: popCenter.dx - dotSize / 2,
                  top: popCenter.dy - dotSize / 2,
                  width: dotSize,
                  height: dotSize,
                  child: IgnorePointer(
                    child: DotPop(
                      key: ValueKey(pop!.seq),
                      color: popColor == null ? AppColors.dotEmpty : _parseColor(popColor),
                      erased: pop.erased,
                      size: dotSize,
                      hole: popColor != null && hasComment(pop.month, pop.day) ? holeColor : null,
                    ),
                  ),
                ),
            ],
          ),
        );
        return anchors == null ? box : MorphAnchor.grid(anchors: anchors, geometry: geometry, child: box);
      },
    );
  }
}

/// The grid's chrome: month letters along the top, day numbers down the
/// left and the ring around today, laid out from the same geometry as the
/// dots so each label sits on its row or column.
class _GridChrome extends StatelessWidget {
  final TrackerGridGeometry geometry;
  final double labelSize;
  final DateTime? today;

  const _GridChrome({required this.geometry, required this.labelSize, required this.today});

  @override
  Widget build(BuildContext context) {
    final style = AppFonts.pixel(fontSize: labelSize, color: AppColors.textMuted);
    final today = this.today;
    final ring = geometry.dotSize + 4;
    final todayCenter = today == null ? null : geometry.center(month: today.month, day: today.day);
    return Stack(
      children: [
        Positioned(
          left: geometry.labelColWidth,
          top: 0,
          height: geometry.rowHeight,
          child: Row(
            children: [
              for (final label in TrackerGrid._monthLabels)
                SizedBox(width: geometry.cellSize, child: Center(child: Text(label, style: style))),
            ],
          ),
        ),
        Positioned(
          left: 0,
          top: geometry.rowHeight,
          width: geometry.labelColWidth,
          child: Column(
            children: [
              for (var day = 1; day <= 31; day++)
                SizedBox(height: geometry.rowHeight, child: Center(child: Text('$day', style: style))),
            ],
          ),
        ),
        if (todayCenter != null)
          Positioned(
            left: todayCenter.dx - ring / 2,
            top: todayCenter.dy - ring / 2,
            width: ring,
            height: ring,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

/// The one animated widget of the grid: the dot that just changed, at its
/// new colour, 0.6 → 1.15 → 1 over [AppMotion.pop]; an erase shrinks the old
/// colour to nothing over [AppMotion.quick]. Keyed on the change's seq, so a
/// new change restarts it.
class DotPop extends StatelessWidget {
  final Color color;
  final bool erased;
  final double size;

  /// The colour of the hole when the cell carries a comment: the pop stays
  /// over the dot after its bounce, so it must look exactly like it.
  final Color? hole;

  const DotPop({super.key, required this.color, required this.erased, required this.size, this.hole});

  static final Animatable<double> fillScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.15).chain(CurveTween(curve: AppMotion.enter)), weight: 60),
    TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: AppMotion.exit)), weight: 40),
  ]);

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: hole != null && !erased ? Center(child: _commentHole(size, hole!)) : null,
    );
    // Reduced motion: the final state at once (a TweenAnimationBuilder would
    // still paint its first frame at 0.6).
    if (AppMotion.reduced(context)) return erased ? const SizedBox.shrink() : dot;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.of(context, erased ? AppMotion.quick : AppMotion.pop),
      child: dot,
      builder: (context, t, child) {
        final scale = erased ? 1 - AppMotion.exit.transform(t) : fillScale.transform(t);
        return Opacity(
          opacity: erased ? 1 - t : 1,
          child: Transform.scale(scale: scale, child: child),
        );
      },
    );
  }
}

/// The comment ring's centre: a hole of the screen's colour, a third of the
/// dot, with a 1 px line in the accent (the today ring's colour) just outside
/// it, so the ring reads on a dot of the screen's own colour too.
Widget _commentHole(double dotSize, Color hole) => Container(
      key: const Key('dot.comment'),
      width: dotSize * 0.34 + 2,
      height: dotSize * 0.34 + 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hole,
        border: Border.all(color: AppColors.accent, width: 1),
      ),
    );

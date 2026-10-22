import 'package:flutter/material.dart';

import '../models/cell_change.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';

/// The year grid widget: 12 months x 31 days of colored dots.
///
/// Fills all available space, using the constraining axis (width or height)
/// to determine the cell size.
class TrackerGrid extends StatelessWidget {
  final int year;
  final String? Function(int month, int day) getCellColor;
  /// Called with the global position of the tap, so the editor can be born
  /// from the dot.
  final void Function(int month, int day, Offset globalPosition) onCellPress;
  /// The cell that just changed on this device, drawn once as a [DotPop]
  /// over the grid (null: nothing to pop).
  final CellChange? pop;

  const TrackerGrid({
    super.key,
    required this.year,
    required this.getCellColor,
    required this.onCellPress,
    this.pop,
  });

  /// Centre of the dot of (month, day) in the grid's own coordinates: one
  /// label column on the left, one header row on top.
  static Offset cellCenter({
    required int month,
    required int day,
    required double labelColWidth,
    required double cellSize,
    required double rowHeight,
  }) =>
      Offset(labelColWidth + cellSize * (month - 1) + cellSize / 2, rowHeight * day + rowHeight / 2);

  static const List<String> _monthLabels = [
    'J', 'F', 'M', 'A', 'M', 'J',
    'J', 'A', 'S', 'O', 'N', 'D',
  ];

  static const int _cols = 13; // 1 label + 12 months
  static const int _rows = 32; // 1 header + 31 days

  static int getDaysInMonth(int month, int year) {
    if (month == 2) {
      final isLeap =
          (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return isLeap ? 29 : 28;
    }
    if ([4, 6, 9, 11].contains(month)) return 30;
    return 31;
  }

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
        final dotSize = cellSize * 0.78;

        final gridW = labelColWidth + cellSize * 12;
        final gridH = rowHeight * _rows;

        // A fill pops at the cell's *current* colour (a recolor or a remote
        // edit right after the tap must show), and vanishes with the cell;
        // an erase shrinks the colour that was there.
        final pop = this.pop;
        final popColor = pop == null ? null : pop.erased ? pop.color : getCellColor(pop.month, pop.day);
        final popCenter = pop != null && pop.year == year && (pop.erased || popColor != null)
            ? cellCenter(month: pop.month, day: pop.day, labelColWidth: labelColWidth, cellSize: cellSize, rowHeight: rowHeight)
            : null;

        return SizedBox(
          width: gridW,
          height: gridH,
          child: Stack(
            children: [
              Column(
            children: [
              // Month headers row
              SizedBox(
                height: rowHeight,
                child: Row(
                  children: [
                    SizedBox(width: labelColWidth),
                    ...List.generate(12, (m) {
                      return SizedBox(
                        width: cellSize,
                        child: Center(
                          child: Text(
                            _monthLabels[m],
                            style: AppFonts.pixel(
                              fontSize: labelSize,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              // Day rows (1..31)
              ...List.generate(31, (dayIdx) {
                final day = dayIdx + 1;
                return SizedBox(
                  height: rowHeight,
                  child: Row(
                    children: [
                      // Day label
                      SizedBox(
                        width: labelColWidth,
                        child: Center(
                          child: Text(
                            '$day',
                            style: AppFonts.pixel(
                              fontSize: labelSize,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                      // Month cells
                      ...List.generate(12, (mIdx) {
                        final month = mIdx + 1;
                        final maxDays = getDaysInMonth(month, year);
                        final valid = day <= maxDays;
                        final color = valid ? getCellColor(month, day) : null;
                        final isToday = showToday &&
                            month == today.month &&
                            day == today.day;

                        return SizedBox(
                          width: cellSize,
                          child: Center(
                            child: GestureDetector(
                              onTapUp: valid ? (d) => onCellPress(month, day, d.globalPosition) : null,
                              child: valid
                                  ? Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: dotSize,
                                          height: dotSize,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: color != null
                                                ? _parseColor(color)
                                                : AppColors.dotEmpty,
                                            border: color == null
                                                ? Border.all(
                                                    color: AppColors.dotBorder,
                                                    width: 0.5,
                                                  )
                                                : null,
                                          ),
                                        ),
                                        if (isToday)
                                          Container(
                                            width: dotSize + 4,
                                            height: dotSize + 4,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppColors.accent,
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                      ],
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
                    ),
                  ),
                ),
            ],
          ),
        );
      },
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

  const DotPop({super.key, required this.color, required this.erased, required this.size});

  static final Animatable<double> fillScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.15).chain(CurveTween(curve: AppMotion.enter)), weight: 60),
    TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: AppMotion.exit)), weight: 40),
  ]);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.of(context, erased ? AppMotion.quick : AppMotion.pop),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
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

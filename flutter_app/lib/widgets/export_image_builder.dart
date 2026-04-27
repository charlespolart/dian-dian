import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models/cell_model.dart';
import '../models/legend_model.dart';
import '../theme/app_theme.dart';
import 'tracker_grid.dart';

/// Builds and captures an enriched export image off-screen.
class ExportImageBuilder {
  static Future<ui.Image?> capture({
    required BuildContext context,
    required String title,
    required int year,
    required List<CellModel> cells,
    required List<LegendModel> legends,
    double pixelRatio = 3.0,
  }) async {
    final widget = _ExportLayout(
      title: title,
      year: year,
      cells: cells,
      legends: legends,
    );

    // Render off-screen
    final repaintBoundary = RenderRepaintBoundary();
    final view = View.of(context);
    final renderView = RenderView(
      view: view,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        logicalConstraints: const BoxConstraints(
          minWidth: 377,
          maxWidth: 377,
          maxHeight: 1200,
        ),
        devicePixelRatio: pixelRatio,
      ),
    );

    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final element = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(800, 1100)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: widget,
        ),
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(element);
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final image = await repaintBoundary.toImage(pixelRatio: pixelRatio);

    buildOwner.finalizeTree();

    return image;
  }
}

class _ExportLayout extends StatelessWidget {
  final String title;
  final int year;
  final List<CellModel> cells;
  final List<LegendModel> legends;

  const _ExportLayout({
    required this.title,
    required this.year,
    required this.cells,
    required this.legends,
  });

  Color _parseHex(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final filledDays = cells.length;
    final isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    final totalDays = isLeap ? 366 : 365;
    final yearPercent = totalDays > 0 ? (filledDays / totalDays * 100).round() : 0;

    // Legend distribution
    final legendCounts = <String, int>{};
    for (final cell in cells) {
      legendCounts[cell.color] = (legendCounts[cell.color] ?? 0) + 1;
    }

    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SizedBox(
        // Fixed width = legend(90) + gap(12) + grid(13×15) + grid padding(16) + shell padding(20)
        width: 345,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: title ~ year ~ (fixed height, text scales down if needed)
            SizedBox(
              height: 24,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    title,
                    style: AppFonts.pixel(fontSize: 18, color: AppColors.title).copyWith(letterSpacing: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '~ $year ~',
                    style: AppFonts.dot(fontSize: 14, color: AppColors.subtitle),
                  ),
                ],
              ),
            ),
            ),
            const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.shell,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.shellBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Legends
                SizedBox(
                  width: 90,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LEGEND',
                        style: AppFonts.pixel(fontSize: 9, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 8),
                      ...legends.map((l) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _parseHex(l.color),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                l.label,
                                style: AppFonts.dot(fontSize: 10, color: AppColors.text),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Grid
                Expanded(child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.screen,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.screenBorder),
                    ),
                    child: _ExportGrid(cells: cells, year: year),
                )),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Stats bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.shell,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.shellBorder),
            ),
            child: Column(
              children: [
                // Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(value: '$filledDays', label: 'days'),
                    _StatItem(value: '$yearPercent%', label: 'year'),
                  ],
                ),
                if (legends.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  // Distribution bars
                  ...legends.map((l) {
                    final count = legendCounts[l.color] ?? 0;
                    final pct = filledDays > 0 ? count / filledDays : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _parseHex(l.color),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 70,
                            child: Text(
                              l.label,
                              style: AppFonts.dot(fontSize: 9, color: AppColors.text),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 6,
                                backgroundColor: AppColors.dotEmpty,
                                valueColor: AlwaysStoppedAnimation(_parseHex(l.color)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$count',
                            style: AppFonts.pixel(fontSize: 8, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Footer
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '点点 Dian Dian',
                style: AppFonts.pixel(fontSize: 9, color: AppColors.textMuted),
              ),
              const SizedBox(width: 8),
              Text(
                '·',
                style: AppFonts.dot(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(width: 8),
              Text(
                'diandian.overridedev.com',
                style: AppFonts.dot(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppFonts.pixel(fontSize: 18, color: AppColors.title)),
        Text(label, style: AppFonts.dot(fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }
}

/// Simplified grid for export — no interactivity, just colored dots.
class _ExportGrid extends StatelessWidget {
  final List<CellModel> cells;
  final int year;

  const _ExportGrid({required this.cells, required this.year});

  static const _monthLabels = ['J','F','M','A','M','J','J','A','S','O','N','D'];

  Color _parseHex(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final colorMap = <String, String>{};
    for (final c in cells) {
      colorMap['${c.month},${c.day}'] = c.color;
    }

    const dotSize = 12.0;
    const gap = 3.0;
    const labelSize = 7.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Month headers
        Row(
          children: [
            SizedBox(width: dotSize + gap),
            ...List.generate(12, (m) => SizedBox(
              width: dotSize + gap,
              child: Center(
                child: Text(
                  _monthLabels[m],
                  style: AppFonts.pixel(fontSize: labelSize, color: AppColors.textMuted),
                ),
              ),
            )),
          ],
        ),
        SizedBox(height: gap),
        // Day rows
        ...List.generate(31, (dayIdx) {
          final day = dayIdx + 1;
          return Padding(
            padding: EdgeInsets.only(bottom: gap),
            child: Row(
              children: [
                SizedBox(
                  width: dotSize + gap,
                  child: Center(
                    child: Text(
                      '$day',
                      style: AppFonts.pixel(fontSize: labelSize, color: AppColors.textMuted),
                    ),
                  ),
                ),
                ...List.generate(12, (mIdx) {
                  final month = mIdx + 1;
                  final maxDays = TrackerGrid.getDaysInMonth(month, year);
                  final valid = day <= maxDays;
                  final key = '$month,$day';
                  final color = valid ? colorMap[key] : null;

                  return Padding(
                    padding: EdgeInsets.only(right: gap),
                    child: valid
                        ? Container(
                            width: dotSize,
                            height: dotSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color != null
                                  ? _parseHex(color)
                                  : AppColors.dotEmpty,
                              border: color == null
                                  ? Border.all(color: AppColors.dotBorder, width: 0.5)
                                  : null,
                            ),
                          )
                        : SizedBox(width: dotSize, height: dotSize),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }
}

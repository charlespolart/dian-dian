import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../models/cell_model.dart';
import '../models/legend_model.dart';
import '../models/page_model.dart';
import '../providers/cells_provider.dart';
import '../providers/language_provider.dart';
import '../providers/legends_provider.dart';
import '../providers/pages_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/marquee_text.dart';

class PageListScreen extends StatefulWidget {
  final void Function(String id, int year) onSelectPage;
  final VoidCallback onOpenSettings;
  final int selectedYear;
  final ValueChanged<int> onYearChanged;

  const PageListScreen({
    super.key,
    required this.onSelectPage,
    required this.onOpenSettings,
    required this.selectedYear,
    required this.onYearChanged,
  });

  @override
  State<PageListScreen> createState() => _PageListScreenState();
}

class _PageListScreenState extends State<PageListScreen> {
  late int _selectedYear;
  int? _draggingIndex;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.selectedYear;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final pagesProv = context.read<PagesProvider>();
      await pagesProv.fetchPages();
      if (!mounted) return;
      _fetchPreviews(pagesProv.pages);
    });
  }

  void _fetchPreviews(List<PageModel> pages) {
    final cellsProv = context.read<CellsProvider>();
    final legendsProv = context.read<LegendsProvider>();
    for (final page in pages) {
      cellsProv.fetchPreviewCells(page.id);
      legendsProv.fetchPreviewLegends(page.id);
    }
  }

  List<PageModel> _pagesForYear(List<PageModel> pages) {
    return pages.where((p) => p.year == _selectedYear).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
  }

  void _onReorderPages(List<PageModel> yearPages, int fromIndex, int toIndex) {
    final ids = yearPages.map((p) => p.id).toList();
    final movedId = ids.removeAt(fromIndex);
    ids.insert(toIndex, movedId);
    context.read<PagesProvider>().reorderPages(ids);
    setState(() => _draggingIndex = null);
  }

  Future<void> _createPage() async {
    final prov = context.read<PagesProvider>();
    await prov.createPage('Untitled', year: _selectedYear);
    // Navigate to the newly created page
    final pages = _pagesForYear(prov.pages);
    if (pages.isNotEmpty && mounted) {
      final newest = pages.last;
      _openTracker(newest);
    }
  }

  void _openTracker(PageModel page) {
    final cellsProv = context.read<CellsProvider>();
    final legendsProv = context.read<LegendsProvider>();
    cellsProv.setPageId(page.id);
    legendsProv.setPageId(page.id);

    widget.onSelectPage(page.id, page.year);
  }

  Future<void> _deletePage(PageModel page) async {
    final lang = context.read<LanguageProvider>();
    final confirmed = await ConfirmDialog.show(
      context,
      title: lang.t('common.delete'),
      message: lang.t('tracker.deletePageConfirm'),
      confirmLabel: lang.t('common.delete'),
      cancelLabel: lang.t('common.cancel'),
      destructive: true,
    );
    if (confirmed != true || !mounted) return;

    context.read<PagesProvider>().softDeletePage(page);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final pages = context.watch<PagesProvider>().pages;
    final yearPages = _pagesForYear(pages);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Column(
        children: [
          // Header banner (covers safe area top)
          Container(
            decoration: const BoxDecoration(
              color: AppColors.shell,
              border: Border(
                bottom: BorderSide(color: AppColors.shellBorder, width: 0.5),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 2,
              20,
              2,
            ),
            child: Row(
                children: [
                  // Logo
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '\u70B9\u70B9',
                        style: AppFonts.pixel(
                          fontSize: 24,
                          color: AppColors.title,
                        ),
                      ),
                      Text(
                        'Dian Dian',
                        style: AppFonts.pixel(
                          fontSize: 11,
                          color: AppColors.subtitle,
                        ),
                      ),
                    ],
                  ),
                  // Year navigation centered
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () { setState(() => _selectedYear--); widget.onYearChanged(_selectedYear); },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              '<',
                              style: AppFonts.pixel(
                                fontSize: 18,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$_selectedYear',
                          style: AppFonts.pixel(
                            fontSize: 20,
                            color: AppColors.title,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () { setState(() => _selectedYear++); widget.onYearChanged(_selectedYear); },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              '>',
                              style: AppFonts.pixel(
                                fontSize: 18,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Settings button
                  GestureDetector(
                    onTap: widget.onOpenSettings,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: SvgPicture.asset(
                        'assets/icons/settings_heart.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          AppColors.bgDot,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page grid
            Expanded(
              child: yearPages.isEmpty
                  ? Center(
                      child: Text(
                        lang.t('tracker.noTrackers'),
                        style: AppFonts.dot(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    )
                  : Consumer2<CellsProvider, LegendsProvider>(
                      builder: (context, cellsProv, legendsProv, _) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            // Responsive: fit 2 cards on phone, more on tablet
                            final maxExtent =
                                constraints.maxWidth < 600 ? 180.0 : 200.0;
                            return GridView.builder(
                              padding: const EdgeInsets.only(
                                left: 8,
                                right: 8,
                                top: 8,
                                bottom: 72,
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: maxExtent,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                // Grid is 12 wide × 31 tall → ratio ~0.45 with title space
                                childAspectRatio: 0.45,
                              ),
                              itemCount: yearPages.length,
                              itemBuilder: (_, index) {
                                final page = yearPages[index];
                                final previewCells =
                                    cellsProv.getPreviewCells(page.id);
                                final previewLegends =
                                    legendsProv.getPreviewLegends(page.id);
                                return DragTarget<int>(
                                  onWillAcceptWithDetails: (d) => d.data != index,
                                  onAcceptWithDetails: (d) =>
                                      _onReorderPages(yearPages, d.data, index),
                                  builder: (context, candidateData, _) {
                                    final isOver = candidateData.isNotEmpty;
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        _PageCard(
                                          page: page,
                                          cells: previewCells,
                                          legends: previewLegends,
                                          onTap: () => _openTracker(page),
                                          onDelete: () => _deletePage(page),
                                          isDragGhost: _draggingIndex == index,
                                          dragHandle: Draggable<int>(
                                            data: index,
                                            onDragStarted: () =>
                                                setState(() => _draggingIndex = index),
                                            onDragEnd: (_) =>
                                                setState(() => _draggingIndex = null),
                                            feedback: Material(
                                              color: Colors.transparent,
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: AppColors.shell,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: AppColors.accent),
                                                ),
                                                child: Icon(
                                                  Icons.drag_indicator,
                                                  size: 16,
                                                  color: AppColors.accent,
                                                ),
                                              ),
                                            ),
                                            childWhenDragging: const SizedBox(width: 18, height: 10),
                                            child: Padding(
                                              padding: const EdgeInsets.all(2),
                                              child: Text(
                                                '≡',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  height: 1,
                                                  color: AppColors.textMuted,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Drop indicator
                                        if (isOver)
                                          Positioned(
                                            left: 0,
                                            right: 0,
                                            top: -2,
                                            child: Container(
                                              height: 3,
                                              decoration: BoxDecoration(
                                                color: AppColors.accent,
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
          // Undo delete bar
        ],
      ),

      // Floating action button
      floatingActionButton: GestureDetector(
        onTap: _createPage,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.bg,
            border: Border.all(color: AppColors.bgDot, width: 1.5),
          ),
          child: Center(
            child: Icon(
              Icons.add_rounded,
              size: 26,
              color: AppColors.bgDot,
            ),
          ),
        ),
      ),
    );
  }
}

/// A card displaying a page with a full grid preview, legend dots, and title.
class _PageCard extends StatelessWidget {
  final PageModel page;
  final List<CellModel> cells;
  final List<LegendModel> legends;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isDragGhost;
  final Widget? dragHandle;

  const _PageCard({
    required this.page,
    required this.cells,
    required this.legends,
    required this.onTap,
    required this.onDelete,
    this.isDragGhost = false,
    this.dragHandle,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDragGhost ? 0.3 : 1.0,
      child: GestureDetector(
        onTap: isDragGhost ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.shell,
          border: Border.all(color: AppColors.shellBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                // Title
                MarqueeText(
                  text: page.title,
                  style: AppFonts.pixel(fontSize: 11, color: AppColors.text),
                ),
            // Legend dots (transparent placeholder if none)
            const SizedBox(height: 3),
            legends.isNotEmpty
                ? Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    runSpacing: 2,
                    children: legends.map((l) {
                      return Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _hexToColor(l.color),
                        ),
                      );
                    }).toList(),
                  )
                : Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                    ),
                  ),
            const SizedBox(height: 6),
            // Full grid preview
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.screen,
                  border: Border.all(color: AppColors.screenBorder),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: _MiniGrid(cells: cells, year: page.year),
              ),
            ),
            ],
          ),
          // Drag handle top-left
          if (dragHandle != null)
            Positioned(
              top: -8,
              left: -8,
              child: dragHandle!,
            ),
          // Delete button top-right
          if (!isDragGhost)
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.shell,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
        ],
        ),
      ),
    ),
    );
  }

  static Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

/// Paints a full 12-column × 31-row preview grid matching the tracker layout.
/// Days that don't exist for a given month are left blank.
class _MiniGridPainter extends CustomPainter {
  final Map<String, Color> colorMap;
  final int year;

  _MiniGridPainter(this.colorMap, this.year);

  static int _daysInMonth(int month, int year) {
    if (month == 2) {
      final isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return isLeap ? 29 : 28;
    }
    if ([4, 6, 9, 11].contains(month)) return 30;
    return 31;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const cols = 12; // months
    const rows = 31; // max days

    final pad = 3.0;
    final availW = size.width - pad * 2;
    final availH = size.height - pad * 2;

    final stepX = availW / cols;
    final stepY = availH / rows;
    final dotRadius = (stepX < stepY ? stepX : stepY) * 0.42;

    final emptyPaint = Paint()..color = AppColors.dotEmpty;

    for (int m = 0; m < cols; m++) {
      final month = m + 1;
      final maxDays = _daysInMonth(month, year);
      final cx = pad + stepX * m + stepX / 2;
      for (int d = 0; d < rows; d++) {
        final day = d + 1;
        if (day > maxDays) continue;
        final cy = pad + stepY * d + stepY / 2;
        final key = '$month,$day';
        final cellColor = colorMap[key];
        final paint = cellColor != null ? (Paint()..color = cellColor) : emptyPaint;
        canvas.drawCircle(Offset(cx, cy), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_MiniGridPainter old) =>
      old.colorMap != colorMap || old.year != year;
}

class _MiniGrid extends StatelessWidget {
  final List<CellModel> cells;
  final int year;

  const _MiniGrid({required this.cells, required this.year});

  @override
  Widget build(BuildContext context) {
    final colorMap = <String, Color>{};
    for (final c in cells) {
      colorMap['${c.month},${c.day}'] = _hexToColor(c.color);
    }
    return CustomPaint(
      painter: _MiniGridPainter(colorMap, year),
      child: const SizedBox.expand(),
    );
  }

  static Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

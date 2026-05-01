import 'package:flutter/foundation.dart' show kIsWeb;
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
import '../providers/premium_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialog.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/ad_banner.dart';
import '../widgets/download_app_banner.dart';
import '../widgets/global_stats_dialog.dart';
import '../widgets/swipe_nav.dart';
import '../widgets/premium_gate_dialog.dart';
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
  bool _bannerVisible = kIsWeb;

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

  /// Fetches preview cells for the active year + legends (year-agnostic).
  void _fetchPreviews(List<PageModel> pages) {
    final cellsProv = context.read<CellsProvider>();
    final legendsProv = context.read<LegendsProvider>();
    for (final page in pages) {
      cellsProv.fetchPreviewCells(page.id, _selectedYear);
      legendsProv.fetchPreviewLegends(page.id);
    }
  }

  void _changeYear(int delta) {
    setState(() => _selectedYear += delta);
    widget.onYearChanged(_selectedYear);
    // Re-fetch cell previews for the new year (legends are year-agnostic).
    final cellsProv = context.read<CellsProvider>();
    for (final page in context.read<PagesProvider>().pages) {
      cellsProv.fetchPreviewCells(page.id, _selectedYear);
    }
  }

  List<PageModel> _sortedPages(List<PageModel> pages) {
    return List<PageModel>.of(pages)
      ..sort((a, b) => a.position.compareTo(b.position));
  }

  void _onReorderPages(List<PageModel> sortedPages, int fromIndex, int toIndex) {
    final ids = sortedPages.map((p) => p.id).toList();
    final movedId = ids.removeAt(fromIndex);
    ids.insert(toIndex, movedId);
    context.read<PagesProvider>().reorderPages(ids);
    setState(() => _draggingIndex = null);
  }

  Future<void> _createPage() async {
    // Check tracker limit for free users
    final premium = context.read<PremiumProvider>();
    if (!premium.isPremium) {
      final totalPages = context.read<PagesProvider>().pages.length;
      if (totalPages >= PremiumProvider.maxFreeTrackers) {
        final lang = context.read<LanguageProvider>();
        await PremiumGateDialog.show(context, feature: lang.t('premium.trackerLimit'));
        return;
      }
    }

    final lang = context.read<LanguageProvider>();
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AppDialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lang.t('tracker.newTracker'),
                style: AppFonts.pixel(fontSize: 16, color: AppColors.title),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 35,
                style: AppFonts.dot(fontSize: 14, color: AppColors.inputText),
                decoration: InputDecoration(
                  hintText: lang.t('tracker.titleHint'),
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10,
                  ),
                  isDense: true,
                ),
                onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Text(
                      lang.t('common.cancel'),
                      style: AppFonts.pixel(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(controller.text.trim()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.btnAdd,
                        border: Border.all(color: AppColors.btnAddBorder),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        lang.t('common.create'),
                        style: AppFonts.pixel(fontSize: 12, color: AppColors.btnAddText),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (title == null || title.isEmpty || !mounted) return;

    final prov = context.read<PagesProvider>();
    await prov.createPage(title);
    if (prov.pages.isNotEmpty && mounted) {
      final newest = _sortedPages(prov.pages).last;
      _openTracker(newest);
    }
  }

  void _openTracker(PageModel page) {
    final cellsProv = context.read<CellsProvider>();
    final legendsProv = context.read<LegendsProvider>();
    cellsProv.setContext(pageId: page.id, year: _selectedYear);
    legendsProv.setPageId(page.id);

    widget.onSelectPage(page.id, _selectedYear);
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
    final sortedPages = _sortedPages(pages);

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Column(
        children: [

          // Header banner (covers safe area top)
          Container(
            decoration: BoxDecoration(
              color: AppColors.shell,
              border: Border(
                bottom: BorderSide(color: AppColors.shellBorder, width: 0.5),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 2,
              8,
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
                  // Year navigation centered (swipe + tap)
                  Expanded(
                    child: SwipeNav(
                      arrowSize: 18,
                      arrowColor: AppColors.accent,
                      onPrev: () => _changeYear(-1),
                      onNext: () => _changeYear(1),
                      center: Text(
                        '$_selectedYear',
                        style: AppFonts.pixel(fontSize: 20, color: AppColors.title),
                      ),
                    ),
                  ),
                  // Premium button (free users only)
                  if (!context.watch<PremiumProvider>().isPremium)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => PremiumGateDialog.show(context, feature: lang.t('premium.upgrade')),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                        child: Icon(Icons.star_rounded, size: 24, color: AppColors.accent),
                      ),
                    ),
                  // Global stats button
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => GlobalStatsDialog.show(context, year: _selectedYear),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      child: Icon(Icons.bar_chart, size: 24, color: AppColors.accent),
                    ),
                  ),
                  // Settings button
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onOpenSettings,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      child: SvgPicture.asset(
                        'assets/icons/settings_heart.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          AppColors.accent,
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
              child: sortedPages.isEmpty
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
                              padding: EdgeInsets.only(
                                left: 8,
                                right: 8,
                                top: 8,
                                bottom: _bannerVisible ? 90 : 80,
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: maxExtent,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                // Grid is 12 wide × 31 tall → ratio ~0.45 with title space
                                childAspectRatio: 0.45,
                              ),
                              itemCount: sortedPages.length,
                              itemBuilder: (_, index) {
                                final page = sortedPages[index];
                                final previewCells =
                                    cellsProv.getPreviewCells(page.id, _selectedYear);
                                final previewLegends =
                                    legendsProv.getPreviewLegends(page.id);
                                return DragTarget<int>(
                                  onWillAcceptWithDetails: (d) => d.data != index,
                                  onAcceptWithDetails: (d) =>
                                      _onReorderPages(sortedPages, d.data, index),
                                  builder: (context, candidateData, _) {
                                    final isOver = candidateData.isNotEmpty;
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        _PageCard(
                                          page: page,
                                          year: _selectedYear,
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
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                decoration: BoxDecoration(
                                                  color: AppColors.shell,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: AppColors.accent),
                                                ),
                                                child: Text(
                                                  '≡',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    height: 1,
                                                    color: AppColors.accent,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            childWhenDragging: const SizedBox(width: 28, height: 28),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              color: Colors.transparent,
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
                                        // Drop highlight overlay
                                        if (isOver)
                                          Positioned.fill(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: AppColors.accent.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: AppColors.accent.withValues(alpha: 0.5),
                                                  width: 2,
                                                ),
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
            // Download app banner (web only)
            DownloadAppBanner(
              onDismissed: () => setState(() => _bannerVisible = false),
            ),
          ],
        ),
          // Ad banner pinned to bottom (mobile free users only)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AdBannerWidget(),
          ),

          // FAB positioned manually
          Positioned(
            right: 16,
            bottom: _bannerVisible
                ? 56
                : (!kIsWeb && !context.read<PremiumProvider>().isPremium ? 66 : 16),
            child: GestureDetector(
              onTap: _createPage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bg,
                  border: Border.all(color: AppColors.accent, width: 1.5),
                ),
                child: Center(
                  child: Icon(
                    Icons.add_rounded,
                    size: 26,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A card displaying a page with a full grid preview, legend dots, and title.
class _PageCard extends StatelessWidget {
  final PageModel page;
  final int year;
  final List<CellModel> cells;
  final List<LegendModel> legends;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isDragGhost;
  final Widget? dragHandle;

  const _PageCard({
    required this.page,
    required this.year,
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
        decoration: BoxDecoration(
          color: AppColors.shell,
          border: Border.all(color: AppColors.shellBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 14),
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
                child: _MiniGrid(cells: cells, year: year),
              ),
            ),
              ],
            ),
          ),
          // Drag handle top-left
          if (dragHandle != null)
            Positioned(
              top: 0,
              left: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {}, // absorb taps so they don't open the tracker
                child: dragHandle!,
              ),
            ),
          // Delete button top-right
          if (!isDragGhost)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onDelete,
                child: Padding(
                  padding: const EdgeInsets.all(8),
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

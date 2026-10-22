import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../models/legend_model.dart';
import '../data/tracker_lock.dart';
import '../models/page_model.dart';
import '../models/year_cells.dart';
import '../providers/cells_provider.dart';
import '../providers/language_provider.dart';
import '../providers/legends_provider.dart';
import '../providers/pages_provider.dart';
import '../providers/premium_provider.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialog.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/ad_banner.dart';
import '../widgets/download_app_banner.dart';
import '../widgets/global_stats_dialog.dart';
import '../widgets/swipe_nav.dart';
import '../widgets/slide_switcher.dart';
import '../widgets/premium_gate_dialog.dart';
import '../widgets/marquee_text.dart';
import '../widgets/utf16_length_limit.dart';
import '../widgets/drag_feedback.dart';
import '../widgets/keep_trackers_dialog.dart';
import '../widgets/press_scale.dart';
import '../theme/motion.dart';
import '../widgets/appear.dart';
import '../widgets/morph_anchors.dart';

enum ListEntrance { cascade, none }

/// The cascade: card [index] waits 30 ms per rank; from the 13th on, no animation.
Duration? entranceDelay(int index) => index < 12 ? Duration(milliseconds: 30 * index) : null;

const double _gridSidePadding = 8;
const double _gridTopPadding = 8;
const double _gridSpacing = 12;
const double _cardAspectRatio = 0.45;

/// Columns and card height for a list [width] px wide, computed the way
/// `SliverGridDelegateWithMaxCrossAxisExtent` does (180 px cards under 600,
/// 200 above).
({int columns, double rowExtent}) gridMetrics(double width) {
  final maxExtent = width < 600 ? 180.0 : 200.0;
  final usable = width - 2 * _gridSidePadding;
  final columns = ((usable + _gridSpacing) / (maxExtent + _gridSpacing)).ceil();
  final cardWidth = (usable - (columns - 1) * _gridSpacing) / columns;
  return (columns: columns, rowExtent: cardWidth / _cardAspectRatio);
}

/// Initial scroll offset that puts the row of card [index] in view: 0 when it
/// already is, otherwise just enough, with one spacing of breath.
double revealScrollOffset({
  required int index,
  required int columns,
  required double rowExtent,
  required double spacing,
  required double viewportHeight,
  required double topPadding,
}) {
  final row = index ~/ columns;
  final rowTop = topPadding + row * (rowExtent + spacing);
  final rowBottom = rowTop + rowExtent;
  if (rowBottom <= viewportHeight) return 0;
  return rowBottom - viewportHeight + spacing;
}

class PageListScreen extends StatefulWidget {
  final void Function(String id, int year) onSelectPage;
  final VoidCallback onOpenSettings;
  final int selectedYear;
  final ValueChanged<int> onYearChanged;
  /// Keys for the card → tracker morph (null in tests).
  final MorphAnchors? anchors;
  /// Cascade on arrival from login / settings; none when coming back from a tracker.
  final ListEntrance entrance;
  /// Coming back from this tracker: the grid opens scrolled so its card is in view.
  final String? revealPageId;

  const PageListScreen({
    super.key,
    required this.onSelectPage,
    required this.onOpenSettings,
    required this.selectedYear,
    required this.onYearChanged,
    this.anchors,
    this.entrance = ListEntrance.cascade,
    this.revealPageId,
  });

  @override
  State<PageListScreen> createState() => _PageListScreenState();
}

class _PageListScreenState extends State<PageListScreen> {
  late int _selectedYear;
  // Sign of the last year change: the cards and the label slide that way.
  int _yearDirection = 0;
  int? _draggingIndex;
  // The "which trackers stay open" question, asked once per session when a
  // free account is over the limit without a stored choice.
  bool _keepAsked = false;
  bool _bannerVisible = kIsWeb;
  final DateTime _entranceStart = DateTime.now();
  /// Decided once per card id on its first build and kept, so a rebuild
  /// never cuts an entrance short.
  final Map<String, ({AppearStyle style, Duration delay})> _appearance = {};
  late final Set<String> _seenIds;
  bool _firstBuildDone = false;
  String? _removingId;
  ScrollController? _scroll;
  /// Keeps the scroll offset across the year slide (a new GridView per
  /// year); unique per screen so a new list still starts on its reveal row.
  late final PageStorageKey<int> _gridStorageKey = PageStorageKey(identityHashCode(this));

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.selectedYear;
    _seenIds = context.read<PagesProvider>().pages.map((p) => p.id).toSet();
    WidgetsBinding.instance.addPostFrameCallback((_) => _firstBuildDone = true);
    // Everything the cards need (pages, legends, this year's cells) comes
    // from the store; this is a no-op when the year is already loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SyncService>().ensureYear(_selectedYear);
    });
  }

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  /// The card the morph measures, registered while it is in the grid.
  Widget _anchored(String pageId, Widget card) {
    final anchors = widget.anchors;
    return anchors == null ? card : MorphAnchor.card(anchors: anchors, pageId: pageId, child: card);
  }

  ({AppearStyle style, Duration delay}) _appearanceOf(String id, int index) {
    return _appearance.putIfAbsent(id, () {
      if (_firstBuildDone && !_seenIds.contains(id)) {
        _seenIds.add(id);
        return (style: AppearStyle.pop, delay: Duration.zero);
      }
      final delay = entranceDelay(index);
      final fresh = DateTime.now().difference(_entranceStart) < const Duration(milliseconds: 600);
      if (widget.entrance == ListEntrance.cascade && fresh && delay != null) {
        return (style: AppearStyle.rise, delay: delay);
      }
      return (style: AppearStyle.none, delay: Duration.zero);
    });
  }

  void _changeYear(int delta) {
    setState(() {
      _yearDirection = delta.sign;
      _selectedYear += delta;
    });
    widget.onYearChanged(_selectedYear);
    // Instant when the year is cached; one bootstrap request otherwise.
    context.read<SyncService>().ensureYear(_selectedYear);
  }

  List<PageModel> _sortedPages(List<PageModel> pages) {
    return List<PageModel>.of(pages)
      ..sort((a, b) => a.position.compareTo(b.position));
  }

  void _onReorderPages(
    List<PageModel> sortedPages,
    int fromIndex,
    int toIndex,
  ) {
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
        await PremiumGateDialog.show(
          context,
          feature: lang.t('premium.trackerLimit'),
          event: 'tracker_limit',
        );
        return;
      }
    }

    final created = await showAppDialog<PageModel?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CreateTrackerDialog(),
    );

    if (created != null && mounted) {
      // The new card is not an "appearance": the morph opens the tracker from
      // it once it has painted (centred fallback if it is off screen).
      _seenIds.add(created.id);
      _appearance[created.id] = (style: AppearStyle.none, delay: Duration.zero);
      setState(() {});
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      _openTracker(created);
    }
  }

  void _openTracker(PageModel page) {
    // Free-tier guard: trackers beyond the first 3 (by createdAt) are locked.
    final premium = context.read<PremiumProvider>();
    final pages = context.read<PagesProvider>().pages;
    if (premium.lockedTrackerIds(pages).contains(page.id)) {
      final lang = context.read<LanguageProvider>();
      PremiumGateDialog.show(context, feature: lang.t('premium.trackerLimit'), event: 'locked_tracker');
      return;
    }

    // Synchronous: the tracker paints from the store immediately.
    context.read<CellsProvider>().setContext(
      pageId: page.id,
      year: _selectedYear,
    );
    context.read<LegendsProvider>().setPageId(page.id);
    context.read<SyncService>().ensureYear(_selectedYear);

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

    // Shrink and fade first, then leave the grid. The removal is committed
    // even if the list goes away meanwhile: the user confirmed it.
    final pagesProv = context.read<PagesProvider>();
    setState(() => _removingId = page.id);
    await Future<void>.delayed(AppMotion.of(context, AppMotion.quick));
    pagesProv.softDeletePage(page);
    _appearance.remove(page.id);
    _seenIds.remove(page.id);
    if (mounted) setState(() => _removingId = null);
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
                    bottom: BorderSide(
                      color: AppColors.shellBorder,
                      width: 0.5,
                    ),
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
                        center: SlideSwitcher(
                          direction: _yearDirection,
                          distance: 12,
                          child: Text(
                            '$_selectedYear',
                            key: ValueKey(_selectedYear),
                            style: AppFonts.pixel(
                              fontSize: 20,
                              color: AppColors.title,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Premium button (free users only)
                    if (!context.watch<PremiumProvider>().isPremium)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => PremiumGateDialog.show(
                          context,
                          feature: lang.t('premium.upgrade'),
                          event: 'list_upgrade',
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 14,
                          ),
                          child: Icon(
                            Icons.star_rounded,
                            size: 24,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    // Global stats button
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () =>
                          GlobalStatsDialog.show(context, year: _selectedYear),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        child: Icon(
                          Icons.bar_chart,
                          size: 24,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    // Settings button
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onOpenSettings,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
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
                          final premium = context.read<PremiumProvider>();
                          final lockedIds = premium.lockedTrackerIds(sortedPages);
                          if (!_keepAsked &&
                              !premium.isPremium &&
                              sortedPages.length > PremiumProvider.maxFreeTrackers &&
                              !hasKeepChoice(sortedPages)) {
                            _keepAsked = true;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                KeepTrackersDialog.show(context, maxTrackers: PremiumProvider.maxFreeTrackers);
                              }
                            });
                          }
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final metrics = gridMetrics(constraints.maxWidth);
                              final revealIndex = widget.revealPageId == null
                                  ? -1
                                  : sortedPages.indexWhere((p) => p.id == widget.revealPageId);
                              _scroll ??= ScrollController(
                                initialScrollOffset: revealIndex < 0
                                    ? 0
                                    : revealScrollOffset(
                                        index: revealIndex,
                                        columns: metrics.columns,
                                        rowExtent: metrics.rowExtent,
                                        spacing: _gridSpacing,
                                        viewportHeight: constraints.maxHeight,
                                        topPadding: _gridTopPadding,
                                      ),
                              );
                              // Responsive: fit 2 cards on phone, more on tablet
                              final maxExtent = constraints.maxWidth < 600
                                  ? 180.0
                                  : 200.0;
                              return SlideSwitcher(
                                direction: _yearDirection,
                                expand: true,
                                child: KeyedSubtree(
                                  key: ValueKey(_selectedYear),
                                  child: GridView.builder(
                                key: _gridStorageKey,
                                controller: _scroll,
                                padding: EdgeInsets.only(
                                  left: _gridSidePadding,
                                  right: _gridSidePadding,
                                  top: _gridTopPadding,
                                  bottom: _bannerVisible ? 90 : 80,
                                ),
                                gridDelegate:
                                    SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: maxExtent,
                                      mainAxisSpacing: _gridSpacing,
                                      crossAxisSpacing: _gridSpacing,
                                      // Grid is 12 wide × 31 tall → ratio ~0.45 with title space
                                      childAspectRatio: _cardAspectRatio,
                                    ),
                                itemCount: sortedPages.length,
                                itemBuilder: (_, index) {
                                  final page = sortedPages[index];
                                  final previewCells = cellsProv.cellsFor(
                                    page.id,
                                    _selectedYear,
                                  );
                                  final previewLegends = legendsProv.legendsFor(
                                    page.id,
                                  );
                                  // The static handle, also drawn on the drag copy.
                                  final handleGlyph = Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    color: Colors.transparent,
                                    child: Text(
                                      '≡',
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  );
                                  return LayoutBuilder(
                                    builder: (context, cell) => DragTarget<int>(
                                      onWillAcceptWithDetails: (d) =>
                                          d.data != index,
                                      onAcceptWithDetails: (d) =>
                                          _onReorderPages(
                                            sortedPages,
                                            d.data,
                                            index,
                                          ),
                                      builder: (context, candidateData, _) {
                                        final isOver = candidateData.isNotEmpty;
                                        final appearance = _appearanceOf(page.id, index);
                                        final removing = _removingId == page.id;
                                        return Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Appear(
                                              key: ValueKey('appear_${page.id}'),
                                              style: appearance.style,
                                              delay: appearance.delay,
                                              child: AnimatedScale(
                                                scale: removing ? 0.85 : 1,
                                                duration: AppMotion.of(context, AppMotion.quick),
                                                curve: AppMotion.exit,
                                                child: AnimatedOpacity(
                                                  opacity: removing ? 0 : 1,
                                                  duration: AppMotion.of(context, AppMotion.quick),
                                                  child: _anchored(
                                                    page.id,
                                                    PageCard(
                                                    page: page,
                                                    year: _selectedYear,
                                                    cells: previewCells,
                                                    legends: previewLegends,
                                                    onTap: removing ? null : () => _openTracker(page),
                                                    onDelete: () {
                                                      if (!removing) _deletePage(page);
                                                    },
                                                    isDragGhost:
                                                        _draggingIndex == index,
                                                    isLocked: lockedIds.contains(
                                                      page.id,
                                                    ),
                                                    dragHandle: removing
                                                        ? null
                                                        : Draggable<int>(
                                                      data: index,
                                                      onDragStarted: () => setState(
                                                        () => _draggingIndex = index,
                                                      ),
                                                      onDragEnd: (_) => setState(
                                                        () => _draggingIndex = null,
                                                      ),
                                                      // A copy of the card follows the finger.
                                                      feedback: DragFeedback(
                                                        width: cell.maxWidth,
                                                        height: cell.maxHeight,
                                                        radius: 10,
                                                        child: PageCard(
                                                          page: page,
                                                          year: _selectedYear,
                                                          cells: previewCells,
                                                          legends: previewLegends,
                                                          onTap: () {},
                                                          onDelete: () {},
                                                          isLocked: lockedIds
                                                              .contains(page.id),
                                                          dragHandle: handleGlyph,
                                                        ),
                                                      ),
                                                      childWhenDragging:
                                                          const SizedBox(
                                                            width: 28,
                                                            height: 28,
                                                          ),
                                                      child: handleGlyph,
                                                    ),
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
                                                    color: AppColors.accent
                                                        .withValues(
                                                          alpha: 0.12,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    border: Border.all(
                                                      color: AppColors.accent
                                                          .withValues(
                                                            alpha: 0.5,
                                                          ),
                                                      width: 2,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  );
                                },
                                  ),
                                ),
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
                : (!kIsWeb && !context.read<PremiumProvider>().isPremium
                      ? 66
                      : 16),
            child: PressScale(
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
/// [PageCard.frozen] is the static copy the card → tracker morph stretches:
/// no handle, no cross, no tap.
class PageCard extends StatelessWidget {
  final PageModel page;
  final int year;
  final YearCells? cells;
  final List<LegendModel> legends;
  final VoidCallback? onTap;
  final VoidCallback onDelete;
  final bool isDragGhost;
  final bool isLocked;
  final Widget? dragHandle;
  final bool frozen;

  const PageCard({
    super.key,
    required this.page,
    required this.year,
    required this.cells,
    required this.legends,
    required this.onTap,
    required this.onDelete,
    this.isDragGhost = false,
    this.isLocked = false,
    this.dragHandle,
  }) : frozen = false;

  const PageCard.frozen({
    super.key,
    required this.page,
    required this.year,
    required this.cells,
    required this.legends,
    required this.isLocked,
  })  : onTap = null,
        onDelete = _noop,
        isDragGhost = false,
        dragHandle = null,
        frozen = true;

  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    final cardOpacity = isDragGhost ? 0.3 : (isLocked ? 0.55 : 1.0);
    return Opacity(
      opacity: cardOpacity,
      child: GestureDetector(
        onTap: isDragGhost || frozen ? null : onTap,
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
                      style: AppFonts.pixel(
                        fontSize: 11,
                        color: AppColors.text,
                      ),
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
              // Lock badge (free tier — tracker beyond the first 3 by createdAt)
              if (isLocked)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.shell.withValues(alpha: 0.85),
                          border: Border.all(
                            color: AppColors.accent,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          size: 18,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
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
              if (!isDragGhost && !frozen)
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
///
/// Takes the immutable [YearCells] straight from the store: its identity
/// changes exactly when its content does, so `shouldRepaint` is both cheap
/// and exact (previously every provider notification repainted every card).
class _MiniGridPainter extends CustomPainter {
  final YearCells? cells;
  final int year;

  _MiniGridPainter(this.cells, this.year);

  static Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

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
        final cell = cells?.get(month, day);
        final paint = cell != null
            ? (Paint()..color = _hexToColor(cell.color))
            : emptyPaint;
        canvas.drawCircle(Offset(cx, cy), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_MiniGridPainter old) =>
      !identical(old.cells, cells) || old.year != year;
}

class _MiniGrid extends StatelessWidget {
  final YearCells? cells;
  final int year;

  const _MiniGrid({required this.cells, required this.year});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MiniGridPainter(cells, year),
      child: const SizedBox.expand(),
    );
  }
}

/// "New tracker" prompt that owns the create request — the button shows a
/// spinner once the network call has been running for [_spinnerDelay], so
/// fast networks never flash one. Pops with the created [PageModel] on
/// success or `null` on cancel/failure.
class _CreateTrackerDialog extends StatefulWidget {
  const _CreateTrackerDialog();

  @override
  State<_CreateTrackerDialog> createState() => _CreateTrackerDialogState();
}

class _CreateTrackerDialogState extends State<_CreateTrackerDialog> {
  static const _spinnerDelay = Duration(milliseconds: 250);

  final _controller = TextEditingController();
  Timer? _spinnerTimer;
  bool _busy = false;
  bool _showSpinner = false;

  @override
  void dispose() {
    _spinnerTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_busy) return;
    final title = _controller.text.trim();
    if (title.isEmpty) return;

    setState(() => _busy = true);
    _spinnerTimer = Timer(_spinnerDelay, () {
      if (mounted) setState(() => _showSpinner = true);
    });

    final created = await context.read<PagesProvider>().createPage(title);

    _spinnerTimer?.cancel();
    if (!mounted) return;
    Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    return AppDialog(
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
              controller: _controller,
              autofocus: true,
              // Server limit, counted the server's way (UTF-16 units, not characters).
              inputFormatters: const [Utf16LengthLimit(35)],
              enabled: !_busy,
              style: AppFonts.dot(fontSize: 14, color: AppColors.inputText),
              decoration: InputDecoration(
                hintText: lang.t('tracker.titleHint'),
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
              onSubmitted: (_) => _create(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _busy ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    lang.t('common.cancel'),
                    style: AppFonts.pixel(
                      fontSize: 12,
                      color: _busy ? AppColors.dotEmpty : AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                PressScale(
                  onTap: _create,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.btnAdd,
                      border: Border.all(color: AppColors.btnAddBorder),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: _showSpinner
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppColors.btnAddText,
                            ),
                          )
                        : Text(
                            lang.t('common.create'),
                            style: AppFonts.pixel(
                              fontSize: 12,
                              color: AppColors.btnAddText,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

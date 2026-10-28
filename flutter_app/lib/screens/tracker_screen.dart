import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/page_model.dart';
import '../providers/cells_provider.dart';
import '../providers/language_provider.dart';
import '../providers/legends_provider.dart';
import '../providers/pages_provider.dart';
import '../providers/premium_provider.dart';
import '../services/audio_service.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../widgets/cell_editor_dialog.dart';
import '../widgets/export_image_builder.dart';
import '../widgets/marquee_text.dart';
import '../widgets/dashed_border.dart';
import '../widgets/legend_editor_dialog.dart';
import '../widgets/premium_gate_dialog.dart';
import '../widgets/slide_switcher.dart';
import '../widgets/morph_anchors.dart';
import '../widgets/stats_detail_dialog.dart';
import '../widgets/ad_banner.dart';
import '../widgets/swipe_nav.dart';
import '../widgets/tracker_grid.dart';
import '../widgets/press_scale.dart';

/// How the tracker arrives: by the open morph — its chrome (labels, sidebar,
/// bar) then reveals itself once the stage hands over — or any other way,
/// whole at once.
enum TrackerEntrance { morph, none }

class TrackerScreen extends StatefulWidget {
  final String pageId;
  final int initialYear;
  final VoidCallback onBack;
  final VoidCallback onOpenSettings;
  final ValueChanged<int>? onYearChanged;
  /// The key the card → tracker morph measures the book shell with.
  final MorphAnchors? anchors;
  /// Read once, when the screen mounts.
  final TrackerEntrance entrance;

  const TrackerScreen({
    super.key,
    required this.pageId,
    required this.initialYear,
    required this.onBack,
    required this.onOpenSettings,
    this.onYearChanged,
    this.anchors,
    this.entrance = TrackerEntrance.none,
  });

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> with SingleTickerProviderStateMixin {
  /// Width the landscape title's pencil can take beside the text (gap + the
  /// largest pencil): the font fit leaves it out of the text's width.
  static const double _pencilRoom = 28;

  /// The landscape pencil grows with the title: 14 px was lost next to 36 px.
  static double _pencilSize(double fontSize) => (fontSize * 0.55).clamp(14.0, 22.0);

  static const _sidebarExpandedLandscape = 150.0;
  static const _sidebarExpandedPortrait = 90.0;
  static const _sidebarExpandedTabletPortrait = 140.0;
  static const _sidebarCollapsed = 32.0;

  bool _editingTitle = false;
  double _bottomSafe = 0;
  bool _showLegendLabels = true;
  String? _selectedLegendId;
  late TextEditingController _titleController;
  late int _year;
  // Sign of the last year change: the grid and the label slide that way.
  int _yearDirection = 0;

  // The reveal after the open morph: one clock for the screen, three slices
  // — the grid's chrome, then the sidebar, then the bar — each a short
  // entrance (`quick`: the dots have just landed, the rest must feel part of
  // that landing, not a second act), a stagger apart, the first starting
  // where the stage hands over to the real tracker. The clock belongs to
  // the screen, so a year change (a new grid) never replays it.
  late final AnimationController _reveal;
  late final Animation<double> _revealGrid;
  late final Animation<double> _revealSidebar;
  late final Animation<double> _revealBar;
  // Landscape only: the left panel comes in by steps after its back button.
  late final Animation<double> _revealYear;
  late final Animation<double> _revealStars;
  late final Animation<double> _revealActions;
  bool _revealArmed = false;

  /// From the start of the open morph to where the real tracker takes over.
  static Duration get revealDelay => AppMotion.screen * AppMotion.debugMorphSlowdown * AppMotion.morphHandover;
  /// From the start of the open morph to the end of the last group's entrance.
  static Duration get revealTotal => revealDelay + AppMotion.stagger * 5 + AppMotion.quick;

  Animation<double> _revealSlice(int group) {
    final total = revealTotal.inMicroseconds.toDouble();
    final start = revealDelay + AppMotion.stagger * group;
    return CurvedAnimation(
      parent: _reveal,
      curve: Interval(start.inMicroseconds / total, (start + AppMotion.quick).inMicroseconds / total, curve: AppMotion.enter),
    );
  }

  /// Registers [child] for the card → tracker morph when the shell owns anchors.
  Widget _anchor(String key, Widget child) {
    final anchors = widget.anchors;
    return anchors == null ? child : MorphAnchor(anchors: anchors, anchorKey: key, child: child);
  }

  /// The landscape title's anchor, with how it is set.
  Widget _anchorTitle(MorphTitleEnd end, Widget child) {
    final anchors = widget.anchors;
    return anchors == null ? child : MorphAnchor.title(anchors: anchors, end: end, child: child);
  }

  PageModel get _page {
    final pages = context.read<PagesProvider>().pages;
    return pages.firstWhere((p) => p.id == widget.pageId);
  }

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear;
    final pages = context.read<PagesProvider>().pages;
    final page = pages.firstWhere((p) => p.id == widget.pageId);
    _titleController = TextEditingController(text: page.title);
    _reveal = AnimationController(vsync: this, duration: revealTotal);
    _revealGrid = _revealSlice(0);
    _revealSidebar = _revealSlice(1);
    _revealBar = _revealSlice(2);
    _revealYear = _revealSlice(3);
    _revealStars = _revealSlice(4);
    _revealActions = _revealSlice(5);
  }

  void _changeYear(int delta) {
    context.read<AudioService?>()?.play(delta > 0 ? SoundCue.stepNext : SoundCue.stepPrev);
    final newYear = _year + delta;
    setState(() {
      _yearDirection = delta.sign;
      _year = newYear;
    });
    // Synchronous pointer move; the grid paints from the store at once when
    // the year is cached, and one bootstrap fills it otherwise.
    context.read<CellsProvider>().setYear(newYear);
    context.read<SyncService>().ensureYear(newYear);
    widget.onYearChanged?.call(newYear);
  }

  /// "Today": the cell editor on today's date, from any year. When the
  /// current year is not in the store yet, its bootstrap is awaited first so
  /// the editor shows today's real cell, not an empty one.
  Future<void> _openToday() async {
    final today = DateTime.now();
    if (_year != today.year) {
      _changeYear(today.year - _year);
      await context.read<SyncService>().ensureYear(today.year);
      if (!mounted) return;
    }
    CellEditorDialog.show(context, month: today.month, day: today.day, year: today.year);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bottomSafe == 0) {
      _bottomSafe = MediaQuery.of(context).padding.bottom;
    }
    if (!_revealArmed) {
      _revealArmed = true;
      if (widget.entrance == TrackerEntrance.morph && !AppMotion.reduced(context)) {
        _reveal.forward();
      } else {
        _reveal.value = 1;
      }
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _saveTitle() {
    final newTitle = _titleController.text.trim();
    if (newTitle.isNotEmpty && newTitle != _page.title) {
      context.read<PagesProvider>().updatePage(_page.id, {'title': newTitle});
    }
    setState(() => _editingTitle = false);
  }

  void _showDetailedStats() {
    final premium = context.read<PremiumProvider>();
    if (!premium.isPremium) {
      final lang = context.read<LanguageProvider>();
      PremiumGateDialog.show(context, feature: lang.t('premium.feature.stats'), event: 'stats');
      return;
    }
    final cellsProv = context.read<CellsProvider>();
    final legends = context.read<LegendsProvider>().legends;
    StatsDetailDialog.show(
      context,
      cells: cellsProv.cells,
      legends: legends,
      year: _year,
    );
  }

  Future<void> _exportImage(BuildContext buttonContext) async {
    // iPad requires sharePositionOrigin to anchor the share popover —
    // capture before any awaits so the RenderBox is guaranteed alive.
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    final premium = context.read<PremiumProvider>();
    if (!premium.isPremium) {
      final lang = context.read<LanguageProvider>();
      await PremiumGateDialog.show(context, feature: lang.t('premium.feature.export'), event: 'export');
      return;
    }

    try {
      final cellsProv = context.read<CellsProvider>();
      final legends = context.read<LegendsProvider>().legends;

      final image = await ExportImageBuilder.capture(
        context: context,
        title: _page.title,
        year: _year,
        cells: cellsProv.cells,
        legends: legends,
      );
      if (image == null) return;

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, name: '${_page.title}.png', mimeType: 'image/png')],
          sharePositionOrigin: origin,
        ),
      );
    } catch (e) {
      debugPrint('Export failed: $e');
    }
  }

  Color _parseHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final cellsProv = context.watch<CellsProvider>();
    final legends = context.watch<LegendsProvider>().legends;
    // Watch pages so title updates are reflected — and leave if this tracker
    // vanished (deleted on another device, or a bootstrap pruning a stale
    // snapshot) instead of crashing on a missing page.
    final pagesProv = context.watch<PagesProvider>();
    if (!pagesProv.pages.any((p) => p.id == widget.pageId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onBack();
      });
      return const SizedBox.shrink();
    }
    // Locked by the free tier (premium lapsed while open, or restored from
    // a stale state): leave and show the gate, instead of editing on.
    if (context.watch<PremiumProvider>().lockedTrackerIds(pagesProv.pages).contains(widget.pageId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onBack();
        PremiumGateDialog.show(context, feature: lang.t('premium.trackerLimit'), event: 'locked_tracker');
      });
      return const SizedBox.shrink();
    }

    // Stats are memoized in the provider (recomputed only when cells change).
    final filledDays = cellsProv.filledDays;
    final streak = cellsProv.currentStreak;
    final daysInYear = _isLeapYear(_year) ? 366 : 365;
    final yearPercent =
        daysInYear > 0 ? (filledDays / daysInYear * 100).round() : 0;

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final useWideLayout = isLandscape;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: MediaQuery.removeViewInsets(
        context: context,
        removeBottom: true,
        child: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: useWideLayout
                ? _buildLandscapeLayout(lang, cellsProv, legends, filledDays, streak, yearPercent)
                : _buildPortraitLayout(lang, cellsProv, legends, filledDays, streak, yearPercent),
          ),
          Positioned(
            left: 0,
            right: useWideLayout ? null : 0,
            bottom: 0,
            child: const AdBannerWidget(),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 0, top: 0, bottom: 0),
      child: Row(
        children: [
          FadeTransition(
            opacity: _revealBar,
            child: PressScale(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onBack,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '<',
                  style: AppFonts.pixel(
                    fontSize: 20,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _editingTitle
                ? TextField(
                    controller: _titleController,
                    autofocus: true,
                    maxLength: 35,
                    style: AppFonts.pixel(
                      fontSize: 16,
                      color: AppColors.title,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      counterText: '',
                    ),
                    onSubmitted: (_) => _saveTitle(),
                    onTapOutside: (_) => _saveTitle(),
                  )
                : PressScale(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _editingTitle = true),
                    // Pencil: the title is renamed by tapping it, which
                    // nothing showed before.
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: _anchor(
                            MorphAnchors.barTitle,
                            MarqueeText(
                              text: _page.title,
                              style: AppFonts.pixel(
                                fontSize: 16,
                                color: AppColors.title,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        FadeTransition(
                          opacity: _revealBar,
                          child: Icon(Icons.edit, size: 12, color: AppColors.accent),
                        ),
                      ],
                    ),
                  ),
          ),
          FadeTransition(
            opacity: _revealBar,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PressScale(
                  behavior: HitTestBehavior.opaque,
                  onTap: _showDetailedStats,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Icon(Icons.bar_chart, size: 18, color: AppColors.accent),
                  ),
                ),
                Builder(
                  builder: (ctx) => PressScale(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _exportImage(ctx),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      child: Icon(Icons.ios_share, size: 18, color: AppColors.accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(CellsProvider cellsProv, List legends) {
    final change = cellsProv.lastChange;
    final pop = change != null && change.pageId == _page.id && change.year == _year ? change : null;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Center(
          child: SlideSwitcher(
            direction: _yearDirection,
            child: KeyedSubtree(
              key: ValueKey(_year),
              child: TrackerGrid(
                anchors: widget.anchors,
                chrome: _revealGrid,
                year: _year,
                pop: pop,
                getCellColor: (month, day) => cellsProv.getCellColor(month, day),
                hasComment: (month, day) => (cellsProv.getCell(month, day)?.comment ?? '').isNotEmpty,
                onCellPress: (month, day, at) {
                  final existingCell = cellsProv.getCell(month, day);
                  if (existingCell != null) {
                    // Cell is filled → open dialog to view/edit comment
                    CellEditorDialog.show(context, month: month, day: day, year: _year, origin: at);
                  } else if (_selectedLegendId != null) {
                    // Legend selected as brush → fill directly
                    try {
                      final legend = legends.firstWhere((l) => l.id == _selectedLegendId);
                      cellsProv.setCell(month, day, legend.color);
                    } catch (_) {
                      // Legend was deleted, deselect
                      setState(() => _selectedLegendId = null);
                    }
                  } else {
                    // No brush selected → open dialog
                    CellEditorDialog.show(context, month: month, day: day, year: _year, origin: at);
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookShell({
    required LanguageProvider lang,
    required CellsProvider cellsProv,
    required List legends,
    required int filledDays,
    required int streak,
    required int yearPercent,
    bool fitWidth = false,
  }) {
    final shell = Container(
      decoration: BoxDecoration(
        color: AppColors.shell,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.shellBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            _anchor(
              MorphAnchors.screen,
              Container(
                decoration: BoxDecoration(
                  color: AppColors.screen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    FadeTransition(
                      opacity: _revealSidebar,
                      child: _buildSidebar(
                        lang: lang,
                        legends: legends,
                        filledDays: filledDays,
                        streak: streak,
                        yearPercent: yearPercent,
                        isLandscape: fitWidth,
                      ),
                    ),
                    FadeTransition(
                      opacity: _revealGrid,
                      child: DashedVerticalDivider(
                        color: AppColors.screenBorder,
                        dashLength: 4,
                        gapLength: 3,
                      ),
                    ),
                    _buildGrid(cellsProv, legends),
                  ],
                ),
              ),
            ),
            // The screen's dashed edge, drawn over it: the morph's layer ends
            // with no edge, so it comes in with the grid's chrome.
            Positioned.fill(
              child: IgnorePointer(
                child: FadeTransition(
                  opacity: _revealGrid,
                  child: DashedBorder(
                    color: AppColors.screenBorder,
                    borderRadius: 10,
                    dashLength: 5,
                    gapLength: 3,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // The morph measures the shell through this anchor.
    final anchors = widget.anchors;
    final content = anchors == null ? shell : MorphAnchor(anchors: anchors, anchorKey: MorphAnchors.shell, child: shell);

    if (!fitWidth) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
        child: content,
      );
    }

    // In fitWidth mode, calculate width from available height
    // Grid: 13 cols × 32 rows, so width = height × 13/32
    // Plus sidebar + divider + paddings
    return LayoutBuilder(
      builder: (context, constraints) {
        final availH = constraints.maxHeight - 8; // outer padding (4*2)
        final gridH = availH - 16; // shell padding (8*2)
        final gridW = gridH * 13 / 32;
        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
        final expandedSidebarW = isLandscape ? _sidebarExpandedLandscape : _sidebarExpandedPortrait;
        final sidebarW = _showLegendLabels ? expandedSidebarW : _sidebarCollapsed;
        final totalW = gridW + sidebarW + 1 + 12 + 16 + 18;
        return Padding(
          padding: EdgeInsets.all(fitWidth ? 4 : 8),
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.base),
            width: totalW.clamp(200, constraints.maxWidth),
            child: content,
          ),
        );
      },
    );
  }

  Widget _buildPortraitLayout(
    LanguageProvider lang,
    CellsProvider cellsProv,
    List legends,
    int filledDays,
    int streak,
    int yearPercent,
  ) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    return Padding(
      padding: EdgeInsets.only(bottom: _bottomSafe),
      child: Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availH = constraints.maxHeight - 20;
              final gridCellH = availH / 32;
              final gridW = gridCellH * 13;
              final sidebarW = _showLegendLabels
                  ? (isTablet ? _sidebarExpandedTabletPortrait : _sidebarExpandedPortrait)
                  : _sidebarCollapsed;
              final maxW = gridW + sidebarW + 50;
              return Center(
                child: AnimatedContainer(
                  duration: AppMotion.of(context, AppMotion.base),
                  constraints: BoxConstraints(maxWidth: maxW),
                  child: _buildBookShell(
                    lang: lang,
                    cellsProv: cellsProv,
                    legends: legends,
                    filledDays: filledDays,
                    streak: streak,
                    yearPercent: yearPercent,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildLandscapeLayout(
    LanguageProvider lang,
    CellsProvider cellsProv,
    List legends,
    int filledDays,
    int streak,
    int yearPercent,
  ) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left panel. The title is the morph's landing and never fades (the
          // layer hands over to it); the rest comes in by steps: back button
          // with the bar's group, then the year, the stars, the actions.
          SizedBox(
            width: 240,
            child: Column(
              children: [
                // Back button top-left
FadeTransition(opacity: _revealBar, child:                 Align(
                  alignment: Alignment.centerLeft,
                  child: PressScale(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onBack,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        '<',
                        style: AppFonts.pixel(fontSize: 20, color: AppColors.accent),
                      ),
                    ),
                  ),
                )),
                // Centered content
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PressScale(
                          onTap: () => setState(() => _editingTitle = true),
                          child: _editingTitle
                              ? TextField(
                                  controller: _titleController,
                                  autofocus: true,
                                  maxLength: 35,
                                  textAlign: TextAlign.center,
                                  style: AppFonts.pixel(fontSize: 36, color: AppColors.title).copyWith(letterSpacing: 2),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    counterText: '',
                                  ),
                                  onSubmitted: (_) => _saveTitle(),
                                  onTapOutside: (_) => _saveTitle(),
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    const maxLines = 4;
                                    const sizes = [36.0, 30.0, 24.0, 20.0, 16.0];
                                    final scaler = MediaQuery.textScalerOf(context);

                                    // Pick the largest font size that fits in [maxLines].
                                    double fontSize = sizes.last;
                                    var lines = 1;
                                    for (final size in sizes) {
                                      final style = AppFonts.pixel(fontSize: size, color: AppColors.title).copyWith(letterSpacing: 2);
                                      final painter = TextPainter(
                                        text: TextSpan(text: _page.title, style: style),
                                        textDirection: TextDirection.ltr,
                                        textAlign: TextAlign.center,
                                        maxLines: maxLines,
                                        textScaler: scaler,
                                      )..layout(maxWidth: constraints.maxWidth - _pencilRoom);
                                      fontSize = size;
                                      lines = painter.computeLineMetrics().length;
                                      if (!painter.didExceedMaxLines) break;
                                    }
                                    // The morph's title lands here: this size, centred, and
                                    // whether it wraps (then the run dissolves into it).
                                    final titleEnd = MorphTitleEnd(fontSize: fontSize, letterSpacing: 2, centred: true, wraps: lines > 1);

                                    // Pencil on the title's line, to its right: the
                                    // title is renamed by tapping it. The fit above
                                    // keeps the pencil's room out of the text's width.
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: _anchorTitle(
                                            titleEnd,
                                            Text(
                                              _page.title,
                                              style: AppFonts.pixel(fontSize: fontSize, color: AppColors.title).copyWith(letterSpacing: 2),
                                              textAlign: TextAlign.center,
                                              softWrap: true,
                                              maxLines: maxLines,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        FadeTransition(
                                          opacity: _revealBar,
                                          child: Icon(Icons.edit, size: _pencilSize(fontSize), color: AppColors.accent),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 12),
FadeTransition(opacity: _revealYear, child:                         Text(
                          '~ $_year ~',
                          style: AppFonts.dot(fontSize: 24, color: AppColors.subtitle, fontWeight: FontWeight.w500).copyWith(letterSpacing: 3),
                        )),
                        const SizedBox(height: 8),
FadeTransition(opacity: _revealStars, child:                         Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (_) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Icon(Icons.star_border, size: 26, color: AppColors.star),
                          )),
                        )),
                        const SizedBox(height: 16),
FadeTransition(opacity: _revealActions, child:                         Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PressScale(
                              behavior: HitTestBehavior.opaque,
                              onTap: _showDetailedStats,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(Icons.bar_chart, size: 20, color: AppColors.accent),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Builder(
                              builder: (ctx) => PressScale(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _exportImage(ctx),
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(Icons.ios_share, size: 20, color: AppColors.accent),
                                ),
                              ),
                            ),
                          ],
                        )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Grid shell — sized to fit
          _buildBookShell(
            lang: lang,
            cellsProv: cellsProv,
            legends: legends,
            filledDays: filledDays,
            streak: streak,
            yearPercent: yearPercent,
            fitWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar({
    required LanguageProvider lang,
    required List legends,
    required int filledDays,
    required int streak,
    required int yearPercent,
    bool isLandscape = false,
  }) {
    final showLabels = _showLegendLabels;
    final isTabletSidebar = MediaQuery.of(context).size.shortestSide >= 600;
    final expandedW = isLandscape ? _sidebarExpandedLandscape : isTabletSidebar ? _sidebarExpandedTabletPortrait : _sidebarExpandedPortrait;
    final collapsedW = _sidebarCollapsed;
    final currentW = showLabels ? expandedW : collapsedW;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final dotSize = isLandscape ? 16.0 : isTablet ? 18.0 : 14.0;
    final labelFs = isLandscape ? 13.0 : isTablet ? 14.0 : 9.0;
    final editFs = isLandscape ? 12.0 : isTablet ? 13.0 : 9.0;
    final sectionFs = isLandscape ? 11.0 : isTablet ? 12.0 : 8.0;

    return AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.base),
      width: currentW,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: SizedBox(
          width: currentW,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
          children: [
            // Toggle labels button
            PressScale(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() => _showLegendLabels = !_showLegendLabels);
                context.read<AudioService?>()?.play(_showLegendLabels ? SoundCue.panelOpen : SoundCue.panelClose);
              },
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4, top: 2),
                  child: Icon(
                    showLabels ? Icons.chevron_left : Icons.chevron_right,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),

            // Year (interactive when sidebar is expanded)
            if (showLabels)
              SwipeNav(
                arrowSize: 11,
                arrowColor: AppColors.accent,
                arrowPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                onPrev: () => _changeYear(-1),
                onNext: () => _changeYear(1),
                center: SlideSwitcher(
                  direction: _yearDirection,
                  distance: 12,
                  child: Text(
                    '$_year',
                    key: ValueKey(_year),
                    style: AppFonts.dot(fontSize: 12, color: AppColors.subtitle),
                  ),
                ),
              )
            else
              RotatedBox(
                quarterTurns: 3,
                child: SlideSwitcher(
                  direction: _yearDirection,
                  distance: 12,
                  child: Text(
                    '$_year',
                    key: ValueKey(_year),
                    style: AppFonts.pixel(fontSize: 9, color: AppColors.subtitle),
                  ),
                ),
              ),
            const SizedBox(height: 4),

            // Legend section title
            _buildSectionHeader(lang.t('tracker.legend'), showLabels, sectionFs),

            // Legend dots + edit button
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: showLabels ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  children: [
                    // Empty state hint
                    if (legends.isEmpty && showLabels)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          lang.t('tracker.addLegendsHint'),
                          style: AppFonts.dot(
                            fontSize: labelFs,
                            color: AppColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (legends.isEmpty && !showLabels)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Icon(
                          Icons.arrow_downward,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ...legends.map<Widget>((legend) {
                      final isSelected = _selectedLegendId == legend.id;
                      return PressScale(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            _selectedLegendId = isSelected ? null : legend.id;
                          });
                          context.read<AudioService?>()?.play(SoundCue.select);
                        },
                        child: Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: showLabels
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.accent.withValues(alpha: 0.12) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: isSelected ? Border.all(color: AppColors.accent, width: 1.5) : null,
                                ),
                                child: Row(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: dotSize,
                                    height: dotSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _parseHex(legend.color),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: MarqueeText(
                                      text: legend.label,
                                      style: AppFonts.dot(
                                        fontSize: labelFs,
                                        color: AppColors.text,
                                      ).copyWith(height: 1.0),
                                    ),
                                  ),
                                ],
                              ))
                            : Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: isSelected ? Border.all(color: AppColors.accent, width: 2) : null,
                                ),
                                child: Container(
                                  width: dotSize,
                                  height: dotSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _parseHex(legend.color),
                                  ),
                                ),
                              ),
                      ),
                      );
                    }),
                    // Edit button right after legends
                    const SizedBox(height: 4),
                    Center(child: _MaybePulse(
                      pulse: legends.isEmpty,
                      child: PressScale(
                        onTapAt: (at) => LegendEditorDialog.show(context, pageId: _page.id, origin: at),
                        child: DashedBorder(
                        color: AppColors.inputBorder,
                        borderRadius: 4,
                        dashLength: 3,
                        gapLength: 2,
                        padding: EdgeInsets.symmetric(
                          horizontal: showLabels ? 8 : 4,
                          vertical: 5,
                        ),
                        child: showLabels
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit,
                                    size: 10,
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    lang.t('tracker.editLegends'),
                                    style: AppFonts.pixel(
                                      fontSize: editFs,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              )
                            : Icon(
                                Icons.edit,
                                size: 12,
                                color: AppColors.accent,
                              ),
                      ),
                    ))),
                  ],
                ),
              ),
            ),

            // Today's dot: the daily action, apart from the legend tools.
            // Empty (dashed, "+") until the day is set, then in its color
            // with the grid's "today" ring. Tap = editor on today's date.
            const SizedBox(height: 6),
            _todayDot(label: lang.t('tracker.today'), showLabel: showLabels, fontSize: editFs, dotSize: dotSize),
            const SizedBox(height: 8),

            // Stats at bottom
            _buildSectionHeader(lang.t('tracker.stats'), showLabels, sectionFs),
            if (showLabels && (isLandscape || isTablet)) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat('$filledDays', lang.t('tracker.statDays'), fontSize: isTablet && !isLandscape ? 13.0 : 15.0),
                  _buildStat('$streak', lang.t('tracker.statStreak'), fontSize: isTablet && !isLandscape ? 13.0 : 15.0),
                  _buildStat('$yearPercent%', lang.t('tracker.statYear'), fontSize: isTablet && !isLandscape ? 13.0 : 15.0),
                ],
              ),
            ] else if (showLabels) ...[
              _buildStat('$filledDays', lang.t('tracker.statDays')),
              _buildStat('$streak', lang.t('tracker.statStreak')),
              _buildStat('$yearPercent%', lang.t('tracker.statYear')),
            ] else ...[
              _buildMiniStat(Icons.grid_view, '$filledDays'),
              const SizedBox(height: 2),
              CustomPaint(
                size: const Size(double.infinity, 1),
                painter: _DashedLinePainter(color: AppColors.screenBorder),
              ),
              const SizedBox(height: 2),
              _buildMiniStat(Icons.local_fire_department, '$streak'),
              const SizedBox(height: 2),
              CustomPaint(
                size: const Size(double.infinity, 1),
                painter: _DashedLinePainter(color: AppColors.screenBorder),
              ),
              const SizedBox(height: 2),
              _buildMiniStat(Icons.percent, '$yearPercent'),
            ],
          ],
        ),
      ),
      ),
      ),
    );
  }

  /// Today's dot, the sidebar's primary action. Shows the color set for
  /// today on this tracker (any displayed year), or an empty dashed dot
  /// with a "+" when nothing is set yet. Framed like Edit, bigger.
  Widget _todayDot({
    required String label,
    required bool showLabel,
    required double fontSize,
    required double dotSize,
  }) {
    final today = DateTime.now();
    final color = context
        .read<CellsProvider>()
        .cellsFor(_page.id, today.year)
        ?.get(today.month, today.day)
        ?.color;
    final big = showLabel ? dotSize * 1.8 : dotSize * 1.3;
    final dot = color != null
        ? Container(
            width: big + 6,
            height: big + 6,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 1.5),
            ),
            child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, color: _parseHex(color)),
            ),
          )
        : CustomPaint(
            painter: _DashedCirclePainter(color: AppColors.accent),
            child: Container(
              width: big + 6,
              height: big + 6,
              alignment: Alignment.center,
              child: Icon(Icons.add, size: big * 0.6, color: AppColors.accent),
            ),
          );
    return Semantics(
      button: true,
      child: PressScale(
        onTap: _openToday,
        child: DashedBorder(
          color: AppColors.inputBorder,
          borderRadius: 6,
          dashLength: 3,
          gapLength: 2,
          padding: EdgeInsets.symmetric(horizontal: showLabel ? 8 : 4, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              dot,
              if (showLabel) ...[
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppFonts.pixel(fontSize: fontSize, color: AppColors.accent),
                  maxLines: 1,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String label, bool expanded, [double fontSize = 9]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        children: [
          if (expanded) ...[
            Text(
              label,
              style: AppFonts.pixel(
                fontSize: fontSize,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 3),
            FractionallySizedBox(
              widthFactor: 0.5,
              child: CustomPaint(
                size: const Size(double.infinity, 1),
                painter: _DashedLinePainter(color: AppColors.screenBorder),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppFonts.pixel(fontSize: 12, color: AppColors.title),
        ),
      ],
    );
  }

  Widget _buildStat(String value, String label, {double fontSize = 13}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Column(
        children: [
          Text(
            value,
            style: AppFonts.pixel(fontSize: fontSize, color: AppColors.title),
          ),
          Text(
            label,
            style: AppFonts.dot(fontSize: fontSize * 0.7, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  bool _isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }
}

/// Pulses its child with a subtle opacity animation when [pulse] is true.
class _MaybePulse extends StatefulWidget {
  final bool pulse;
  final Widget child;

  const _MaybePulse({required this.pulse, required this.child});

  @override
  State<_MaybePulse> createState() => _MaybePulseState();
}

class _MaybePulseState extends State<_MaybePulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.pulse) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _MaybePulse old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.pulse && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.pulse) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.4 + 0.6 * (1 - _controller.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Dashed circle for the empty "today" dot (DashedBorder only does rounded rects).
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  const _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 1;
    const dashes = 14;
    const gapRatio = 0.4;
    final step = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * step,
        step * (1 - gapRatio),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    double x = 0;
    const dash = 3.0;
    const gap = 2.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset((x + dash).clamp(0, size.width), 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}

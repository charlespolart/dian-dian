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
import '../theme/app_theme.dart';
import '../widgets/cell_editor_dialog.dart';
import '../widgets/export_image_builder.dart';
import '../widgets/marquee_text.dart';
import '../widgets/dashed_border.dart';
import '../widgets/legend_editor_dialog.dart';
import '../widgets/premium_gate_dialog.dart';
import '../widgets/stats_detail_dialog.dart';
import '../widgets/tracker_grid.dart';

class TrackerScreen extends StatefulWidget {
  final String pageId;
  final VoidCallback onBack;
  final VoidCallback onOpenSettings;

  const TrackerScreen({
    super.key,
    required this.pageId,
    required this.onBack,
    required this.onOpenSettings,
  });

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  static const _sidebarExpandedLandscape = 150.0;
  static const _sidebarExpandedPortrait = 90.0;
  static const _sidebarExpandedTabletPortrait = 140.0;
  static const _sidebarCollapsed = 32.0;

  bool _editingTitle = false;
  bool _showLegendLabels = true;
  late TextEditingController _titleController;

  PageModel get _page {
    final pages = context.read<PagesProvider>().pages;
    return pages.firstWhere((p) => p.id == widget.pageId);
  }

  @override
  void initState() {
    super.initState();
    final pages = context.read<PagesProvider>().pages;
    final page = pages.firstWhere((p) => p.id == widget.pageId);
    _titleController = TextEditingController(text: page.title);
  }

  @override
  void dispose() {
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
      PremiumGateDialog.show(context, feature: lang.t('premium.feature.stats'));
      return;
    }
    final cellsProv = context.read<CellsProvider>();
    final legends = context.read<LegendsProvider>().legends;
    StatsDetailDialog.show(
      context,
      cells: cellsProv.cells,
      legends: legends,
      year: _page.year,
    );
  }

  Future<void> _exportImage() async {
    final premium = context.read<PremiumProvider>();
    if (!premium.isPremium) {
      final lang = context.read<LanguageProvider>();
      await PremiumGateDialog.show(context, feature: lang.t('premium.feature.export'));
      return;
    }

    try {
      final cellsProv = context.read<CellsProvider>();
      final legends = context.read<LegendsProvider>().legends;

      final image = await ExportImageBuilder.capture(
        context: context,
        title: _page.title,
        year: _page.year,
        cells: cellsProv.cells,
        legends: legends,
      );
      if (image == null) return;

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: '${_page.title}.png', mimeType: 'image/png')],
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
    // Watch pages so title updates are reflected
    context.watch<PagesProvider>();

    // Stats calculation
    final filledDays = cellsProv.cells.length;
    final streak = _calculateStreak(cellsProv);
    final daysInYear = _isLeapYear(_page.year) ? 366 : 365;
    final yearPercent =
        daysInYear > 0 ? (filledDays / daysInYear * 100).round() : 0;

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final useWideLayout = isLandscape;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: useWideLayout
            ? _buildLandscapeLayout(lang, cellsProv, legends, filledDays, streak, yearPercent)
            : _buildPortraitLayout(lang, cellsProv, legends, filledDays, streak, yearPercent),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          GestureDetector(
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
                : GestureDetector(
                    onTap: () => setState(() => _editingTitle = true),
                    child: MarqueeText(
                      text: _page.title,
                      style: AppFonts.pixel(
                        fontSize: 16,
                        color: AppColors.title,
                      ),
                    ),
                  ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _showDetailedStats,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.bar_chart, size: 18, color: AppColors.accent),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _exportImage,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.ios_share, size: 18, color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(CellsProvider cellsProv) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Center(
          child: TrackerGrid(
            year: _page.year,
            getCellColor: (month, day) => cellsProv.getCellColor(month, day),
            onCellPress: (month, day) {
              CellEditorDialog.show(context, month: month, day: day, year: _page.year);
            },
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
    final content = Container(
      decoration: BoxDecoration(
        color: AppColors.shell,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.shellBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: DashedBorder(
          color: AppColors.screenBorder,
          borderRadius: 10,
          dashLength: 5,
          gapLength: 3,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.screen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildSidebar(
                  lang: lang,
                  legends: legends,
                  filledDays: filledDays,
                  streak: streak,
                  yearPercent: yearPercent,
                  isLandscape: fitWidth,
                ),
                DashedVerticalDivider(
                  color: AppColors.screenBorder,
                  dashLength: 4,
                  gapLength: 3,
                ),
                _buildGrid(cellsProv),
              ],
            ),
          ),
        ),
      ),
    );

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
            duration: const Duration(milliseconds: 200),
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

    return Column(
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
                  duration: const Duration(milliseconds: 200),
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
          // Left panel: back, title, year, stars
          SizedBox(
            width: 240,
            child: Column(
              children: [
                // Back button top-left
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
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
                ),
                // Centered content
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
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
                              : Text(
                                  _page.title,
                                  style: AppFonts.pixel(fontSize: 36, color: AppColors.title).copyWith(letterSpacing: 2),
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '~ ${_page.year} ~',
                          style: AppFonts.dot(fontSize: 24, color: AppColors.subtitle, fontWeight: FontWeight.w500).copyWith(letterSpacing: 3),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (_) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Icon(Icons.star_border, size: 26, color: AppColors.star),
                          )),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _showDetailedStats,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(Icons.bar_chart, size: 20, color: AppColors.accent),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _exportImage,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(Icons.ios_share, size: 20, color: AppColors.accent),
                              ),
                            ),
                          ],
                        ),
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
      duration: const Duration(milliseconds: 200),
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
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _showLegendLabels = !_showLegendLabels),
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

            // Year
            if (showLabels)
              Text(
                '~ ${_page.year} ~',
                style: AppFonts.dot(fontSize: 12, color: AppColors.subtitle),
                textAlign: TextAlign.center,
              )
            else
              RotatedBox(
                quarterTurns: 3,
                child: Text(
                  '${_page.year}',
                  style: AppFonts.pixel(fontSize: 9, color: AppColors.subtitle),
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
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: showLabels
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
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
                              )
                            : Container(
                                width: dotSize,
                                height: dotSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _parseHex(legend.color),
                                ),
                              ),
                      );
                    }),
                    // Edit button right after legends
                    const SizedBox(height: 4),
                    Center(child: _MaybePulse(
                      pulse: legends.isEmpty,
                      child: GestureDetector(
                        onTap: () {
                          LegendEditorDialog.show(context, pageId: _page.id);
                        },
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

  int _calculateStreak(CellsProvider cellsProv) {
    // Calculate current streak ending today (or the most recent filled day)
    final now = DateTime.now();
    int streak = 0;
    DateTime check = DateTime(now.year, now.month, now.day);

    // Only calculate streak for the page's year
    if (check.year != _page.year) {
      check = DateTime(_page.year, 12, 31);
    }

    while (check.year == _page.year) {
      final cell = cellsProv.getCell(check.month, check.day);
      if (cell != null) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else {
        // If today has no cell, try starting from yesterday
        if (streak == 0) {
          check = check.subtract(const Duration(days: 1));
          final prevCell = cellsProv.getCell(check.month, check.day);
          if (prevCell != null) {
            streak++;
            check = check.subtract(const Duration(days: 1));
            continue;
          }
        }
        break;
      }
    }

    return streak;
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

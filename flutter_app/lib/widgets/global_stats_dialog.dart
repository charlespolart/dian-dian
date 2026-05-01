import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cell_model.dart';
import '../models/page_model.dart';
import '../providers/language_provider.dart';
import '../providers/pages_provider.dart';
import '../providers/premium_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'app_dialog.dart';
import 'marquee_text.dart';
import 'premium_gate_dialog.dart';

class GlobalStatsDialog extends StatelessWidget {
  final int year;

  const GlobalStatsDialog({super.key, required this.year});

  static Future<void> show(BuildContext context, {required int year}) async {
    final premium = context.read<PremiumProvider>();
    if (!premium.isPremium) {
      final lang = context.read<LanguageProvider>();
      await PremiumGateDialog.show(context, feature: lang.t('premium.feature.stats'));
      return;
    }
    return showDialog(
      context: context,
      builder: (_) => GlobalStatsDialog(year: year),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    final pages = context.read<PagesProvider>().pages;

    return AppDialog(
      maxWidth: 420,
      child: _GlobalStatsContent(lang: lang, pages: pages, year: year),
    );
  }
}

class _GlobalStatsContent extends StatefulWidget {
  final LanguageProvider lang;
  final List<PageModel> pages;
  final int year;

  const _GlobalStatsContent({
    required this.lang,
    required this.pages,
    required this.year,
  });

  @override
  State<_GlobalStatsContent> createState() => _GlobalStatsContentState();
}

class _GlobalStatsContentState extends State<_GlobalStatsContent> {
  static const _spinnerDelay = Duration(milliseconds: 250);

  final _api = ApiService();
  final Map<String, List<CellModel>> _cellsPerPage = {};
  bool _initialLoading = true;
  bool _refreshing = false;
  bool _allTime = false;
  Timer? _spinnerTimer;

  @override
  void initState() {
    super.initState();
    _fetchAllCells(initial: true);
  }

  @override
  void dispose() {
    _spinnerTimer?.cancel();
    super.dispose();
  }

  /// Fetches cells for every page. The initial load shows a full spinner
  /// (no data yet); subsequent fetches keep the old data visible. The
  /// overlay spinner only appears if the fetch takes longer than
  /// [_spinnerDelay] — instant loads don't flash the spinner at all.
  Future<void> _fetchAllCells({bool initial = false}) async {
    final fetchAllTime = _allTime;
    final query = fetchAllTime ? '?all=true' : '?year=${widget.year}';
    final results = <String, List<CellModel>>{};

    _spinnerTimer?.cancel();
    if (!initial) {
      _spinnerTimer = Timer(_spinnerDelay, () {
        if (mounted) setState(() => _refreshing = true);
      });
    }

    for (final page in widget.pages) {
      try {
        final response = await _api.apiFetch('/api/cells/${page.id}$query');
        if (response.statusCode == 200) {
          final list = jsonDecode(response.body) as List<dynamic>;
          results[page.id] = list
              .map((j) => CellModel.fromJson(j as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}
    }

    _spinnerTimer?.cancel();
    if (!mounted) return;
    // Race guard: a faster newer toggle might have already replaced our scope.
    if (fetchAllTime != _allTime) return;
    setState(() {
      _cellsPerPage
        ..clear()
        ..addAll(results);
      _initialLoading = false;
      _refreshing = false;
    });
  }

  void _setAllTime(bool value) {
    if (value == _allTime) return;
    setState(() => _allTime = value);
    _fetchAllCells();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;

    final header = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          lang.t('stats.global'),
          style: AppFonts.pixel(fontSize: 16, color: AppColors.title),
        ),
        const SizedBox(height: 12),
        _RangeToggle(
          allTime: _allTime,
          thisYearLabel: lang.t('stats.thisYear'),
          allTimeLabel: lang.t('stats.allTime'),
          onChanged: _setAllTime,
        ),
        const SizedBox(height: 16),
      ],
    );

    if (_initialLoading) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            header,
            const SizedBox(height: 20),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      );
    }

    final totalPages = widget.pages.length;
    int totalCells = 0;
    String? mostActiveName;
    int mostActiveCells = 0;
    int bestStreak = 0;

    for (final page in widget.pages) {
      final cells = _cellsPerPage[page.id] ?? [];
      totalCells += cells.length;

      if (cells.length > mostActiveCells) {
        mostActiveCells = cells.length;
        mostActiveName = page.title;
      }

      // Best streak for this page (uses each cell's own year so it works
      // across both "this year" and "all time" modes — and lets streaks span
      // year boundaries naturally).
      if (cells.isNotEmpty) {
        final days = <DateTime>{};
        for (final c in cells) {
          try {
            days.add(DateTime(c.year, c.month, c.day));
          } catch (_) {}
        }
        final sorted = days.toList()..sort();
        int current = 1;
        for (int i = 1; i < sorted.length; i++) {
          if (sorted[i].difference(sorted[i - 1]).inDays == 1) {
            current++;
            if (current > bestStreak) bestStreak = current;
          } else {
            current = 1;
          }
        }
        if (sorted.length == 1 && bestStreak == 0) bestStreak = 1;
      }
    }

    // Per-tracker breakdown
    final trackerStats = widget.pages.map((page) {
      final cells = _cellsPerPage[page.id] ?? [];
      return _TrackerStat(name: page.title, count: cells.length);
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final maxCount = trackerStats.isEmpty ? 1 : max(trackerStats.first.count, 1);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              header,

          // Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatBox(value: '$totalPages', label: lang.t('stats.trackers')),
              _StatBox(value: '$totalCells', label: lang.t('tracker.statDays')),
              _StatBox(value: '$bestStreak', label: lang.t('stats.bestStreak')),
            ],
          ),
          const SizedBox(height: 20),

          // Most active
          if (mostActiveName != null) ...[
            Text(
              lang.t('stats.mostActive'),
              style: AppFonts.pixel(fontSize: 10, color: AppColors.textMuted),
            ),
            const SizedBox(height: 4),
            MarqueeText(
              text: mostActiveName,
              style: AppFonts.pixel(fontSize: 14, color: AppColors.title),
            ),
            Text(
              '$mostActiveCells ${lang.t('tracker.statDays')}',
              style: AppFonts.dot(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
          ],

          // Per-tracker breakdown
          Text(
            lang.t('stats.perTracker'),
            style: AppFonts.pixel(fontSize: 10, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          ...trackerStats.map((t) {
            final ratio = t.count / maxCount;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: MarqueeText(
                      text: t.name,
                      style: AppFonts.dot(fontSize: 10, color: AppColors.text),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 8,
                        backgroundColor: AppColors.dotEmpty,
                        valueColor: AlwaysStoppedAnimation(AppColors.accent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${t.count}',
                      style: AppFonts.pixel(fontSize: 9, color: AppColors.textMuted),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Text(
              lang.t('settings.back'),
              style: AppFonts.pixel(fontSize: 12, color: AppColors.accent),
            ),
          ),
        ],
      ),
        ),
        // Subtle overlay spinner shown while the range toggle is loading.
        // Positioned over the content rather than reserving layout space —
        // avoids any jump when it appears/disappears.
        if (_refreshing)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.shell.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TrackerStat {
  final String name;
  final int count;

  _TrackerStat({required this.name, required this.count});
}

/// Two pill-shaped buttons side by side; the active one is filled with accent.
class _RangeToggle extends StatelessWidget {
  final bool allTime;
  final String thisYearLabel;
  final String allTimeLabel;
  final ValueChanged<bool> onChanged;

  const _RangeToggle({
    required this.allTime,
    required this.thisYearLabel,
    required this.allTimeLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.shell,
        border: Border.all(color: AppColors.shellBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(label: thisYearLabel, active: !allTime, onTap: () => onChanged(false)),
          _segment(label: allTimeLabel, active: allTime, onTap: () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _segment({required String label, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: AppFonts.pixel(
            fontSize: 11,
            color: active ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppFonts.pixel(fontSize: 16, color: AppColors.title)),
        const SizedBox(height: 2),
        Text(label, style: AppFonts.dot(fontSize: 9, color: AppColors.textMuted)),
      ],
    );
  }
}

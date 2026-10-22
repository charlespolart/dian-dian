import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/page_model.dart';
import '../providers/cells_provider.dart';
import '../providers/language_provider.dart';
import '../providers/pages_provider.dart';
import '../providers/premium_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'app_dialog.dart';
import 'marquee_text.dart';
import 'premium_gate_dialog.dart';
import 'press_scale.dart';

class GlobalStatsDialog extends StatelessWidget {
  final int year;

  const GlobalStatsDialog({super.key, required this.year});

  static Future<void> show(BuildContext context, {required int year}) async {
    final premium = context.read<PremiumProvider>();
    if (!premium.isPremium) {
      final lang = context.read<LanguageProvider>();
      await PremiumGateDialog.show(context, feature: lang.t('premium.feature.stats'), event: 'global_stats');
      return;
    }
    return showAppDialog(
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
      footer: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              lang.t('settings.back'),
              style: AppFonts.pixel(fontSize: 12, color: AppColors.accent),
            ),
          ),
        ),
      ),
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
  /// Filled dates per page for the selected range. Only dates are needed:
  /// counts and streaks derive from them.
  final Map<String, List<DateTime>> _daysPerPage = {};
  bool _initialLoading = true;
  bool _refreshing = false;
  bool _allTime = false;
  Timer? _spinnerTimer;

  @override
  void initState() {
    super.initState();
    _load(initial: true);
  }

  @override
  void dispose() {
    _spinnerTimer?.cancel();
    super.dispose();
  }

  /// "This year" comes straight from the store (zero requests — the page
  /// list already holds that year). "All time" is one request returning
  /// every filled date of every page.
  Future<void> _load({bool initial = false}) async {
    final fetchAllTime = _allTime;

    if (!fetchAllTime) {
      final cellsProv = context.read<CellsProvider>();
      final results = <String, List<DateTime>>{};
      for (final page in widget.pages) {
        final cells = cellsProv.cellsFor(page.id, widget.year);
        results[page.id] = [
          if (cells != null)
            for (final c in cells.values) DateTime(c.year, c.month, c.day),
        ];
      }
      _spinnerTimer?.cancel();
      setState(() {
        _daysPerPage
          ..clear()
          ..addAll(results);
        _initialLoading = false;
        _refreshing = false;
      });
      return;
    }

    _spinnerTimer?.cancel();
    if (!initial) {
      _spinnerTimer = Timer(_spinnerDelay, () {
        if (mounted) setState(() => _refreshing = true);
      });
    }

    final results = <String, List<DateTime>>{};
    try {
      final response = await _api.apiFetch('/api/stats/days');
      if (response.statusCode == 200) {
        final byPage = jsonDecode(response.body) as Map<String, dynamic>;
        for (final page in widget.pages) {
          final rows = byPage[page.id] as List<dynamic>? ?? const [];
          final days = <DateTime>[];
          for (final r in rows) {
            try {
              final t = r as List<dynamic>;
              days.add(DateTime(t[0] as int, t[1] as int, t[2] as int));
            } catch (_) {}
          }
          results[page.id] = days;
        }
      }
    } catch (_) {}

    _spinnerTimer?.cancel();
    if (!mounted) return;
    // Race guard: a faster newer toggle might have already replaced our scope.
    if (fetchAllTime != _allTime) return;
    setState(() {
      _daysPerPage
        ..clear()
        ..addAll(results);
      _initialLoading = false;
      _refreshing = false;
    });
  }

  void _setAllTime(bool value) {
    if (value == _allTime) return;
    setState(() => _allTime = value);
    _load();
  }

  /// Longest run of consecutive dates (dates are deduplicated first).
  static int _bestStreak(List<DateTime> days) {
    if (days.isEmpty) return 0;
    final sorted = days.toSet().toList()..sort();
    int best = 1, current = 1;
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i].difference(sorted[i - 1]).inDays == 1) {
        current++;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }
    return best;
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
      final days = _daysPerPage[page.id] ?? const [];
      totalCells += days.length;

      if (days.length > mostActiveCells) {
        mostActiveCells = days.length;
        mostActiveName = page.title;
      }

      // Best streak per page; dates carry their own year so streaks span
      // year boundaries naturally in "all time" mode.
      final streak = _bestStreak(days);
      if (streak > bestStreak) bestStreak = streak;
    }

    // Per-tracker breakdown
    final trackerStats = widget.pages.map((page) {
      final days = _daysPerPage[page.id] ?? const [];
      return _TrackerStat(name: page.title, count: days.length);
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final maxCount = trackerStats.isEmpty ? 1 : max(trackerStats.first.count, 1);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
    return PressScale(
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

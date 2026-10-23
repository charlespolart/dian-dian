import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cell_model.dart';
import '../models/legend_model.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import 'tracker_grid.dart';
import 'app_dialog.dart';
import 'press_scale.dart';

class StatsDetailDialog extends StatelessWidget {
  final List<CellModel> cells;
  final List<LegendModel> legends;
  final int year;

  const StatsDetailDialog({
    super.key,
    required this.cells,
    required this.legends,
    required this.year,
  });

  static Future<void> show(
    BuildContext context, {
    required List<CellModel> cells,
    required List<LegendModel> legends,
    required int year,
  }) {
    return showAppDialog(
      context: context,
      builder: (_) => StatsDetailDialog(cells: cells, legends: legends, year: year),
    );
  }

  Color _parseHex(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  bool _isLeapYear(int y) => (y % 4 == 0 && y % 100 != 0) || (y % 400 == 0);

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    final totalDays = _isLeapYear(year) ? 366 : 365;
    final filledDays = cells.length;
    final yearPercent = totalDays > 0 ? (filledDays / totalDays * 100) : 0.0;

    // Legend distribution
    final legendCounts = <String, int>{};
    for (final cell in cells) {
      legendCounts[cell.color] = (legendCounts[cell.color] ?? 0) + 1;
    }

    // Monthly fill rates
    final monthlyFill = List.generate(12, (m) {
      final month = m + 1;
      final maxDays = TrackerGrid.getDaysInMonth(month, year);
      final filled = cells.where((c) => c.month == month).length;
      return filled / maxDays;
    });

    // Streak calculation
    final currentStreak = _calcStreak(false);
    final bestStreak = _calcBestStreak();

    // Day of week distribution
    final weekdayCounts = List.filled(7, 0);
    for (final cell in cells) {
      try {
        final date = DateTime(year, cell.month, cell.day);
        weekdayCounts[date.weekday - 1]++;
      } catch (_) {}
    }
    final maxWeekday = weekdayCounts.reduce(max);

    return AppDialog(
      maxWidth: 420,
      footer: Center(
        child: PressScale(
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Center(
              child: Text(
                lang.t('tracker.stats'),
                style: AppFonts.pixel(fontSize: 16, color: AppColors.title),
              ),
            ),
            const SizedBox(height: 16),

            // Summary row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatBox(value: '$filledDays', label: lang.t('tracker.statDays')),
                _StatBox(value: '$currentStreak', label: lang.t('tracker.statStreak')),
                _StatBox(value: '${yearPercent.round()}%', label: lang.t('tracker.statYear')),
                _StatBox(value: '$bestStreak', label: lang.t('stats.bestStreak')),
              ],
            ),
            const SizedBox(height: 20),

            // Legend distribution
            Text(
              lang.t('stats.distribution'),
              style: AppFonts.pixel(fontSize: 10, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            ...legends.map((legend) {
              final count = legendCounts[legend.color] ?? 0;
              final pct = filledDays > 0 ? count / filledDays : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _parseHex(legend.color),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 60,
                      child: Text(
                        legend.label,
                        style: AppFonts.dot(fontSize: 10, color: AppColors.text),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor: AppColors.dotEmpty,
                          valueColor: AlwaysStoppedAnimation(_parseHex(legend.color)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '$count',
                        style: AppFonts.pixel(fontSize: 9, color: AppColors.textMuted),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),

            // Monthly progression
            Text(
              lang.t('stats.monthly'),
              style: AppFonts.pixel(fontSize: 10, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(12, (i) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: monthlyFill[i].clamp(0.05, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _monthLabels[i],
                            style: AppFonts.pixel(fontSize: 6, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),

            // Day of week
            Text(
              lang.t('stats.weekday'),
              style: AppFonts.pixel(fontSize: 10, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final ratio = maxWeekday > 0 ? weekdayCounts[i] / maxWeekday : 0.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: ratio.clamp(0.05, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _dayLabels[i],
                            style: AppFonts.pixel(fontSize: 6, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calcStreak(bool fromEnd) {
    final now = DateTime.now();
    int streak = 0;
    DateTime check = DateTime(year, now.month, now.day);
    if (check.year != year) check = DateTime(year, 12, 31);

    while (check.year == year) {
      final hasCell = cells.any((c) => c.month == check.month && c.day == check.day);
      if (hasCell) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else {
        if (streak == 0) {
          check = check.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }
    }
    return streak;
  }

  int _calcBestStreak() {
    if (cells.isEmpty) return 0;
    final days = <DateTime>{};
    for (final c in cells) {
      try {
        days.add(DateTime(year, c.month, c.day));
      } catch (_) {}
    }
    final sorted = days.toList()..sort();
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

  static const _monthLabels = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
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

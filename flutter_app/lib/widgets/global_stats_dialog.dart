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
  const GlobalStatsDialog({super.key});

  static Future<void> show(BuildContext context) async {
    final premium = context.read<PremiumProvider>();
    if (!premium.isPremium) {
      final lang = context.read<LanguageProvider>();
      await PremiumGateDialog.show(context, feature: lang.t('premium.feature.stats'));
      return;
    }
    return showDialog(
      context: context,
      builder: (_) => const GlobalStatsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    final pages = context.read<PagesProvider>().pages;

    return AppDialog(
      maxWidth: 420,
      child: _GlobalStatsContent(lang: lang, pages: pages),
    );
  }
}

class _GlobalStatsContent extends StatefulWidget {
  final LanguageProvider lang;
  final List<PageModel> pages;

  const _GlobalStatsContent({required this.lang, required this.pages});

  @override
  State<_GlobalStatsContent> createState() => _GlobalStatsContentState();
}

class _GlobalStatsContentState extends State<_GlobalStatsContent> {
  final _api = ApiService();
  final Map<String, List<CellModel>> _cellsPerPage = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllCells();
  }

  Future<void> _fetchAllCells() async {
    for (final page in widget.pages) {
      try {
        final response = await _api.apiFetch('/api/cells/${page.id}');
        if (response.statusCode == 200) {
          final list = jsonDecode(response.body) as List<dynamic>;
          _cellsPerPage[page.id] = list
              .map((j) => CellModel.fromJson(j as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;

    if (_loading) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accent,
            ),
          ),
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

      // Best streak for this page
      if (cells.isNotEmpty) {
        final days = <DateTime>{};
        for (final c in cells) {
          try {
            days.add(DateTime(page.year, c.month, c.day));
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
      return _TrackerStat(name: page.title, year: page.year, count: cells.length);
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final maxCount = trackerStats.isEmpty ? 1 : max(trackerStats.first.count, 1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            lang.t('stats.global'),
            style: AppFonts.pixel(fontSize: 16, color: AppColors.title),
          ),
          const SizedBox(height: 16),

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
    );
  }
}

class _TrackerStat {
  final String name;
  final int year;
  final int count;

  _TrackerStat({required this.name, required this.year, required this.count});
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

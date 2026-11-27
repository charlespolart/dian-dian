import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mutation.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import 'app_dialog.dart';
import 'press_scale.dart';

/// One line of the message: what happened to an element, and for a day the
/// version that was not kept (H17), to do it again if wanted.
class OutcomeLine {
  const OutcomeLine(this.text, {this.yourColor, this.yourComment, this.yourCleared = false});

  final String text;
  final String? yourColor;
  final String? yourComment;
  final bool yourCleared;

  bool get hasYours => yourColor != null || yourCleared;
}

/// The changes a sync did not keep, told once (H17, H20, H21, H22) with
/// those the server refused (H12): « 2 modifications faites hors ligne
/// n'ont pas été gardées », then one line per element with its reason.
class SyncOutcomesDialog extends StatelessWidget {
  const SyncOutcomesDialog({super.key, required this.outcomes});

  final List<SyncOutcome> outcomes;

  static Future<void> show(BuildContext context, List<SyncOutcome> outcomes) =>
      showAppDialog(context: context, builder: (_) => SyncOutcomesDialog(outcomes: outcomes));

  /// The texts this file shows (every language has them, see its test).
  static const textKeys = [
    'sync.notKept.one', 'sync.notKept.other', 'sync.refused.one', 'sync.refused.other',
    'sync.dayChanged', 'sync.yours', 'sync.yoursCleared', 'sync.quoted',
    'sync.trackerDeleted', 'sync.daysLost.one', 'sync.daysLost.other', 'sync.notDeleted',
    'sync.renamed', 'sync.trackerChanged', 'sync.legendChanged', 'sync.legendDeleted', 'sync.legendNotDeleted',
    'sync.pagesOrder', 'sync.keepChoice', 'sync.legendsOrder',
    'sync.setting.theme', 'sync.setting.language', 'sync.setting.cursor',
    'sync.rejected.legendLimit', 'sync.rejected.trackerLimit', 'sync.rejected.locked',
    'sync.rejected.invalid', 'sync.rejected.invalidAccount',
  ];

  static String _count(LanguageProvider lang, String key, int n) =>
      n == 1 ? lang.t('$key.one') : lang.t('$key.other').replaceAll('{n}', '$n');

  static String _fill(String text, {String? title, String? label, String? date}) => text
      .replaceAll('{title}', title ?? '…')
      .replaceAll('{label}', label ?? '…')
      .replaceAll('{date}', date ?? '…');

  static String? _dateOf(LanguageProvider lang, Map<String, dynamic> d) {
    final (y, m, day) = (d['year'], d['month'], d['day']);
    if (y is! int || m is! int || day is! int) return null;
    return lang.shortDate(DateTime(y, m, day));
  }

  static String? _pageOf(SyncOutcome o) => Mutation.pageOf(o.kind, o.data);

  /// The lines for the changes set aside (changed or deleted elsewhere).
  static List<OutcomeLine> notKeptLines(List<SyncOutcome> outcomes, LanguageProvider lang) {
    final lines = <OutcomeLine>[];
    // A tracker deleted elsewhere: one line, counting the days it took (H20).
    final gone = <String, List<SyncOutcome>>{};
    for (final o in outcomes) {
      final page = _pageOf(o);
      final legendOnly = o.kind == 'legend.update' || o.kind == 'legend.delete';
      if (o.status == 'deleted' && !legendOnly && page != null) {
        (gone[page] ??= []).add(o);
        continue;
      }
      lines.add(_notKept(o, lang));
    }
    for (final group in gone.values) {
      final title = group.map((o) => o.pageTitle).whereType<String>().firstOrNull;
      final days = group.where((o) => o.kind.startsWith('cell.')).length;
      final text = _fill(lang.t('sync.trackerDeleted'), title: title);
      lines.add(OutcomeLine(days == 0 ? text : '$text ${_count(lang, 'sync.daysLost', days)}'));
    }
    return lines;
  }

  static OutcomeLine _notKept(SyncOutcome o, LanguageProvider lang) {
    final current = o.current is Map ? (o.current as Map).cast<String, dynamic>() : const <String, dynamic>{};
    final title = o.pageTitle;
    switch (o.kind) {
      case 'cell.set':
      case 'cell.clear':
        return OutcomeLine(
          _fill(lang.t('sync.dayChanged'), title: title, date: _dateOf(lang, o.data)),
          yourColor: o.kind == 'cell.set' ? o.data['color'] as String? : null,
          yourComment: o.kind == 'cell.set' ? o.data['comment'] as String? : null,
          yourCleared: o.kind == 'cell.clear',
        );
      case 'page.delete':
        return OutcomeLine(_fill(lang.t('sync.notDeleted'), title: title));
      case 'page.update':
        final kept = current['title'] as String?;
        return OutcomeLine(o.data.containsKey('title') && kept != null
            ? _fill(lang.t('sync.renamed'), title: kept)
            : _fill(lang.t('sync.trackerChanged'), title: title));
      case 'legend.update':
      case 'legend.delete':
        final label = current['label'] as String? ?? o.legendLabel;
        if (o.status == 'deleted') return OutcomeLine(_fill(lang.t('sync.legendDeleted'), title: title, label: o.legendLabel));
        return OutcomeLine(_fill(lang.t(o.kind == 'legend.delete' ? 'sync.legendNotDeleted' : 'sync.legendChanged'), title: title, label: label));
      case 'pages.reorder':
        return OutcomeLine(lang.t('sync.pagesOrder'));
      case 'pages.keep':
        return OutcomeLine(lang.t('sync.keepChoice'));
      case 'legends.reorder':
        return OutcomeLine(_fill(lang.t('sync.legendsOrder'), title: title));
      case 'setting.set':
        final key = o.data['key'];
        if (key == 'theme' || key == 'language' || key == 'cursor') return OutcomeLine(lang.t('sync.setting.$key'));
    }
    return OutcomeLine(_fill(lang.t('sync.trackerChanged'), title: title));
  }

  /// The lines for the changes the server refused (H12): the element, and why.
  static List<OutcomeLine> refusedLines(List<SyncOutcome> outcomes, LanguageProvider lang) => [
        for (final o in outcomes)
          OutcomeLine(switch ((o.kind, o.reason)) {
            ('legend.create', 'legend_limit') =>
              _fill(lang.t('sync.rejected.legendLimit'), title: o.pageTitle, label: o.data['label'] as String? ?? o.legendLabel),
            ('page.create', 'tracker_limit') => _fill(lang.t('sync.rejected.trackerLimit'), title: o.data['title'] as String? ?? o.pageTitle),
            (_, 'locked') => _fill(lang.t('sync.rejected.locked'), title: o.pageTitle, date: _dateOf(lang, o.data)),
            _ => o.pageTitle == null ? lang.t('sync.rejected.invalidAccount') : _fill(lang.t('sync.rejected.invalid'), title: o.pageTitle),
          }),
      ];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final notKept = [for (final o in outcomes) if (o.status != 'rejected') o];
    final refused = [for (final o in outcomes) if (o.status == 'rejected') o];
    return AppDialog(
      footer: Center(
        child: Semantics(
          button: true,
          child: PressScale(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.btnAdd,
                border: Border.all(color: AppColors.btnAddBorder),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(lang.t('common.ok'), style: AppFonts.pixel(fontSize: 12, color: AppColors.btnAddText)),
            ),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notKept.isNotEmpty) ..._section(lang, _count(lang, 'sync.notKept', notKept.length), notKeptLines(notKept, lang)),
            if (notKept.isNotEmpty && refused.isNotEmpty) const SizedBox(height: 10),
            if (refused.isNotEmpty) ..._section(lang, _count(lang, 'sync.refused', refused.length), refusedLines(refused, lang)),
          ],
        ),
      ),
    );
  }

  List<Widget> _section(LanguageProvider lang, String title, List<OutcomeLine> lines) => [
        Text(title, style: AppFonts.pixel(fontSize: 13, color: AppColors.title)),
        const SizedBox(height: 8),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.text, style: AppFonts.dot(fontSize: 12, color: AppColors.text)),
                if (line.hasYours) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(lang.t('sync.yours'), style: AppFonts.dot(fontSize: 11, color: AppColors.textMuted)),
                      if (line.yourColor != null)
                        Container(
                          key: const Key('sync.yourColor'),
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _color(line.yourColor!),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.dotBorder),
                          ),
                        ),
                      if (line.yourComment != null && line.yourComment!.isNotEmpty)
                        Text(lang.t('sync.quoted').replaceAll('{text}', line.yourComment!),
                            style: AppFonts.dot(fontSize: 11, color: AppColors.textMuted)),
                      if (line.yourCleared) Text(lang.t('sync.yoursCleared'), style: AppFonts.dot(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ],
            ),
          ),
      ];

  static Color _color(String hex) => Color(int.tryParse('FF${hex.replaceFirst('#', '')}', radix: 16) ?? 0xFF888888);
}

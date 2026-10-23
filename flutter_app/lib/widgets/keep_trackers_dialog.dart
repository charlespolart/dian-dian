import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/tracker_lock.dart';
import '../models/page_model.dart';
import '../providers/language_provider.dart';
import '../providers/pages_provider.dart';
import '../theme/app_theme.dart';
import 'app_dialog.dart';
import 'press_scale.dart';

/// A free account over the limit chooses which trackers stay open. The
/// most active ones are preselected; the choice is stored on the server
/// (`PUT /api/pages/keep`) so every device agrees. Nothing is deleted: the
/// others reopen with Premium or a new choice.
class KeepTrackersDialog extends StatefulWidget {
  final int maxTrackers;

  const KeepTrackersDialog({super.key, required this.maxTrackers});

  static Future<void> show(BuildContext context, {required int maxTrackers}) {
    return showAppDialog(
      context: context,
      builder: (_) => KeepTrackersDialog(maxTrackers: maxTrackers),
    );
  }

  @override
  State<KeepTrackersDialog> createState() => _KeepTrackersDialogState();
}

class _KeepTrackersDialogState extends State<KeepTrackersDialog> {
  late final Set<String> _selected;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final pages = context.read<PagesProvider>().pages;
    final kept = pages.where((p) => p.keepFree).map((p) => p.id);
    final seed = hasKeepChoice(pages) ? kept : mostActiveTrackers(pages).map((p) => p.id);
    _selected = seed.take(widget.maxTrackers).toSet();
  }

  int _needed(List<PageModel> pages) =>
      pages.length < widget.maxTrackers ? pages.length : widget.maxTrackers;

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else if (_selected.length < widget.maxTrackers) {
        _selected.add(id);
      }
    });
  }

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await context.read<PagesProvider>().keepFree(_selected.toList());
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _busy = false);
    }
  }

  String _activity(LanguageProvider lang, PageModel page) {
    if (page.recentCells == 0 && page.lastCellAt == null) return lang.t('keep.never');
    return lang.t('keep.recent').replaceFirst('{n}', '${page.recentCells}');
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final pages = mostActiveTrackers(context.watch<PagesProvider>().pages);
    final needed = _needed(pages);
    final ready = _selected.length == needed && !_busy;
    return AppDialog(
      footer: Center(
        child: Semantics(
          button: true,
          enabled: ready,
          child: PressScale(
            onTap: ready ? _confirm : null,
            child: Opacity(
              opacity: ready ? 1 : 0.5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.btnAdd,
                  border: Border.all(color: AppColors.btnAddBorder),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  lang.t('keep.confirm').replaceFirst('{n}', '$needed'),
                  style: AppFonts.pixel(fontSize: 12, color: AppColors.btnAddText),
                ),
              ),
            ),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              lang.t('keep.title').replaceFirst('{n}', '${widget.maxTrackers}'),
              style: AppFonts.pixel(fontSize: 16, color: AppColors.title),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              lang.t('keep.intro').replaceFirst('{n}', '$needed'),
              style: AppFonts.dot(fontSize: 13, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            for (final page in pages)
              _Row(
                page: page,
                selected: _selected.contains(page.id),
                activity: _activity(lang, page),
                onTap: _busy ? null : () => _toggle(page.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final PageModel page;
  final bool selected;
  final String activity;
  final VoidCallback? onTap;

  const _Row({required this.page, required this.selected, required this.activity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withValues(alpha: 0.10) : AppColors.inputBg,
          border: Border.all(color: selected ? AppColors.accent : AppColors.inputBorder, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Checkbox(
              key: Key('keep.${page.id}'),
              value: selected,
              onChanged: onTap == null ? null : (_) => onTap!(),
              activeColor: AppColors.accent,
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    page.title,
                    style: AppFonts.dot(fontSize: 14, color: AppColors.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(activity, style: AppFonts.dot(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

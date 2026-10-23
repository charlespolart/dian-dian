import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/first_tracker_decision.dart';
import '../data/first_tracker_templates.dart';
import '../providers/cells_provider.dart';
import '../providers/language_provider.dart';
import '../providers/legends_provider.dart';
import '../providers/pages_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/utf16_length_limit.dart';
import '../widgets/press_scale.dart';
import '../widgets/slide_switcher.dart';

/// First-tracker flow (1.4.0), shown instead of the page list to any account
/// the server reports with no cell at all (new or dormant).
///
/// Screen 1 picks a template (or a custom title); screen 2 creates the page
/// with its legends and sets today's cell in the account's real data. The
/// only exit that creates nothing is "Later". Finishing or skipping is
/// remembered per device and account ([isDone] / [markDone]).
class FirstTrackerScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onLater;
  final void Function(String pageId, int year) onOpenTracker;

  /// Free-tier limit (999 for premium): when the account is at it, the flow
  /// may only replace an empty page, never add one that would be locked.
  final int maxTrackers;

  /// Clock, injectable in tests. Read at tap time, so a flow left open past
  /// midnight still writes the right day.
  final DateTime Function() now;

  const FirstTrackerScreen({
    super.key,
    required this.userId,
    required this.onLater,
    required this.onOpenTracker,
    required this.maxTrackers,
    this.now = DateTime.now,
  });

  static String _prefKey(String userId) => 'first_tracker_done_$userId';

  /// True once this device finished or skipped the flow for [userId].
  static Future<bool> isDone(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey(userId)) ?? false;
  }

  static Future<void> markDone(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey(userId), true);
  }

  @override
  State<FirstTrackerScreen> createState() => _FirstTrackerScreenState();
}

enum _Step { choose, today }

class _FirstTrackerScreenState extends State<FirstTrackerScreen> {
  _Step _step = _Step.choose;
  FirstTrackerTemplate? _template;
  bool _titleOpen = false;
  final _titleController = TextEditingController();
  // Screen 2: the title is renamed by tapping it — the same gesture as in
  // the tracker, which nobody guesses otherwise.
  bool _renaming = false;
  final _renameController = TextEditingController();

  /// Page + legends once the server has them; created at most once.
  CreatedPage? _created;

  /// Idempotency key for the creation, one per flow: every retry sends the
  /// same one, so the server answers with the page it already made.
  final String _clientId = _uuidV4();
  String? _todayColor;
  bool _busy = false;
  bool _error = false;
  Future<bool> Function()? _retry;

  @override
  void initState() {
    super.initState();
    // Continue enables as soon as the custom title is not blank.
    _titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _renameController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// The tracker title: what was typed (custom template, or a rename on
  /// screen 2), else the template name.
  String _title(LanguageProvider lang) {
    final typed = _titleController.text.trim();
    return typed.isNotEmpty ? typed : lang.t(_template!.titleKey);
  }

  void _choose(FirstTrackerTemplate t) {
    setState(() {
      _template = t;
      _titleController.clear();
      if (t.customTitle) {
        _titleOpen = true;
      } else {
        _step = _Step.today;
      }
    });
  }

  void _startRename(LanguageProvider lang) {
    _renameController.text = _title(lang);
    setState(() => _renaming = true);
  }

  /// Keeps the previous title when the field is left blank; patches the
  /// page when it already exists on the server.
  Future<void> _commitRename(LanguageProvider lang) async {
    if (!_renaming) return;
    final typed = _renameController.text.trim();
    final previous = _title(lang);
    setState(() => _renaming = false);
    if (typed.isEmpty || typed == previous) return;
    _titleController.text = typed;
    final created = _created;
    if (created == null) return;
    final pages = context.read<PagesProvider>();
    await pages.updatePage(created.page.id, {'title': typed});
    if (!mounted) return;
    final updated =
        pages.pages.where((p) => p.id == created.page.id).firstOrNull ?? created.page;
    setState(() => _created = CreatedPage(page: updated, legends: created.legends));
  }

  void _continueWithTitle() {
    final title = _titleController.text.trim();
    if (title.isEmpty || title.length > 35) return;
    setState(() => _step = _Step.today);
  }

  Future<void> _later() async {
    await FirstTrackerScreen.markDone(widget.userId);
    if (mounted) widget.onLater();
  }

  /// Runs one server-facing step. On failure the inline error shows and the
  /// step is kept for Retry, so only the failed step is replayed.
  Future<void> _run(Future<bool> Function() step) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = false;
      _retry = step;
    });
    final ok = await step();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = !ok;
      if (ok) _retry = null;
    });
  }

  /// The page this flow would create, if it already exists: same title and
  /// exactly the template's legends. Happens when a POST was committed but
  /// its response never arrived (the WS echo brought the page), or when
  /// another device ran the flow: adopt it rather than create a twin.
  CreatedPage? _adoptable(
    LanguageProvider lang,
    PagesProvider pages,
    LegendsProvider legends,
  ) {
    final title = _title(lang);
    final drafts = _template!.legends(lang);
    for (final page in pages.pages) {
      if (page.title != title) continue;
      final existing = legends.legendsFor(page.id);
      if (existing.length != drafts.length) continue;
      var same = true;
      for (var i = 0; i < drafts.length; i++) {
        if (existing[i].color != drafts[i].color ||
            existing[i].label != drafts[i].label) {
          same = false;
          break;
        }
      }
      if (same) return CreatedPage(page: page, legends: existing);
    }
    return null;
  }

  /// Creates the page with its legends, once. Later calls return the cached
  /// result, so a retry after a failed cell never creates a second page.
  Future<CreatedPage?> _ensureCreated() async {
    final existing = _created;
    if (existing != null) return existing;
    final lang = context.read<LanguageProvider>();
    final pages = context.read<PagesProvider>();
    final legends = context.read<LegendsProvider>();
    final created =
        _adoptable(lang, pages, legends) ??
        await pages.createFirstTracker(
          title: _title(lang),
          legends: _template!.legends(lang),
          replaces: replaceablePageId(pages.pages, legends.legendsFor),
          fallbackWithoutReplaces: pages.pages.length < widget.maxTrackers,
          clientId: _clientId,
        );
    if (created == null || !mounted) return created;
    // Point the store at the new page, as the page list would have.
    legends.setLegends(created.page.id, created.legends);
    legends.setPageId(created.page.id);
    context.read<CellsProvider>().setContext(
      pageId: created.page.id,
      year: widget.now().year,
    );
    _created = created;
    return created;
  }

  Future<void> _pickColor(String color) => _run(() async {
    final created = await _ensureCreated();
    if (created == null || !mounted) return false;
    final today = widget.now();
    final cells = context.read<CellsProvider>();
    cells.setContext(pageId: created.page.id, year: today.year);
    await cells.setCell(today.month, today.day, color);
    // setCell reverts silently when the server refuses: ask the store.
    if (cells.getCell(today.month, today.day)?.color != color) return false;
    _todayColor = color;
    await FirstTrackerScreen.markDone(widget.userId);
    return true;
  });

  Future<void> _notToday() => _run(() async {
    final created = await _ensureCreated();
    if (created == null) return false;
    await FirstTrackerScreen.markDone(widget.userId);
    if (mounted) widget.onOpenTracker(created.page.id, widget.now().year);
    return true;
  });

  void _open() {
    final created = _created;
    if (created != null) {
      widget.onOpenTracker(created.page.id, widget.now().year);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _ShellButton(
                  label: lang.t('firstTracker.later'),
                  onTap: _later,
                ),
              ),
            ),
            // Centered when it fits, scrollable when it does not (keyboard
            // open on "Other…", Larger Text).
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: SlideSwitcher(
                          direction: 1,
                          child: KeyedSubtree(
                            key: ValueKey(_step),
                            child: _step == _Step.choose ? _buildChoose(lang) : _buildToday(lang),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoose(LanguageProvider lang) {
    final columns = MediaQuery.of(context).size.width >= 600 ? 3 : 2;
    return _Card(
      children: [
        Text(
          lang.t('firstTracker.title'),
          style: AppFonts.pixel(fontSize: 18, color: AppColors.title),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          lang.t('firstTracker.subtitle'),
          style: AppFonts.dot(fontSize: 14, color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            for (final t in firstTrackerTemplates)
              _Tile(
                label: lang.t(t.titleKey),
                colors: t.colors,
                placeholder: t.customTitle,
                plusLabel: '+ ${lang.t('firstTracker.titleField')}',
                selected: _titleOpen && identical(t, _template),
                onTap: () => _choose(t),
              ),
          ],
        ),
        if (_titleOpen) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            autofocus: true,
            // Server limit, counted the server's way (UTF-16 units).
            inputFormatters: const [Utf16LengthLimit(35)],
            style: AppFonts.dot(fontSize: 14, color: AppColors.inputText),
            decoration: InputDecoration(
              hintText: lang.t('firstTracker.titleField'),
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              isDense: true,
            ),
            onSubmitted: (_) => _continueWithTitle(),
          ),
          const SizedBox(height: 12),
          _PrimaryButton(
            label: lang.t('firstTracker.continue'),
            enabled: _titleController.text.trim().isNotEmpty,
            onTap: _continueWithTitle,
          ),
        ],
      ],
    );
  }

  Widget _buildToday(LanguageProvider lang) {
    final today = widget.now();
    final legends = _template!.legends(lang);
    return _Card(
      children: [
        if (_renaming)
          TextField(
            key: const Key('firstTracker.title'),
            controller: _renameController,
            autofocus: true,
            textAlign: TextAlign.center,
            inputFormatters: const [Utf16LengthLimit(35)],
            style: AppFonts.pixel(fontSize: 16, color: AppColors.title),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onSubmitted: (_) => _commitRename(lang),
            onTapOutside: (_) => _commitRename(lang),
          )
        else
          Semantics(
            button: true,
            child: PressScale(
              behavior: HitTestBehavior.opaque,
              onTap: _busy ? null : () => _startRename(lang),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      _title(lang),
                      style: AppFonts.pixel(fontSize: 16, color: AppColors.title),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.edit, size: 12, color: AppColors.accent),
                ],
              ),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          lang.t('firstTracker.renameHint'),
          style: AppFonts.dot(fontSize: 11, color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          lang.longDate(today),
          style: AppFonts.dot(fontSize: 14, color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          lang.t('firstTracker.today'),
          style: AppFonts.pixel(fontSize: 14, color: AppColors.text),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Center(
          child: _BigDot(color: _todayColor, busy: _busy),
        ),
        const SizedBox(height: 20),
        for (final l in legends)
          _LegendButton(
            color: l.color,
            label: l.label,
            selected: _todayColor == l.color,
            enabled: !_busy,
            onTap: () => _pickColor(l.color),
          ),
        if (_error) ...[
          const SizedBox(height: 4),
          Text(
            lang.t('firstTracker.error'),
            style: AppFonts.dot(fontSize: 13, color: AppColors.btnResetText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Center(
            child: _ShellButton(
              label: lang.t('firstTracker.retry'),
              onTap: () {
                final retry = _retry;
                if (retry != null) _run(retry);
              },
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (_todayColor != null)
          _PrimaryButton(
            label: lang.t('firstTracker.open'),
            enabled: !_busy,
            onTap: _open,
          )
        else
          Semantics(
            button: true,
            enabled: !_busy,
            child: PressScale(
              onTap: _busy ? null : _notToday,
              child: Text(
                lang.t('firstTracker.notToday'),
                style: AppFonts.pixel(fontSize: 12, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

/// A random v4 uuid (no package needed).
String _uuidV4() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

Color _hex(String hex) =>
    Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));

/// The shell card used by both screens.
class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.shell,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.shellBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Small bordered button in the shell colors ("Later", "Retry").
class _ShellButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ShellButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: PressScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.shell,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.shellBorder),
          ),
          child: Text(
            label,
            style: AppFonts.pixel(fontSize: 12, color: AppColors.accent),
          ),
        ),
      ),
    );
  }
}

/// Full-width accent button ("Continue", "Open my tracker").
class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _PrimaryButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: PressScale(
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.btnAdd,
              border: Border.all(color: AppColors.btnAddBorder),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: AppFonts.pixel(fontSize: 12, color: AppColors.btnAddText),
            ),
          ),
        ),
      ),
    );
  }
}

/// Template tile: name + its legend dots (empty dots and "+ Title" for Other…).
class _Tile extends StatelessWidget {
  final String label;
  final List<String> colors;
  final bool placeholder;
  final String plusLabel;
  final bool selected;
  final VoidCallback onTap;

  const _Tile({
    required this.label,
    required this.colors,
    required this.placeholder,
    required this.plusLabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: PressScale(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.inputBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppFonts.pixel(fontSize: 11, color: AppColors.title),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final c in colors)
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: placeholder ? AppColors.dotEmpty : _hex(c),
                        border: placeholder
                            ? Border.all(color: AppColors.dotBorder, width: 0.5)
                            : null,
                      ),
                    ),
                ],
              ),
              if (placeholder) ...[
                const SizedBox(height: 6),
                Text(
                  plusLabel,
                  style: AppFonts.dot(fontSize: 11, color: AppColors.accent),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Today's dot: empty, or colored with the grid's "today" ring.
class _BigDot extends StatelessWidget {
  final String? color;
  final bool busy;
  const _BigDot({required this.color, required this.busy});

  @override
  Widget build(BuildContext context) {
    final c = color;
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c != null ? _hex(c) : AppColors.dotEmpty,
              border: c == null ? Border.all(color: AppColors.dotBorder) : null,
            ),
          ),
          if (c != null)
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent, width: 2),
              ),
            ),
          if (busy)
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.accent,
              ),
            ),
        ],
      ),
    );
  }
}

/// One legend as a button: dot + label, highlighted when it is today's color.
class _LegendButton extends StatelessWidget {
  final String color;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _LegendButton({
    required this.color,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        enabled: enabled,
        child: PressScale(
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.accent.withValues(alpha: 0.12)
                  : AppColors.inputBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.inputBorder,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hex(color),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: AppFonts.dot(fontSize: 14, color: AppColors.text),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

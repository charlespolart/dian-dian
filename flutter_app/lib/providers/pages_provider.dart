import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/change_sink.dart';
import '../models/legend_model.dart';
import '../models/page_model.dart';
import '../services/audio_service.dart';

/// A legend to create along with a page (first-tracker flow).
typedef LegendDraft = ({String color, String label});

/// What [PagesProvider.createFirstTracker] returns: the page and its legends,
/// as written on the phone.
class CreatedPage {
  final PageModel page;
  final List<LegendModel> legends;
  const CreatedPage({required this.page, required this.legends});
}

class PagesProvider extends ChangeNotifier {
  final AudioService _audio;
  ChangeSink? _sink;
  static const _uuid = Uuid();

  List<PageModel> _pages = [];
  PageModel? _pendingDeletePage;
  Timer? _deleteTimer;

  List<PageModel> get pages => _pages;
  PageModel? get pendingDeletePage => _pendingDeletePage;

  PagesProvider({AudioService? audio, ChangeSink? sink})
      : _audio = audio ?? AudioService(),
        _sink = sink;

  /// Where this provider writes its changes: the session's copy and queue
  /// (offline sync). Without one (no session), changes stay on screen only.
  void bind(ChangeSink? sink) => _sink = sink;

  /// The user id the trackers made here carry (the session's account).
  String userId = '';

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  /// Replaces the list with the trackers of the phone's copy. A tracker whose
  /// deletion is still undoable stays hidden.
  void applyPages(List<PageModel> pages) {
    final hidden = _pendingDeletePage?.id;
    final kept = {for (final p in pages) p.id};
    _deletedElsewhere.addAll([for (final p in _pages) if (!kept.contains(p.id)) p.id]);
    _pages = [for (final p in pages) if (p.id != hidden) p];
    notifyListeners();
  }

  /// Whether the tracker [id] left the list because the copy no longer has
  /// it — deleted on another device (case 53) — rather than because the
  /// session ended. This phone deletes only through [softDeletePage], which
  /// hides the tracker before the copy loses it.
  bool deletedElsewhere(String id) => _deletedElsewhere.contains(id);
  final Set<String> _deletedElsewhere = {};

  /// Replaces the list with a bootstrap-shaped payload (the 1.4.0 snapshot).
  void applyBootstrap(List<dynamic> list) {
    applyPages(list.map((json) => PageModel.fromJson(_parsePalette(json as Map<String, dynamic>))).toList());
  }

  void clear() {
    _deleteTimer?.cancel();
    _deleteTimer = null;
    _pendingDeletePage = null;
    _deletedElsewhere.clear();
    _pages = [];
    notifyListeners();
  }

  /// True, after telling the user, when the phone cannot write yet (no full
  /// copy of the account, H15): the change is not made.
  bool _refused() {
    final sink = _sink;
    if (sink == null || sink.canWrite) return false;
    sink.refused();
    return true;
  }

  Future<void> _record(String kind, Map<String, dynamic> data, {bool judged = false}) async {
    try {
      await _sink?.record(kind, data, judged: judged);
    } catch (e) {
      debugPrint('PagesProvider: $kind not written: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Changes
  // ---------------------------------------------------------------------------

  /// Creates a tracker at the end of the list, on the phone at once (offline
  /// too, H2); the server receives it with the queue.
  Future<PageModel?> createPage(String title) async {
    if (_refused()) return null;
    final page = PageModel(
      id: _uuid.v4(),
      userId: userId,
      title: title,
      year: DateTime.now().year,
      position: _pages.length,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    _pages = [..._pages, page];
    notifyListeners();
    _audio.play(SoundCue.trackerCreate);
    await _record('page.create', {'id': page.id, 'title': title});
    return page;
  }

  /// Creates a tracker with its [legends]. With [replaces], an empty tracker
  /// of the user is deleted and the new one takes its place. When that
  /// tracker is gone and [fallbackWithoutReplaces] is false (the caller is at
  /// the free limit: a plain creation would be a locked tracker), nothing is
  /// created and null is returned. [clientId], when given, is the new
  /// tracker's id: a retry of the same gesture finds it instead of a twin
  /// (returned without legends: the caller keeps the ones it shows).
  Future<CreatedPage?> createFirstTracker({
    required String title,
    required List<LegendDraft> legends,
    String? replaces,
    bool fallbackWithoutReplaces = true,
    String? clientId,
  }) async {
    if (_refused()) return null;
    final id = clientId ?? _uuid.v4();
    final existing = _pages.where((p) => p.id == id).firstOrNull;
    if (existing != null) return CreatedPage(page: existing, legends: const []);

    var index = _pages.length;
    final replacedIndex = replaces == null ? -1 : _pages.indexWhere((p) => p.id == replaces);
    if (replaces != null && replacedIndex == -1 && !fallbackWithoutReplaces) return null;

    final now = DateTime.now();
    final page = PageModel(
      id: id,
      userId: userId,
      title: title,
      year: now.year,
      position: replacedIndex == -1 ? _pages.length : _pages[replacedIndex].position,
      createdAt: now.toUtc().toIso8601String(),
    );
    final rows = [
      for (var i = 0; i < legends.length; i++)
        LegendModel(id: _uuid.v4(), pageId: id, color: legends[i].color, label: legends[i].label, position: i, createdAt: now.toUtc().toIso8601String()),
    ];
    final next = [..._pages];
    if (replacedIndex != -1) {
      next.removeAt(replacedIndex);
      index = replacedIndex;
    }
    next.insert(index.clamp(0, next.length), page);
    _pages = next;
    notifyListeners();
    _audio.play(SoundCue.trackerCreate);

    // Judged by the server: if another phone just put a day in the tracker
    // being replaced, it is kept (the server's guard of 1.4.0, minor 12).
    if (replacedIndex != -1) await _record('page.delete', {'id': replaces}, judged: true);
    await _record('page.create', {
      'id': id,
      'title': title,
      'legends': [for (final l in rows) {'id': l.id, 'color': l.color, 'label': l.label}],
    });
    if (replacedIndex != -1) {
      await _record('pages.reorder', {'ids': [for (final p in _pages) p.id]});
    }
    return CreatedPage(page: page, legends: rows);
  }

  /// Which trackers stay open on a free account over the limit (≤ the free limit).
  Future<bool> keepFree(List<String> ids) async {
    if (_refused()) return false;
    _pages = [for (final p in _pages) p.copyWith(keepFree: ids.contains(p.id))];
    notifyListeners();
    await _record('pages.keep', {'ids': ids});
    return true;
  }

  /// Renames a tracker or changes its palette (`title`, `palette`).
  Future<void> updatePage(String id, Map<String, dynamic> updates) async {
    if (_refused()) return;
    final index = _pages.indexWhere((p) => p.id == id);
    if (index == -1) return;
    final page = _pages[index];
    final title = updates['title'] as String?;
    final updated = PageModel(
      id: page.id,
      userId: page.userId,
      title: title ?? page.title,
      year: page.year,
      position: page.position,
      palette: updates.containsKey('palette') ? _palette(updates['palette']) : page.palette,
      createdAt: page.createdAt,
      recentCells: page.recentCells,
      lastCellAt: page.lastCellAt,
      keepFree: page.keepFree,
    );
    _pages = [..._pages]..[index] = updated;
    notifyListeners();
    await _record('page.update', {
      'id': id,
      'title': ?title,
      if (updates.containsKey('palette')) 'palette': updates['palette'],
    });
  }

  Future<void> reorderPages(List<String> ids) async {
    if (_refused()) return;
    _applyOrder(ids);
    notifyListeners();
    await _record('pages.reorder', {'ids': ids});
  }

  /// Reorders locally by [ids]; pages absent from [ids] keep their relative
  /// order at the end.
  void _applyOrder(List<String> ids) {
    final byId = {for (final p in _pages) p.id: p};
    final seen = ids.toSet();
    final ordered = <PageModel>[];
    for (final id in ids) {
      final page = byId[id];
      if (page != null) ordered.add(page.copyWith(position: ordered.length));
    }
    for (final p in _pages) {
      if (!seen.contains(p.id)) ordered.add(p.copyWith(position: ordered.length));
    }
    _pages = ordered;
  }

  /// Soft-delete a page: hidden at once, deleted after [delay] unless undone.
  /// The deletion is held on the phone meanwhile: an app killed during the
  /// delay finds it done when reopened (H14).
  void softDeletePage(PageModel page, {Duration delay = const Duration(seconds: 8)}) {
    if (_refused()) return;
    // Cancel any previous pending delete
    _commitPendingDelete();

    _pendingDeletePage = page;
    _pages = [for (final p in _pages) if (p.id != page.id) p];
    notifyListeners();
    unawaited(_hold(page.id, release: false));

    _deleteTimer = Timer(delay, () {
      _commitPendingDelete();
    });
  }

  /// Undo a pending soft delete.
  void undoDeletePage() {
    _deleteTimer?.cancel();
    _deleteTimer = null;
    final page = _pendingDeletePage;
    if (page != null) {
      _pendingDeletePage = null;
      _reinsert(page, _pages.length);
      notifyListeners();
      unawaited(_hold(page.id, release: true));
    }
  }

  /// Cancel pending delete without committing (used on logout). Its hold
  /// stays on the phone: if the copy is kept (the server closed the
  /// session, H25), the next session of this account finds it done.
  void cancelPendingDelete() {
    _deleteTimer?.cancel();
    _deleteTimer = null;
    final page = _pendingDeletePage;
    if (page != null) {
      _pendingDeletePage = null;
      _reinsert(page, _pages.length);
      notifyListeners();
    }
  }

  void _commitPendingDelete() {
    _deleteTimer?.cancel();
    _deleteTimer = null;
    final page = _pendingDeletePage;
    if (page != null) {
      _pendingDeletePage = null;
      unawaited(_record('page.delete', {'id': page.id}));
      notifyListeners();
    }
  }

  /// Deletes a page at once.
  Future<void> deletePage(String id) async {
    if (_refused()) return;
    final before = _pages.length;
    _pages = [for (final p in _pages) if (p.id != id) p];
    if (_pages.length != before) {
        notifyListeners();
    }
    await _record('page.delete', {'id': id});
  }

  Future<void> _hold(String pageId, {required bool release}) async {
    try {
      release ? await _sink?.releaseDelete(pageId) : await _sink?.holdDelete(pageId);
    } catch (e) {
      debugPrint('PagesProvider: delete hold not written: $e');
    }
  }

  void _reinsert(PageModel page, int index) {
    if (_pages.any((p) => p.id == page.id)) return;
    _pages = [..._pages]..insert(index.clamp(0, _pages.length), page);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Parses the `palette` field when it arrives as a JSON string rather than
  /// an already-decoded list.
  Map<String, dynamic> _parsePalette(Map<String, dynamic> json) {
    final palette = json['palette'];
    if (palette is String) {
      return {...json, 'palette': jsonDecode(palette)};
    }
    return json;
  }

  static List<List<String>>? _palette(Object? raw) =>
      raw == null ? null : [for (final row in raw as List) (row as List).cast<String>()];

  @override
  void dispose() {
    _deleteTimer?.cancel();
    super.dispose();
  }
}

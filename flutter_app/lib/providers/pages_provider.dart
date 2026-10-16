import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/legend_model.dart';
import '../models/page_model.dart';
import '../services/api_service.dart';
import '../services/ws_service.dart';

/// A legend to create along with a page (first-tracker flow).
typedef LegendDraft = ({String color, String label});

/// What [PagesProvider.createFirstTracker] returns: the page and its legends
/// as the server stored them.
class CreatedPage {
  final PageModel page;
  final List<LegendModel> legends;
  const CreatedPage({required this.page, required this.legends});
}

class PagesProvider extends ChangeNotifier {
  final ApiService _api;
  final WsService _ws = WsService();
  RemoveListener? _removeWsListener;

  List<PageModel> _pages = [];
  PageModel? _pendingDeletePage;
  Timer? _deleteTimer;
  int _mutationEpoch = 0;

  List<PageModel> get pages => _pages;
  PageModel? get pendingDeletePage => _pendingDeletePage;

  /// Incremented by every change that did NOT come from a bootstrap apply
  /// (optimistic edits, reverts, WS events). `SyncService` uses it to know
  /// whether a server body may be skipped or must be (re)applied.
  int get mutationEpoch => _mutationEpoch;
  void _touch() => _mutationEpoch++;

  PagesProvider({ApiService? api}) : _api = api ?? ApiService() {
    _removeWsListener = _ws.addListener(_onWsMessage);
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Replaces the page list with the bootstrap payload (pushed by `SyncService`).
  void applyBootstrap(List<dynamic> list) {
    _pages = list
        .map((json) => PageModel.fromJson(_parsePalette(json as Map<String, dynamic>)))
        .toList();
    notifyListeners();
  }

  void clear() {
    _deleteTimer?.cancel();
    _deleteTimer = null;
    _pendingDeletePage = null;
    _pages = [];
    notifyListeners();
  }

  /// Creates a new page on the server and returns the created [PageModel],
  /// or `null` if the request failed.
  Future<PageModel?> createPage(String title) async {
    try {
      final response = await _api.apiFetch(
        '/api/pages',
        method: 'POST',
        body: {
          'title': title,
          'position': _pages.length,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final page = PageModel.fromJson(_parsePalette(json));
        if (!_pages.any((p) => p.id == page.id)) {
          _pages.add(page);
          _touch();
        }
        notifyListeners();
        return page;
      }
    } catch (e) {
      debugPrint('PagesProvider: createPage failed: $e');
    }
    return null;
  }

  /// Creates a page with its [legends] in one server transaction (backend
  /// ≥ 1.2.0). With [replaces], an empty page of the user is deleted in that
  /// transaction and the new page takes its slot; if the server refuses it
  /// (404 gone, 409 not empty any more) the page is created without
  /// replacing anything — unless [fallbackWithoutReplaces] is false (the
  /// caller is at the free limit and a plain creation would be a locked
  /// tracker), in which case the refusal is a failure. Returns `null` on
  /// failure: nothing was created.
  Future<CreatedPage?> createFirstTracker({
    required String title,
    required List<LegendDraft> legends,
    String? replaces,
    bool fallbackWithoutReplaces = true,
    String? clientId,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'legends': [for (final l in legends) {'color': l.color, 'label': l.label}],
      if (replaces != null) 'replaces': replaces else 'position': _pages.length,
      // Idempotency key (backend ≥ 1.2.0): a retry after a lost response
      // gets the page already created (200) instead of a twin.
      'clientId': ?clientId,
    };
    try {
      var response = await _api.apiFetch('/api/pages', method: 'POST', body: body);
      if (replaces != null &&
          fallbackWithoutReplaces &&
          (response.statusCode == 404 || response.statusCode == 409)) {
        body.remove('replaces');
        body['position'] = _pages.length;
        response = await _api.apiFetch('/api/pages', method: 'POST', body: body);
      }
      if (response.statusCode != 201 && response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final page = PageModel.fromJson(_parsePalette(json));
      final legendRows = (json['legends'] as List<dynamic>? ?? const [])
          .map((j) => LegendModel.fromJson(j as Map<String, dynamic>))
          .toList(growable: false);

      // The replaced page leaves; the new one takes its index (or the end).
      var index = _pages.length;
      final replaced = json['replaced'] as String?;
      if (replaced != null) {
        final i = _pages.indexWhere((p) => p.id == replaced);
        if (i != -1) {
          _pages.removeAt(i);
          index = i;
        }
      }
      if (!_pages.any((p) => p.id == page.id)) {
        _pages.insert(index.clamp(0, _pages.length), page);
      }
      _touch();
      notifyListeners();
      return CreatedPage(page: page, legends: legendRows);
    } catch (e) {
      debugPrint('PagesProvider: createFirstTracker failed: $e');
      return null;
    }
  }

  /// Which trackers stay open on a free account over the limit (≤ the free
  /// limit). Optimistic; reverted when the server refuses.
  Future<bool> keepFree(List<String> ids) async {
    final previous = _pages;
    _pages = [for (final p in _pages) p.copyWith(keepFree: ids.contains(p.id))];
    _touch();
    notifyListeners();
    try {
      final response = await _api.apiFetch('/api/pages/keep', method: 'PUT', body: {'ids': ids});
      if (response.statusCode == 200) return true;
    } catch (e) {
      debugPrint('PagesProvider: keepFree failed: $e');
    }
    _pages = previous;
    _touch();
    notifyListeners();
    return false;
  }

  Future<void> updatePage(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _api.apiFetch(
        '/api/pages/$id',
        method: 'PATCH',
        body: updates,
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final updated = PageModel.fromJson(_parsePalette(json));
        final index = _pages.indexWhere((p) => p.id == id);
        if (index != -1) {
          _pages[index] = updated;
          _touch();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('PagesProvider: updatePage failed: $e');
    }
  }

  Future<void> reorderPages(List<String> ids) async {
    final previous = _pages;
    _applyOrder(ids);
    _touch();
    notifyListeners();

    // One request + one transaction server-side (was a PATCH per page).
    try {
      final response = await _api.apiFetch(
        '/api/pages/reorder',
        method: 'PUT',
        body: {'ids': ids},
      );
      if (response.statusCode != 200) {
        _pages = previous;
        _touch();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('PagesProvider: reorderPages failed: $e');
      _pages = previous;
      _touch();
      notifyListeners();
    }
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

  /// Soft-delete a page: remove locally, start timer, delete on server after delay.
  void softDeletePage(PageModel page, {Duration delay = const Duration(seconds: 8)}) {
    // Cancel any previous pending delete
    _commitPendingDelete();

    _pendingDeletePage = page;
    _pages.removeWhere((p) => p.id == page.id);
    _touch();
    notifyListeners();

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
    }
  }

  /// Cancel pending delete without committing (used on logout).
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
      // Already removed locally by softDeletePage; put it back if the server says no.
      _deleteOnServer(page.id, restore: page, restoreIndex: _pages.length);
      notifyListeners();
    }
  }

  /// Hard delete: removes locally at once, restores the page if the server
  /// rejects the request (a 404 means it is already gone — keep it gone).
  Future<void> deletePage(String id) async {
    final index = _pages.indexWhere((p) => p.id == id);
    final page = index == -1 ? null : _pages[index];
    if (page != null) {
      _pages.removeAt(index);
      _touch();
      notifyListeners();
    }
    await _deleteOnServer(id, restore: page, restoreIndex: index);
  }

  Future<void> _deleteOnServer(String id, {PageModel? restore, int restoreIndex = -1}) async {
    try {
      final response = await _api.apiFetch('/api/pages/$id', method: 'DELETE');
      final gone = response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 404;
      if (!gone && restore != null) {
        _reinsert(restore, restoreIndex);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('PagesProvider: deletePage failed: $e');
      if (restore != null) {
        _reinsert(restore, restoreIndex);
        notifyListeners();
      }
    }
  }

  void _reinsert(PageModel page, int index) {
    if (_pages.any((p) => p.id == page.id)) return;
    _pages.insert(index.clamp(0, _pages.length), page);
    _touch();
  }

  // ---------------------------------------------------------------------------
  // WebSocket
  // ---------------------------------------------------------------------------

  @visibleForTesting
  void debugHandleWs(WsMessage message) => _onWsMessage(message);

  void _onWsMessage(WsMessage message) {
    switch (message.event) {
      case 'page:created':
        final json = message.data as Map<String, dynamic>;
        final page = PageModel.fromJson(_parsePalette(json));
        if (!_pages.any((p) => p.id == page.id)) {
          _pages.add(page);
          _touch();
          notifyListeners();
        }
        break;

      case 'page:updated':
        final json = message.data as Map<String, dynamic>;
        final updated = PageModel.fromJson(_parsePalette(json));
        final index = _pages.indexWhere((p) => p.id == updated.id);
        if (index != -1) {
          _pages[index] = updated;
          _touch();
          notifyListeners();
        }
        break;

      case 'page:deleted':
        final json = message.data as Map<String, dynamic>;
        final id = json['id'] as String;
        final before = _pages.length;
        _pages.removeWhere((p) => p.id == id);
        if (_pages.length != before) _touch();
        notifyListeners();
        break;

      case 'pages:reordered':
        final json = message.data as Map<String, dynamic>;
        final ids = (json['ids'] as List<dynamic>?)?.cast<String>();
        if (ids == null) break;
        _applyOrder(ids);
        _touch();
        notifyListeners();
        break;

      case 'pages:kept':
        final json = message.data as Map<String, dynamic>;
        final ids = (json['ids'] as List<dynamic>?)?.cast<String>();
        if (ids == null) break;
        _pages = [for (final p in _pages) p.copyWith(keepFree: ids.contains(p.id))];
        _touch();
        notifyListeners();
        break;
    }
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

  @override
  void dispose() {
    _removeWsListener?.call();
    super.dispose();
  }
}

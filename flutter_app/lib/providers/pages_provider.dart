import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/page_model.dart';
import '../services/api_service.dart';
import '../services/ws_service.dart';

class PagesProvider extends ChangeNotifier {
  final ApiService _api;
  final WsService _ws = WsService();
  RemoveListener? _removeWsListener;

  List<PageModel> _pages = [];
  PageModel? _pendingDeletePage;
  Timer? _deleteTimer;

  List<PageModel> get pages => _pages;
  PageModel? get pendingDeletePage => _pendingDeletePage;

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
        }
        notifyListeners();
        return page;
      }
    } catch (e) {
      debugPrint('PagesProvider: createPage failed: $e');
    }
    return null;
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
        notifyListeners();
      }
    } catch (e) {
      debugPrint('PagesProvider: reorderPages failed: $e');
      _pages = previous;
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
      if (!_pages.any((p) => p.id == page.id)) {
        _pages.add(page);
      }
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
      if (!_pages.any((p) => p.id == page.id)) {
        _pages.add(page);
      }
      notifyListeners();
    }
  }

  void _commitPendingDelete() {
    _deleteTimer?.cancel();
    _deleteTimer = null;
    final page = _pendingDeletePage;
    if (page != null) {
      _pendingDeletePage = null;
      deletePage(page.id);
      notifyListeners();
    }
  }

  Future<void> deletePage(String id) async {
    try {
      final response = await _api.apiFetch(
        '/api/pages/$id',
        method: 'DELETE',
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        _pages.removeWhere((p) => p.id == id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('PagesProvider: deletePage failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // WebSocket
  // ---------------------------------------------------------------------------

  void _onWsMessage(WsMessage message) {
    switch (message.event) {
      case 'page:created':
        final json = message.data as Map<String, dynamic>;
        final page = PageModel.fromJson(_parsePalette(json));
        if (!_pages.any((p) => p.id == page.id)) {
          _pages.add(page);
          notifyListeners();
        }
        break;

      case 'page:updated':
        final json = message.data as Map<String, dynamic>;
        final updated = PageModel.fromJson(_parsePalette(json));
        final index = _pages.indexWhere((p) => p.id == updated.id);
        if (index != -1) {
          _pages[index] = updated;
          notifyListeners();
        }
        break;

      case 'page:deleted':
        final json = message.data as Map<String, dynamic>;
        final id = json['id'] as String;
        _pages.removeWhere((p) => p.id == id);
        notifyListeners();
        break;

      case 'pages:reordered':
        final json = message.data as Map<String, dynamic>;
        final ids = (json['ids'] as List<dynamic>?)?.cast<String>();
        if (ids == null) break;
        _applyOrder(ids);
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

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/page_model.dart';
import '../services/api_service.dart';
import '../services/ws_service.dart';

class PagesProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final WsService _ws = WsService();
  RemoveListener? _removeWsListener;

  List<PageModel> _pages = [];
  PageModel? _pendingDeletePage;
  Timer? _deleteTimer;

  List<PageModel> get pages => _pages;
  PageModel? get pendingDeletePage => _pendingDeletePage;

  PagesProvider() {
    _removeWsListener = _ws.addListener(_onWsMessage);
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<void> fetchPages() async {
    try {
      final response = await _api.apiFetch('/api/pages');
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        _pages = list
            .map((json) => PageModel.fromJson(_parsePalette(json as Map<String, dynamic>)))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('PagesProvider: fetchPages failed: $e');
    }
  }

  Future<void> createPage(String title, {int? year}) async {
    try {
      final response = await _api.apiFetch(
        '/api/pages',
        method: 'POST',
        body: {
          'title': title,
          'year': year ?? DateTime.now().year,
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
      }
    } catch (e) {
      debugPrint('PagesProvider: createPage failed: $e');
    }
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
    // Optimistic: reorder local list and update positions
    final reordered = <PageModel>[];
    for (int i = 0; i < ids.length; i++) {
      try {
        final page = _pages.firstWhere((p) => p.id == ids[i]);
        reordered.add(page.copyWith(position: i));
      } catch (_) {}
    }
    // Keep pages not in ids list unchanged
    final otherPages = _pages.where((p) => !ids.contains(p.id)).toList();
    _pages = [...reordered, ...otherPages];
    notifyListeners();

    // Update positions on server
    for (int i = 0; i < ids.length; i++) {
      _api.apiFetch(
        '/api/pages/${ids[i]}',
        method: 'PATCH',
        body: {'position': i},
      );
    }
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

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/legend_model.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../services/ws_service.dart';

/// Legends of every page, keyed by page id. Lists are copy-on-write
/// (unmodifiable), so a list instance changes exactly when its content does.
///
/// Loading happens through [applyBootstrap] (pushed by `SyncService`); the
/// current page is only a pointer, so [setPageId] is synchronous.
class LegendsProvider extends ChangeNotifier {
  final ApiService _api;
  final AudioService _audio;
  final WsService _ws = WsService();
  RemoveListener? _removeWsListener;

  final Map<String, List<LegendModel>> _byPage = {};
  String? _currentPageId;
  int _mutationEpoch = 0;

  /// Incremented by every change that did NOT come from a bootstrap apply.
  int get mutationEpoch => _mutationEpoch;

  LegendsProvider({ApiService? api, AudioService? audio})
      : _api = api ?? ApiService(),
        _audio = audio ?? AudioService() {
    _removeWsListener = _ws.addListener(_onWsMessage);
  }

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  String? get currentPageId => _currentPageId;

  List<LegendModel> get legends {
    final pageId = _currentPageId;
    return pageId == null ? const [] : legendsFor(pageId);
  }

  List<LegendModel> legendsFor(String pageId) => _byPage[pageId] ?? const [];

  // ---------------------------------------------------------------------------
  // Active page / bulk load
  // ---------------------------------------------------------------------------

  void setPageId(String? id) {
    _currentPageId = id;
    notifyListeners();
  }

  /// Replaces everything with the bootstrap payload `{ pageId: [legend, ...] }`.
  void applyBootstrap(Map<String, dynamic> byPage) {
    _byPage.clear();
    byPage.forEach((pageId, list) {
      // Direct write: a bootstrap apply must not bump the mutation epoch.
      _byPage[pageId] = List.unmodifiable(
        (list as List<dynamic>).map((j) => LegendModel.fromJson(j as Map<String, dynamic>)),
      );
    });
    notifyListeners();
  }

  /// Replaces the legends of [pageId] with [list] — used right after a page
  /// is created together with its legends, without waiting for the WS echo.
  void setLegends(String pageId, List<LegendModel> list) {
    _set(pageId, list);
    notifyListeners();
  }

  void clear() {
    _byPage.clear();
    _currentPageId = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Internal copy-on-write helpers
  // ---------------------------------------------------------------------------

  void _set(String pageId, List<LegendModel> list) {
    _byPage[pageId] = List.unmodifiable(list);
    _mutationEpoch++;
  }

  String? _pageOf(String legendId) {
    for (final e in _byPage.entries) {
      if (e.value.any((l) => l.id == legendId)) return e.key;
    }
    return null;
  }

  bool _add(LegendModel legend) {
    final list = legendsFor(legend.pageId);
    if (list.any((l) => l.id == legend.id)) return false;
    _set(legend.pageId, [...list, legend]);
    return true;
  }

  bool _replace(LegendModel legend) {
    final list = legendsFor(legend.pageId);
    final i = list.indexWhere((l) => l.id == legend.id);
    if (i == -1) return false;
    final copy = [...list];
    copy[i] = legend;
    _set(legend.pageId, copy);
    return true;
  }

  bool _remove(String pageId, String id) {
    final list = legendsFor(pageId);
    if (!list.any((l) => l.id == id)) return false;
    _set(pageId, list.where((l) => l.id != id).toList());
    return true;
  }

  /// Orders by [ids]; legends absent from [ids] keep their relative order at
  /// the end rather than vanishing.
  void _reorder(String pageId, List<String> ids) {
    final list = legendsFor(pageId);
    final byId = {for (final l in list) l.id: l};
    final seen = ids.toSet();
    _set(pageId, [
      for (final id in ids)
        if (byId.containsKey(id)) byId[id]!,
      ...list.where((l) => !seen.contains(l.id)),
    ]);
  }

  void _recolor(String pageId, Map<String, String> colorMap) {
    final list = legendsFor(pageId);
    _set(pageId, [
      for (final l in list)
        colorMap.containsKey(l.color) ? l.copyWith(color: colorMap[l.color]) : l,
    ]);
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  Future<void> createLegend(String color, String label) async {
    final pageId = _currentPageId;
    if (pageId == null) return;

    try {
      final response = await _api.apiFetch(
        '/api/legends/$pageId',
        method: 'POST',
        body: {'color': color, 'label': label, 'position': legendsFor(pageId).length},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        _add(LegendModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>));
        notifyListeners();
        _audio.play(SoundCue.legendAdd);
      }
    } catch (e) {
      debugPrint('LegendsProvider: createLegend failed: $e');
    }
  }

  Future<void> updateLegend(String id, {String? label, String? color}) async {
    try {
      final body = <String, dynamic>{};
      if (label != null) body['label'] = label;
      if (color != null) body['color'] = color;
      final response = await _api.apiFetch('/api/legends/$id', method: 'PATCH', body: body);
      if (response.statusCode == 200) {
        _replace(LegendModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('LegendsProvider: updateLegend failed: $e');
    }
  }

  Future<void> deleteLegend(String id) async {
    final pageId = _pageOf(id) ?? _currentPageId;
    if (pageId == null) return;

    try {
      final response = await _api.apiFetch('/api/legends/$id', method: 'DELETE');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _remove(pageId, id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('LegendsProvider: deleteLegend failed: $e');
    }
  }

  Future<void> reorderLegends(List<String> ids) async {
    final pageId = _currentPageId;
    if (pageId == null) return;

    final previous = legendsFor(pageId);
    _reorder(pageId, ids);
    notifyListeners();

    try {
      final response = await _api.apiFetch(
        '/api/legends/$pageId/reorder',
        method: 'PUT',
        body: {'ids': ids},
      );
      if (response.statusCode != 200) {
        _set(pageId, previous);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('LegendsProvider: reorderLegends failed: $e');
      _set(pageId, previous);
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // WebSocket — events apply to ANY page so card previews stay fresh too
  // ---------------------------------------------------------------------------

  @visibleForTesting
  void debugHandleWs(WsMessage message) => _onWsMessage(message);

  void _onWsMessage(WsMessage message) {
    switch (message.event) {
      case 'legend:created':
        if (_add(LegendModel.fromJson(message.data as Map<String, dynamic>))) {
          notifyListeners();
        }

      case 'legend:updated':
        if (_replace(LegendModel.fromJson(message.data as Map<String, dynamic>))) {
          notifyListeners();
        }

      case 'legend:deleted':
        final json = message.data as Map<String, dynamic>;
        final id = json['id'] as String;
        final pageId = (json['pageId'] ?? json['page_id']) as String? ?? _pageOf(id);
        if (pageId != null && _remove(pageId, id)) notifyListeners();

      case 'legends:reordered':
        final json = message.data as Map<String, dynamic>;
        final pageId = (json['pageId'] ?? json['page_id']) as String?;
        final ids = (json['ids'] as List<dynamic>?)?.cast<String>();
        if (pageId == null || ids == null) return;
        _reorder(pageId, ids);
        notifyListeners();

      case 'legends:recolored':
        final json = message.data as Map<String, dynamic>;
        final pageId = (json['pageId'] ?? json['page_id']) as String?;
        final raw = json['colorMap'] as Map<String, dynamic>?;
        if (pageId == null || raw == null) return;
        _recolor(pageId, raw.map((k, v) => MapEntry(k, v as String)));
        notifyListeners();

      case 'page:created':
        // Backend ≥ 1.2.0 sends the legends created with the page.
        final json = message.data as Map<String, dynamic>;
        final rows = json['legends'] as List<dynamic>?;
        final pageId = json['id'] as String?;
        if (rows == null || pageId == null) return;
        _set(pageId, [for (final j in rows) LegendModel.fromJson(j as Map<String, dynamic>)]);
        notifyListeners();

      case 'page:deleted':
        final json = message.data as Map<String, dynamic>;
        final pageId = json['id'] as String?;
        if (pageId != null && _byPage.remove(pageId) != null) {
          _mutationEpoch++;
          notifyListeners();
        }
    }
  }

  @override
  void dispose() {
    _removeWsListener?.call();
    super.dispose();
  }
}

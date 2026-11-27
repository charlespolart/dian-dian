import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/change_sink.dart';
import '../models/legend_model.dart';
import '../services/audio_service.dart';

/// Legends of every page, keyed by page id. Lists are copy-on-write
/// (unmodifiable), so a list instance changes exactly when its content does.
///
/// Loading happens through [applyBootstrap] (pushed by `SyncService`); the
/// current page is only a pointer, so [setPageId] is synchronous.
class LegendsProvider extends ChangeNotifier {
  final AudioService _audio;
  ChangeSink? _sink;
  static const _uuid = Uuid();

  final Map<String, List<LegendModel>> _byPage = {};
  String? _currentPageId;

  LegendsProvider({AudioService? audio, ChangeSink? sink})
      : _audio = audio ?? AudioService(),
        _sink = sink;

  /// Where changes are written: the session's copy and queue (offline sync).
  void bind(ChangeSink? sink) => _sink = sink;

  /// Replaces every page's legends with the phone's copy.
  void applyCopy(Map<String, List<LegendModel>> byPage) {
    _byPage
      ..clear()
      ..addAll({for (final e in byPage.entries) e.key: List.unmodifiable(e.value)});
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

  Future<void> _record(String kind, Map<String, dynamic> data) async {
    try {
      await _sink?.record(kind, data);
    } catch (e) {
      debugPrint('LegendsProvider: $kind not written: $e');
    }
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

  /// Replaces everything with the bootstrap payload `{ pageId: [legend, ...] }`
  /// (the 1.4.0 snapshot).
  void applyBootstrap(Map<String, dynamic> byPage) {
    _byPage.clear();
    byPage.forEach((pageId, list) {
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

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  Future<void> createLegend(String color, String label) async {
    final pageId = _currentPageId;
    if (pageId == null || _refused()) return;
    final legend = LegendModel(
      id: _uuid.v4(),
      pageId: pageId,
      color: color,
      label: label,
      position: legendsFor(pageId).length,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    _add(legend);
    notifyListeners();
    _audio.play(SoundCue.legendAdd);
    await _record('legend.create', {'id': legend.id, 'pageId': pageId, 'color': color, 'label': label});
  }

  /// Renames or recolours a legend. A new colour is one change: the copy
  /// recolours the legend's days with it (CellsProvider.recolorCells shows it).
  Future<void> updateLegend(String id, {String? label, String? color}) async {
    final pageId = _pageOf(id);
    if (pageId == null || _refused()) return;
    final old = legendsFor(pageId).firstWhere((l) => l.id == id);
    _replace(old.copyWith(label: label, color: color));
    notifyListeners();
    await _record('legend.update', {'id': id, 'label': ?label, 'color': ?color});
  }

  Future<void> deleteLegend(String id) async {
    final pageId = _pageOf(id) ?? _currentPageId;
    if (pageId == null || _refused()) return;
    _remove(pageId, id);
    notifyListeners();
    await _record('legend.delete', {'id': id});
  }

  Future<void> reorderLegends(List<String> ids) async {
    final pageId = _currentPageId;
    if (pageId == null || _refused()) return;
    _reorder(pageId, ids);
    notifyListeners();
    await _record('legends.reorder', {'pageId': pageId, 'ids': ids});
  }

}

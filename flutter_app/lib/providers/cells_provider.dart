import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/cell_change.dart';
import '../models/cell_model.dart';
import '../models/year_cells.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../services/ws_service.dart';

/// Holds every year of cells the app has loaded, for every page, as
/// immutable [YearCells] keyed by `'$pageId:$year'`.
///
/// Loading is NOT this class's job: `SyncService` fetches a whole year for
/// all pages in one request and pushes it in through [applyBootstrap]. The
/// "current" page/year is only a pointer into the store, so opening a
/// tracker or switching years is synchronous and never shows an empty grid
/// for data we already have.
class CellsProvider extends ChangeNotifier {
  final ApiService _api;
  final AudioService _audio;
  final WsService _ws = WsService();
  RemoveListener? _removeWsListener;

  final Map<String, YearCells> _store = {};
  final Set<int> _loadedYears = {};
  String? _currentPageId;
  int _currentYear = DateTime.now().year;
  int _mutationEpoch = 0;
  CellChange? _lastChange;
  int _changeSeq = 0;

  /// Incremented by every store change that did NOT come from a bootstrap
  /// apply (optimistic edits, reverts, WS events). `SyncService` uses it to
  /// decide whether a server body may be skipped or must be (re)applied.
  int get mutationEpoch => _mutationEpoch;
  void _touch() => _mutationEpoch++;

  /// The last cell this device changed (for the grid's pop); null after a
  /// revert, a clear, or before any local change.
  CellChange? get lastChange => _lastChange;

  CellsProvider({ApiService? api, AudioService? audio})
      : _api = api ?? ApiService(),
        _audio = audio ?? AudioService() {
    _removeWsListener = _ws.addListener(_onWsMessage);
  }

  static String _key(String pageId, int year) => '$pageId:$year';

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  String? get currentPageId => _currentPageId;
  int get currentYear => _currentYear;

  /// Cells of a (page, year), or `null` when that year was never loaded for
  /// this page. Identity changes exactly when the data changes.
  YearCells? cellsFor(String pageId, int year) => _store[_key(pageId, year)];

  YearCells? get current {
    final pageId = _currentPageId;
    return pageId == null ? null : _store[_key(pageId, _currentYear)];
  }

  /// Flat list view of [current] — used by dialogs and the PNG export.
  List<CellModel> get cells => current?.values.toList(growable: false) ?? const [];

  /// True once a bootstrap for [year] has been applied (every page's cells
  /// for that year are known, possibly empty).
  bool isYearLoaded(int year) => _loadedYears.contains(year);

  CellModel? getCell(int month, int day) => current?.get(month, day);
  String? getCellColor(int month, int day) => getCell(month, day)?.color;

  // ---------------------------------------------------------------------------
  // Active page + year (synchronous — no fetch)
  // ---------------------------------------------------------------------------

  void setContext({required String? pageId, required int year}) {
    _currentPageId = pageId;
    _currentYear = year;
    notifyListeners();
  }

  void setYear(int year) {
    if (year == _currentYear) return;
    _currentYear = year;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Bulk load (SyncService)
  // ---------------------------------------------------------------------------

  /// Replaces every entry of [year] with the bootstrap payload
  /// `{ pageId: [[month, day, color, comment?], ...] }`.
  void applyBootstrap(int year, Map<String, dynamic> cellsByPage) {
    _store.removeWhere((_, yc) => yc.year == year);
    cellsByPage.forEach((pageId, rows) {
      _store[_key(pageId, year)] = YearCells.fromCompact(pageId, year, rows as List<dynamic>);
    });
    _loadedYears.add(year);
    notifyListeners();
  }

  void clear() {
    _store.clear();
    _loadedYears.clear();
    _currentPageId = null;
    _currentYear = DateTime.now().year;
    _statsValid = false;
    _lastChange = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Stats (memoized on the current YearCells instance + calendar day)
  // ---------------------------------------------------------------------------

  YearCells? _statsSource;
  bool _statsValid = false;
  int _statsDay = 0;
  int _filledDays = 0;
  int _streak = 0;

  int get filledDays {
    _ensureStats();
    return _filledDays;
  }

  /// Consecutive filled days ending today (or yesterday when today is still
  /// empty), scoped to the current year.
  int get currentStreak {
    _ensureStats();
    return _streak;
  }

  void _ensureStats() {
    final c = current;
    final now = DateTime.now();
    final dayStamp = now.year * 10000 + now.month * 100 + now.day;
    if (_statsValid && identical(c, _statsSource) && dayStamp == _statsDay) return;
    _statsSource = c;
    _statsDay = dayStamp;
    _statsValid = true;
    _filledDays = c?.length ?? 0;
    _streak = _computeStreak(c, now);
  }

  static int _computeStreak(YearCells? c, DateTime now) {
    if (c == null || c.isEmpty) return 0;
    final year = c.year;
    var check = DateTime(now.year, now.month, now.day);
    if (check.year != year) check = DateTime(year, 12, 31);
    // Today may simply not be filled yet — a streak that ended yesterday still counts.
    if (c.get(check.month, check.day) == null) {
      check = DateTime(check.year, check.month, check.day - 1);
    }
    var streak = 0;
    while (check.year == year && c.get(check.month, check.day) != null) {
      streak++;
      // Day arithmetic (not Duration) so DST changes can't skip a date.
      check = DateTime(check.year, check.month, check.day - 1);
    }
    return streak;
  }

  // ---------------------------------------------------------------------------
  // Mutations (optimistic, revert on failure)
  // ---------------------------------------------------------------------------

  YearCells _entry(String pageId, int year) =>
      _store[_key(pageId, year)] ?? YearCells.empty(pageId, year);

  void _put(YearCells yc) {
    _store[_key(yc.pageId, yc.year)] = yc;
    _touch();
  }

  void _revert(String pageId, int year, int month, int day, CellModel? previous) {
    _lastChange = null;
    final entry = _entry(pageId, year);
    _put(previous != null ? entry.upsert(previous) : entry.remove(month, day));
  }

  Future<void> setCell(int month, int day, String color, {String? comment}) async {
    final pageId = _currentPageId;
    if (pageId == null) return;

    final year = _currentYear;
    final previous = getCell(month, day);
    // Server semantics: an absent comment clears it. Mirror that locally so
    // the optimistic cell never shows a comment the server is about to drop.
    final optimistic = CellModel(
      pageId: pageId,
      year: year,
      month: month,
      day: day,
      color: color,
      comment: comment,
      updatedAt: DateTime.now().toIso8601String(),
    );
    _put(_entry(pageId, year).upsert(optimistic));
    _lastChange = CellChange(pageId: pageId, year: year, month: month, day: day, color: color, erased: false, seq: ++_changeSeq);
    notifyListeners();
    _audio.play(SoundCue.dotFill);

    try {
      final response = await _api.apiFetch(
        '/api/cells/$pageId',
        method: 'PUT',
        body: {
          'year': year,
          'month': month,
          'day': day,
          'color': color,
          'comment': ?comment,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final confirmed = CellModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
        _put(_entry(confirmed.pageId, confirmed.year).upsert(confirmed));
      } else {
        _revert(pageId, year, month, day, previous);
      }
    } catch (e) {
      debugPrint('CellsProvider: setCell failed: $e');
      _revert(pageId, year, month, day, previous);
    }
    notifyListeners();
  }

  Future<void> deleteCell(int month, int day) async {
    final pageId = _currentPageId;
    if (pageId == null) return;

    final year = _currentYear;
    final previous = getCell(month, day);
    if (previous == null) return;

    _put(_entry(pageId, year).remove(month, day));
    _lastChange = CellChange(pageId: pageId, year: year, month: month, day: day, color: previous.color, erased: true, seq: ++_changeSeq);
    notifyListeners();
    _audio.play(SoundCue.dotErase);

    try {
      final response = await _api.apiFetch(
        '/api/cells/$pageId',
        method: 'DELETE',
        body: {'year': year, 'month': month, 'day': day},
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        _lastChange = null;
        _put(_entry(pageId, year).upsert(previous));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('CellsProvider: deleteCell failed: $e');
      _lastChange = null;
      _put(_entry(pageId, year).upsert(previous));
      notifyListeners();
    }
  }

  /// Recolor: rename colors across **all years** of the active page. The
  /// server applies it tracker-wide, so every cached year is updated locally
  /// too — no refetch.
  Future<void> recolorCells(Map<String, String> colorMap) async {
    final pageId = _currentPageId;
    if (pageId == null) return;

    final previous = {
      for (final e in _store.entries)
        if (e.value.pageId == pageId) e.key: e.value,
    };
    _recolorPage(pageId, colorMap);
    notifyListeners();

    try {
      final response = await _api.apiFetch(
        '/api/cells/$pageId/recolor',
        method: 'PATCH',
        body: {'colorMap': colorMap},
      );
      if (response.statusCode != 200) _restore(previous);
    } catch (e) {
      debugPrint('CellsProvider: recolorCells failed: $e');
      _restore(previous);
    }
  }

  void _restore(Map<String, YearCells> entries) {
    _store.addAll(entries);
    _touch();
    notifyListeners();
  }

  void _recolorPage(String pageId, Map<String, String> colorMap) {
    for (final key in _store.keys.toList(growable: false)) {
      final yc = _store[key]!;
      if (yc.pageId == pageId) _store[key] = yc.recolor(colorMap);
    }
    _touch();
  }

  // ---------------------------------------------------------------------------
  // WebSocket
  // ---------------------------------------------------------------------------

  @visibleForTesting
  void debugHandleWs(WsMessage message) => _onWsMessage(message);

  void _onWsMessage(WsMessage message) {
    switch (message.event) {
      case 'cell:updated':
        final cell = CellModel.fromJson(message.data as Map<String, dynamic>);
        // Years we never loaded are fetched whole when needed; a lone cell
        // would only masquerade as a loaded year.
        if (!_loadedYears.contains(cell.year)) return;
        _put(_entry(cell.pageId, cell.year).upsert(cell));
        notifyListeners();

      case 'cell:deleted':
        final json = message.data as Map<String, dynamic>;
        final pageId = (json['pageId'] ?? json['page_id']) as String?;
        final year = (json['year'] as int?) ?? _currentYear;
        final month = json['month'] as int?;
        final day = json['day'] as int?;
        if (pageId == null || month == null || day == null) return;
        final existing = cellsFor(pageId, year);
        if (existing == null) return;
        _put(existing.remove(month, day));
        notifyListeners();

      case 'cells:reset':
        final json = message.data as Map<String, dynamic>;
        final pageId = (json['pageId'] ?? json['page_id']) as String?;
        final year = (json['year'] as int?) ?? _currentYear;
        if (pageId == null) return;
        if (!_loadedYears.contains(year) && cellsFor(pageId, year) == null) return;
        _put(YearCells.empty(pageId, year));
        notifyListeners();

      case 'cells:recolored':
        final json = message.data as Map<String, dynamic>;
        final pageId = (json['pageId'] ?? json['page_id']) as String?;
        final raw = json['colorMap'] as Map<String, dynamic>?;
        if (pageId == null || raw == null) return;
        _recolorPage(pageId, raw.map((k, v) => MapEntry(k, v as String)));
        notifyListeners();
    }
  }

  @override
  void dispose() {
    _removeWsListener?.call();
    super.dispose();
  }
}

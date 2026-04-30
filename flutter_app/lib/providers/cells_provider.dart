import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/cell_model.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../services/ws_service.dart';

class CellsProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final AudioService _audio = AudioService();
  final WsService _ws = WsService();
  RemoveListener? _removeWsListener;

  String? _currentPageId;
  int _currentYear = DateTime.now().year;
  List<CellModel> _cells = [];

  /// Preview cache keyed by `'$pageId:$year'`. Used by the page list cards.
  final Map<String, List<CellModel>> _previewCache = {};

  String? get currentPageId => _currentPageId;
  int get currentYear => _currentYear;
  List<CellModel> get cells => _cells;

  CellsProvider() {
    _removeWsListener = _ws.addListener(_onWsMessage);
  }

  // ---------------------------------------------------------------------------
  // Active page+year
  // ---------------------------------------------------------------------------

  /// Sets the active page and year, then loads its cells.
  Future<void> setContext({required String? pageId, required int year}) async {
    _currentPageId = pageId;
    _currentYear = year;
    _cells = [];
    notifyListeners();

    if (pageId != null) {
      await _fetchCells();
    }
  }

  /// Convenience: change only the year while keeping the same page.
  Future<void> setYear(int year) async {
    if (year == _currentYear) return;
    _currentYear = year;
    _cells = [];
    notifyListeners();
    if (_currentPageId != null) {
      await _fetchCells();
    }
  }

  // ---------------------------------------------------------------------------
  // Preview cache (per-page, per-year)
  // ---------------------------------------------------------------------------

  String _previewKey(String pageId, int year) => '$pageId:$year';

  List<CellModel> getPreviewCells(String pageId, int year) =>
      _previewCache[_previewKey(pageId, year)] ?? [];

  Future<void> fetchPreviewCells(String pageId, int year) async {
    try {
      final response = await _api.apiFetch('/api/cells/$pageId?year=$year');
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        _previewCache[_previewKey(pageId, year)] = list
            .map((json) => CellModel.fromJson(json as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('CellsProvider: fetchPreviewCells failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Cell read / write
  // ---------------------------------------------------------------------------

  /// Returns the color for the given month/day on the active year, or `null`.
  String? getCellColor(int month, int day) => getCell(month, day)?.color;

  /// Returns the full [CellModel] for the given month/day on the active year.
  CellModel? getCell(int month, int day) {
    try {
      return _cells.firstWhere((c) => c.month == month && c.day == day);
    } catch (_) {
      return null;
    }
  }

  /// Sets (or updates) a cell with optimistic update. Reverts on failure.
  Future<void> setCell(int month, int day, String color, {String? comment}) async {
    final pageId = _currentPageId;
    if (pageId == null) return;

    final year = _currentYear;
    final previous = getCell(month, day);
    final optimistic = CellModel(
      pageId: pageId,
      year: year,
      month: month,
      day: day,
      color: color,
      comment: comment ?? previous?.comment,
      updatedAt: DateTime.now().toIso8601String(),
    );

    _upsertCell(optimistic);
    notifyListeners();
    _audio.playTap();

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
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final confirmed = CellModel.fromJson(json);
        // Race guard: only apply if the active context still matches.
        if (confirmed.pageId == _currentPageId && confirmed.year == _currentYear) {
          _upsertCell(confirmed);
          notifyListeners();
        }
      } else {
        _revertCell(previous, month, day);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('CellsProvider: setCell failed: $e');
      _revertCell(previous, month, day);
      notifyListeners();
    }
  }

  /// Deletes a cell with optimistic update. Reverts on failure.
  Future<void> deleteCell(int month, int day) async {
    final pageId = _currentPageId;
    if (pageId == null) return;

    final year = _currentYear;
    final previous = getCell(month, day);
    if (previous == null) return;

    _cells.removeWhere((c) => c.month == month && c.day == day);
    notifyListeners();
    _audio.playErase();

    try {
      final response = await _api.apiFetch(
        '/api/cells/$pageId',
        method: 'DELETE',
        body: {'year': year, 'month': month, 'day': day},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        _cells.add(previous);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('CellsProvider: deleteCell failed: $e');
      _cells.add(previous);
      notifyListeners();
    }
  }

  /// Recolor: rename a color across **all years** of the active page.
  /// Server applies it globally per tracker, so we invalidate every cached
  /// year of this page and update the visible cells optimistically.
  Future<void> recolorCells(Map<String, String> colorMap) async {
    final pageId = _currentPageId;
    if (pageId == null) return;

    for (final cell in List<CellModel>.of(_cells)) {
      final newColor = colorMap[cell.color];
      if (newColor != null) {
        final i = _cells.indexOf(cell);
        if (i != -1) _cells[i] = cell.copyWith(color: newColor);
      }
    }
    _previewCache.removeWhere((key, _) => key.startsWith('$pageId:'));
    notifyListeners();

    try {
      await _api.apiFetch(
        '/api/cells/$pageId/recolor',
        method: 'PATCH',
        body: {'colorMap': colorMap},
      );
    } catch (e) {
      debugPrint('CellsProvider: recolorCells failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // WebSocket
  // ---------------------------------------------------------------------------

  void _onWsMessage(WsMessage message) {
    switch (message.event) {
      case 'cell:updated':
        final json = message.data as Map<String, dynamic>;
        final cell = CellModel.fromJson(json);
        // Update preview cache regardless of which year is active.
        final cached = _previewCache[_previewKey(cell.pageId, cell.year)];
        if (cached != null) {
          final i = cached.indexWhere(
              (c) => c.month == cell.month && c.day == cell.day);
          if (i != -1) {
            cached[i] = cell;
          } else {
            cached.add(cell);
          }
        }
        if (cell.pageId == _currentPageId && cell.year == _currentYear) {
          _upsertCell(cell);
        }
        notifyListeners();
        break;

      case 'cell:deleted':
        final json = message.data as Map<String, dynamic>;
        final pageId = (json['pageId'] ?? json['page_id']) as String?;
        final year = (json['year'] as int?) ?? _currentYear;
        final month = json['month'] as int?;
        final day = json['day'] as int?;
        if (pageId == null || month == null || day == null) break;
        _previewCache[_previewKey(pageId, year)]
            ?.removeWhere((c) => c.month == month && c.day == day);
        if (pageId == _currentPageId && year == _currentYear) {
          _cells.removeWhere((c) => c.month == month && c.day == day);
        }
        notifyListeners();
        break;

      case 'cells:reset':
        final json = message.data as Map<String, dynamic>;
        final pageId = (json['pageId'] ?? json['page_id']) as String?;
        final year = (json['year'] as int?) ?? _currentYear;
        if (pageId == null) break;
        _previewCache[_previewKey(pageId, year)] = [];
        if (pageId == _currentPageId && year == _currentYear) {
          _cells = [];
        }
        notifyListeners();
        break;

      case 'cells:recolored':
        final json = message.data as Map<String, dynamic>;
        final pageId = (json['pageId'] ?? json['page_id']) as String?;
        if (pageId == null) break;
        // Recolor is cross-year — flush previews for that page; refetch on demand.
        _previewCache.removeWhere((key, _) => key.startsWith('$pageId:'));
        if (pageId == _currentPageId) {
          // Reload current view to reflect the new colors.
          _fetchCells();
        } else {
          notifyListeners();
        }
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  Future<void> _fetchCells() async {
    final pageId = _currentPageId;
    final year = _currentYear;
    if (pageId == null) return;
    try {
      final response = await _api.apiFetch('/api/cells/$pageId?year=$year');
      if (response.statusCode == 200) {
        // Race guard: discard if context changed while we were fetching.
        if (_currentPageId != pageId || _currentYear != year) return;
        final list = jsonDecode(response.body) as List<dynamic>;
        _cells = list
            .map((json) => CellModel.fromJson(json as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('CellsProvider: fetchCells failed: $e');
    }
  }

  void _upsertCell(CellModel cell) {
    final index = _cells.indexWhere(
      (c) => c.month == cell.month && c.day == cell.day,
    );
    if (index != -1) {
      _cells[index] = cell;
    } else {
      _cells.add(cell);
    }
  }

  void _revertCell(CellModel? previous, int month, int day) {
    if (previous != null) {
      _upsertCell(previous);
    } else {
      _cells.removeWhere((c) => c.month == month && c.day == day);
    }
  }

  @override
  void dispose() {
    _removeWsListener?.call();
    super.dispose();
  }
}

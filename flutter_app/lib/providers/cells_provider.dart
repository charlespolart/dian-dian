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
  List<CellModel> _cells = [];
  final Map<String, List<CellModel>> _previewCache = {};

  String? get currentPageId => _currentPageId;
  List<CellModel> get cells => _cells;

  CellsProvider() {
    _removeWsListener = _ws.addListener(_onWsMessage);
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<void> setPageId(String? id) async {
    _currentPageId = id;
    _cells = [];
    notifyListeners();

    if (id != null) {
      await _fetchCells();
    }
  }

  /// Returns cached preview cells for a page (used by PageListScreen cards).
  List<CellModel> getPreviewCells(String pageId) => _previewCache[pageId] ?? [];

  /// Fetches cells for preview without changing the active page.
  Future<void> fetchPreviewCells(String pageId) async {
    try {
      final response = await _api.apiFetch('/api/cells/$pageId');
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        _previewCache[pageId] = list
            .map((json) => CellModel.fromJson(json as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('CellsProvider: fetchPreviewCells failed: $e');
    }
  }

  /// Returns the color for the given month/day, or `null` if no cell exists.
  String? getCellColor(int month, int day) {
    final cell = getCell(month, day);
    return cell?.color;
  }

  /// Returns the full [CellModel] for the given month/day, or `null`.
  CellModel? getCell(int month, int day) {
    try {
      return _cells.firstWhere((c) => c.month == month && c.day == day);
    } catch (_) {
      return null;
    }
  }

  /// Sets (or updates) a cell with optimistic update. Reverts on failure.
  Future<void> setCell(int month, int day, String color, {String? comment}) async {
    if (_currentPageId == null) return;

    final previous = getCell(month, day);
    final optimistic = CellModel(
      pageId: _currentPageId!,
      month: month,
      day: day,
      color: color,
      comment: comment ?? previous?.comment,
      updatedAt: DateTime.now().toIso8601String(),
    );

    // Apply optimistic update
    _upsertCell(optimistic);
    notifyListeners();
    _audio.playTap();

    try {
      final response = await _api.apiFetch(
        '/api/cells/$_currentPageId',
        method: 'PUT',
        body: {
          'month': month,
          'day': day,
          'color': color,
          'comment': ?comment,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final confirmed = CellModel.fromJson(json);
        _upsertCell(confirmed);
        notifyListeners();
      } else {
        // Revert on failure
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
    if (_currentPageId == null) return;

    final previous = getCell(month, day);
    if (previous == null) return;

    // Apply optimistic delete
    _cells.removeWhere((c) => c.month == month && c.day == day);
    notifyListeners();
    _audio.playErase();

    try {
      final response = await _api.apiFetch(
        '/api/cells/$_currentPageId',
        method: 'DELETE',
        body: {'month': month, 'day': day},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        // Revert on failure
        _cells.add(previous);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('CellsProvider: deleteCell failed: $e');
      _cells.add(previous);
      notifyListeners();
    }
  }

  /// Recolor cells: swap oldColor → newColor on the current page.
  Future<void> recolorCells(Map<String, String> colorMap) async {
    if (_currentPageId == null) return;

    // Optimistic update
    for (final cell in _cells) {
      final newColor = colorMap[cell.color];
      if (newColor != null) {
        _cells[_cells.indexOf(cell)] = cell.copyWith(color: newColor);
      }
    }
    notifyListeners();

    try {
      await _api.apiFetch(
        '/api/cells/$_currentPageId/recolor',
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
        if (cell.pageId == _currentPageId) {
          _upsertCell(cell);
          notifyListeners();
        }
        break;

      case 'cell:deleted':
        final json = message.data as Map<String, dynamic>;
        final pageId = (json['pageId'] ?? json['page_id']) as String?;
        final month = json['month'] as int?;
        final day = json['day'] as int?;
        if (pageId == _currentPageId && month != null && day != null) {
          _cells.removeWhere((c) => c.month == month && c.day == day);
          notifyListeners();
        }
        break;

      case 'cells:reset':
        final json = message.data as Map<String, dynamic>;
        final pageId = (json['pageId'] ?? json['page_id']) as String?;
        if (pageId == _currentPageId) {
          _cells = [];
          notifyListeners();
        }
        break;

      case 'cells:recolored':
        final json = message.data as Map<String, dynamic>;
        final pageId = (json['pageId'] ?? json['page_id']) as String?;
        if (pageId == _currentPageId) {
          final updated = json['cells'] as List<dynamic>?;
          if (updated != null) {
            for (final cellJson in updated) {
              final cell = CellModel.fromJson(cellJson as Map<String, dynamic>);
              _upsertCell(cell);
            }
            notifyListeners();
          }
        }
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  Future<void> _fetchCells() async {
    try {
      final response = await _api.apiFetch('/api/cells/$_currentPageId');
      if (response.statusCode == 200) {
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

import 'package:flutter/foundation.dart';

import '../data/change_sink.dart';
import '../models/cell_change.dart';
import '../models/cell_model.dart';
import '../models/year_cells.dart';
import '../services/audio_service.dart';

/// Holds every year of cells the app has loaded, for every page, as
/// immutable [YearCells] keyed by `'$pageId:$year'`.
///
/// Loading is NOT this class's job: `SyncService` pushes the phone's copy in
/// through [applyCopy] (every year), and changes go to the copy and its
/// queue through the bound [ChangeSink] (offline sync). The
/// "current" page/year is only a pointer into the store, so opening a
/// tracker or switching years is synchronous and never shows an empty grid
/// for data we already have.
class CellsProvider extends ChangeNotifier {
  final AudioService _audio;
  ChangeSink? _sink;

  final Map<String, YearCells> _store = {};
  final Set<int> _loadedYears = {};
  // Every year is known once the phone's copy is applied.
  bool _copyLoaded = false;
  String? _currentPageId;
  int _currentYear = DateTime.now().year;
  CellChange? _lastChange;
  int _changeSeq = 0;

  /// The last cell this device changed (for the grid's pop); null after a
  /// clear, or before any local change.
  CellChange? get lastChange => _lastChange;

  CellsProvider({AudioService? audio, ChangeSink? sink})
      : _audio = audio ?? AudioService(),
        _sink = sink;

  /// Where changes are written: the session's copy and queue.
  void bind(ChangeSink? sink) => _sink = sink;

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

  /// True once the phone's copy is applied (every year), or a 1.4.0 snapshot
  /// of [year] (every page's cells for that year are known, possibly empty).
  bool isYearLoaded(int year) => _copyLoaded || _loadedYears.contains(year);

  /// Every coloured day of [pageId], all years (all-time stats, on the phone).
  List<DateTime> allDays(String pageId) => [
        for (final yc in _store.values)
          if (yc.pageId == pageId)
            for (final c in yc.values) DateTime(c.year, c.month, c.day),
      ];

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
  /// `{ pageId: [[month, day, color, comment?], ...] }` (the 1.4.0 snapshot,
  /// shown until the first full copy arrives).
  void applyBootstrap(int year, Map<String, dynamic> cellsByPage) {
    _store.removeWhere((_, yc) => yc.year == year);
    cellsByPage.forEach((pageId, rows) {
      _store[_key(pageId, year)] = YearCells.fromCompact(pageId, year, rows as List<dynamic>);
    });
    _loadedYears.add(year);
    notifyListeners();
  }

  /// Replaces the store with the phone's copy: every page, every year.
  void applyCopy(Map<String, Map<int, YearCells>> cellsByPage) {
    _store.clear();
    for (final page in cellsByPage.entries) {
      for (final year in page.value.entries) {
        _store[_key(page.key, year.key)] = year.value;
      }
    }
    _copyLoaded = true;
    notifyListeners();
  }

  void clear() {
    _store.clear();
    _loadedYears.clear();
    _copyLoaded = false;
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
  // Changes (on screen at once, then written to the copy and its queue)
  // ---------------------------------------------------------------------------

  YearCells _entry(String pageId, int year) =>
      _store[_key(pageId, year)] ?? YearCells.empty(pageId, year);

  void _put(YearCells yc) => _store[_key(yc.pageId, yc.year)] = yc;

  Future<void> _record(String kind, Map<String, dynamic> data) async {
    try {
      await _sink?.record(kind, data);
    } catch (e) {
      debugPrint('CellsProvider: $kind not written: $e');
    }
  }

  /// Colours a day, on the phone at once (offline too, H1); the server
  /// receives it with the queue.
  Future<void> setCell(int month, int day, String color, {String? comment}) async {
    final pageId = _currentPageId;
    if (pageId == null) return;

    final year = _currentYear;
    // Server semantics: an absent comment clears it.
    final cell = CellModel(
      pageId: pageId,
      year: year,
      month: month,
      day: day,
      color: color,
      comment: comment,
      updatedAt: DateTime.now().toIso8601String(),
    );
    _put(_entry(pageId, year).upsert(cell));
    _lastChange = CellChange(pageId: pageId, year: year, month: month, day: day, color: color, erased: false, seq: ++_changeSeq);
    notifyListeners();
    _audio.play(SoundCue.dotFill);
    await _record('cell.set', {'pageId': pageId, 'year': year, 'month': month, 'day': day, 'color': color, 'comment': comment});
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
    await _record('cell.clear', {'pageId': pageId, 'year': year, 'month': month, 'day': day});
  }

  /// Recolours the active page's days on screen, all years. Nothing is
  /// written: the legend's colour change (LegendsProvider.updateLegend) is
  /// the change, and the copy recolours its days with it.
  Future<void> recolorCells(Map<String, String> colorMap) async {
    final pageId = _currentPageId;
    if (pageId == null) return;
    _recolorPage(pageId, colorMap);
    notifyListeners();
  }

  void _recolorPage(String pageId, Map<String, String> colorMap) {
    for (final key in _store.keys.toList(growable: false)) {
      final yc = _store[key]!;
      if (yc.pageId == pageId) _store[key] = yc.recolor(colorMap);
    }
  }
}

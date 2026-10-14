import 'cell_model.dart';

/// Immutable set of cells for one (page, year).
///
/// Every mutation returns a new instance and never touches the old one, so
/// `identical(a, b)` answers "did anything change?" — painters rely on that
/// for a cheap, exact `shouldRepaint`, and the provider's memoized stats rely
/// on it to know when to recompute. Lookups are O(1) by `month * 32 + day`.
class YearCells {
  final String pageId;
  final int year;
  final Map<int, CellModel> _byKey;

  const YearCells._(this.pageId, this.year, this._byKey);

  factory YearCells.empty(String pageId, int year) =>
      YearCells._(pageId, year, const {});

  factory YearCells.fromList(String pageId, int year, Iterable<CellModel> cells) =>
      YearCells._(pageId, year, {for (final c in cells) c.key: c});

  /// Parses bootstrap tuples: `[month, day, color]` / `[month, day, color, comment]`.
  factory YearCells.fromCompact(String pageId, int year, List<dynamic> rows) =>
      YearCells.fromList(
        pageId,
        year,
        rows.map((r) => CellModel.fromCompact(pageId, year, r as List<dynamic>)),
      );

  CellModel? get(int month, int day) => _byKey[CellModel.keyOf(month, day)];
  int get length => _byKey.length;
  bool get isEmpty => _byKey.isEmpty;
  Iterable<CellModel> get values => _byKey.values;

  YearCells upsert(CellModel cell) =>
      YearCells._(pageId, year, {..._byKey, cell.key: cell});

  YearCells remove(int month, int day) {
    final key = CellModel.keyOf(month, day);
    if (!_byKey.containsKey(key)) return this;
    final copy = Map<int, CellModel>.of(_byKey)..remove(key);
    return YearCells._(pageId, year, copy);
  }

  /// Renames colors in bulk (legend recolor). Returns `this` when nothing
  /// matched so callers can skip a repaint.
  YearCells recolor(Map<String, String> colorMap) {
    var changed = false;
    final copy = <int, CellModel>{};
    for (final e in _byKey.entries) {
      final next = colorMap[e.value.color];
      if (next != null && next != e.value.color) {
        copy[e.key] = e.value.copyWith(color: next);
        changed = true;
      } else {
        copy[e.key] = e.value;
      }
    }
    return changed ? YearCells._(pageId, year, copy) : this;
  }

  List<List<dynamic>> toCompact() => [for (final c in _byKey.values) c.toCompact()];
}

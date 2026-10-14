import 'package:flutter_test/flutter_test.dart';
import 'package:dian_dian/models/cell_model.dart';
import 'package:dian_dian/models/year_cells.dart';

void main() {
  group('CellModel compact', () {
    test('parses a 3-tuple and a 4-tuple', () {
      final a = CellModel.fromCompact('p', 2026, [12, 31, '#FF0000']);
      expect(a.month, 12);
      expect(a.day, 31);
      expect(a.color, '#FF0000');
      expect(a.comment, isNull);
      expect(a.pageId, 'p');
      expect(a.year, 2026);

      final b = CellModel.fromCompact('p', 2026, [2, 29, '#00FF00', 'leap']);
      expect(b.comment, 'leap');
    });

    test('toCompact omits an absent or empty comment', () {
      final a = CellModel.fromCompact('p', 2026, [12, 31, '#FF0000']);
      expect(a.toCompact(), [12, 31, '#FF0000']);
      final b = CellModel.fromCompact('p', 2026, [2, 29, '#00FF00', 'leap']);
      expect(b.toCompact(), [2, 29, '#00FF00', 'leap']);
      final c = a.copyWith(comment: '');
      expect(c.toCompact(), [12, 31, '#FF0000']);
    });

    test('key is unique per month/day', () {
      expect(CellModel.keyOf(1, 31), isNot(CellModel.keyOf(2, 1)));
      expect(CellModel.keyOf(12, 31), 12 * 32 + 31);
      final a = CellModel.fromCompact('p', 2026, [3, 4, '#000000']);
      expect(a.key, CellModel.keyOf(3, 4));
    });
  });

  group('YearCells', () {
    final base = YearCells.fromCompact('p', 2026, [
      [1, 1, '#AAAAAA'],
      [1, 2, '#BBBBBB', 'hi'],
    ]);

    test('get / length / values', () {
      expect(base.length, 2);
      expect(base.isEmpty, isFalse);
      expect(base.get(1, 2)?.comment, 'hi');
      expect(base.get(3, 3), isNull);
      expect(base.values.map((c) => c.day), containsAll([1, 2]));
    });

    test('upsert returns a new instance and leaves the old untouched', () {
      final next = base.upsert(CellModel.fromCompact('p', 2026, [1, 1, '#CCCCCC']));
      expect(identical(next, base), isFalse);
      expect(base.get(1, 1)!.color, '#AAAAAA');
      expect(next.get(1, 1)!.color, '#CCCCCC');
      expect(next.length, 2);
    });

    test('upsert of a new day grows the set', () {
      final next = base.upsert(CellModel.fromCompact('p', 2026, [7, 14, '#CCCCCC']));
      expect(next.length, 3);
      expect(next.get(7, 14)!.color, '#CCCCCC');
    });

    test('remove drops the day, and is identity-stable for a missing day', () {
      final next = base.remove(1, 2);
      expect(next.length, 1);
      expect(next.get(1, 2), isNull);
      expect(base.length, 2);
      expect(identical(base.remove(9, 9), base), isTrue);
    });

    test('recolor maps only matching colors, identity-stable when nothing matches', () {
      final next = base.recolor({'#AAAAAA': '#111111'});
      expect(next.get(1, 1)!.color, '#111111');
      expect(next.get(1, 2)!.color, '#BBBBBB');
      expect(identical(base.recolor({'#ZZZZZZ': '#111111'}), base), isTrue);
    });

    test('toCompact round-trips', () {
      final again = YearCells.fromCompact('p', 2026, base.toCompact());
      expect(again.length, 2);
      expect(again.get(1, 2)!.comment, 'hi');
      expect(again.get(1, 1)!.color, '#AAAAAA');
    });

    test('empty', () {
      final e = YearCells.empty('p', 2026);
      expect(e.isEmpty, isTrue);
      expect(e.length, 0);
      expect(e.pageId, 'p');
      expect(e.year, 2026);
    });
  });
}

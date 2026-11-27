import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/models/year_cells.dart';
import 'package:dian_dian/providers/cells_provider.dart';
import 'package:dian_dian/services/audio_service.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CellsProvider loaded({RecordingSink? sink}) {
    final p = CellsProvider(audio: AudioService.silent(), sink: sink);
    p.applyBootstrap(2026, {
      'a': [
        [1, 1, '#AAAAAA'],
        [1, 2, '#BBBBBB', 'hi'],
      ],
      'b': <dynamic>[],
    });
    return p;
  }

  Map<int, YearCells> years(String pageId, Map<int, List<List<dynamic>>> rows) =>
      {for (final e in rows.entries) e.key: YearCells.fromCompact(pageId, e.key, e.value)};

  test('applyBootstrap loads every page and marks the year loaded', () {
    final p = loaded();
    expect(p.isYearLoaded(2026), isTrue);
    expect(p.isYearLoaded(2025), isFalse);
    expect(p.cellsFor('a', 2026)!.length, 2);
    expect(p.cellsFor('b', 2026)!.isEmpty, isTrue);
    expect(p.cellsFor('a', 2025), isNull);
  });

  test('applyBootstrap replaces the year wholesale (a page removed server-side disappears)', () {
    final p = loaded();
    p.applyBootstrap(2026, {'b': [[5, 5, '#CCCCCC']]});
    expect(p.cellsFor('a', 2026), isNull);
    expect(p.cellsFor('b', 2026)!.length, 1);
  });

  test('applyCopy loads every year of every page and every year counts as loaded', () {
    final p = loaded();
    p.applyCopy({
      'a': years('a', {2024: [[3, 3, '#AAAAAA']], 2026: [[1, 1, '#AAAAAA']]}),
    });
    expect(p.cellsFor('a', 2024)!.length, 1);
    expect(p.cellsFor('a', 2026)!.length, 1);
    expect(p.cellsFor('b', 2026), isNull, reason: 'the copy replaces the store');
    expect(p.isYearLoaded(1999), isTrue, reason: 'the phone has every year');
  });

  test('allDays gives every coloured day of a page, all years', () {
    final p = CellsProvider(audio: AudioService.silent());
    p.applyCopy({
      'a': years('a', {2024: [[3, 3, '#AAAAAA']], 2026: [[1, 1, '#AAAAAA'], [1, 2, '#AAAAAA']]}),
      'b': years('b', {2026: [[5, 5, '#AAAAAA']]}),
    });
    expect(p.allDays('a').toSet(), {DateTime(2024, 3, 3), DateTime(2026, 1, 1), DateTime(2026, 1, 2)});
    expect(p.allDays('c'), isEmpty);
  });

  test('setContext is synchronous and exposes the current cells', () {
    final p = loaded();
    var notified = 0;
    p.addListener(() => notified++);
    p.setContext(pageId: 'a', year: 2026);
    expect(notified, 1);
    expect(p.currentPageId, 'a');
    expect(p.currentYear, 2026);
    expect(p.getCell(1, 2)?.comment, 'hi');
    expect(p.getCellColor(1, 1), '#AAAAAA');
    expect(p.getCellColor(9, 9), isNull);
    expect(p.cells.length, 2);
    expect(p.filledDays, 2);
  });

  test('setYear switches the current year without fetching', () {
    final p = loaded();
    p.setContext(pageId: 'a', year: 2026);
    p.setYear(2025);
    expect(p.currentYear, 2025);
    expect(p.current, isNull);
    expect(p.filledDays, 0);
    expect(p.currentStreak, 0);
    p.setYear(2026);
    expect(p.filledDays, 2);
  });

  test('currentStreak counts consecutive days ending today or yesterday', () {
    final p = CellsProvider(audio: AudioService.silent());
    final now = DateTime.now();
    final d0 = DateTime(now.year, now.month, now.day);
    final days = [d0, d0.subtract(const Duration(days: 1)), d0.subtract(const Duration(days: 2))]
        .where((d) => d.year == now.year)
        .toList();
    p.applyBootstrap(now.year, {
      'a': [for (final d in days) [d.month, d.day, '#AAAAAA']],
    });
    p.setContext(pageId: 'a', year: now.year);
    expect(p.currentStreak, days.length);

    // Gap before the run → streak unaffected by the earlier day.
    final far = d0.subtract(const Duration(days: 10));
    if (far.year == now.year) {
      p.applyBootstrap(now.year, {
        'a': [for (final d in days) [d.month, d.day, '#AAAAAA'], [far.month, far.day, '#AAAAAA']],
      });
      expect(p.currentStreak, days.length);
    }
  });

  test('stats are memoized per YearCells instance', () async {
    final p = loaded(sink: RecordingSink());
    p.setContext(pageId: 'a', year: 2026);
    expect(p.filledDays, 2);
    await p.setCell(3, 3, '#CCCCCC');
    expect(p.filledDays, 3);
  });

  test('setCell shows the day at once and writes one cell.set', () async {
    final sink = RecordingSink();
    final p = loaded(sink: sink);
    p.setContext(pageId: 'a', year: 2026);
    var notified = 0;
    p.addListener(() => notified++);
    await p.setCell(3, 3, '#CCCCCC', comment: 'note');
    expect(p.getCell(3, 3)?.color, '#CCCCCC');
    expect(notified, 1);
    expect(sink.log, [['cell.set', {'pageId': 'a', 'year': 2026, 'month': 3, 'day': 3, 'color': '#CCCCCC', 'comment': 'note'}]]);
  });

  test('deleteCell writes one cell.clear; an empty day writes nothing', () async {
    final sink = RecordingSink();
    final p = loaded(sink: sink);
    p.setContext(pageId: 'a', year: 2026);
    await p.deleteCell(1, 1);
    await p.deleteCell(9, 9);
    expect(p.getCell(1, 1), isNull);
    expect(p.filledDays, 1);
    expect(sink.log, [['cell.clear', {'pageId': 'a', 'year': 2026, 'month': 1, 'day': 1}]]);
  });

  test('a change that could not be written stays on screen (nothing is undone, H1)', () async {
    final sink = RecordingSink()..fail = true;
    final p = loaded(sink: sink);
    p.setContext(pageId: 'a', year: 2026);
    await p.setCell(3, 3, '#CCCCCC');
    await p.deleteCell(1, 1);
    expect(p.getCell(3, 3)?.color, '#CCCCCC');
    expect(p.getCell(1, 1), isNull);
  });

  test('recolorCells recolours every year of the page on screen and writes nothing', () async {
    final sink = RecordingSink();
    final p = loaded(sink: sink);
    p.applyBootstrap(2025, {'a': [[5, 5, '#AAAAAA']], 'b': <dynamic>[]});
    p.setContext(pageId: 'a', year: 2026);
    await p.recolorCells({'#AAAAAA': '#111111'});
    expect(p.cellsFor('a', 2026)!.get(1, 1)!.color, '#111111');
    expect(p.cellsFor('a', 2025)!.get(5, 5)!.color, '#111111');
    expect(p.cellsFor('a', 2026)!.get(1, 2)!.color, '#BBBBBB');
    expect(sink.changes, isEmpty, reason: 'the legend colour change is the one change (LegendsProvider)');
  });

  test('identity only changes for the touched (page, year)', () async {
    final p = loaded(sink: RecordingSink());
    p.setContext(pageId: 'a', year: 2026);
    final a = p.cellsFor('a', 2026);
    final b = p.cellsFor('b', 2026);
    await p.deleteCell(1, 1);
    expect(identical(p.cellsFor('a', 2026), a), isFalse);
    expect(identical(p.cellsFor('b', 2026), b), isTrue);
  });

  test('a fill plays dotFill, an erase plays dotErase', () async {
    SharedPreferences.setMockInitialValues({});
    final rec = await recordingAudio();
    final p = CellsProvider(audio: rec.service, sink: RecordingSink());
    p.applyBootstrap(2026, {'a': <dynamic>[]});
    p.setContext(pageId: 'a', year: 2026);
    await p.setCell(1, 1, '#AAAAAA');
    await p.deleteCell(1, 1);
    expect(rec.players.played, [SoundCue.dotFill, SoundCue.dotErase]);
  });

  test('clear forgets everything', () {
    final p = loaded();
    p.applyCopy({'a': years('a', {2026: [[1, 1, '#AAAAAA']]})});
    p.setContext(pageId: 'a', year: 2026);
    p.clear();
    expect(p.isYearLoaded(2026), isFalse);
    expect(p.cellsFor('a', 2026), isNull);
    expect(p.currentPageId, isNull);
    expect(p.cells, isEmpty);
  });

  test('without a full copy (H15), no day changes, each attempt is refused; a recolour stays silent', () async {
    final sink = RecordingSink()..canWrite = false;
    final p = loaded(sink: sink);
    p.setContext(pageId: 'a', year: 2026);
    await p.setCell(3, 3, '#CCCCCC');
    await p.deleteCell(1, 1);
    await p.recolorCells({'#AAAAAA': '#111111'});
    expect(p.getCell(3, 3), isNull);
    expect(p.getCell(1, 1)?.color, '#AAAAAA');
    expect(p.lastChange, isNull);
    expect(sink.changes, isEmpty);
    expect(sink.refusals, 2, reason: 'the recolour follows a legend change already refused');
  });

  group('lastChange', () {
    CellsProvider withSink() {
      final p = CellsProvider(audio: AudioService.silent(), sink: RecordingSink());
      p.applyBootstrap(2026, {'a': [[1, 1, '#AAAAAA']]});
      p.setContext(pageId: 'a', year: 2026);
      return p;
    }

    test('is null until this device changes a cell, then names the cell and its new colour', () async {
      final p = withSink();
      expect(p.lastChange, isNull);
      await p.setCell(1, 3, '#111111');
      final c = p.lastChange!;
      expect((c.pageId, c.year, c.month, c.day, c.color, c.erased), ('a', 2026, 1, 3, '#111111', false));
    });

    test('seq grows at every change, an erase keeps the old colour', () async {
      final p = withSink();
      await p.setCell(1, 3, '#111111');
      final first = p.lastChange!.seq;
      await p.deleteCell(1, 1);
      final c = p.lastChange!;
      expect(c.seq, greaterThan(first));
      expect((c.month, c.day, c.color, c.erased), (1, 1, '#AAAAAA', true));
    });

    test('a bootstrap, a load of the copy or clear() never produce a pop', () async {
      final p = withSink();
      p.applyBootstrap(2026, {'a': [[2, 2, '#BBBBBB']]});
      expect(p.lastChange, isNull);
      p.applyCopy({'a': years('a', {2026: [[3, 3, '#CCCCCC']]})});
      expect(p.lastChange, isNull);
      await p.setCell(1, 3, '#111111');
      p.clear();
      expect(p.lastChange, isNull);
    });
  });
}

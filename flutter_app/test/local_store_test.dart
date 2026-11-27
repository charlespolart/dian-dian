import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dian_dian/data/local_store.dart';
import 'package:dian_dian/data/mutation.dart';

const p1 = '11111111-1111-4111-8111-111111111111';
const l1 = '22222222-2222-4222-8222-222222222222';

Future<LocalStore> memory() => LocalStore.open('u1', factory: databaseFactoryFfiNoIsolate, path: inMemoryDatabasePath);

/// A copy the server sent: one tracker, one legend, one coloured day.
SyncDelta seed({int rev = 10}) => SyncDelta.fromJson({
      'rev': rev,
      'full': true,
      'pages': [
        {'id': p1, 'title': 'Mood', 'position': 0, 'keepFree': false, 'createdAt': '2026-01-01T00:00:00Z', 'palette': null, 'rev': 5, 'editRev': 5, 'contentRev': 8, 'legendsOrderRev': 0},
      ],
      'legends': [
        {'id': l1, 'pageId': p1, 'color': '#AAAAAA', 'label': 'Good', 'position': 0, 'rev': 6, 'editRev': 6},
      ],
      'cells': {
        p1: [
          [2026, 3, 1, '#AAAAAA', null, 8, 8, DateTime.now().millisecondsSinceEpoch],
        ],
      },
      'deletions': <dynamic>[],
      'pagesOrder': {'rev': 2, 'ids': [p1]},
      'keepFree': {'rev': 0, 'ids': <String>[]},
      'legendsOrder': <String, dynamic>{},
      'settings': {'theme': {'rev': 3, 'value': 'defaultTheme'}},
      'premium': false,
      'vip': false,
    });

Map<String, dynamic> day(int d, {String color = '#BBBBBB', String? comment}) =>
    {'pageId': p1, 'year': 2026, 'month': 3, 'day': d, 'color': color, 'comment': comment};

void main() {
  setUpAll(sqfliteFfiInit);

  test('the copy the server sent is what the screens read, with the activity of each tracker', () async {
    final s = await memory();
    await s.applyServer(seed());
    final copy = await s.load();
    expect(copy.pages.single.title, 'Mood');
    expect(copy.pages.single.recentCells, 1, reason: 'a day changed in the last 90 days');
    expect(copy.legends[p1]!.single.label, 'Good');
    expect(copy.cells[p1]![2026]!.get(3, 1)!.color, '#AAAAAA');
    expect(await s.lastRev(), 10);
    expect(await s.hasFullCopy(), isTrue);
  });

  test('a change and its entry in the queue are written together, or not at all', () async {
    final s = await memory();
    await s.applyServer(seed());
    await expectLater(s.record('cell.set', {'pageId': p1, 'year': 2026, 'month': 3}, offline: true), throwsA(anything));
    expect(await s.pendingCount(), 0);
    expect((await s.load()).cells[p1]![2026]!.get(3, 2), isNull);

    final m = await s.record('cell.set', day(2), offline: true);
    expect(await s.pendingCount(), 1);
    expect(m.waited, isTrue, reason: 'made offline');
    expect(m.base, 0, reason: 'the day did not exist for the phone');
    expect((await s.load()).cells[p1]![2026]!.get(3, 2)!.color, '#BBBBBB', reason: 'shown at once (H1)');
  });

  test('a change carries the number its element had on the phone', () async {
    final s = await memory();
    await s.applyServer(seed());
    expect((await s.record('cell.set', day(1), offline: true)).base, 8);
    expect((await s.record('page.update', {'id': p1, 'title': 'Humeur'}, offline: true)).base, 5);
    expect((await s.record('page.delete', {'id': p1}, offline: true)).base, 8, reason: 'a deletion compares the whole tracker (H21)');
    expect((await s.record('setting.set', {'key': 'theme', 'value': 'night'}, offline: false)).base, 3);
  });

  test('two changes of the same day not yet sent become one: the last state, with the first base (H28)', () async {
    final s = await memory();
    await s.applyServer(seed());
    final first = await s.record('cell.set', day(1, color: '#111111'), offline: true);
    await s.record('cell.set', day(1, color: '#222222', comment: 'x'), offline: true);
    final queue = await s.pending();
    expect(queue, hasLength(1));
    expect(queue.single.id, first.id);
    expect(queue.single.base, 8);
    expect(queue.single.data['color'], '#222222');

    await s.markSent([first.id]);
    await s.record('cell.set', day(1, color: '#333333'), offline: true);
    expect(await s.pending(), hasLength(2), reason: 'a change already sent is never merged with a later one');
  });

  test('an acknowledged change makes the next ones of its element start from its number (H28)', () async {
    final s = await memory();
    await s.applyServer(seed());
    final a = await s.record('cell.set', day(1, color: '#111111'), offline: true);
    await s.markSent([a.id]);
    final b = await s.record('cell.set', day(1, color: '#222222'), offline: true);
    final del = await s.record('page.delete', {'id': p1}, offline: true);
    final outcomes = await s.settle([MutationResult.fromJson({'id': a.id, 'status': 'applied', 'revs': {'element': 12, 'content': 12, 'account': 12}})]);
    expect(outcomes, isEmpty);
    final queue = await s.pending();
    expect(queue.map((m) => m.id), [b.id, del.id]);
    expect(queue.first.base, 12, reason: 'my own change never counts as one made elsewhere');
    expect(queue.last.base, 12, reason: 'nor for the deletion of its tracker');
  });

  test('a change set aside leaves the queue, is told, and asks for the full copy back (H17)', () async {
    final s = await memory();
    await s.applyServer(seed());
    final a = await s.record('cell.set', day(1, color: '#111111'), offline: true);
    final outcomes = await s.settle([MutationResult.fromJson({'id': a.id, 'status': 'changed', 'current': {'color': '#AAAAAA', 'comment': null}})]);
    expect(await s.pendingCount(), 0);
    expect(outcomes.single.status, 'changed');
    expect(outcomes.single.kind, 'cell.set');
    expect(outcomes.single.data['color'], '#111111', reason: 'what was not kept, for the message');
    expect(await s.needsFullCopy(), isTrue);
  });

  test('a tracker deleted elsewhere takes with it everything queued inside it (H20)', () async {
    final s = await memory();
    await s.applyServer(seed());
    final a = await s.record('cell.set', day(1), offline: true);
    await s.record('cell.set', day(2), offline: true);
    await s.record('legend.update', {'id': l1, 'label': 'Fine'}, offline: true);
    final outcomes = await s.settle([MutationResult.fromJson({'id': a.id, 'status': 'deleted'})]);
    expect(await s.pendingCount(), 0);
    expect(outcomes, hasLength(3), reason: 'counted in the same message');
  });

  test('what the server sends updates the copy, except an element with a change waiting', () async {
    final s = await memory();
    await s.applyServer(seed());
    await s.record('cell.set', day(1, color: '#111111'), offline: true);
    await s.applyServer(SyncDelta.fromJson({
      'rev': 14, 'full': false, 'pages': <dynamic>[], 'legends': <dynamic>[],
      'cells': {
        p1: [
          [2026, 3, 1, '#999999', null, 13, 13, 0],
          [2026, 3, 5, '#999999', null, 14, 14, 0],
        ],
      },
      'deletions': <dynamic>[], 'legendsOrder': <String, dynamic>{}, 'settings': <String, dynamic>{}, 'premium': false, 'vip': false,
    }));
    final cells = (await s.load()).cells[p1]![2026]!;
    expect(cells.get(3, 1)!.color, '#111111', reason: 'my waiting change stays shown until the server decides');
    expect(cells.get(3, 5)!.color, '#999999');
    expect(await s.lastRev(), 14);
  });

  test('a deletion trace removes the element; a cleared day keeps its number for the next change', () async {
    final s = await memory();
    await s.applyServer(seed());
    await s.applyServer(SyncDelta.fromJson({
      'rev': 20, 'full': false, 'pages': <dynamic>[], 'legends': <dynamic>[], 'cells': <String, dynamic>{},
      'deletions': [
        {'kind': 'cell', 'key': '$p1:2026-03-01', 'pageId': p1, 'rev': 19},
        {'kind': 'legend', 'key': l1, 'pageId': p1, 'rev': 20},
      ],
      'legendsOrder': <String, dynamic>{}, 'settings': <String, dynamic>{}, 'premium': false, 'vip': false,
    }));
    final copy = await s.load();
    expect(copy.cells[p1]?[2026]?.get(3, 1), isNull);
    expect(copy.legends[p1] ?? const [], isEmpty);
    expect((await s.record('cell.set', day(1), offline: true)).base, 19, reason: 'compared with the cleared day, not with nothing');
  });

  test('local effects: a legend recolour recolours its days; deleting a tracker removes it with its content', () async {
    final s = await memory();
    await s.applyServer(seed());
    await s.record('legend.update', {'id': l1, 'color': '#CCCCCC'}, offline: false);
    expect((await s.load()).cells[p1]![2026]!.get(3, 1)!.color, '#CCCCCC');
    await s.record('page.delete', {'id': p1}, offline: false);
    final copy = await s.load();
    expect(copy.pages, isEmpty);
    expect(copy.cells[p1], isNull);
  });

  test('the queue survives closing the app (H4); signing out erases the file', () async {
    final dir = await Directory.systemTemp.createTemp('local_store');
    final path = '${dir.path}/dian_u1.db';
    var s = await LocalStore.open('u1', factory: databaseFactoryFfiNoIsolate, path: path);
    await s.applyServer(seed());
    await s.record('cell.set', day(2), offline: true);
    await s.close();
    s = await LocalStore.open('u1', factory: databaseFactoryFfiNoIsolate, path: path);
    expect(await s.pendingCount(), 1);
    await s.close();
    await LocalStore.deleteFor('u1', factory: databaseFactoryFfiNoIsolate, path: path);
    expect(File(path).existsSync(), isFalse);
    await dir.delete(recursive: true);
  });

  test('a tracker deletion still undoable is held on the phone; releasing it or writing the delete lets it go (H14)', () async {
    final store = await memory();
    await store.applyServer(seed());
    await store.holdDelete(p1);
    expect(await store.heldDeletes(), [p1]);
    await store.releaseDelete(p1);
    expect(await store.heldDeletes(), isEmpty);
    expect(await store.pendingCount(), 0, reason: 'an undo writes nothing');

    await store.holdDelete(p1);
    await store.record('page.delete', {'id': p1}, offline: false);
    expect(await store.heldDeletes(), isEmpty, reason: 'in the same transaction as the delete');
    expect(await store.pendingCount(), 1);
    await store.close();
  });

  test('a change set aside names its tracker and legend as the phone knew them, even deleted on the phone (H21)', () async {
    final store = await memory();
    await store.applyServer(seed());
    final rename = await store.record('legend.update', {'id': l1, 'color': '#000000'}, offline: true);
    final delete = await store.record('page.delete', {'id': p1}, offline: true);
    final told = await store.settle([
      MutationResult(id: rename.id, status: 'changed', current: {'label': 'Bien', 'color': '#AAAAAA'}),
      MutationResult(id: delete.id, status: 'changed'),
    ]);
    expect(told.map((o) => (o.kind, o.pageTitle, o.legendLabel)), [
      ('legend.update', 'Mood', 'Good'),
      ('page.delete', 'Mood', null),
    ]);
    expect(SyncOutcome.fromJson(told.first.toJson()).legendLabel, 'Good', reason: 'kept until told, across a restart');
    await store.close();
  });

  test('a legend recoloured elsewhere recolours what waits on the phone: its days and its queued changes (H29)', () async {
    final store = await memory();
    await store.applyServer(seed());
    await store.record('cell.set', day(5, color: '#AAAAAA'), offline: true);
    await store.record('cell.set', day(1, color: '#AAAAAA', comment: 'note'), offline: true);
    await store.applyServer(SyncDelta.fromJson({
      'rev': 11, 'full': false,
      'pages': <dynamic>[],
      'legends': [
        {'id': l1, 'pageId': p1, 'color': '#CCCCCC', 'label': 'Good', 'position': 0, 'rev': 11, 'editRev': 11},
      ],
      'cells': {
        p1: [[2026, 3, 1, '#CCCCCC', null, 11, 8, 0]],
      },
      'deletions': <dynamic>[], 'legendsOrder': <String, dynamic>{}, 'settings': <String, dynamic>{}, 'premium': false, 'vip': false,
    }));
    expect([for (final m in await store.pending()) m.data['color']], ['#CCCCCC', '#CCCCCC'], reason: 'they leave in the new colour');
    expect((await store.pending()).last.data['comment'], 'note', reason: 'my comment is kept');
    final copy = await store.load();
    expect(copy.cells[p1]![2026]!.get(3, 5)!.color, '#CCCCCC');
    expect(copy.cells[p1]![2026]!.get(3, 1)!.color, '#CCCCCC');
    await store.close();
  });

  test('a refused change asks for the full copy back: the phone then drops what the server does not have (H12)', () async {
    final store = await memory();
    await store.applyServer(seed());
    const extra = '44444444-4444-4444-8444-444444444444';
    final create = await store.record('page.create', {'id': extra, 'title': 'Over the limit'}, offline: false);
    final told = await store.settle([MutationResult(id: create.id, status: 'rejected', reason: 'tracker_limit')]);
    expect(told.single.reason, 'tracker_limit');
    expect(await store.needsFullCopy(), isTrue);
    await store.applyServer(seed(rev: 12));
    expect((await store.load()).pages.map((p) => p.id), [p1], reason: 'the refused tracker is gone from the phone');
    await store.close();
  });
}

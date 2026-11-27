import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/models/page_model.dart';
import 'package:dian_dian/providers/pages_provider.dart';
import 'package:dian_dian/services/audio_service.dart';

import 'helpers.dart';

final _uuidV4 = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

void main() {
  late RecordingSink sink;

  PagesProvider withPages(List<Map<String, dynamic>> pages, {AudioService? audio}) =>
      PagesProvider(audio: audio ?? AudioService.silent(), sink: sink)..applyBootstrap(pages);

  setUp(() => sink = RecordingSink());

  test('createPage gives the tracker at once, with an id made by the app, and writes one page.create (H2)', () async {
    final p = withPages([pageJson('a')])..userId = 'u1';
    final created = await p.createPage('Sport');
    expect(created!.id, matches(_uuidV4));
    expect((created.title, created.position, created.userId), ('Sport', 1, 'u1'));
    expect(p.pages.map((x) => x.id), ['a', created.id]);
    expect(sink.log, [['page.create', {'id': created.id, 'title': 'Sport'}]]);
  });

  test('a creation that could not be written stays on screen', () async {
    sink.fail = true;
    final p = withPages([pageJson('a')]);
    final created = await p.createPage('Sport');
    expect(created, isNotNull);
    expect(p.pages.length, 2);
  });

  test('createFirstTracker writes the tracker with its legends in one page.create', () async {
    final p = withPages([pageJson('a'), pageJson('b', position: 1)]);
    final created = await p.createFirstTracker(
      title: 'Humeur',
      legends: const [(color: '#FFEC99', label: 'Génial'), (color: '#FFD43B', label: 'Super')],
    );
    final page = created!.page;
    expect(p.pages.map((x) => x.id), ['a', 'b', page.id]);
    expect(created.legends.map((l) => (l.color, l.label, l.position, l.pageId)), [
      ('#FFEC99', 'Génial', 0, page.id),
      ('#FFD43B', 'Super', 1, page.id),
    ]);
    expect(created.legends.every((l) => _uuidV4.hasMatch(l.id)), isTrue);
    expect(sink.log, [
      ['page.create', {
        'id': page.id,
        'title': 'Humeur',
        'legends': [
          {'id': created.legends[0].id, 'color': '#FFEC99', 'label': 'Génial'},
          {'id': created.legends[1].id, 'color': '#FFD43B', 'label': 'Super'},
        ],
      }],
    ]);
  });

  test('createFirstTracker with replaces deletes the empty tracker, creates the new one and puts it in its place', () async {
    final p = withPages([pageJson('a'), pageJson('b', position: 1)]);
    final created = await p.createFirstTracker(title: 'Humeur', legends: const [], replaces: 'a');
    final id = created!.page.id;
    expect(p.pages.map((x) => x.id), [id, 'b']);
    expect(sink.kinds, ['page.delete', 'page.create', 'pages.reorder']);
    expect(sink.changes.first.$2, {'id': 'a'});
    expect(sink.changes.last.$2, {'ids': [id, 'b']});
  });

  test('createFirstTracker whose replaced tracker is gone creates a plain one, unless the caller forbids it (free limit)', () async {
    final p = withPages([pageJson('a')]);
    final plain = await p.createFirstTracker(title: 'X', legends: const [], replaces: 'gone');
    expect(p.pages.map((x) => x.id), ['a', plain!.page.id]);
    expect(sink.kinds, ['page.create']);

    sink.changes.clear();
    final atLimit = withPages([pageJson('a'), pageJson('b', position: 1), pageJson('c', position: 2)]);
    expect(await atLimit.createFirstTracker(title: 'X', legends: const [], replaces: 'gone', fallbackWithoutReplaces: false), isNull);
    expect(atLimit.pages.map((x) => x.id), ['a', 'b', 'c']);
    expect(sink.changes, isEmpty);
  });

  test('createFirstTracker uses the clientId as the tracker id; the same gesture again finds it', () async {
    const id = '11111111-1111-4111-8111-111111111111';
    final p = withPages(const []);
    final created = await p.createFirstTracker(title: 'X', legends: const [(color: '#FFEC99', label: 'G')], clientId: id);
    expect(created!.page.id, id);
    final again = await p.createFirstTracker(title: 'X', legends: const [(color: '#FFEC99', label: 'G')], clientId: id);
    expect(again!.page.id, id);
    expect(again.legends, isEmpty, reason: 'the caller keeps the legends it shows');
    expect(p.pages.length, 1);
    expect(sink.kinds, ['page.create'], reason: 'no twin');
  });

  test('keepFree flags the kept trackers, clears the others and writes one pages.keep', () async {
    final p = withPages([pageJson('a', keepFree: true), pageJson('b', position: 1), pageJson('c', position: 2)]);
    expect(await p.keepFree(['b', 'c']), isTrue);
    expect(p.pages.map((x) => '${x.id}:${x.keepFree}'), ['a:false', 'b:true', 'c:true']);
    expect(sink.log, [['pages.keep', {'ids': ['b', 'c']}]]);
  });

  test('updatePage renames at once and writes the title only', () async {
    final p = withPages([pageJson('a', title: 'Old')]);
    await p.updatePage('a', {'title': 'New'});
    expect(p.pages.single.title, 'New');
    expect(sink.log, [['page.update', {'id': 'a', 'title': 'New'}]]);
  });

  test('updatePage changes the palette and writes it', () async {
    final p = withPages([pageJson('a')]);
    final palette = [['#111111', '#222222']];
    await p.updatePage('a', {'palette': palette});
    expect(p.pages.single.palette, palette);
    expect(sink.log, [['page.update', {'id': 'a', 'palette': palette}]]);
  });

  test('reorderPages reorders at once and writes pages.reorder', () async {
    final p = withPages([pageJson('a'), pageJson('b', position: 1), pageJson('c', position: 2)]);
    await p.reorderPages(['c', 'a', 'b']);
    expect(p.pages.map((x) => '${x.id}:${x.position}'), ['c:0', 'a:1', 'b:2']);
    expect(sink.log, [['pages.reorder', {'ids': ['c', 'a', 'b']}]]);
  });

  test('deletePage removes at once and writes page.delete', () async {
    final p = withPages([pageJson('a'), pageJson('b', position: 1)]);
    await p.deletePage('a');
    expect(p.pages.map((x) => x.id), ['b']);
    expect(sink.log, [['page.delete', {'id': 'a'}]]);
  });

  test('a soft delete writes nothing until its delay is over; an undo writes nothing', () async {
    const delay = Duration(milliseconds: 40);
    final p = withPages([pageJson('a'), pageJson('b', position: 1)]);
    p.softDeletePage(p.pages.first, delay: delay);
    expect(p.pages.map((x) => x.id), ['b']);
    p.undoDeletePage();
    await Future<void>.delayed(delay * 2);
    expect(sink.changes, isEmpty);
    expect(p.pages.map((x) => x.id), containsAll(['a', 'b']));

    p.softDeletePage(p.pages.firstWhere((x) => x.id == 'a'), delay: delay);
    expect(sink.changes, isEmpty);
    await Future<void>.delayed(delay * 2);
    expect(sink.log, [['page.delete', {'id': 'a'}]]);
    expect(p.pendingDeletePage, isNull);
  });

  test('a load of the copy keeps a tracker whose deletion is still undoable hidden', () {
    final p = withPages([pageJson('a'), pageJson('b', position: 1)]);
    p.softDeletePage(p.pages.first);
    p.applyPages([PageModel.fromJson(pageJson('a')), PageModel.fromJson(pageJson('b', position: 1))]);
    expect(p.pages.map((x) => x.id), ['b']);
    p.cancelPendingDelete();
  });

  test('PageModel reads activity and keepFree, defaults when absent (snapshot of 1.3.0)', () {
    final full = PageModel.fromJson(pageJson('a', recentCells: 7, lastCellAt: '2026-10-15T00:00:00Z', keepFree: true));
    expect(full.recentCells, 7);
    expect(full.lastCellAt, '2026-10-15T00:00:00Z');
    expect(full.keepFree, isTrue);
    final old = PageModel.fromJson({'id': 'b', 'userId': 'u1', 'title': 'T', 'year': 2026, 'position': 0, 'palette': null, 'createdAt': ''});
    expect(old.recentCells, 0);
    expect(old.lastCellAt, isNull);
    expect(old.keepFree, isFalse);
    expect(PageModel.fromJson(full.toJson()).keepFree, isTrue, reason: 'round-trips through the snapshot');
  });

  test('a created tracker plays trackerCreate, the first tracker too; a load of the copy plays nothing', () async {
    SharedPreferences.setMockInitialValues({});
    final rec = await recordingAudio();
    final p = withPages(const [], audio: rec.service);
    await p.createPage('New');
    await p.createFirstTracker(title: 'X', legends: const []);
    p.applyPages([PageModel.fromJson(pageJson('c', position: 2))]);
    await Future<void>.delayed(Duration.zero);
    expect(rec.players.played, [SoundCue.trackerCreate, SoundCue.trackerCreate]);
  });

  test('a soft delete is held on the phone; an undo releases it; its end writes it (H14)', () async {
    const delay = Duration(milliseconds: 40);
    final p = withPages([pageJson('a'), pageJson('b', position: 1)]);
    p.softDeletePage(p.pages.first, delay: delay);
    await Future<void>.delayed(Duration.zero);
    expect(sink.held, {'a'});
    p.undoDeletePage();
    await Future<void>.delayed(Duration.zero);
    expect(sink.held, isEmpty);
    expect(sink.changes, isEmpty);

    p.softDeletePage(p.pages.firstWhere((x) => x.id == 'a'), delay: delay);
    await Future<void>.delayed(delay * 2);
    expect(sink.log, [['page.delete', {'id': 'a'}]]);
    expect(sink.held, isEmpty);
  });

  test('without a full copy (H15), no tracker change is made and each attempt is refused', () async {
    sink.canWrite = false;
    final p = withPages([pageJson('a'), pageJson('b', position: 1)]);
    expect(await p.createPage('New'), isNull);
    expect(await p.createFirstTracker(title: 'X', legends: const []), isNull);
    expect(await p.keepFree(['a']), isFalse);
    await p.updatePage('a', {'title': 'Renamed'});
    await p.reorderPages(['b', 'a']);
    await p.deletePage('a');
    p.softDeletePage(p.pages.first);
    expect(p.pages.map((x) => '${x.id}:${x.title}:${x.keepFree}'), ['a:T:false', 'b:T:false']);
    expect(p.pendingDeletePage, isNull);
    expect(sink.changes, isEmpty);
    expect(sink.held, isEmpty);
    expect(sink.refusals, 7);
  });
}

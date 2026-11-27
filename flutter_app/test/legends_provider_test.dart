import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/models/legend_model.dart';
import 'package:dian_dian/providers/legends_provider.dart';
import 'package:dian_dian/services/audio_service.dart';

import 'helpers.dart';

Map<String, dynamic> legend(String id, String pageId, String color, int pos) =>
    {'id': id, 'pageId': pageId, 'color': color, 'label': id, 'position': pos, 'createdAt': ''};

final _uuidV4 = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  LegendsProvider loaded({RecordingSink? sink}) => LegendsProvider(audio: AudioService.silent(), sink: sink)
    ..applyBootstrap({
      'a': [legend('l1', 'a', '#AAAAAA', 0), legend('l2', 'a', '#BBBBBB', 1)],
      'b': <dynamic>[],
    });

  test('legendsFor / legends follow the current page', () {
    final p = loaded();
    expect(p.legendsFor('a').length, 2);
    expect(p.legendsFor('unknown'), isEmpty);
    expect(p.legends, isEmpty);
    p.setPageId('a');
    expect(p.currentPageId, 'a');
    expect(p.legends.map((l) => l.id), ['l1', 'l2']);
  });

  test('setPageId is synchronous and notifies once', () {
    final p = loaded();
    var notified = 0;
    p.addListener(() => notified++);
    p.setPageId('a');
    expect(notified, 1);
  });

  test('applyBootstrap replaces everything; clear empties', () {
    final p = loaded();
    p.applyBootstrap({'c': [legend('l9', 'c', '#000000', 0)]});
    expect(p.legendsFor('a'), isEmpty);
    expect(p.legendsFor('c').length, 1);
    p.clear();
    expect(p.legendsFor('c'), isEmpty);
    expect(p.currentPageId, isNull);
  });

  test('applyCopy replaces every page with the copy', () {
    final p = loaded()..setPageId('a');
    p.applyCopy({'c': [LegendModel.fromJson(legend('l9', 'c', '#000000', 0))]});
    expect(p.legendsFor('a'), isEmpty);
    expect(p.legendsFor('c').single.id, 'l9');
    expect(p.currentPageId, 'a', reason: 'the page on screen stays');
  });

  test('setLegends replaces a page list', () {
    final p = loaded();
    p.setLegends('b', [LegendModel.fromJson(legend('l9', 'b', '#999999', 0))]);
    expect(p.legendsFor('b').single.id, 'l9');
  });

  test('createLegend shows it at once with an id made by the app and writes one legend.create', () async {
    final sink = RecordingSink();
    final p = loaded(sink: sink)..setPageId('a');
    await p.createLegend('#CCCCCC', 'Sport');
    final created = p.legends.last;
    expect((created.color, created.label, created.position), ('#CCCCCC', 'Sport', 2));
    expect(created.id, matches(_uuidV4));
    expect(sink.log, [['legend.create', {'id': created.id, 'pageId': 'a', 'color': '#CCCCCC', 'label': 'Sport'}]]);
  });

  test('a new colour is one change: legend.update with the colour', () async {
    final sink = RecordingSink();
    final p = loaded(sink: sink)..setPageId('a');
    await p.updateLegend('l1', color: '#111111');
    expect(p.legends.first.color, '#111111');
    expect(sink.log, [['legend.update', {'id': 'l1', 'color': '#111111'}]]);
  });

  test('a rename writes legend.update with the label only', () async {
    final sink = RecordingSink();
    final p = loaded(sink: sink)..setPageId('a');
    await p.updateLegend('l2', label: 'Lu');
    expect(p.legends.last.label, 'Lu');
    expect(sink.log, [['legend.update', {'id': 'l2', 'label': 'Lu'}]]);
  });

  test('deleteLegend and reorderLegends write legend.delete and legends.reorder', () async {
    final sink = RecordingSink();
    final p = loaded(sink: sink)..setPageId('a');
    await p.reorderLegends(['l2', 'l1']);
    expect(p.legends.map((l) => l.id), ['l2', 'l1']);
    await p.deleteLegend('l1');
    expect(p.legends.map((l) => l.id), ['l2']);
    expect(sink.log, [
      ['legends.reorder', {'pageId': 'a', 'ids': ['l2', 'l1']}],
      ['legend.delete', {'id': 'l1'}],
    ]);
  });

  test('reorder keeps legends missing from ids at the end', () async {
    final p = loaded(sink: RecordingSink())..setPageId('a');
    await p.reorderLegends(['l2']);
    expect(p.legends.map((l) => l.id), ['l2', 'l1']);
  });

  test('a change that could not be written stays on screen', () async {
    final sink = RecordingSink()..fail = true;
    final p = loaded(sink: sink)..setPageId('a');
    await p.createLegend('#CCCCCC', 'Sport');
    await p.deleteLegend('l1');
    expect(p.legends.map((l) => l.label), ['l2', 'Sport']);
  });

  test('a created legend plays legendAdd', () async {
    SharedPreferences.setMockInitialValues({});
    final rec = await recordingAudio();
    final p = LegendsProvider(audio: rec.service, sink: RecordingSink())
      ..applyBootstrap({'a': <dynamic>[]})
      ..setPageId('a');
    await p.createLegend('#ff0000', 'Sport');
    expect(rec.players.played, [SoundCue.legendAdd]);
  });

  test('without a full copy (H15), no legend changes and each attempt is refused', () async {
    final sink = RecordingSink()..canWrite = false;
    final p = loaded(sink: sink)..setPageId('a');
    await p.createLegend('#CCCCCC', 'Sport');
    await p.updateLegend('l1', color: '#111111');
    await p.deleteLegend('l2');
    await p.reorderLegends(['l2', 'l1']);
    expect(p.legends.map((l) => '${l.id}:${l.color}'), ['l1:#AAAAAA', 'l2:#BBBBBB']);
    expect(sink.changes, isEmpty);
    expect(sink.refusals, 4);
  });
}

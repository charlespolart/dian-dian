import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/providers/legends_provider.dart';
import 'package:dian_dian/services/ws_service.dart';

Map<String, dynamic> legend(String id, String pageId, String color, int pos) =>
    {'id': id, 'pageId': pageId, 'color': color, 'label': id, 'position': pos, 'createdAt': ''};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  LegendsProvider loaded() => LegendsProvider()
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

  test('legends:reordered uses ids (previously ignored: expected a legends list)', () {
    final p = loaded()..setPageId('a');
    p.debugHandleWs(const WsMessage(event: 'legends:reordered', data: {'pageId': 'a', 'ids': ['l2', 'l1']}));
    expect(p.legends.map((l) => l.id), ['l2', 'l1']);
  });

  test('legends:reordered keeps legends missing from ids at the end', () {
    final p = loaded()..setPageId('a');
    p.debugHandleWs(const WsMessage(event: 'legends:reordered', data: {'pageId': 'a', 'ids': ['l2']}));
    expect(p.legends.map((l) => l.id), ['l2', 'l1']);
  });

  test('legends:recolored uses colorMap (previously ignored)', () {
    final p = loaded()..setPageId('a');
    p.debugHandleWs(const WsMessage(event: 'legends:recolored', data: {
      'pageId': 'a', 'colorMap': {'#AAAAAA': '#111111'},
    }));
    expect(p.legends.first.color, '#111111');
    expect(p.legends.last.color, '#BBBBBB');
  });

  test('legend events apply to non-current pages too (card previews stay fresh)', () {
    final p = loaded()..setPageId('a');
    p.debugHandleWs(WsMessage(event: 'legend:created', data: legend('l3', 'b', '#CCCCCC', 0)));
    expect(p.legendsFor('b').length, 1);
    p.debugHandleWs(WsMessage(event: 'legend:updated', data: legend('l3', 'b', '#DDDDDD', 0)));
    expect(p.legendsFor('b').first.color, '#DDDDDD');
    p.debugHandleWs(const WsMessage(event: 'legend:deleted', data: {'id': 'l3', 'pageId': 'b'}));
    expect(p.legendsFor('b'), isEmpty);
  });

  test('legend:created is idempotent (own echo from the server)', () {
    final p = loaded()..setPageId('a');
    p.debugHandleWs(WsMessage(event: 'legend:created', data: legend('l1', 'a', '#AAAAAA', 0)));
    expect(p.legends.length, 2);
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
}

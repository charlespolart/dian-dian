import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:dian_dian/data/connectivity.dart';
import 'package:dian_dian/services/ws_service.dart';

/// The account as the server holds it, with the two sync routes.
class FakeSyncServer {
  bool offline = false;
  /// When set, every answer waits for it.
  Completer<void>? hold;
  int rev = 1;
  int pulls = 0;
  int healthChecks = 0;
  bool premium = false;
  final batches = <List<String>>[];
  /// The kinds that arrived judged by the offline rule.
  final waitedKinds = <String>[];
  final pages = <String, Map<String, dynamic>>{};
  final legends = <String, Map<String, dynamic>>{};
  /// pageId → [year, month, day, color, comment, rev, editRev, updatedAtMs].
  final cells = <String, List<List<dynamic>>>{};
  final settings = <String, Map<String, dynamic>>{};

  void addPage(String id, {String title = 'T', int position = 0}) {
    rev++;
    pages[id] = {
      'id': id, 'title': title, 'position': position, 'palette': null, 'keepFree': false, 'createdAt': '',
      'rev': rev, 'editRev': rev, 'contentRev': rev, 'legendsOrderRev': 0,
    };
  }

  void addCell(String pageId, int year, int month, int day, String color) {
    rev++;
    (cells[pageId] ??= []).add([year, month, day, color, null, rev, rev, 0]);
  }

  void _apply(Map<String, dynamic> m) {
    final data = (m['data'] as Map).cast<String, dynamic>();
    switch (m['kind']) {
      case 'page.create':
        addPage(data['id'] as String, title: data['title'] as String, position: pages.length);
        for (final (i, l) in ((data['legends'] as List?) ?? const []).indexed) {
          legends[l['id'] as String] = {'id': l['id'], 'pageId': data['id'], 'color': l['color'], 'label': l['label'], 'position': i, 'rev': rev, 'editRev': rev};
        }
      case 'cell.set':
        addCell(data['pageId'] as String, data['year'] as int, data['month'] as int, data['day'] as int, data['color'] as String);
      case 'setting.set':
        rev++;
        settings[data['key'] as String] = {'rev': rev, 'value': data['value']};
    }
  }

  late final client = MockClient((req) async {
    if (hold != null) await hold!.future;
    if (offline) throw const SocketException('offline');
    if (req.url.path == '/api/health') {
      healthChecks++;
      return http.Response('{"ok":true}', 200);
    }
    if (req.url.path == '/api/sync/mutations') {
      final mutations = (jsonDecode(req.body)['mutations'] as List).cast<Map<String, dynamic>>();
      batches.add([for (final m in mutations) m['kind'] as String]);
      waitedKinds.addAll([for (final m in mutations) if (m['waited'] == true) m['kind'] as String]);
      final results = <Map<String, dynamic>>[];
      for (final m in mutations) {
        _apply(m);
        results.add({'id': m['id'], 'status': 'applied', 'revs': {'element': rev, 'account': rev}});
      }
      return http.Response(jsonEncode({'results': results, 'rev': rev}), 200);
    }
    if (req.url.path == '/api/sync') {
      pulls++;
      return http.Response(jsonEncode({
        'rev': rev,
        'full': req.url.queryParameters['since'] == '0',
        'pages': pages.values.toList(),
        'legends': legends.values.toList(),
        'cells': cells,
        'deletions': [],
        'legendsOrder': {},
        'settings': settings,
        'premium': premium,
        'vip': false,
      }), 200);
    }
    return http.Response('{}', 404);
  });

  List<String> get sentKinds => batches.expand((b) => b).toList();
}

class FakeNetwork implements NetworkWatcher {
  final _changes = StreamController<void>.broadcast();
  @override
  Stream<void> get onChange => _changes.stream;
  void comeBack() => _changes.add(null);
}

/// The WebSocket, minus the socket: [receive] hands a message to the listeners.
class FakeWs implements WsService {
  final _listeners = <WsListener>[];
  @override
  VoidCallback? onReconnected;
  @override
  RemoveListener addListener(WsListener listener) {
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  @override
  void ensureConnected() {}
  @override
  void connect() {}
  @override
  void disconnect() {}

  void receive(String event, [Object? data]) {
    for (final l in List.of(_listeners)) {
      l(WsMessage(event: event, data: data));
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

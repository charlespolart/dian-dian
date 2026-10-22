import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/services/snapshot_store.dart';
import 'package:dian_dian/services/token_store.dart';

/// In-memory [TokenStore] for tests.
class FakeTokens implements TokenStore {
  String? refresh;
  String? userId;
  FakeTokens({this.refresh = 'r', this.userId = 'u1'});

  @override
  Future<String?> getRefreshToken() async => refresh;
  @override
  Future<void> setRefreshToken(String token) async => refresh = token;
  @override
  Future<void> deleteRefreshToken() async => refresh = null;
  @override
  Future<String?> getUserId() async => userId;
  @override
  Future<void> setUserId(String id) async => userId = id;
  @override
  Future<void> deleteUserId() async => userId = null;
}

/// In-memory [SnapshotStore] for tests.
class MemorySnapshots implements SnapshotStore {
  String? data;
  int writes = 0;

  @override
  Future<String?> read() async => data;
  @override
  Future<void> write(String json) async {
    data = json;
    writes++;
  }

  @override
  Future<void> delete() async => data = null;
}

Map<String, dynamic> pageJson(
  String id, {
  int position = 0,
  String title = 'T',
  String createdAt = '',
  int recentCells = 0,
  String? lastCellAt,
  bool keepFree = false,
}) =>
    {
      'id': id,
      'userId': 'u1',
      'title': title,
      'year': 2026,
      'position': position,
      'palette': null,
      'createdAt': createdAt,
      'recentCells': recentCells,
      'lastCellAt': lastCellAt,
      'keepFree': keepFree,
    };

Map<String, dynamic> legendJson(String id, String pageId, String color, int position, {String? label}) => {
      'id': id,
      'pageId': pageId,
      'color': color,
      'label': label ?? id,
      'position': position,
      'createdAt': '',
    };

/// A 500 × 844 logical surface, portrait: tall enough to scroll, wide enough
/// for a header under the test font (every glyph a square).
void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1500, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

/// A 600 × 900 logical surface, portrait tablet: the tracker's sidebar at its
/// wide setting, where the year row fits under the test font.
void tabletPortrait(WidgetTester tester) {
  tester.view.physicalSize = const Size(1800, 2700);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

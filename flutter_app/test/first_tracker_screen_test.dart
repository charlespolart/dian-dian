import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/providers/cells_provider.dart';
import 'package:dian_dian/providers/language_provider.dart';
import 'package:dian_dian/providers/legends_provider.dart';
import 'package:dian_dian/providers/pages_provider.dart';
import 'package:dian_dian/screens/first_tracker_screen.dart';
import 'package:dian_dian/services/api_service.dart';
import 'package:dian_dian/services/audio_service.dart';

import 'helpers.dart';

/// Like the real server: JSON in UTF-8 (a bare `http.Response` would encode
/// the body as Latin-1 and choke on the en dash of the Sleep labels).
http.Response _json(String body, int status) =>
    http.Response(body, status, headers: const {'content-type': 'application/json; charset=utf-8'});

/// Providers + a fake server around a [FirstTrackerScreen]. The server
/// answers POST /api/pages with the page "n" and the legends it was sent,
/// and PUT /api/cells/n with the cell it was sent.
class Harness {
  final List<http.Request> requests = [];
  int pageStatus = 201;
  /// 409 on any POST carrying `replaces` (the page is no longer empty).
  bool refuseReplace = false;
  int Function() cellStatus = () => 200;
  late final PagesProvider pages;
  late final LegendsProvider legends;
  late final CellsProvider cells;
  late final Widget widget;

  Harness({
    required DateTime Function() now,
    VoidCallback? onLater,
    void Function(String pageId, int year)? onOpen,
    List<Map<String, dynamic>> pageRows = const [],
    Map<String, dynamic> legendRows = const {},
    int maxTrackers = 3,
  }) {
    final client = MockClient((req) async {
      requests.add(req);
      if (req.method == 'POST' && req.url.path == '/api/pages') {
        if (pageStatus != 201) return _json('{"error":"x"}', pageStatus);
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        if (refuseReplace && body.containsKey('replaces')) return _json('{"error":"Page is not empty"}', 409);
        final sent = body['legends'] as List<dynamic>;
        return _json(jsonEncode({
          ...pageJson('n', title: body['title'] as String),
          'legends': [
            for (var i = 0; i < sent.length; i++)
              legendJson('l$i', 'n', sent[i]['color'] as String, i, label: sent[i]['label'] as String),
          ],
          'replaced': body['replaces'],
        }), 201);
      }
      if (req.method == 'PUT' && req.url.path == '/api/cells/n') {
        final status = cellStatus();
        if (status != 200) return _json('{"error":"x"}', status);
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        return _json(jsonEncode({'pageId': 'n', ...body, 'updatedAt': ''}), 200);
      }
      return _json('{"error":"unexpected ${req.method} ${req.url.path}"}', 404);
    });
    final api = ApiService.custom(client: client, tokens: FakeTokens());
    pages = PagesProvider(api: api)..applyBootstrap(pageRows);
    legends = LegendsProvider(api: api)..applyBootstrap(legendRows);
    cells = CellsProvider(api: api, audio: AudioService.silent())
      ..applyBootstrap(now().year, {for (final p in pageRows) p['id'] as String: <dynamic>[]});
    widget = MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider.value(value: pages),
        ChangeNotifierProvider.value(value: legends),
        ChangeNotifierProvider.value(value: cells),
      ],
      child: MaterialApp(
        home: FirstTrackerScreen(
          userId: 'u1',
          maxTrackers: maxTrackers,
          now: now,
          onLater: onLater ?? () {},
          onOpenTracker: onOpen ?? (_, _) {},
        ),
      ),
    );
  }

  List<http.Request> get posts => requests.where((r) => r.method == 'POST').toList();
  List<http.Request> get puts => requests.where((r) => r.method == 'PUT').toList();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final oct15 = DateTime(2026, 10, 15, 9);

  testWidgets('Mood → Great creates the page with five legends and sets today\'s cell', (tester) async {
    final h = Harness(now: () => oct15);
    await tester.pumpWidget(h.widget);
    await tester.pump();
    expect(find.text('What do you want to track?'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);

    await tester.tap(find.text('Mood'));
    await tester.pumpAndSettle();
    expect(find.text('Thursday, October 15'), findsOneWidget);
    expect(find.text('And today?'), findsOneWidget);
    expect(find.text('Not today'), findsOneWidget);
    expect(h.requests, isEmpty, reason: 'nothing is created before a choice');

    await tester.tap(find.text('Great'));
    await tester.pumpAndSettle();

    final body = jsonDecode(h.posts.single.body) as Map<String, dynamic>;
    expect(body['title'], 'Mood');
    expect(body['position'], 0);
    expect(body.containsKey('replaces'), isFalse);
    expect((body['legends'] as List).map((l) => l['label']), ['Great', 'Good', 'Okay', 'Meh', 'Low']);
    expect(jsonDecode(h.puts.single.body), {'year': 2026, 'month': 10, 'day': 15, 'color': '#FFEC99'});
    expect(h.legends.legendsFor('n').length, 5);
    expect(h.cells.getCell(10, 15)!.color, '#FFEC99');
    expect(find.text('Open my tracker'), findsOneWidget);
    expect(find.text('Not today'), findsNothing);
    expect((await SharedPreferences.getInstance()).getBool('first_tracker_done_u1'), isTrue);
  });

  testWidgets('Open my tracker hands the created page and the current year to the parent', (tester) async {
    String? opened;
    final h = Harness(now: () => oct15, onOpen: (id, year) => opened = '$id/$year');
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Mood'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Great'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open my tracker'));
    await tester.pump();
    expect(opened, 'n/2026');
  });

  testWidgets('a failed cell shows the error; Retry only replays the cell', (tester) async {
    var failCell = true;
    final h = Harness(now: () => oct15)..cellStatus = () => failCell ? 500 : 200;
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Mood'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Great'));
    await tester.pumpAndSettle();
    expect(find.text("Can't reach the server, try again"), findsOneWidget);
    expect(find.text('Open my tracker'), findsNothing);
    expect(h.posts.length, 1);
    expect(h.puts.length, 1);

    failCell = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(h.posts.length, 1, reason: 'the page is never created twice');
    expect(h.puts.length, 2);
    expect(find.text("Can't reach the server, try again"), findsNothing);
    expect(find.text('Open my tracker'), findsOneWidget);
  });

  testWidgets('a failed page creation shows the error; Retry creates it then sets the cell', (tester) async {
    final h = Harness(now: () => oct15)..pageStatus = 500;
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Sleep'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('8 h+'));
    await tester.pumpAndSettle();
    expect(find.text("Can't reach the server, try again"), findsOneWidget);
    expect(h.puts, isEmpty);
    expect(h.pages.pages, isEmpty);

    h.pageStatus = 201;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(h.posts.length, 2);
    expect(h.puts.length, 1);
    expect(find.text('Open my tracker'), findsOneWidget);
  });

  testWidgets('the date is read at tap time (midnight while the screen is open)', (tester) async {
    var clock = DateTime(2026, 10, 15, 23, 59);
    final h = Harness(now: () => clock);
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Mood'));
    await tester.pumpAndSettle();
    expect(find.text('Thursday, October 15'), findsOneWidget);

    clock = DateTime(2026, 10, 16, 0, 1);
    await tester.tap(find.text('Great'));
    await tester.pumpAndSettle();
    expect(jsonDecode(h.puts.single.body), {'year': 2026, 'month': 10, 'day': 16, 'color': '#FFEC99'});
    expect(find.text('Friday, October 16'), findsOneWidget);
  });

  testWidgets('Other… needs a non-blank title before continuing', (tester) async {
    final h = Harness(now: () => oct15);
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Other…'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('And today?'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Water');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Water'), findsOneWidget);
    expect(find.text('Yes'), findsOneWidget);
    expect(find.text('A little'), findsOneWidget);
    expect(find.text('No'), findsOneWidget);

    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect((jsonDecode(h.posts.single.body) as Map)['title'], 'Water');
  });

  testWidgets('Not today creates the tracker without a cell and opens it', (tester) async {
    String? opened;
    final h = Harness(now: () => oct15, onOpen: (id, year) => opened = '$id/$year');
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Sleep'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not today'));
    await tester.pumpAndSettle();
    expect(h.posts.length, 1);
    expect(h.puts, isEmpty);
    expect(opened, 'n/2026');
    expect((await SharedPreferences.getInstance()).getBool('first_tracker_done_u1'), isTrue);
  });

  testWidgets('a dormant account\'s empty page is replaced, not doubled', (tester) async {
    final h = Harness(
      now: () => oct15,
      pageRows: [pageJson('old', title: 'My Tracker')],
      legendRows: {'old': <dynamic>[]},
    );
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Habits'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    final body = jsonDecode(h.posts.single.body) as Map<String, dynamic>;
    expect(body['replaces'], 'old');
    expect(body.containsKey('position'), isFalse);
    expect(h.pages.pages.map((p) => p.id), ['n']);
  });

  testWidgets('Later leaves without a request and is remembered for this account on this device', (tester) async {
    var later = false;
    final h = Harness(now: () => oct15, onLater: () => later = true);
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(later, isTrue);
    expect(h.requests, isEmpty);
    expect((await SharedPreferences.getInstance()).getBool('first_tracker_done_u1'), isTrue);
    expect(await FirstTrackerScreen.isDone('u1'), isTrue);
    expect(await FirstTrackerScreen.isDone('u2'), isFalse);
  });

  testWidgets('at the free limit, a refused replace shows the error instead of creating a locked 4th tracker', (tester) async {
    final h = Harness(
      now: () => oct15,
      pageRows: [pageJson('old', title: 'My Tracker'), pageJson('p2', position: 1), pageJson('p3', position: 2)],
      legendRows: {
        'old': <dynamic>[],
        'p2': [legendJson('l2', 'p2', '#111111', 0)],
        'p3': [legendJson('l3', 'p3', '#222222', 0)],
      },
      maxTrackers: 3,
    )..refuseReplace = true;
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Habits'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(h.posts.length, 1, reason: 'no fallback POST without replaces');
    expect((jsonDecode(h.posts.single.body) as Map)['replaces'], 'old');
    expect(h.pages.pages.length, 3, reason: 'nothing created');
    expect(find.text("Can't reach the server, try again"), findsOneWidget);
    expect(find.text('Open my tracker'), findsNothing);
    expect(find.text('Later'), findsOneWidget);
  });
}

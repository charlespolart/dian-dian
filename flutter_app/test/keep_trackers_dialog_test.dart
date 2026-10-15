import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/providers/language_provider.dart';
import 'package:dian_dian/providers/pages_provider.dart';
import 'package:dian_dian/services/api_service.dart';
import 'package:dian_dian/widgets/keep_trackers_dialog.dart';

import 'helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late List<http.Request> requests;
  late PagesProvider pages;

  Widget host() {
    requests = [];
    final client = MockClient((req) async {
      requests.add(req);
      return http.Response('{"ok":true}', 200, headers: const {'content-type': 'application/json; charset=utf-8'});
    });
    pages = PagesProvider(api: ApiService.custom(client: client, tokens: FakeTokens()))
      ..applyBootstrap([
        pageJson('mood', title: 'Mood', recentCells: 40, lastCellAt: '2026-10-15T00:00:00Z'),
        pageJson('sleep', title: 'Sleep', position: 1, recentCells: 12, lastCellAt: '2026-10-10T00:00:00Z'),
        pageJson('books', title: 'Books', position: 2),
        pageJson('gym', title: 'Gym', position: 3, recentCells: 3, lastCellAt: '2026-09-01T00:00:00Z'),
        pageJson('water', title: 'Water', position: 4, recentCells: 1, lastCellAt: '2026-05-01T00:00:00Z'),
      ]);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider.value(value: pages),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => KeepTrackersDialog.show(context, maxTrackers: 3),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  bool checked(WidgetTester tester, String title) =>
      tester.widget<Checkbox>(find.byKey(Key('keep.$title'))).value == true;

  testWidgets('the three most active trackers are preselected', (tester) async {
    await open(tester);
    expect(find.text('Free account: 3 trackers'), findsOneWidget);
    expect(checked(tester, 'mood'), isTrue);
    expect(checked(tester, 'sleep'), isTrue);
    expect(checked(tester, 'gym'), isTrue);
    expect(checked(tester, 'books'), isFalse);
    expect(checked(tester, 'water'), isFalse);
    expect(find.text('40 days filled in the last 90'), findsOneWidget);
    expect(find.text('never filled'), findsOneWidget);
  });

  testWidgets('at most three: a fourth tap is ignored until one is unchecked', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('keep.books')));
    await tester.pump();
    expect(checked(tester, 'books'), isFalse, reason: 'already three');
    await tester.tap(find.byKey(const Key('keep.gym')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('keep.books')));
    await tester.pump();
    expect(checked(tester, 'gym'), isFalse);
    expect(checked(tester, 'books'), isTrue);
  });

  testWidgets('Keep these 3 sends the choice and closes', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('keep.sleep')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('keep.water')));
    await tester.pump();
    await tester.tap(find.text('Keep these 3'));
    await tester.pumpAndSettle();
    final put = requests.single;
    expect(put.method, 'PUT');
    expect(put.url.path, '/api/pages/keep');
    expect((jsonDecode(put.body) as Map)['ids'], unorderedEquals(['mood', 'gym', 'water']));
    expect(find.text('Keep these 3'), findsNothing, reason: 'closed');
  });

  testWidgets('with fewer than three selected the button is disabled', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('keep.sleep')));
    await tester.pump();
    await tester.tap(find.text('Keep these 3'));
    await tester.pumpAndSettle();
    expect(requests, isEmpty);
  });
}

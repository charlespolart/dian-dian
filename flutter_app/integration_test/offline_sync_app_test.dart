// The real app on a simulator or a phone (native SQLite, network watcher,
// secure storage) against a RUNNING local backend on :3001 — offline sync,
// chantier 10. Run (backend up, simulator booted):
//   cd flutter_app && flutter test integration_test/offline_sync_app_test.dart -d <device id>
// Registers a throwaway account, signs in through the screens, makes the
// first tracker with today's day, then reads the server: both arrived
// through the sync, with the app's own ids.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

import 'package:dian_dian/main.dart' as app;
import 'package:dian_dian/services/api_service.dart';

Future<void> settleFor(WidgetTester tester, Duration total) async {
  final end = DateTime.now().add(total);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> waitFor(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 20)}) async {
  final end = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) {
      final shown = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? t.textSpan?.toPlainText()).toList();
      throw TestFailure('not found in time: $finder\nOn screen: $shown');
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sign in, first tracker with today\'s day: on the phone at once, on the server through the sync', (tester) async {
    final base = ApiService.baseUrl;
    final email = 'device-${DateTime.now().millisecondsSinceEpoch}@example.com';
    const password = 'device-password-123';
    final reg = await http.post(Uri.parse('$base/api/auth/register'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email, 'password': password}));
    expect(reg.statusCode, 201, reason: reg.body);
    final token = jsonDecode(reg.body)['accessToken'] as String;

    app.main();
    await waitFor(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField).at(0), email);
    await tester.enterText(find.byType(TextField).at(1), password);
    await tester.tap(find.text('Log in').last);
    await waitFor(tester, find.text('Mood'), timeout: const Duration(seconds: 30));

    await tester.tap(find.text('Mood'));
    await waitFor(tester, find.text('Great'));
    await tester.tap(find.text('Great'));
    await waitFor(tester, find.text('Open my tracker'));
    await settleFor(tester, const Duration(seconds: 3)); // the queue leaves

    final sync = await http.get(Uri.parse('$base/api/sync?since=0'), headers: {'Authorization': 'Bearer $token'});
    final copy = jsonDecode(sync.body) as Map<String, dynamic>;
    final pages = (copy['pages'] as List).cast<Map<String, dynamic>>();
    expect(pages.map((p) => p['title']), ['Mood'], reason: 'the tracker made on the phone reached the server');
    final days = (copy['cells'] as Map)[pages.single['id']] as List;
    final today = DateTime.now();
    expect(days.map((c) => (c as List).sublist(0, 4)), [[today.year, today.month, today.day, '#FFEC99']]);
    expect((copy['legends'] as List).length, 5, reason: 'with its legends, ids made by the app');

    await tester.tap(find.text('Open my tracker'));
    await settleFor(tester, const Duration(seconds: 2));
    expect(find.text('Mood'), findsWidgets, reason: 'the tracker opens');

    await http.delete(Uri.parse('$base/api/auth/account'), headers: {'Authorization': 'Bearer $token'});
  });
}

// The real app on a simulator or a phone against a RUNNING local backend on
// :3001 — the welcome screen, chantier 9. Run (backend up, simulator booted,
// keychain reset: `xcrun simctl keychain <sim> reset`):
//   cd flutter_app && flutter test integration_test/welcome_app_test.dart -d <device id>
// « Continue without an account », first tracker with today's day, then
// reads the server with the phone's own key: the account was born under the
// id the phone chose, and the tracker reached it through the sync.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

import 'package:dian_dian/main.dart' as app;
import 'package:dian_dian/services/api_service.dart';
import 'package:dian_dian/services/storage_service.dart';

import 'offline_sync_app_test.dart' show settleFor, waitFor;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('« Continue without an account »: first tracker, today\'s day, on the server under the phone\'s id', (tester) async {
    app.main();
    await waitFor(tester, find.text('Continue without an account'));
    expect(find.text('Continue with email'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    await tester.tap(find.text('Continue without an account'));
    await waitFor(tester, find.text('Mood'), timeout: const Duration(seconds: 30));

    await tester.tap(find.text('Mood'));
    await waitFor(tester, find.text('Great'));
    await tester.tap(find.text('Great'));
    await waitFor(tester, find.text('Open my tracker'));
    await settleFor(tester, const Duration(seconds: 3)); // the queue leaves

    final storage = StorageService();
    final id = await storage.getUserId();
    final key = await storage.invisibleKey(id!);
    expect(key, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
    final base = ApiService.baseUrl;
    final opened = await http.post(Uri.parse('$base/api/auth/key'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode({'id': id, 'key': key}));
    expect(opened.statusCode, 200, reason: opened.body);
    final session = jsonDecode(opened.body) as Map<String, dynamic>;
    expect([session['userId'], session['kind'], session['email']], [id, 'invisible', null]);
    final token = session['accessToken'] as String;

    final sync = await http.get(Uri.parse('$base/api/sync?since=0'), headers: {'Authorization': 'Bearer $token'});
    final copy = jsonDecode(sync.body) as Map<String, dynamic>;
    final pages = (copy['pages'] as List).cast<Map<String, dynamic>>();
    expect(pages.map((p) => p['title']), ['Mood'], reason: 'the tracker made on the phone reached the server');
    final days = (copy['cells'] as Map)[pages.single['id']] as List;
    final today = DateTime.now();
    expect(days.map((c) => (c as List).sublist(0, 4)), [[today.year, today.month, today.day, '#FFEC99']]);

    await tester.tap(find.text('Open my tracker'));
    await settleFor(tester, const Duration(seconds: 2));
    expect(find.text('Mood'), findsWidgets, reason: 'the tracker opens');

    await http.delete(Uri.parse('$base/api/auth/account'), headers: {'Authorization': 'Bearer $token'});
  });
}

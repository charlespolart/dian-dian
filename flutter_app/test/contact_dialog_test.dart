import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/providers/language_provider.dart';
import 'package:dian_dian/services/api_service.dart';
import 'package:dian_dian/widgets/contact_dialog.dart';

import 'helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late List<http.Request> requests;
  late int status;

  Widget host({String? email = 'me@example.com', String? userId = 'u1'}) {
    requests = [];
    status = 200;
    final client = MockClient((req) async {
      requests.add(req);
      return http.Response(status == 200 ? '{"ok":true}' : '{"error":"x"}', status,
          headers: const {'content-type': 'application/json; charset=utf-8'});
    });
    final api = ApiService.custom(client: client, tokens: FakeTokens());
    return ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => ContactDialog.show(
              context,
              email: email,
              userId: userId,
              version: Future.value('1.4.0'),
              api: api,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('sends the reason, the message, the account email and a trailer with user id and version', (tester) async {
    await tester.pumpWidget(host());
    await open(tester);
    expect(find.text('An idea, a bug, a question?'), findsOneWidget);
    await tester.tap(find.text('Bug'));
    await tester.enterText(find.byKey(const Key('contact.message')), 'The grid is empty on Tuesdays');
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    final req = requests.single;
    expect(req.method, 'POST');
    expect(req.url.path, '/api/contact');
    final body = jsonDecode(req.body) as Map<String, dynamic>;
    expect(body['name'], 'App · Bug');
    expect(body['email'], 'me@example.com');
    final message = body['message'] as String;
    expect(message, startsWith('[Bug] The grid is empty on Tuesdays'));
    expect(message, contains('user: u1'));
    expect(message, contains('app: 1.4.0'));
    expect(message, contains('lang: en'));
    expect(find.text("Thanks, it's sent. We reply by email."), findsOneWidget);
  });

  testWidgets('the reply email is prefilled but editable; Idea is the default reason', (tester) async {
    await tester.pumpWidget(host());
    await open(tester);
    expect(tester.widget<TextField>(find.byKey(const Key('contact.email'))).controller!.text, 'me@example.com');
    await tester.enterText(find.byKey(const Key('contact.email')), 'other@example.com');
    await tester.enterText(find.byKey(const Key('contact.message')), 'Dark mode please');
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
    expect(body['email'], 'other@example.com');
    expect(body['name'], 'App · Idea');
    expect(body['message'], startsWith('[Idea] Dark mode please'));
  });

  testWidgets('nothing is sent while the message is blank or the email is invalid', (tester) async {
    await tester.pumpWidget(host(email: null));
    await open(tester);
    await tester.tap(find.text('Send'));
    await tester.pump();
    expect(requests, isEmpty);
    await tester.enterText(find.byKey(const Key('contact.message')), 'hello');
    await tester.enterText(find.byKey(const Key('contact.email')), 'not-an-email');
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pump();
    expect(requests, isEmpty);
    expect(find.text('Invalid email address'), findsOneWidget);
  });

  testWidgets('a failed send shows the error and keeps the message', (tester) async {
    await tester.pumpWidget(host());
    await open(tester);
    status = 500;
    await tester.enterText(find.byKey(const Key('contact.message')), 'keep me');
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(find.text('Could not send, try again'), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(const Key('contact.message'))).controller!.text, 'keep me');
    expect(find.text("Thanks, it's sent. We reply by email."), findsNothing);
  });
}

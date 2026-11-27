import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/data/network_gate.dart';
import 'package:dian_dian/models/cell_model.dart';
import 'package:dian_dian/models/page_model.dart';
import 'package:dian_dian/models/year_cells.dart';
import 'package:dian_dian/providers/auth_provider.dart';
import 'package:dian_dian/providers/cells_provider.dart';
import 'package:dian_dian/providers/language_provider.dart';
import 'package:dian_dian/providers/pages_provider.dart';
import 'package:dian_dian/providers/premium_provider.dart';
import 'package:dian_dian/services/api_service.dart';
import 'package:dian_dian/services/audio_service.dart';
import 'package:dian_dian/widgets/account_section.dart';

import 'auth_fakes.dart';
import 'helpers.dart';
import 'sync_fakes.dart';

const _invisibleKey = 'k0k0k0k0k0k0k0k0k0k0k0k0k0k0k0k0k0k0k0k0k0k';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late AuthProvider auth;
  late List<http.Request> sent;
  late int logouts;

  /// The account section of the settings, for an [invisible] or an attached
  /// account, with two trackers and three days coloured. [delete]: how the
  /// server answers the deletion.
  Future<void> pump(WidgetTester tester, {required bool invisible, http.Response Function()? delete}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    ignoreOverflowUnderTestFont(tester);
    sent = [];
    logouts = 0;
    final storage = FakeStorage()..values['user'] = 'u1';
    if (invisible) {
      storage.values['key:u1'] = _invisibleKey;
      storage.values['created:u1'] = 'yes';
    } else {
      storage.values['refresh'] = 'r1';
    }
    final profile = jsonEncode({
      'accessToken': 'a1', 'refreshToken': 'r2', 'userId': 'u1',
      'email': invisible ? null : 'a@b.fr', 'kind': invisible ? 'invisible' : 'attached', 'methods': invisible ? [] : ['email', 'password'],
    });
    auth = AuthProvider.custom(
      api: ApiService.custom(
        client: MockClient((req) async {
          sent.add(req);
          return switch (req.url.path) {
            '/api/auth/refresh' || '/api/auth/key' => http.Response(profile, 200),
            '/api/auth/account' => delete?.call() ?? http.Response('{"ok":true}', 200),
            '/api/auth/sessions/close-others' => http.Response('{"closed":2}', 200),
            _ => http.Response('{}', 404),
          };
        }),
        tokens: storage,
        keys: storage,
      ),
      ws: FakeWs(),
      storage: storage,
    );
    final pages = PagesProvider(audio: AudioService.silent())
      ..applyPages([PageModel.fromJson(pageJson('p1', title: 'Sport')), PageModel.fromJson(pageJson('p2', title: 'Mood'))]);
    CellModel cell(String page, int day) => CellModel(pageId: page, year: 2026, month: 1, day: day, color: '#AAAAAA', updatedAt: '');
    final cells = CellsProvider(audio: AudioService.silent())
      ..applyCopy({
        'p1': {2025: YearCells.fromList('p1', 2025, [cell('p1', 1)]), 2026: YearCells.fromList('p1', 2026, [cell('p1', 2)])},
        'p2': {2026: YearCells.fromList('p2', 2026, [cell('p2', 3)])},
      });
    final lang = LanguageProvider();
    await lang.setLang(Language.fr);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: lang),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: pages),
        ChangeNotifierProvider.value(value: cells),
        ChangeNotifierProvider(create: (_) => PremiumProvider()),
      ],
      child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: AccountSection(onLogout: () async => logouts++)))),
    ));
    await tester.pumpAndSettle();
    expect(auth.isAuthenticated, isTrue);
  }

  const sentence = 'Sans compte, vos trackers peuvent ne pas vous suivre sur un autre téléphone. "Mes données" dit ce qu\'il en est.';

  testWidgets('an invisible account: the sentence of case 10, no sign-out, « Supprimer mes données », « Restaurer les achats »', (tester) async {
    await pump(tester, invisible: true);
    expect(find.text(sentence), findsOneWidget);
    expect(find.text('Se déconnecter'), findsNothing);
    expect(find.text('Déconnecter mes autres appareils'), findsNothing);
    expect(find.text('Supprimer mes données'), findsOneWidget);
    expect(find.text('Restaurer les achats'), findsOneWidget);
  });

  testWidgets('an attached account: its address, sign-out, « Déconnecter mes autres appareils », « Supprimer mon compte et mes données »', (tester) async {
    await pump(tester, invisible: false);
    expect(find.text('a@b.fr'), findsOneWidget);
    expect(find.text(sentence), findsNothing);
    expect(find.text('Se déconnecter'), findsOneWidget);
    expect(find.text('Déconnecter mes autres appareils'), findsOneWidget);
    expect(find.text('Supprimer mon compte et mes données'), findsOneWidget);
    expect(find.text('Restaurer les achats'), findsOneWidget);
    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();
    expect(logouts, 1);
  });

  for (final invisible in [true, false]) {
    testWidgets('the confirmation says what goes, with its numbers, and that it goes everywhere (case 65, ${invisible ? 'invisible' : 'attached'})', (tester) async {
      await pump(tester, invisible: invisible);
      await tester.tap(find.text(invisible ? 'Supprimer mes données' : 'Supprimer mon compte et mes données'));
      await tester.pumpAndSettle();
      expect(
        find.text('${invisible ? 'Vos' : 'Votre compte, vos'} 2 trackers et leurs 3 points seront effacés du serveur, de cet appareil, et de tout autre appareil ou sauvegarde qui les contient. Pour vider seulement cet appareil, désinstallez l\'app.'),
        findsOneWidget,
      );
    });
  }

  Future<void> confirmDeletion(WidgetTester tester, {required bool invisible}) async {
    await tester.tap(find.text(invisible ? 'Supprimer mes données' : 'Supprimer mon compte et mes données'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), invisible ? 'DELETE' : 'a@b.fr');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer').last);
    await tester.pumpAndSettle();
  }

  testWidgets('no answer from the server: « Suppression impossible pour l\'instant, réessayez. », and nothing changes (case 66)', (tester) async {
    await pump(tester, invisible: true, delete: () => http.Response('{"error":"Server error"}', 500));
    await confirmDeletion(tester, invisible: true);
    expect(find.text('Suppression impossible pour l\'instant, réessayez.'), findsOneWidget);
    expect(auth.isAuthenticated, isTrue);
  });

  testWidgets('the deletion is done: the session ends as asked, the copy goes, the data said deleted', (tester) async {
    await pump(tester, invisible: false);
    await confirmDeletion(tester, invisible: false);
    expect(sent.where((r) => r.url.path == '/api/auth/account').single.method, 'DELETE');
    expect(auth.isAuthenticated, isFalse);
    expect(auth.sessionEnded, SessionEnd.deletedHere);
    expect(SessionEnd.deletedHere.keepsCopy, isFalse);
  });

  testWidgets('a retried deletion whose first answer was lost: told deleted, not « deleted on another device » (case 66)', (tester) async {
    await pump(tester, invisible: true, delete: () => http.Response('{"error":"Session ended","code":"account_deleted"}', 401));
    await confirmDeletion(tester, invisible: true);
    expect(auth.isAuthenticated, isFalse);
    expect(auth.sessionEnded, SessionEnd.deletedHere);
  });

  testWidgets('offline, the deletion is not begun (H6)', (tester) async {
    await pump(tester, invisible: true);
    NetworkGate.deviceOffline = () async => true;
    await tester.tap(find.text('Supprimer mes données'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(sent.where((r) => r.url.path == '/api/auth/account'), isEmpty);
  });

  testWidgets('« Déconnecter mes autres appareils » asks first, then closes the others and says so (case 52)', (tester) async {
    await pump(tester, invisible: false);
    await tester.tap(find.text('Déconnecter mes autres appareils'));
    await tester.pumpAndSettle();
    expect(sent.where((r) => r.url.path == '/api/auth/sessions/close-others'), isEmpty, reason: 'a confirmation first');
    await tester.tap(find.text('Déconnecter'));
    await tester.pumpAndSettle();
    expect(sent.where((r) => r.url.path == '/api/auth/sessions/close-others'), hasLength(1));
    expect(find.text('Vos autres appareils ont été déconnectés.'), findsOneWidget);
    expect(auth.isAuthenticated, isTrue);
  });
}

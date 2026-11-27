import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/providers/language_provider.dart';
import 'package:dian_dian/services/api_service.dart';
import 'package:dian_dian/widgets/session_dialogs.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<Object?> run(WidgetTester tester, Future<Object?> Function(BuildContext context) open) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final lang = LanguageProvider();
    await lang.setLang(Language.fr);
    Object? result;
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: lang,
      child: MaterialApp(
        home: Builder(builder: (context) => TextButton(onPressed: () async => result = await open(context), child: const Text('go'))),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    return result;
  }

  group('H10, signing out with changes waiting', () {
    testWidgets('online: the queue leaves first, then the sign-out goes ahead without a question', (tester) async {
      var flushed = false;
      await run(tester, (context) => SessionDialogs.confirmSignOut(context, flush: () async => flushed = true, pending: () => 0));
      expect(flushed, isTrue);
      expect(find.text('Rester connecté'), findsNothing);
    });

    testWidgets('offline with 3 waiting: the question of the spec; « Rester connecté » keeps the session', (tester) async {
      Future<bool> attempt(String button) async {
        bool? go;
        await run(tester, (context) async => go = await SessionDialogs.confirmSignOut(context, flush: () async => false, pending: () => 3));
        expect(find.text('3 modifications ne sont pas envoyées'), findsOneWidget);
        expect(find.text('Vous êtes hors ligne. Si vous vous déconnectez maintenant, elles seront perdues.'), findsOneWidget);
        await tester.tap(find.text(button));
        await tester.pumpAndSettle();
        return go!;
      }

      expect(await attempt('Rester connecté'), isFalse);
      expect(await attempt('Me déconnecter quand même'), isTrue);
    });

    testWidgets('offline with nothing waiting: no question', (tester) async {
      final go = await run(tester, (context) => SessionDialogs.confirmSignOut(context, flush: () async => false, pending: () => 0));
      expect(go, isTrue);
      expect(find.text('Rester connecté'), findsNothing);
    });
  });

  testWidgets('H24: the account was deleted on another device', (tester) async {
    await run(tester, (context) => SessionDialogs.sessionEnded(context, SessionEnd.accountDeleted, pending: 2));
    expect(find.text('Ce compte a été supprimé'), findsOneWidget);
    expect(find.text("Il a été supprimé depuis un autre appareil. Les 2 modifications faites hors ligne n'ont pas été envoyées."), findsOneWidget);
  });

  testWidgets('H25: the session was closed; the changes wait for the reconnection', (tester) async {
    await run(tester, (context) => SessionDialogs.sessionEnded(context, SessionEnd.reconnect, pending: 4));
    expect(find.text('Reconnectez-vous : vos 4 modifications en attente seront envoyées.'), findsOneWidget);
    await tester.tap(find.text('Me reconnecter'));
    await tester.pumpAndSettle();
    expect(find.text('Me reconnecter'), findsNothing);
  });

  test('a session closed with nothing waiting says nothing; a deleted account always does', () {
    expect(SessionDialogs.tellsSessionEnd(SessionEnd.reconnect, pending: 0), isFalse);
    expect(SessionDialogs.tellsSessionEnd(SessionEnd.reconnect, pending: 1), isTrue);
    expect(SessionDialogs.tellsSessionEnd(SessionEnd.accountDeleted, pending: 0), isTrue);
  });

  testWidgets('H25: signing in to another account warns that the waiting changes will be lost, and lets go back', (tester) async {
    bool? go;
    await run(tester, (context) async => go = await SessionDialogs.confirmOtherAccount(context, pending: 4));
    expect(find.text('4 modifications en attente seront perdues'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(go, isFalse);
    await run(tester, (context) async => go = await SessionDialogs.confirmOtherAccount(context, pending: 4));
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(go, isTrue);
  });

  test('the texts exist in the four languages', () {
    for (final key in SessionDialogs.textKeys) {
      for (final lang in Language.values) {
        expect(LanguageProvider.translationFor(lang, key), isNotNull, reason: '$key in ${lang.name}');
      }
    }
  });
}

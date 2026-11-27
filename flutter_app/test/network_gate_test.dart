import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/data/network_gate.dart';
import 'package:dian_dian/providers/language_provider.dart';
import 'package:dian_dian/widgets/connection_needed_dialog.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NetworkGate.deviceOffline = () async => false;
    NetworkGate.serverReachable = null;
  });

  test('a phone without a network is offline, without asking the server', () async {
    var asked = false;
    NetworkGate.deviceOffline = () async => true;
    NetworkGate.serverReachable = () async => asked = true;
    expect(await NetworkGate.isOffline(), isTrue);
    expect(asked, isFalse);
  });

  test('with a network, the session decides: a server that does not answer is offline too (H16)', () async {
    NetworkGate.serverReachable = () async => false;
    expect(await NetworkGate.isOffline(), isTrue);
    NetworkGate.serverReachable = () async => true;
    expect(await NetworkGate.isOffline(), isFalse);
    NetworkGate.serverReachable = null;
    expect(await NetworkGate.isOffline(), isFalse, reason: 'no session (login screen): the gesture tries');
  });

  Future<bool?> tap(WidgetTester tester) async {
    final lang = LanguageProvider();
    await lang.setLang(Language.fr);
    bool? blocked;
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: lang,
      child: MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => blocked = await ConnectionNeededDialog.blockIfOffline(context),
            child: const Text('buy'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('buy'));
    await tester.pumpAndSettle();
    return blocked;
  }

  testWidgets('H6: offline, a gesture that needs the server is not started, and the app says why', (tester) async {
    NetworkGate.deviceOffline = () async => true;
    await tap(tester);
    expect(find.text('Il faut une connexion'), findsOneWidget);
    expect(
      find.text("Acheter ou restaurer Premium, créer un compte, s'y connecter et supprimer ses données demandent du réseau. Vos trackers restent utilisables."),
      findsOneWidget,
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });

  testWidgets('online, the gesture goes ahead without a word', (tester) async {
    expect(await tap(tester), isFalse);
    expect(find.text('Il faut une connexion'), findsNothing);
  });

  test('the texts exist in the four languages', () {
    for (final key in ['net.required.title', 'net.required.body', 'net.purchaseLater']) {
      for (final lang in Language.values) {
        expect(LanguageProvider.translationFor(lang, key), isNotNull, reason: '$key in ${lang.name}');
      }
    }
  });
}

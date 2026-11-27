import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/data/network_gate.dart';
import 'package:dian_dian/providers/language_provider.dart';
import 'package:dian_dian/providers/premium_provider.dart';
import 'package:dian_dian/widgets/premium_gate_dialog.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final lang = LanguageProvider();
    await lang.setLang(Language.fr);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: lang),
        ChangeNotifierProvider(create: (_) => PremiumProvider()),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => PremiumGateDialog.show(context, feature: lang.t('premium.trackerLimit')),
            child: const Text('limit'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('limit'));
    await tester.pumpAndSettle();
  }

  testWidgets('H7: offline, the limit wall adds that buying will be possible once back online', (tester) async {
    NetworkGate.deviceOffline = () async => true;
    await open(tester);
    expect(find.text('Les comptes gratuits sont limités à 3 trackers'), findsOneWidget);
    expect(find.text("L'achat sera possible au retour du réseau."), findsOneWidget);
  });

  testWidgets('online, the wall is as before', (tester) async {
    NetworkGate.deviceOffline = () async => false;
    await open(tester);
    expect(find.text("L'achat sera possible au retour du réseau."), findsNothing);
  });

  testWidgets('H6: offline, Restore is not started', (tester) async {
    NetworkGate.deviceOffline = () async => true;
    await open(tester);
    await tester.tap(find.text('Restaurer un achat'));
    await tester.pumpAndSettle();
    expect(find.text('Il faut une connexion'), findsOneWidget);
  });
}

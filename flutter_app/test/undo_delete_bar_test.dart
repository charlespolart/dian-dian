import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/providers/language_provider.dart';
import 'package:dian_dian/widgets/undo_delete_bar.dart';

void main() {
  // The real tree: the bar is a sibling of the stage in the shell's Stack,
  // under MaterialApp and the app's providers, under no Scaffold.
  Widget host(LanguageProvider lang) => ChangeNotifierProvider.value(
        value: lang,
        child: MaterialApp(
          home: Stack(children: [
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: UndoDeleteBar(pageName: 'Mood', onUndo: () {}, duration: const Duration(seconds: 8)),
            ),
          ]),
        ),
      );

  testWidgets('the undo bar never inherits the MaterialApp fallback style (the yellow double underline)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(host(LanguageProvider()));
    await tester.pump();
    final riches = tester.widgetList<RichText>(find.descendant(of: find.byType(UndoDeleteBar), matching: find.byType(RichText)));
    expect(riches.length, 2, reason: 'the label and the Undo button');
    for (final rich in riches) {
      final style = rich.text.style!;
      expect(style.decoration, TextDecoration.none, reason: rich.text.toPlainText());
      expect(style.debugLabel ?? '', isNot(contains('fallback')));
    }
  });

  testWidgets('the label and the button come from the translations, in the app\'s language', (tester) async {
    SharedPreferences.setMockInitialValues({'app_language': 'fr'});
    await tester.pumpWidget(host(LanguageProvider()));
    await tester.pump();
    expect(find.text('« Mood » supprimé'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
    expect(find.text('Undo'), findsNothing);
  });

  test('every language has the bar\'s two keys', () {
    for (final lang in Language.values) {
      expect(LanguageProvider.translationFor(lang, 'tracker.deleted'), contains('{name}'), reason: lang.name);
      expect(LanguageProvider.translationFor(lang, 'common.undo'), isNotNull, reason: lang.name);
    }
  });
}

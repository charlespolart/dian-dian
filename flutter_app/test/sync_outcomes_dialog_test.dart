import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/data/mutation.dart';
import 'package:dian_dian/providers/language_provider.dart';
import 'package:dian_dian/widgets/sync_outcomes_dialog.dart';

SyncOutcome day(int d, String status, {String color = '#8CE99A', String? comment, Object? current, String title = 'Humeur', String? reason}) => SyncOutcome(
      kind: 'cell.set',
      data: {'pageId': 'p', 'year': DateTime.now().year, 'month': 3, 'day': d, 'color': color, 'comment': comment},
      status: status,
      current: current,
      reason: reason,
      pageTitle: title,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> show(WidgetTester tester, List<SyncOutcome> outcomes, {Language language = Language.fr}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final lang = LanguageProvider();
    await lang.setLang(language);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: lang,
      child: MaterialApp(
        home: Builder(
          builder: (context) => TextButton(onPressed: () => SyncOutcomesDialog.show(context, outcomes), child: const Text('open')),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('H17: the day kept is the other device\'s, and the message gives mine back', (tester) async {
    await show(tester, [day(12, 'changed', comment: 'bonne journée', current: {'color': '#FFEC99', 'comment': null})]);
    expect(find.text("1 modification faite hors ligne n'a pas été gardée"), findsOneWidget);
    expect(find.text("Le 12 mars de « Humeur » avait été modifié depuis un autre appareil. C'est cette version qui est gardée."), findsOneWidget);
    expect(find.text('La vôtre :'), findsOneWidget);
    expect(find.text('« bonne journée »'), findsOneWidget);
    expect(find.byKey(const Key('sync.yourColor')), findsOneWidget, reason: 'my colour, drawn');
  });

  testWidgets('H20: one line per tracker deleted elsewhere, counting its days', (tester) async {
    await show(tester, [for (final d in [1, 2, 3]) day(d, 'deleted', title: 'Sport')]);
    expect(find.text("3 modifications faites hors ligne n'ont pas été gardées"), findsOneWidget);
    expect(find.text('« Sport » a été supprimé depuis un autre appareil. Les 3 jours coloriés hors ligne n\'ont pas été gardés.'), findsOneWidget);
  });

  testWidgets('H21 and H22: a deletion not applied, a rename kept from elsewhere', (tester) async {
    await show(tester, [
      const SyncOutcome(kind: 'page.delete', data: {'id': 'p'}, status: 'changed', pageTitle: 'Sport'),
      const SyncOutcome(kind: 'page.update', data: {'id': 'q', 'title': 'Forme'}, status: 'changed', current: {'title': 'Santé'}, pageTitle: 'Forme'),
    ]);
    expect(find.text("2 modifications faites hors ligne n'ont pas été gardées"), findsOneWidget);
    expect(find.text("« Sport » n'a pas été supprimé : il a été modifié depuis un autre appareil pendant que vous étiez hors ligne. Supprimez-le de nouveau si vous le voulez toujours."), findsOneWidget);
    expect(find.text("Ce tracker s'appelle « Santé » : il a été renommé depuis un autre appareil."), findsOneWidget);
  });

  testWidgets('H12: a refusal says the element and why', (tester) async {
    await show(tester, [
      const SyncOutcome(kind: 'legend.create', data: {'id': 'l', 'pageId': 'p', 'color': '#FFEC99', 'label': 'Très bien'}, status: 'rejected', reason: 'legend_limit', pageTitle: 'Humeur'),
    ]);
    expect(find.text("1 modification n'a pas pu être enregistrée"), findsOneWidget);
    expect(find.text("La légende « Très bien » de « Humeur » n'a pas été créée : ce tracker a déjà 12 légendes."), findsOneWidget);
  });

  testWidgets('both kinds in one sync: one message, two counts', (tester) async {
    await show(tester, [
      day(12, 'changed'),
      day(13, 'rejected', reason: 'locked'),
    ]);
    expect(find.text("1 modification faite hors ligne n'a pas été gardée"), findsOneWidget);
    expect(find.text("1 modification n'a pas pu être enregistrée"), findsOneWidget);
    expect(find.text("Le 13 mars de « Humeur » n'a pas été enregistré : ce tracker est verrouillé."), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text("1 modification n'a pas pu être enregistrée"), findsNothing);
  });

  testWidgets('a legend, the orders and the settings changed elsewhere are named too', (tester) async {
    await show(tester, [
      const SyncOutcome(kind: 'legend.update', data: {'id': 'l', 'color': '#000000'}, status: 'changed', current: {'label': 'Bien', 'color': '#AAAAAA'}, pageTitle: 'Humeur', legendLabel: 'Bon'),
      const SyncOutcome(kind: 'pages.reorder', data: {'ids': ['a']}, status: 'changed'),
      const SyncOutcome(kind: 'setting.set', data: {'key': 'theme', 'value': 'ocean'}, status: 'changed', current: 'sakura'),
    ], language: Language.en);
    expect(find.text('3 changes made offline were not kept'), findsOneWidget);
    expect(find.text('The legend "Bien" of "Humeur" had been changed on another device. That version is kept.'), findsOneWidget);
    expect(find.text('The order of the trackers had been changed on another device. That order is kept.'), findsOneWidget);
    expect(find.text('The theme had been changed on another device. That theme is kept.'), findsOneWidget);
  });

  testWidgets('a refused tracker is one line; the days coloured in it are counted, not told apart (minor 2)', (tester) async {
    await show(tester, [
      const SyncOutcome(kind: 'page.create', data: {'id': 'p', 'title': 'Cinq'}, status: 'rejected', reason: 'tracker_limit', pageTitle: 'Cinq'),
      day(1, 'rejected', reason: 'tracker_limit', title: 'Cinq'),
    ]);
    expect(find.text("2 modifications n'ont pas pu être enregistrées"), findsOneWidget);
    expect(find.text("« Cinq » n'a pas été créé : les comptes gratuits sont limités à 3 trackers."), findsOneWidget);
    expect(find.textContaining('Une modification de « Cinq »'), findsNothing);
  });

  test('every message text exists in the four languages', () {
    for (final key in SyncOutcomesDialog.textKeys) {
      for (final lang in Language.values) {
        expect(LanguageProvider.translationFor(lang, key), isNotNull, reason: '$key in ${lang.name}');
      }
    }
  });
}

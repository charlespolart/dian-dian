import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/data/sync_engine.dart';
import 'package:dian_dian/providers/language_provider.dart';
import 'package:dian_dian/widgets/sync_banner.dart';

class FakeStatus extends ChangeNotifier implements SyncStatus {
  @override
  bool isOffline = false;
  @override
  int pendingCount = 0;
  @override
  int returns = 0;
  @override
  int returnedSent = 0;

  void offline(int pending) {
    isOffline = true;
    pendingCount = pending;
    notifyListeners();
  }

  void back(int sent) {
    isOffline = false;
    pendingCount = 0;
    returns++;
    returnedSent = sent;
    notifyListeners();
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late FakeStatus status;
  late double childTopPadding;

  Future<void> pump(WidgetTester tester, {double statusBar = 47}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    tester.view.padding = FakeViewPadding(top: statusBar * 3);
    tester.view.viewPadding = FakeViewPadding(top: statusBar * 3);
    addTearDown(tester.view.reset);
    final lang = LanguageProvider();
    await lang.setLang(Language.fr);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: lang,
      child: MaterialApp(
        home: Stack(
          children: [
            SyncBannerFrame(
              status: status,
              child: Builder(builder: (context) {
                childTopPadding = MediaQuery.paddingOf(context).top;
                return const SizedBox.expand();
              }),
            ),
            SyncToast(status: status, bottom: 60),
          ],
        ),
      ),
    ));
    await tester.pump();
  }

  setUp(() => status = FakeStatus());

  testWidgets('nothing shows when all is well', (tester) async {
    await pump(tester);
    expect(find.textContaining('Hors ligne'), findsNothing);
    expect(find.textContaining('Synchronisé'), findsNothing);
    expect(childTopPadding, 47, reason: 'the screens keep the status bar');
  });

  testWidgets('offline without a queue: everything is saved on this phone, under the status bar', (tester) async {
    await pump(tester);
    status.offline(0);
    await tester.pump();
    final strip = find.text('Hors ligne · tout est enregistré sur ce téléphone');
    expect(strip, findsOneWidget);
    expect(tester.getTopLeft(strip).dy, greaterThanOrEqualTo(47), reason: 'not under the status bar');
    expect(childTopPadding, 0, reason: 'the screens lay out below the strip, which takes the status bar');
  });

  testWidgets('offline with changes waiting: how many', (tester) async {
    await pump(tester);
    status.offline(3);
    await tester.pump();
    expect(find.text('Hors ligne · 3 modifications à envoyer'), findsOneWidget);
    status.offline(1);
    await tester.pump();
    expect(find.text('Hors ligne · 1 modification à envoyer'), findsOneWidget);
  });

  testWidgets('back: « Synchronisé · 31 modifications envoyées » above the bottom bars, gone by itself', (tester) async {
    await pump(tester);
    status.offline(31);
    await tester.pump();
    status.back(31);
    await tester.pump();
    final toast = find.text('Synchronisé · 31 modifications envoyées');
    expect(toast, findsOneWidget);
    expect(find.textContaining('Hors ligne'), findsNothing);
    final box = find.ancestor(of: toast, matching: find.byKey(const Key('sync.toast')));
    expect(tester.getBottomLeft(box).dy, closeTo(844 - 60, 0.5));
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(toast, findsNothing);
  });

  testWidgets('back with nothing sent: « Synchronisé »', (tester) async {
    await pump(tester);
    status.back(0);
    await tester.pump();
    expect(find.text('Synchronisé'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  test('every banner text exists in the four languages', () {
    for (final key in SyncBannerFrame.textKeys) {
      for (final lang in Language.values) {
        expect(LanguageProvider.translationFor(lang, key), isNotNull, reason: '$key in ${lang.name}');
      }
    }
  });
}

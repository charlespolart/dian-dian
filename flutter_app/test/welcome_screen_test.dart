import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/data/network_gate.dart';
import 'package:dian_dian/providers/auth_provider.dart';
import 'package:dian_dian/providers/language_provider.dart';
import 'package:dian_dian/screens/welcome_screen.dart';
import 'package:dian_dian/services/api_service.dart';
import 'package:dian_dian/widgets/oauth_buttons.dart';

import 'auth_fakes.dart';
import 'sync_fakes.dart';

/// Apple's and Google's windows, closed by the person (case 4) or failing.
class FakeWindows implements IdentityWindows {
  int opened = 0;
  Object? failure;
  @override
  Future<String?> apple() async {
    opened++;
    if (failure != null) throw failure!;
    return null;
  }

  @override
  Future<String?> google() => apple();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // The buttons' font, in place of the test font whose every glyph is a
  // square: a proportional one from the app's assets, present on any
  // machine, whose labels measure as in the iPhone's system font (the
  // longest, 244 points against 245 at full size).
  setUpAll(() async {
    final loader = FontLoader('.SF Pro Text')
      ..addFont(Future.value(ByteData.view(Uint8List.fromList(File('assets/fonts/DotGothic16-Regular.ttf').readAsBytesSync()).buffer)));
    await loader.load();
  });

  late AuthProvider auth;
  late int emails;

  Future<void> pump(WidgetTester tester, {IdentityWindows windows = const IdentityWindows()}) async {
    emails = 0;
    final storage = FakeStorage();
    auth = AuthProvider.custom(
      api: ApiService.custom(client: MockClient((req) async => throw http.ClientException('no network')), tokens: storage, keys: storage),
      ws: FakeWs(),
      storage: storage,
    );
    final lang = LanguageProvider();
    await lang.setLang(Language.fr);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: lang),
        ChangeNotifierProvider.value(value: auth),
      ],
      child: MaterialApp(home: WelcomeScreen(onEmail: () => emails++, windows: windows)),
    ));
    await tester.pumpAndSettle();
  }

  const keys = ['welcome.apple', 'welcome.google', 'welcome.email', 'welcome.noAccount'];

  testWidgets('four buttons of the same size, and the sentence below (iPhone)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await pump(tester);
      final sizes = [for (final k in keys) tester.getSize(find.byKey(ValueKey(k)))];
      expect(sizes.toSet(), hasLength(1), reason: '$sizes');
      for (final label in ['Continuer avec Apple', 'Continuer avec Google', 'Continuer avec un e-mail', 'Continuer sans compte']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text("Avec un compte, vous retrouvez vos points sur un autre téléphone. Sans compte, ils restent liés à cette installation de l'app."), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  for (final language in Language.values) {
    testWidgets('a narrow phone (${language.name}): every label shows whole, all four in one size, not small', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      tester.view.physicalSize = const Size(360 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      try {
        await pump(tester);
        final lang = tester.element(find.byType(WelcomeScreen)).read<LanguageProvider>();
        await lang.setLang(language);
        await tester.pumpAndSettle();
        final sizes = <double?>{};
        for (final k in keys) {
          final label = find.descendant(of: find.byKey(ValueKey(k)), matching: find.text(lang.t(k)));
          final paragraph = tester.renderObject<RenderParagraph>(label);
          expect(paragraph.didExceedMaxLines, isFalse, reason: '$k is cut');
          sizes.add(paragraph.text.style?.fontSize);
        }
        expect(sizes, hasLength(1), reason: 'the same weight for the four: $sizes');
        expect(sizes.single, greaterThanOrEqualTo(16), reason: '« Continuer sans compte » never small (an anti-goal of the spec)');
      } finally {
        debugDefaultTargetPlatformOverride = null;
        tester.view.reset();
      }
    });
  }

  testWidgets('Apple only on the iPhone', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await pump(tester);
      expect(find.byKey(const ValueKey('welcome.apple')), findsNothing);
      expect(find.byKey(const ValueKey('welcome.google')), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('« Continuer sans compte » enters at once, offline too (cases 1 and 5)', (tester) async {
    NetworkGate.deviceOffline = () async => true;
    await pump(tester);
    await tester.tap(find.text('Continuer sans compte'));
    await tester.pumpAndSettle();
    expect(auth.isAuthenticated, isTrue);
    expect(auth.isNewAccount, isTrue);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('offline, Apple, Google and e-mail say a connection is needed, and that one can start without an account (case 5)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      NetworkGate.deviceOffline = () async => true;
      final windows = FakeWindows();
      await pump(tester, windows: windows);
      for (final k in ['welcome.apple', 'welcome.google', 'welcome.email']) {
        await tester.tap(find.byKey(ValueKey(k)));
        await tester.pumpAndSettle();
        expect(find.text('Il faut une connexion pour se connecter à un compte. Vous pouvez commencer sans compte et le créer plus tard.'), findsOneWidget, reason: k);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
      }
      expect(windows.opened, 0);
      expect(emails, 0);
      expect(auth.isAuthenticated, isFalse);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('online, « Continuer avec un e-mail » opens the e-mail screen', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Continuer avec un e-mail'));
    await tester.pumpAndSettle();
    expect(emails, 1);
  });

  testWidgets('an Apple or Google window closed by the person: back to the welcome screen, no message (case 4)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      final windows = FakeWindows();
      await pump(tester, windows: windows);
      for (final k in ['welcome.apple', 'welcome.google']) {
        await tester.tap(find.byKey(ValueKey(k)));
        await tester.pumpAndSettle();
      }
      expect(windows.opened, 2);
      expect(find.byType(Dialog), findsNothing);
      expect(find.byKey(const ValueKey('welcome.error')), findsNothing);
      expect(auth.isAuthenticated, isFalse);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

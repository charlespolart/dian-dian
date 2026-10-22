import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/data/whats_new.dart';
import 'package:dian_dian/providers/language_provider.dart';
import 'package:dian_dian/widgets/whats_new_dialog.dart';

void main() {
  group('shouldShowWhatsNew', () {
    test('never on a fresh install (nothing seen, no cell yet): the version is only recorded', () {
      expect(shouldShowWhatsNew(seenVersion: null, currentVersion: '1.4.0', hasNotes: true, existingUser: false), isFalse);
    });

    test('nothing seen yet but an account that already has cells: the app was updated from a version without the box', () {
      expect(shouldShowWhatsNew(seenVersion: null, currentVersion: '1.4.0', hasNotes: true, existingUser: true), isTrue);
    });

    test('once after an update that has notes', () {
      expect(shouldShowWhatsNew(seenVersion: '1.3.0', currentVersion: '1.4.0', hasNotes: true, existingUser: true), isTrue);
      expect(shouldShowWhatsNew(seenVersion: '1.4.0', currentVersion: '1.4.0', hasNotes: true, existingUser: true), isFalse);
    });

    test('not for a version without notes (a quiet patch)', () {
      expect(shouldShowWhatsNew(seenVersion: '1.4.0', currentVersion: '1.4.1', hasNotes: false, existingUser: true), isFalse);
      expect(shouldShowWhatsNew(seenVersion: null, currentVersion: '1.4.1', hasNotes: false, existingUser: true), isFalse);
    });
  });

  group('whatsNewFor', () {
    test('1.4.0 has three to six bullets in every language', () {
      for (final lang in Language.values) {
        final bullets = whatsNewFor('1.4.0', lang);
        expect(bullets, isNotNull, reason: '$lang');
        expect(bullets!.length, inInclusiveRange(3, 6), reason: '$lang');
        for (final b in bullets) {
          expect(b.trim(), isNotEmpty);
        }
      }
    });

    test('an unknown version has no notes', () {
      expect(whatsNewFor('0.0.1', Language.en), isNull);
    });

    test('French bullets say vous, never tu', () {
      final tu = RegExp(r"\b(tu|ton|ta|tes|toi)\b", caseSensitive: false);
      for (final b in whatsNewFor('1.4.0', Language.fr)!) {
        expect(tu.hasMatch(b), isFalse, reason: b);
      }
    });
  });

  testWidgets('the dialog shows the version, the bullets, and closes on OK', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => WhatsNewDialog.show(context, version: '1.4.0', bullets: const ['First bullet', 'Second bullet']),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text("✨ What's new in 1.4.0"), findsOneWidget);
    expect(find.text('First bullet'), findsOneWidget);
    expect(find.text('Second bullet'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('First bullet'), findsNothing);
  });
}

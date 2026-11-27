import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/providers/language_provider.dart';
import 'package:dian_dian/widgets/connection_needed_dialog.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const expected = {
    Language.fr: 'Il faut une connexion pour finir la mise à jour de vos trackers',
    Language.en: 'A connection is needed to finish updating your trackers',
    Language.zhCN: '需要联网才能完成追踪器的更新',
    Language.zhTW: '需要連網才能完成追蹤器的更新',
  };

  for (final entry in expected.entries) {
    testWidgets('H15: the refusal says a connection is needed (${entry.key.name}), and OK closes it', (tester) async {
      final lang = LanguageProvider();
      await lang.setLang(entry.key);
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: lang,
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(onPressed: () => ConnectionNeededDialog.show(context), child: const Text('open')),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
      await tester.tap(find.text(lang.t('common.ok')));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsNothing);
    });
  }
}

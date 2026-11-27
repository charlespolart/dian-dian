import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/data/change_sink.dart';
import 'package:dian_dian/providers/language_provider.dart';
import 'package:dian_dian/providers/theme_provider.dart';
import 'package:dian_dian/theme/app_theme.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RecordingSink sink;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sink = RecordingSink();
    SettingsSink.sink = sink;
  });
  tearDown(() => SettingsSink.sink = null);

  test('a theme or a language chosen goes through the queue as setting.set', () async {
    await ThemeProvider().setTheme(AppThemeType.values.last);
    await LanguageProvider().setLang(Language.fr);
    await Future<void>.delayed(Duration.zero);
    expect(sink.log, [
      ['setting.set', {'key': 'theme', 'value': AppThemeType.values.last.name}],
      ['setting.set', {'key': 'language', 'value': 'fr'}],
    ]);
  });

  test('without a session, nothing is sent and nothing breaks', () async {
    SettingsSink.sink = null;
    await ThemeProvider().setTheme(AppThemeType.values.first);
    expect(sink.changes, isEmpty);
  });
}

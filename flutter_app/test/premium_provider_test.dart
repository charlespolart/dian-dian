import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/data/change_sink.dart';
import 'package:dian_dian/providers/premium_provider.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<PremiumProvider> provider({required bool cachedPremium}) async {
    SharedPreferences.setMockInitialValues({'is_premium': cachedPremium});
    final p = PremiumProvider();
    // Let _init read the prefs (and the SDK init fail harmlessly: no plugin).
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return p;
  }

  tearDown(() => SettingsSink.sink = null);

  test('the server saying "not premium" revokes a cached premium (lapsed subscription)', () async {
    final p = await provider(cachedPremium: true);
    expect(p.isPremium, isTrue, reason: 'cached for instant UI');
    await p.applyServerPremium(false);
    expect(p.isPremium, isFalse);
    expect((await SharedPreferences.getInstance()).getBool('is_premium'), isFalse);
  });

  test('the server saying "premium" grants it', () async {
    final p = await provider(cachedPremium: false);
    await p.applyServerPremium(true);
    expect(p.isPremium, isTrue);
    expect((await SharedPreferences.getInstance()).getBool('is_premium'), isTrue);
  });

  test('the cursor goes through the queue as one setting {id, enabled}', () async {
    final sink = RecordingSink();
    SettingsSink.sink = sink;
    final p = await provider(cachedPremium: true);
    await p.setCursorId('cat');
    await p.setCursorEnabled(true);
    await Future<void>.delayed(Duration.zero);
    expect(sink.log, [
      ['setting.set', {'key': 'cursor', 'value': {'id': 'cat', 'enabled': false}}],
      ['setting.set', {'key': 'cursor', 'value': {'id': 'cat', 'enabled': true}}],
    ]);
  });
}

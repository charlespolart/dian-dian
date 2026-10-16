import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/providers/premium_provider.dart';
import 'package:dian_dian/services/api_service.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ApiService server(int status, {bool premium = false}) => ApiService.custom(
        client: MockClient((req) async {
          expect(req.url.path, '/api/purchase/status');
          return http.Response(status == 200 ? '{"premium": $premium}' : '{"error":"x"}', status,
              headers: const {'content-type': 'application/json; charset=utf-8'});
        }),
        tokens: FakeTokens(),
      );

  Future<PremiumProvider> provider({required bool cachedPremium}) async {
    SharedPreferences.setMockInitialValues({'is_premium': cachedPremium});
    final p = PremiumProvider();
    // Let _init read the prefs (and the SDK init fail harmlessly: no plugin).
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return p;
  }

  test('the server saying "not premium" revokes a cached premium (lapsed subscription)', () async {
    final p = await provider(cachedPremium: true);
    expect(p.isPremium, isTrue, reason: 'cached for instant UI');
    await p.checkServerSubscription(api: server(200, premium: false));
    expect(p.isPremium, isFalse);
    expect((await SharedPreferences.getInstance()).getBool('is_premium'), isFalse);
  });

  test('the server saying "premium" grants it', () async {
    final p = await provider(cachedPremium: false);
    await p.checkServerSubscription(api: server(200, premium: true));
    expect(p.isPremium, isTrue);
    expect((await SharedPreferences.getInstance()).getBool('is_premium'), isTrue);
  });

  test('a server error changes nothing', () async {
    final p = await provider(cachedPremium: true);
    await p.checkServerSubscription(api: server(500));
    expect(p.isPremium, isTrue);
  });
}

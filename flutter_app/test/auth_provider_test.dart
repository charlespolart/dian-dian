import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/providers/auth_provider.dart';

void main() {
  test('a launch lands at once only on a session still held: an account id and its renewal token (review, minor 1)', () {
    expect(AuthProvider.landsAtOnce(storedUserId: 'u1', refreshToken: 'r'), isTrue);
    expect(AuthProvider.landsAtOnce(storedUserId: 'u1', refreshToken: null), isFalse,
        reason: 'a session the server closed keeps the account id for the reconnection (H25), not a session: no flash of the trackers, no message again');
    expect(AuthProvider.landsAtOnce(storedUserId: null, refreshToken: 'r'), isFalse);
  });
}

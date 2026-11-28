import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/data/first_tracker_decision.dart';

void main() {
  test('an account just born on this phone lands at once: its empty copy already says « first tracker » (review, minor 9)', () {
    expect(waitsForFirstSync(hydrated: false, snapshotActivated: false, newAccount: true), isFalse);
  });

  test('otherwise, a phone that shows nothing yet, or does not know the account active, waits for the first sync', () {
    expect(waitsForFirstSync(hydrated: false, snapshotActivated: null, newAccount: false), isTrue);
    expect(waitsForFirstSync(hydrated: true, snapshotActivated: false, newAccount: false), isTrue);
    expect(waitsForFirstSync(hydrated: true, snapshotActivated: true, newAccount: false), isFalse);
  });
}

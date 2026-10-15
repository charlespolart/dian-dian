import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/services/orientation_policy.dart';

void main() {
  test('phones (shortest side under 600 dp) are locked to portrait', () {
    expect(preferredOrientationsFor(390), [DeviceOrientation.portraitUp]);
    expect(preferredOrientationsFor(599.9), [DeviceOrientation.portraitUp]);
  });

  test('tablets keep every orientation', () {
    expect(preferredOrientationsFor(600), isNull);
    expect(preferredOrientationsFor(834), isNull);
  });
}

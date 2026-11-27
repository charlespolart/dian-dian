import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/data/network_gate.dart';

/// Every test starts with a phone that has a network and no session: the
/// real check asks a native plugin the tests do not have. A test that wants
/// the phone offline sets `NetworkGate.deviceOffline` itself.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() {
    NetworkGate.deviceOffline = () async => false;
    NetworkGate.serverReachable = null;
    NetworkGate.serverUnreachableNow = null;
  });
  await testMain();
}

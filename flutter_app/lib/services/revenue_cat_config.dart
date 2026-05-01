import 'package:flutter/foundation.dart';

/// RevenueCat configuration. Replace the test key with platform-specific keys
/// (`appl_xxx` / `goog_xxx`) before shipping to production.
class RevenueCatConfig {
  static const String _testKey = 'test_JeRyqDcJGeDeIwpbchhpZVvQmba';

  static const String _iosKey = 'appl_xIhkBrSyJHNrEAxLhqBuUMHzcts';
  // TODO: replace with `goog_xxx` once the Android app is connected in RC.
  static const String _androidKey = _testKey;

  static const String premiumEntitlement = 'premium';

  static String? apiKeyForPlatform() {
    if (kIsWeb) return null; // Not supported on web
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return _iosKey;
      case TargetPlatform.android:
        return _androidKey;
      default:
        return null;
    }
  }
}

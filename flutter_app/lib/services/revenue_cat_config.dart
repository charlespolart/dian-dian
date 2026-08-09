import 'package:flutter/foundation.dart';

/// RevenueCat configuration.
///
/// These are PUBLIC SDK keys — they are meant to ship inside the binary (see
/// `security/app-security.md`: only keys designed to be public belong in a
/// mobile build). The secret that must never appear here is the webhook secret,
/// which lives server-side.
class RevenueCatConfig {
  static const String _iosKey = 'appl_xIhkBrSyJHNrEAxLhqBuUMHzcts';
  static const String _androidKey = 'goog_BeLETkxvPFmTrsrAVBjigUXVqYw';

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

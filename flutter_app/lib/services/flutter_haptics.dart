import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'audio_service.dart';

/// [HapticSink] on Flutter's `HapticFeedback`: the Taptic Engine on iPhone
/// (impact light / medium, the pickers' selection click); on Android the
/// system's haptic constants, which follow the phone's "touch vibration"
/// setting and whose feel depends on its motor. Never throws: a device
/// without a motor, or a test without a platform, just feels nothing.
class FlutterHaptics implements HapticSink {
  @override
  Future<void> feel(Haptic haptic) async {
    try {
      switch (haptic) {
        case Haptic.light:
          await HapticFeedback.lightImpact();
        case Haptic.medium:
          await HapticFeedback.mediumImpact();
        case Haptic.selection:
          await HapticFeedback.selectionClick();
        case Haptic.none:
          break;
      }
    } catch (e) {
      debugPrint('AudioService: haptic ${haptic.name} failed: $e');
    }
  }
}

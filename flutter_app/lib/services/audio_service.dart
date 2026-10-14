import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal(enabled: true);
  factory AudioService() => _instance;

  /// No-op variant for headless contexts (tests without a platform binding),
  /// where merely constructing an AudioPlayer throws.
  AudioService.silent() : _enabled = false;

  AudioService._internal({required bool enabled}) : _enabled = enabled;

  final bool _enabled;

  // Lazy: creating an AudioPlayer touches the platform channel, which is
  // unavailable in unit tests that construct providers.
  AudioPlayer? _tap;
  AudioPlayer? _erase;
  AudioPlayer get _tapPlayer => _tap ??= AudioPlayer();
  AudioPlayer get _erasePlayer => _erase ??= AudioPlayer();

  // Callers fire-and-forget these; a sound that fails to play (plugin not
  // available, audio session busy) must never bubble up as an unhandled
  // error out of a cell tap.
  Future<void> playTap() async {
    if (!_enabled) return;
    try {
      await _tapPlayer.stop();
      await _tapPlayer.play(AssetSource('sounds/dot-tap.mp3'));
    } catch (e) {
      debugPrint('AudioService: playTap failed: $e');
    }
  }

  Future<void> playErase() async {
    if (!_enabled) return;
    try {
      await _erasePlayer.stop();
      await _erasePlayer.play(AssetSource('sounds/dot-erase.mp3'));
    } catch (e) {
      debugPrint('AudioService: playErase failed: $e');
    }
  }
}

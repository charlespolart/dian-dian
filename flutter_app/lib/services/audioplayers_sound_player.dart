import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'audio_service.dart';

/// [SoundPlayer] on audioplayers. The source stays loaded across stops
/// (`ReleaseMode.stop`); low-latency mode on Android (SoundPool; no effect
/// on iOS). The global audio context is set once, by the first player:
/// iOS ambient (the silence switch is honoured, music keeps playing),
/// Android sonification without taking audio focus.
///
/// Without a Flutter binding (a pure Dart test building a provider that
/// defaults to the real service) there is no platform to play on: the
/// constructor throws, the service catches it and stays mute.
class AudioplayersSoundPlayer implements SoundPlayer {
  static Future<void>? _context;
  late final AudioPlayer _player;

  AudioplayersSoundPlayer() {
    if (!_hasBinding) throw StateError('no Flutter binding, no audio');
    _player = AudioPlayer();
  }

  static bool get _hasBinding {
    try {
      ServicesBinding.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _setContext() => _context ??= AudioPlayer.global
      .setAudioContext(AudioContext(
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
        android: const AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.none,
        ),
      ))
      .catchError((Object e) => debugPrint('AudioService: audio context failed: $e'));

  @override
  Future<void> load(String assetPath) async {
    // The player creates itself asynchronously and every call below waits
    // for that first: calling one right away routes a creation failure into
    // the caller's catch instead of an unhandled error.
    await _player.setReleaseMode(ReleaseMode.stop);
    await _setContext();
    await _player.setPlayerMode(PlayerMode.lowLatency);
    await _player.setSourceAsset(assetPath);
  }

  @override
  Future<void> play() async {
    await _player.stop();
    await _player.resume();
  }

  @override
  Future<void> dispose() => _player.dispose();
}

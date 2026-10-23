import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'audio_service.dart';

/// [SoundPlayer] on audioplayers. The source stays loaded across stops
/// (`ReleaseMode.stop`); low-latency mode on Android (SoundPool; no effect
/// on iOS). The global audio context is set once, by the first player:
/// iOS ambient (the silence switch is honoured, music keeps playing),
/// Android sonification without taking audio focus.
class AudioplayersSoundPlayer implements SoundPlayer {
  static Future<void>? _context;
  final AudioPlayer _player = AudioPlayer();

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
    await _setContext();
    await _player.setReleaseMode(ReleaseMode.stop);
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

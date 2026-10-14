import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // Lazy: creating an AudioPlayer touches the platform channel, which is
  // unavailable in unit tests that construct providers.
  AudioPlayer? _tap;
  AudioPlayer? _erase;
  AudioPlayer get _tapPlayer => _tap ??= AudioPlayer();
  AudioPlayer get _erasePlayer => _erase ??= AudioPlayer();

  Future<void> playTap() async {
    await _tapPlayer.stop();
    await _tapPlayer.play(AssetSource('sounds/dot-tap.mp3'));
  }

  Future<void> playErase() async {
    await _erasePlayer.stop();
    await _erasePlayer.play(AssetSource('sounds/dot-erase.mp3'));
  }
}

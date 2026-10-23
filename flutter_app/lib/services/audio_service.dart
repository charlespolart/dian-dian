import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audioplayers_sound_player.dart';

/// The moments that sound (spec §1). Each palette has one file per cue.
enum SoundCue {
  dotFill,
  dotErase,
  trackerOpen,
  trackerClose,
  dialogOpen,
  dialogClose,
  trackerCreate,
  legendAdd,
  yearChange,
  press,
}

/// A folder under assets/sounds: three while they are compared, one ships.
enum SoundPalette { paper, interface, pixel }

extension SoundCueFile on SoundCue {
  /// The file stem: `dotFill` → `dot_fill`.
  String get file => name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

  /// The asset path audioplayers wants (relative to `assets/`).
  String assetIn(SoundPalette palette) => 'sounds/${palette.name}/$file.wav';
}

/// One preloaded sound, replayable from its start. The real one wraps an
/// `AudioPlayer`; tests inject a fake that records.
abstract class SoundPlayer {
  Future<void> load(String assetPath);
  Future<void> play();
  Future<void> dispose();
}

/// The app's sounds: one player per cue, preloaded for the current palette;
/// the "Sons" switch and the palette persisted on the device. [play] never
/// throws and never waits — a sound that fails is a debug line, never an
/// error out of a tap.
class AudioService extends ChangeNotifier {
  static const prefEnabled = 'sounds_enabled';
  static const prefPalette = 'sounds_palette';

  static AudioService? _instance;

  /// The app's one service, on real players.
  factory AudioService() => _instance ??= AudioService.custom(players: AudioplayersSoundPlayer.new);

  /// A service on the players [players] makes (tests: fakes).
  AudioService.custom({required SoundPlayer Function() players}) : _makePlayer = players {
    _loading = _init();
  }

  /// Nothing loads, nothing plays (headless tests).
  AudioService.silent() : _makePlayer = null;

  final SoundPlayer Function()? _makePlayer;
  Future<void> _loading = Future.value();
  Map<SoundCue, SoundPlayer> _players = const {};
  int _generation = 0;
  bool _enabled = true;
  SoundPalette _palette = SoundPalette.paper;
  bool _pressPending = false;

  bool get enabled => _enabled;
  SoundPalette get palette => _palette;

  /// Done once the current palette's players are loaded.
  Future<void> get ready => _loading;

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(prefEnabled) ?? true;
      final name = prefs.getString(prefPalette);
      _palette = SoundPalette.values.firstWhere((p) => p.name == name, orElse: () => SoundPalette.paper);
    } catch (e) {
      debugPrint('AudioService: prefs unavailable: $e');
    }
    notifyListeners();
    await _load();
  }

  /// Loads one player per cue for [_palette]; the previous set is disposed.
  /// A newer generation started meanwhile wins: this one is thrown away.
  Future<void> _load() async {
    final make = _makePlayer;
    if (make == null) return;
    final generation = ++_generation;
    _disposeAll(_players);
    _players = const {};
    final loaded = <SoundCue, SoundPlayer>{};
    for (final cue in SoundCue.values) {
      SoundPlayer? player;
      try {
        player = make();
        await player.load(cue.assetIn(_palette));
        loaded[cue] = player;
      } catch (e) {
        debugPrint('AudioService: ${cue.name} failed to load: $e');
        if (player != null) _disposeAll({cue: player});
      }
    }
    if (generation != _generation) {
      _disposeAll(loaded);
      return;
    }
    _players = loaded;
  }

  void _disposeAll(Map<SoundCue, SoundPlayer> players) {
    for (final p in players.values) {
      unawaited(p.dispose().catchError((Object e) => debugPrint('AudioService: dispose failed: $e')));
    }
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    await _save((prefs) => prefs.setBool(prefEnabled, value));
  }

  Future<void> setPalette(SoundPalette value) async {
    if (_palette == value) return;
    _palette = value;
    notifyListeners();
    await _save((prefs) => prefs.setString(prefPalette, value.name));
    _loading = _load();
    await _loading;
  }

  Future<void> _save(Future<void> Function(SharedPreferences prefs) write) async {
    try {
      await write(await SharedPreferences.getInstance());
    } catch (e) {
      debugPrint('AudioService: prefs write failed: $e');
    }
  }

  /// Fire and forget. [SoundCue.press] waits one microtask and yields to any
  /// other cue played in the same turn: a button that opens a dialog sounds
  /// as the dialog, not as a button and then a dialog.
  void play(SoundCue cue) {
    if (cue == SoundCue.press) {
      if (_pressPending) return;
      _pressPending = true;
      scheduleMicrotask(() {
        if (!_pressPending) return;
        _pressPending = false;
        _playNow(SoundCue.press);
      });
      return;
    }
    _pressPending = false;
    _playNow(cue);
  }

  void _playNow(SoundCue cue) {
    if (!_enabled) return;
    final player = _players[cue];
    if (player == null) return;
    try {
      unawaited(player.play().catchError((Object e) => debugPrint('AudioService: ${cue.name} failed: $e')));
    } catch (e) {
      debugPrint('AudioService: ${cue.name} failed: $e');
    }
  }

  @override
  void dispose() {
    _generation++;
    _disposeAll(_players);
    _players = const {};
    super.dispose();
  }
}

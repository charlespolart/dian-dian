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
  stepNext,    // an arrow steps forward: next year (list, tracker), next day (cell editor)
  stepPrev,    // … or back
  press,
  panelOpen,   // the tracker's side panel unfolds
  panelClose,  // … and folds back
  dragPick,    // a card or a legend is picked up
  dragHover,   // the dragged thing arrives over a place it can take
  dragDrop,    // … and is dropped there
  select,      // a legend or a colour becomes the selection
}

/// A folder under assets/sounds: several while they are compared, one ships.
enum SoundPalette { gentle, cute }

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
  SoundPalette _palette = SoundPalette.gentle;

  /// Weak cues: a button's tic and a dialog's close. They wait one microtask
  /// and yield to a stronger cue of the same turn; after a strong cue they
  /// stay silent for [yieldWindow]: the act and the pop of one gesture make
  /// one sound, even when the pop waits for the server's answer.
  static const _weak = {SoundCue.press, SoundCue.dialogClose};
  static const yieldWindow = Duration(milliseconds: 250);
  SoundCue? _pendingWeak;
  DateTime? _strongAt;

  bool get enabled => _enabled;
  SoundPalette get palette => _palette;

  /// Done once the current palette's players are loaded.
  Future<void> get ready => _loading;

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(prefEnabled) ?? true;
      final name = prefs.getString(prefPalette);
      _palette = SoundPalette.values.firstWhere((p) => p.name == name, orElse: () => SoundPalette.gentle);
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
    final palette = _palette; // this load stays on the palette it started with
    _disposeAll(_players);
    _players = const {};
    final loaded = <SoundCue, SoundPlayer>{};
    for (final cue in SoundCue.values) {
      SoundPlayer? player;
      try {
        player = make();
        await player.load(cue.assetIn(palette));
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

  /// Switches to [value] and reloads every player. With [preview], that cue
  /// plays on the new palette once it is loaded, and a press pending from
  /// the tap that asked for it is dropped (one sound per gesture).
  Future<void> setPalette(SoundPalette value, {SoundCue? preview}) async {
    if (preview != null) _pendingWeak = null;
    if (_palette != value) {
      _palette = value;
      notifyListeners();
      await _save((prefs) => prefs.setString(prefPalette, value.name));
      _loading = _load();
      await _loading;
    }
    if (preview != null) _playNow(preview);
  }

  Future<void> _save(Future<void> Function(SharedPreferences prefs) write) async {
    try {
      await write(await SharedPreferences.getInstance());
    } catch (e) {
      debugPrint('AudioService: prefs write failed: $e');
    }
  }

  /// Fire and forget. One sound per gesture: a weak cue (see [_weak]) waits
  /// one microtask and yields to a stronger cue of the same turn — a button
  /// that opens a dialog sounds as the dialog — and is dropped within
  /// [yieldWindow] of a strong cue — a cell filled then its editor popped
  /// sounds as the fill. Between two weak cues of a turn, the dialog's close
  /// outranks the button's tic.
  void play(SoundCue cue) {
    if (_weak.contains(cue)) {
      final strongAt = _strongAt;
      if (strongAt != null && DateTime.now().difference(strongAt) < yieldWindow) return;
      if (_pendingWeak == null) {
        _pendingWeak = cue;
        scheduleMicrotask(_flushWeak);
      } else if (cue == SoundCue.dialogClose) {
        _pendingWeak = cue;
      }
      return;
    }
    _pendingWeak = null;
    // Opening a dialog does not arm the window: opening then closing it at
    // once is two gestures, and the close must sound.
    if (cue != SoundCue.dialogOpen) _strongAt = DateTime.now();
    _playNow(cue);
  }

  void _flushWeak() {
    final cue = _pendingWeak;
    _pendingWeak = null;
    if (cue != null) _playNow(cue);
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

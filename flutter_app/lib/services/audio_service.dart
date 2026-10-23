import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audioplayers_sound_player.dart';
import 'flutter_haptics.dart';

/// The moments that sound (spec §1): one wav each under assets/sounds.
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

/// What a moment feels like under the finger (spec §3, « Haptique »).
enum Haptic { none, light, medium, selection }

extension SoundCueFile on SoundCue {
  /// The file stem: `dotFill` → `dot_fill`.
  String get file => name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

  /// The asset path audioplayers wants (relative to `assets/`).
  String get asset => 'sounds/$file.wav';

  /// The vibration that goes with the cue: for what changes something (a
  /// dot, a drag, a choice, a step, the panel, a creation), nothing for a
  /// plain button, a dialog or the tracker opening.
  Haptic get haptic => switch (this) {
        SoundCue.dotFill || SoundCue.dotErase || SoundCue.panelOpen || SoundCue.panelClose => Haptic.light,
        SoundCue.dragPick || SoundCue.dragDrop || SoundCue.trackerCreate => Haptic.medium,
        SoundCue.select || SoundCue.stepNext || SoundCue.stepPrev || SoundCue.dragHover => Haptic.selection,
        SoundCue.press ||
        SoundCue.dialogOpen ||
        SoundCue.dialogClose ||
        SoundCue.trackerOpen ||
        SoundCue.trackerClose ||
        SoundCue.legendAdd =>
          Haptic.none,
      };
}

/// Where vibrations go. The real one is Flutter's `HapticFeedback`; tests
/// inject a fake that records.
abstract class HapticSink {
  Future<void> feel(Haptic haptic);
}

/// One preloaded sound, replayable from its start. The real one wraps an
/// `AudioPlayer`; tests inject a fake that records.
abstract class SoundPlayer {
  Future<void> load(String assetPath);
  Future<void> play();
  Future<void> dispose();
}

/// The app's sounds and vibrations: one player per cue, preloaded, a
/// haptic per cue; the "Sons" and "Vibrations" switches persisted on the
/// device, independent of each other. [play] never throws and never waits
/// — a sound that fails is a debug line, never an error out of a tap.
class AudioService extends ChangeNotifier {
  static const prefEnabled = 'sounds_enabled';
  static const prefHaptics = 'haptics_enabled';

  static AudioService? _instance;

  /// The app's one service, on real players and real haptics.
  factory AudioService() => _instance ??= AudioService.custom(players: AudioplayersSoundPlayer.new);

  /// A service on the players [players] makes and on [haptics] (tests: fakes).
  AudioService.custom({required SoundPlayer Function() players, HapticSink? haptics})
      : _makePlayer = players,
        _haptics = haptics ?? FlutterHaptics() {
    _loading = _init();
  }

  /// Nothing loads, nothing plays, nothing vibrates (headless tests).
  AudioService.silent()
      : _makePlayer = null,
        _haptics = null;

  final SoundPlayer Function()? _makePlayer;
  final HapticSink? _haptics;
  Future<void> _loading = Future.value();
  Map<SoundCue, SoundPlayer> _players = const {};
  int _generation = 0;
  bool _enabled = true;
  bool _hapticsEnabled = true;

  /// Weak cues: a button's tic and a dialog's close. They wait one microtask
  /// and yield to a stronger cue of the same turn; after a strong cue they
  /// stay silent for [yieldWindow]: the act and the pop of one gesture make
  /// one sound, even when the pop waits for the server's answer.
  static const _weak = {SoundCue.press, SoundCue.dialogClose};
  static const yieldWindow = Duration(milliseconds: 250);
  SoundCue? _pendingWeak;
  DateTime? _strongAt;

  bool get enabled => _enabled;
  bool get hapticsEnabled => _hapticsEnabled;

  /// Done once the players are loaded.
  Future<void> get ready => _loading;

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(prefEnabled) ?? true;
      _hapticsEnabled = prefs.getBool(prefHaptics) ?? true;
    } catch (e) {
      debugPrint('AudioService: prefs unavailable: $e');
    }
    notifyListeners();
    await _load();
  }

  /// Loads one player per cue. A newer generation started meanwhile (a
  /// dispose) wins: this one is thrown away.
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
        await player.load(cue.asset);
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
    await _save(prefEnabled, value);
  }

  Future<void> setHapticsEnabled(bool value) async {
    if (_hapticsEnabled == value) return;
    _hapticsEnabled = value;
    notifyListeners();
    await _save(prefHaptics, value);
  }

  Future<void> _save(String key, bool value) async {
    try {
      await (await SharedPreferences.getInstance()).setBool(key, value);
    } catch (e) {
      debugPrint('AudioService: prefs write failed: $e');
    }
  }

  /// A vibration on its own (a preview from the settings), while enabled.
  void feel(Haptic haptic) {
    final sink = _haptics;
    if (!_hapticsEnabled || sink == null || haptic == Haptic.none) return;
    try {
      unawaited(sink.feel(haptic).catchError((Object e) => debugPrint('AudioService: haptic failed: $e')));
    } catch (e) {
      debugPrint('AudioService: haptic failed: $e');
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
    feel(cue.haptic);
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

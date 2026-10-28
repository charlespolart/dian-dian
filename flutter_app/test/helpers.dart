import 'dart:async';

import 'package:flutter/widgets.dart' show FlutterError, Size;
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/services/audio_service.dart';
import 'package:dian_dian/services/snapshot_store.dart';
import 'package:dian_dian/services/token_store.dart';

/// In-memory [TokenStore] for tests.
class FakeTokens implements TokenStore {
  String? refresh;
  String? userId;
  FakeTokens({this.refresh = 'r', this.userId = 'u1'});

  @override
  Future<String?> getRefreshToken() async => refresh;
  @override
  Future<void> setRefreshToken(String token) async => refresh = token;
  @override
  Future<void> deleteRefreshToken() async => refresh = null;
  @override
  Future<String?> getUserId() async => userId;
  @override
  Future<void> setUserId(String id) async => userId = id;
  @override
  Future<void> deleteUserId() async => userId = null;
}

/// In-memory [SnapshotStore] for tests.
class MemorySnapshots implements SnapshotStore {
  String? data;
  int writes = 0;

  @override
  Future<String?> read() async => data;
  @override
  Future<void> write(String json) async {
    data = json;
    writes++;
  }

  @override
  Future<void> delete() async => data = null;
}

Map<String, dynamic> pageJson(
  String id, {
  int position = 0,
  String title = 'T',
  String createdAt = '',
  int recentCells = 0,
  String? lastCellAt,
  bool keepFree = false,
}) =>
    {
      'id': id,
      'userId': 'u1',
      'title': title,
      'year': 2026,
      'position': position,
      'palette': null,
      'createdAt': createdAt,
      'recentCells': recentCells,
      'lastCellAt': lastCellAt,
      'keepFree': keepFree,
    };

Map<String, dynamic> legendJson(String id, String pageId, String color, int position, {String? label}) => {
      'id': id,
      'pageId': pageId,
      'color': color,
      'label': label ?? id,
      'position': position,
      'createdAt': '',
    };

/// A 500 × 844 logical surface, portrait: tall enough to scroll, wide enough
/// for a header under the test font (every glyph a square).
void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1500, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

/// A 600 × 900 logical surface, portrait tablet: the tracker's sidebar at its
/// wide setting, where the year row fits under the test font.
void tabletPortrait(WidgetTester tester) {
  tester.view.physicalSize = const Size(1800, 2700);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

/// A 900 × 600 logical surface, landscape: the tracker's wide layout with
/// its left panel.
void landscape(WidgetTester tester) {
  tester.view.physicalSize = const Size(2700, 1800);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

/// Lets a test pass over RenderFlex overflows: the test font draws every
/// glyph as a square, wider than the app's pixel fonts, so a row sized for
/// the real font (the landscape sidebar's stats, 150 px) can spill by a few
/// pixels here and nowhere else. Every other error still fails the test.
void ignoreOverflowUnderTestFont(WidgetTester tester) {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    original?.call(details);
  };
  addTearDown(() => FlutterError.onError = original);
}

/// A [SoundPlayer] that records instead of playing.
class FakeSoundPlayer implements SoundPlayer {
  String? asset;
  int plays = 0;
  bool disposed = false;
  final bool failing;
  final List<String> log;
  final Completer<void>? gate;
  FakeSoundPlayer({this.failing = false, required this.log, this.gate});

  @override
  Future<void> load(String assetPath) async {
    asset = assetPath;
    await gate?.future;
  }
  @override
  Future<void> play() async {
    if (failing) throw StateError('player broken');
    plays++;
    log.add(asset!);
  }
  @override
  Future<void> dispose() async => disposed = true;
}

/// Makes [FakeSoundPlayer]s for `AudioService.custom(players: fakes.call)`
/// and reads them back: [played] is every cue played, in order.
class FakeSoundPlayers {
  final created = <FakeSoundPlayer>[];
  final log = <String>[];
  final bool failing;
  final bool unconstructible;
  /// When set, every load waits on it: a palette stays "loading" until the
  /// test completes the gate.
  final Completer<void>? gate;
  FakeSoundPlayers({this.failing = false, this.unconstructible = false, this.gate});

  SoundPlayer call() {
    if (unconstructible) throw StateError('no audio plugin');
    final p = FakeSoundPlayer(failing: failing, log: log, gate: gate);
    created.add(p);
    return p;
  }

  List<FakeSoundPlayer> get live => created.where((p) => !p.disposed).toList();
  List<SoundCue> get played =>
      log.map((a) => SoundCue.values.firstWhere((c) => a.endsWith('/${c.file}.wav'))).toList();
}

/// A [HapticSink] that records what it was asked to feel.
class FakeHaptics implements HapticSink {
  final felt = <Haptic>[];
  @override
  Future<void> feel(Haptic haptic) async => felt.add(haptic);
}

/// An [AudioService] on fakes, loaded. `SharedPreferences.setMockInitialValues`
/// must have run. Pass [haptics] to read the vibrations back.
Future<({AudioService service, FakeSoundPlayers players})> recordingAudio({FakeHaptics? haptics}) async {
  final players = FakeSoundPlayers();
  final service = AudioService.custom(players: players.call, haptics: haptics ?? FakeHaptics());
  await service.ready;
  return (service: service, players: players);
}

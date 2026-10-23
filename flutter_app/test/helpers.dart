import 'package:flutter/widgets.dart' show Size;
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

/// A [SoundPlayer] that records instead of playing.
class FakeSoundPlayer implements SoundPlayer {
  String? asset;
  int plays = 0;
  bool disposed = false;
  final bool failing;
  final List<String> log;
  FakeSoundPlayer({this.failing = false, required this.log});

  @override
  Future<void> load(String assetPath) async => asset = assetPath;
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
  FakeSoundPlayers({this.failing = false, this.unconstructible = false});

  SoundPlayer call() {
    if (unconstructible) throw StateError('no audio plugin');
    final p = FakeSoundPlayer(failing: failing, log: log);
    created.add(p);
    return p;
  }

  List<FakeSoundPlayer> get live => created.where((p) => !p.disposed).toList();
  List<SoundCue> get played =>
      log.map((a) => SoundCue.values.firstWhere((c) => a.endsWith('/${c.file}.wav'))).toList();
}

/// An [AudioService] on fakes, loaded. `SharedPreferences.setMockInitialValues`
/// must have run.
Future<({AudioService service, FakeSoundPlayers players})> recordingAudio() async {
  final players = FakeSoundPlayers();
  final service = AudioService.custom(players: players.call);
  await service.ready;
  return (service: service, players: players);
}

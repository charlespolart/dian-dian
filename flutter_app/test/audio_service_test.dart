import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/services/audio_service.dart';

import 'helpers.dart';

/// Lets the press microtask and any play future run.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('one player per cue, loaded from the palette folder, paper by default', () async {
    final (:service, :players) = await recordingAudio();
    expect(service.palette, SoundPalette.gentle);
    expect(service.enabled, isTrue);
    expect(SoundCue.dotFill.file, 'dot_fill');
    expect(SoundCue.trackerCreate.assetIn(SoundPalette.cute), 'sounds/cute/tracker_create.wav');
    expect(players.live.map((p) => p.asset), unorderedEquals([for (final c in SoundCue.values) c.assetIn(SoundPalette.gentle)]));
  });

  test('play plays that cue; nothing once disabled', () async {
    final (:service, :players) = await recordingAudio();
    service.play(SoundCue.dotFill);
    service.play(SoundCue.dotErase);
    await settle();
    expect(players.played, [SoundCue.dotFill, SoundCue.dotErase]);
    await service.setEnabled(false);
    service.play(SoundCue.dotFill);
    await settle();
    expect(players.played, [SoundCue.dotFill, SoundCue.dotErase]);
  });

  test('press waits one microtask and yields to another cue of the same turn', () async {
    final (:service, :players) = await recordingAudio();
    service.play(SoundCue.press);
    service.play(SoundCue.dialogOpen);
    await settle();
    expect(players.played, [SoundCue.dialogOpen]);
    await Future<void>.delayed(AudioService.yieldWindow + const Duration(milliseconds: 30));
    service.play(SoundCue.press);
    service.play(SoundCue.press);
    await settle();
    expect(players.played, [SoundCue.dialogOpen, SoundCue.press]);
  });

  test('dialogClose outranks press in the same turn, whichever comes first', () async {
    final (:service, :players) = await recordingAudio();
    service.play(SoundCue.press);
    service.play(SoundCue.dialogClose);
    await settle();
    expect(players.played, [SoundCue.dialogClose]);
    service.play(SoundCue.dialogClose);
    service.play(SoundCue.press);
    await settle();
    expect(players.played, [SoundCue.dialogClose, SoundCue.dialogClose]);
  });

  test('a weak cue soon after a strong one is dropped — the act and the pop of one gesture, even across a server round trip', () async {
    final (:service, :players) = await recordingAudio();
    service.play(SoundCue.dotFill);
    await settle();
    service.play(SoundCue.dialogClose); // the dialog pops once the server answered
    service.play(SoundCue.press);
    await settle();
    expect(players.played, [SoundCue.dotFill]);
    await Future<void>.delayed(AudioService.yieldWindow + const Duration(milliseconds: 30));
    service.play(SoundCue.dialogClose);
    await settle();
    expect(players.played, [SoundCue.dotFill, SoundCue.dialogClose]);
  });

  test('a dialog opened and closed at once sounds both: opening does not arm the yield window', () async {
    final (:service, :players) = await recordingAudio();
    service.play(SoundCue.dialogOpen);
    await settle();
    service.play(SoundCue.dialogClose);
    await settle();
    expect(players.played, [SoundCue.dialogOpen, SoundCue.dialogClose]);
  });

  test('setEnabled and setPalette persist; setPalette swaps every player', () async {
    final (:service, :players) = await recordingAudio();
    await service.setEnabled(false);
    await service.setPalette(SoundPalette.cute);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(AudioService.prefEnabled), isFalse);
    expect(prefs.getString(AudioService.prefPalette), 'cute');
    expect(players.live.map((p) => p.asset), everyElement(startsWith('sounds/cute/')));
    expect(players.created.where((p) => p.disposed), hasLength(SoundCue.values.length));
    final again = await recordingAudio();
    expect(again.service.enabled, isFalse);
    expect(again.service.palette, SoundPalette.cute);
  });

  test('setPalette with a preview drops a pending press and plays the preview on the new palette', () async {
    final (:service, :players) = await recordingAudio();
    service.play(SoundCue.press);
    await service.setPalette(SoundPalette.cute, preview: SoundCue.trackerOpen);
    await settle();
    expect(players.played, [SoundCue.trackerOpen]);
    expect(players.live.where((p) => p.plays > 0).single.asset, 'sounds/cute/tracker_open.wav');
  });

  test('a palette switch during a load keeps only the new palette; the superseded load is disposed whole', () async {
    final players = FakeSoundPlayers(gate: Completer<void>());
    final service = AudioService.custom(players: players.call);
    await settle(); // prefs read, the first player waits on the gate
    expect(players.created, hasLength(1));
    final switching = service.setPalette(SoundPalette.cute);
    players.gate!.complete();
    await switching;
    await service.ready;
    await settle();
    expect(players.live.map((p) => p.asset), unorderedEquals([for (final c in SoundCue.values) c.assetIn(SoundPalette.cute)]));
    final disposed = players.created.where((p) => p.disposed).toList();
    expect(disposed, hasLength(SoundCue.values.length));
    expect(disposed.map((p) => p.asset), everyElement(startsWith('sounds/gentle/')), reason: 'the first load stays on the palette it started with');
  });

  test('disposing the service during a load disposes everything that load produces', () async {
    final players = FakeSoundPlayers(gate: Completer<void>());
    final service = AudioService.custom(players: players.call);
    await settle();
    service.dispose();
    players.gate!.complete();
    await service.ready;
    await settle();
    expect(players.created, hasLength(SoundCue.values.length));
    expect(players.live, isEmpty);
  });

  test('a player that throws never surfaces', () async {
    final players = FakeSoundPlayers(failing: true);
    final service = AudioService.custom(players: players.call);
    await service.ready;
    service.play(SoundCue.dotFill);
    service.play(SoundCue.press);
    await settle();
    expect(players.played, isEmpty);
  });

  test('the same cue twice in a row plays twice, from its one player', () async {
    final (:service, :players) = await recordingAudio();
    service.play(SoundCue.dotFill);
    service.play(SoundCue.dotFill);
    await settle();
    expect(players.played, [SoundCue.dotFill, SoundCue.dotFill]);
    expect(players.live.where((p) => p.plays == 2), hasLength(1));
  });

  test('players that cannot be constructed leave a service that is simply mute', () async {
    final players = FakeSoundPlayers(unconstructible: true);
    final service = AudioService.custom(players: players.call);
    await service.ready;
    service.play(SoundCue.dotFill);
    await settle();
    expect(players.created, isEmpty);
    expect(service.enabled, isTrue);
  });

  test('a play before the palette is loaded is dropped', () async {
    final players = FakeSoundPlayers();
    final service = AudioService.custom(players: players.call);
    service.play(SoundCue.dotFill);
    await service.ready;
    await settle();
    expect(players.played, isEmpty);
  });

  test('the real service in a headless test is mute, never an unhandled error', () async {
    // No Flutter binding here, like the pure-Dart provider tests that build
    // providers without injecting a service.
    final service = AudioService();
    await service.ready;
    service.play(SoundCue.dotFill);
    await settle();
    expect(service.enabled, isTrue);
  });

  test('silent: nothing loads, nothing plays, the switch still works', () async {
    final service = AudioService.silent();
    await service.ready;
    service.play(SoundCue.dotFill);
    await service.setEnabled(false);
    expect(service.enabled, isFalse);
  });
}

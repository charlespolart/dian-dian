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
    expect(service.palette, SoundPalette.paper);
    expect(service.enabled, isTrue);
    expect(SoundCue.dotFill.file, 'dot_fill');
    expect(SoundCue.trackerCreate.assetIn(SoundPalette.pixel), 'sounds/pixel/tracker_create.wav');
    expect(players.live.map((p) => p.asset), unorderedEquals([for (final c in SoundCue.values) c.assetIn(SoundPalette.paper)]));
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
    service.play(SoundCue.press);
    service.play(SoundCue.press);
    await settle();
    expect(players.played, [SoundCue.dialogOpen, SoundCue.press]);
  });

  test('setEnabled and setPalette persist; setPalette swaps every player', () async {
    final (:service, :players) = await recordingAudio();
    await service.setEnabled(false);
    await service.setPalette(SoundPalette.pixel);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(AudioService.prefEnabled), isFalse);
    expect(prefs.getString(AudioService.prefPalette), 'pixel');
    expect(players.live.map((p) => p.asset), everyElement(startsWith('sounds/pixel/')));
    expect(players.created.where((p) => p.disposed), hasLength(SoundCue.values.length));
    final again = await recordingAudio();
    expect(again.service.enabled, isFalse);
    expect(again.service.palette, SoundPalette.pixel);
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

  test('silent: nothing loads, nothing plays, the switch still works', () async {
    final service = AudioService.silent();
    await service.ready;
    service.play(SoundCue.dotFill);
    await service.setEnabled(false);
    expect(service.enabled, isFalse);
  });
}

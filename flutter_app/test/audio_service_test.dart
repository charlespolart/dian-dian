import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/services/audio_service.dart';

import 'helpers.dart';

/// Lets the weak-cue microtask and any play future run.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('one player per cue, loaded from assets/sounds', () async {
    final (:service, :players) = await recordingAudio();
    expect(service.enabled, isTrue);
    expect(SoundCue.dotFill.file, 'dot_fill');
    expect(SoundCue.trackerCreate.asset, 'sounds/tracker_create.wav');
    expect(players.live.map((p) => p.asset), unorderedEquals([for (final c in SoundCue.values) c.asset]));
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

  test('setEnabled persists, and a new service reads it back', () async {
    final (:service, :players) = await recordingAudio();
    await service.setEnabled(false);
    expect((await SharedPreferences.getInstance()).getBool(AudioService.prefEnabled), isFalse);
    final again = await recordingAudio();
    expect(again.service.enabled, isFalse);
    expect(players.live, hasLength(SoundCue.values.length));
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

  test('a play before the sounds are loaded is dropped', () async {
    final players = FakeSoundPlayers();
    final service = AudioService.custom(players: players.call);
    service.play(SoundCue.dotFill);
    await service.ready;
    await settle();
    expect(players.played, isEmpty);
  });

  test('the real service in a headless test is mute, never an unhandled error', () async {
    final service = AudioService();
    await service.ready;
    service.play(SoundCue.dotFill);
    await settle();
    expect(service.enabled, isTrue);
  });

  test('a tracker opening right after its creation is silent: the creation already sounded', () async {
    final (:service, :players) = await recordingAudio();
    service.play(SoundCue.trackerCreate);
    service.play(SoundCue.dialogClose); // the new-tracker dialog closing
    service.play(SoundCue.trackerOpen); // the morph that follows
    await settle();
    expect(players.played, [SoundCue.trackerCreate]);
  });

  test('a tracker opening long after a creation sounds', () async {
    final (:service, :players) = await recordingAudio();
    service.play(SoundCue.trackerCreate);
    await Future<void>.delayed(AudioService.yieldWindow + const Duration(milliseconds: 20));
    service.play(SoundCue.trackerOpen);
    await settle();
    expect(players.played, [SoundCue.trackerCreate, SoundCue.trackerOpen]);
  });

  group('haptics', () {
    test('each cue has its vibration: medium for a dot, heavy for a pick or a creation, light for a step or a choice, a selection click for a hover, none for a button', () {
      expect(SoundCue.dotFill.haptic, Haptic.medium);
      expect(SoundCue.dotErase.haptic, Haptic.medium);
      expect(SoundCue.panelOpen.haptic, Haptic.medium);
      expect(SoundCue.dragPick.haptic, Haptic.heavy);
      expect(SoundCue.dragDrop.haptic, Haptic.heavy);
      expect(SoundCue.trackerCreate.haptic, Haptic.heavy);
      expect(SoundCue.trackerDelete.haptic, Haptic.heavy);
      expect(SoundCue.stepNext.haptic, Haptic.light);
      expect(SoundCue.select.haptic, Haptic.light);
      expect(SoundCue.dragHover.haptic, Haptic.selection);
      for (final c in [SoundCue.press, SoundCue.dialogOpen, SoundCue.dialogClose, SoundCue.trackerOpen, SoundCue.trackerClose, SoundCue.legendAdd]) {
        expect(c.haptic, Haptic.none, reason: c.name);
      }
    });

    test('a cue is felt with its sound, under the same gesture rules', () async {
      final haptics = FakeHaptics();
      final (:service, :players) = await recordingAudio(haptics: haptics);
      service.play(SoundCue.press);
      service.play(SoundCue.dotFill);
      await settle();
      expect(haptics.felt, [Haptic.medium]);
      expect(players.played, [SoundCue.dotFill]);
    });

    test('vibrations and sounds switch independently, each persisted', () async {
      final haptics = FakeHaptics();
      final (:service, :players) = await recordingAudio(haptics: haptics);
      await service.setEnabled(false);
      service.play(SoundCue.dragPick);
      await settle();
      expect(players.played, isEmpty);
      expect(haptics.felt, [Haptic.heavy]);
      await service.setHapticsEnabled(false);
      service.play(SoundCue.dragPick);
      await settle();
      expect(haptics.felt, [Haptic.heavy]);
      expect((await SharedPreferences.getInstance()).getBool(AudioService.prefHaptics), isFalse);
      final again = await recordingAudio();
      expect(again.service.hapticsEnabled, isFalse);
    });

    test('feel() previews a vibration on demand, only while enabled', () async {
      final haptics = FakeHaptics();
      final (:service, :players) = await recordingAudio(haptics: haptics);
      service.feel(Haptic.light);
      await settle();
      expect(haptics.felt, [Haptic.light]);
      await service.setHapticsEnabled(false);
      service.feel(Haptic.light);
      await settle();
      expect(haptics.felt, [Haptic.light]);
    });
  });

  test('silent: nothing loads, nothing plays, the switch still works', () async {
    final service = AudioService.silent();
    await service.ready;
    service.play(SoundCue.dotFill);
    await service.setEnabled(false);
    expect(service.enabled, isFalse);
  });
}

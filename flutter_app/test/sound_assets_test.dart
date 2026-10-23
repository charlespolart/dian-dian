import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/services/audio_service.dart';

void main() {
  test('every palette has every cue as a small RIFF wav', () {
    for (final palette in SoundPalette.values) {
      for (final cue in SoundCue.values) {
        final file = File('assets/${cue.assetIn(palette)}');
        expect(file.existsSync(), isTrue, reason: file.path);
        final bytes = file.readAsBytesSync();
        expect(String.fromCharCodes(bytes.take(4)), 'RIFF', reason: file.path);
        expect(bytes.length, lessThan(100 * 1024), reason: file.path);
      }
    }
  });

  test('pubspec lists each palette folder, not the parent', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final palette in SoundPalette.values) {
      expect(pubspec, contains('- assets/sounds/${palette.name}/'));
    }
    expect(pubspec, isNot(contains('- assets/sounds/\n')));
  });
}

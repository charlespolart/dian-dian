import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/services/audio_service.dart';

void main() {
  test('every cue is a small RIFF wav under assets/sounds', () {
    for (final cue in SoundCue.values) {
      final file = File('assets/${cue.asset}');
      expect(file.existsSync(), isTrue, reason: file.path);
      final bytes = file.readAsBytesSync();
      expect(String.fromCharCodes(bytes.take(4)), 'RIFF', reason: file.path);
      expect(bytes.length, lessThan(100 * 1024), reason: file.path);
    }
  });

  test('pubspec lists the sounds folder', () {
    expect(File('pubspec.yaml').readAsStringSync(), contains('- assets/sounds/\n'));
  });
}

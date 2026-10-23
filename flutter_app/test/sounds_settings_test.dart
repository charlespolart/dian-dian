import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/providers/language_provider.dart';
import 'package:dian_dian/services/audio_service.dart';
import 'package:dian_dian/widgets/press_scale.dart';
import 'package:dian_dian/widgets/sounds_settings.dart';

import 'helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget host(AudioService audio) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider<AudioService>.value(value: audio),
        ],
        child: const MaterialApp(home: Scaffold(body: SoundsSettings())),
      );

  testWidgets('the tile shows the state, flips it on tap, persists, and plays press when turning on', (tester) async {
    final rec = await recordingAudio();
    await tester.pumpWidget(host(rec.service));
    expect(find.text('On'), findsOneWidget);
    await tester.tap(find.widgetWithText(PressScale, 'On'));
    await tester.pumpAndSettle();
    expect(find.text('Off'), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getBool(AudioService.prefEnabled), isFalse);
    // Turning off is silent: the tap's press is dropped once disabled.
    expect(rec.players.played, isEmpty);
    await tester.tap(find.widgetWithText(PressScale, 'Off'));
    await tester.pumpAndSettle();
    expect(find.text('On'), findsOneWidget);
    expect(rec.players.played, [SoundCue.press]);
  });

  testWidgets('in debug, a palette tile cycles the palettes and previews trackerOpen', (tester) async {
    final rec = await recordingAudio();
    await tester.pumpWidget(host(rec.service));
    final tile = find.textContaining('Palette');
    expect(tile, kDebugMode ? findsOneWidget : findsNothing);
    if (!kDebugMode) return;
    await tester.tap(find.widgetWithText(PressScale, 'Palette : gentle'));
    await tester.pumpAndSettle();
    expect(rec.service.palette, SoundPalette.cute);
    expect(find.text('Palette : cute'), findsOneWidget);
    expect(rec.players.played, [SoundCue.trackerOpen]);
  });
}

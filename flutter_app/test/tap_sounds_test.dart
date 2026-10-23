import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/providers/language_provider.dart';
import 'package:dian_dian/services/audio_service.dart';
import 'package:dian_dian/widgets/language_picker_dialog.dart';
import 'package:dian_dian/widgets/top_bar.dart';

import 'helpers.dart';

/// Every tap sounds: the plain buttons that are not PressScale-shaped
/// (back arrows, crosses, links) play press, and a choice plays select.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget host(AudioService audio, Widget home) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider<AudioService>.value(value: audio),
        ],
        child: MaterialApp(home: Scaffold(body: home)),
      );

  testWidgets("the top bar's back arrow plays press", (tester) async {
    final rec = await recordingAudio();
    await tester.pumpWidget(host(rec.service, TopBar(onBack: () {}, title: 'T')));
    await tester.tap(find.text('<'));
    await tester.pumpAndSettle();
    expect(rec.players.played, [SoundCue.press]);
  });

  testWidgets('choosing a language in its picker plays select, not the tic nor the close', (tester) async {
    final rec = await recordingAudio();
    await tester.pumpWidget(host(
      rec.service,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showLanguagePickerDialog(context, context.read<LanguageProvider>()),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('nglish'));
    await tester.pumpAndSettle();
    expect(rec.players.played, [SoundCue.dialogOpen, SoundCue.select]);
  });
}

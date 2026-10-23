import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/services/audio_service.dart';
import 'package:dian_dian/widgets/press_scale.dart';

import 'helpers.dart';

void main() {
  double scaleOf(WidgetTester tester) => tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

  testWidgets('shrinks under the finger, springs back on release, taps once', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Center(child: PressScale(onTap: () => taps++, child: const SizedBox(width: 80, height: 40))),
    ));
    expect(scaleOf(tester), 1);

    final gesture = await tester.startGesture(tester.getCenter(find.byType(PressScale)));
    // The tap recognizer reports the down after its press timeout.
    await tester.pump(const Duration(milliseconds: 150));
    expect(scaleOf(tester), PressScale.scale);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(scaleOf(tester), 1);
    expect(taps, 1);
  });

  testWidgets('a cancelled press springs back without tapping', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Center(child: PressScale(onTap: () => taps++, child: const SizedBox(width: 80, height: 40))),
    ));
    final gesture = await tester.startGesture(tester.getCenter(find.byType(PressScale)));
    await tester.pump(const Duration(milliseconds: 150));
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(scaleOf(tester), 1);
    expect(taps, 0);
  });

  testWidgets('onTapAt gets the global position of the release', (tester) async {
    Offset? at;
    await tester.pumpWidget(MaterialApp(
      home: Center(child: PressScale(onTapAt: (p) => at = p, child: const SizedBox(width: 80, height: 40))),
    ));
    final center = tester.getCenter(find.byType(PressScale));
    await tester.tapAt(center);
    await tester.pumpAndSettle();
    expect(at, center);
  });

  testWidgets('disabled (no callback): no feedback', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Center(child: PressScale(child: SizedBox(width: 80, height: 40))),
    ));
    final gesture = await tester.startGesture(tester.getCenter(find.byType(PressScale)));
    await tester.pump(const Duration(milliseconds: 150));
    expect(scaleOf(tester), 1);
    await gesture.up();
  });

  testWidgets('a tap plays press; without a service it just taps', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final rec = await recordingAudio();
    await tester.pumpWidget(ChangeNotifierProvider<AudioService>.value(
      value: rec.service,
      child: MaterialApp(home: Center(child: PressScale(onTap: () {}, child: const SizedBox(width: 80, height: 40)))),
    ));
    await tester.tap(find.byType(PressScale));
    await tester.pumpAndSettle();
    expect(rec.players.played, [SoundCue.press]);
    var taps = 0;
    await tester.pumpWidget(MaterialApp(home: Center(child: PressScale(onTap: () => taps++, child: const SizedBox(width: 80, height: 40)))));
    await tester.tap(find.byType(PressScale));
    expect(taps, 1);
  });
}

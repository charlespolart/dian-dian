import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/services/ad_service.dart';
import 'package:dian_dian/widgets/ad_banner.dart';

/// The banner pinned to the bottom of a screen, as the list and the tracker
/// place it, with the system bar the device reports.
Widget pinned({required double systemBar, double keyboard = 0, VoidCallback? onClose}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(400, 800),
        viewPadding: EdgeInsets.only(bottom: systemBar),
        padding: EdgeInsets.only(bottom: keyboard > 0 ? 0 : systemBar),
        viewInsets: EdgeInsets.only(bottom: keyboard),
      ),
      child: Stack(children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AdBannerFrame(
            adSize: const Size(320, 50),
            ad: const SizedBox(key: Key('ad'), width: 320, height: 50),
            onClose: onClose ?? () {},
          ),
        ),
      ]),
    ),
  );
}

/// A 400 × 800 screen, so that "800 - y" is the distance to its bottom edge.
void phoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  for (final (name, bar) in [('Android, three-button navigation', 48.0), ('iPhone, home indicator', 34.0), ('no system bar', 0.0)]) {
    testWidgets('$name: the banner sits right above the system bar', (tester) async {
      phoneScreen(tester);
      await tester.pumpWidget(pinned(systemBar: bar));
      expect(tester.getSize(find.byType(AdBannerFrame)).height, 50 + 4 + bar);
      // The ad's bottom edge: 2 of margin above the system bar.
      expect(800 - tester.getBottomLeft(find.byKey(const Key('ad'))).dy, bar + 2);
    });
  }

  testWidgets('the room a screen keeps is exactly the frame above the system bar', (tester) async {
    addTearDown(AdService().enable);
    AdService().enable();
    phoneScreen(tester);
    await tester.pumpWidget(pinned(systemBar: 48));
    expect(tester.getSize(find.byType(AdBannerFrame)).height - 48, AdBannerWidget.reservedHeight(premium: false));
  });

  testWidgets('an open keyboard does not move it: only the system bar counts', (tester) async {
    await tester.pumpWidget(pinned(systemBar: 34, keyboard: 300));
    expect(tester.getSize(find.byType(AdBannerFrame)).height, 50 + 4 + 34);
  });

  testWidgets('the close button calls onClose', (tester) async {
    var closed = 0;
    await tester.pumpWidget(pinned(systemBar: 48, onClose: () => closed++));
    await tester.tap(find.byIcon(Icons.close_rounded));
    expect(closed, 1);
  });

  test('a free account keeps room at the bottom for the standard banner; Premium, ads off or the web keep none', () {
    addTearDown(AdService().enable);
    AdService().enable();
    expect(AdBannerWidget.reservedHeight(premium: false), 50 + 4);
    expect(AdBannerWidget.reservedHeight(premium: true), 0);
    AdService().disable();
    expect(AdBannerWidget.reservedHeight(premium: false), 0);
  });
}

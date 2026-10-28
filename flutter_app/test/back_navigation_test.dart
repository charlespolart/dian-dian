import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/main.dart';
import 'package:dian_dian/screens/tracker_screen.dart';
import 'package:dian_dian/widgets/back_swipe.dart';
import 'package:dian_dian/widgets/screen_stage.dart';

void main() {
  group('systemBackTarget', () {
    test('tracker and settings go back to the page list', () {
      expect(systemBackTarget(AppScreen.tracker), AppScreen.pageList);
      expect(systemBackTarget(AppScreen.settings), AppScreen.pageList);
    });

    test('register and forgot-password go back to login', () {
      expect(systemBackTarget(AppScreen.register), AppScreen.login);
      expect(systemBackTarget(AppScreen.forgotPassword), AppScreen.login);
    });

    test('roots have nowhere to go: the app may close', () {
      expect(systemBackTarget(AppScreen.login), isNull);
      expect(systemBackTarget(AppScreen.pageList), isNull);
      expect(systemBackTarget(AppScreen.firstTracker), isNull);
    });
  });

  group('transitionFor', () {
    test('list ↔ tracker morph, settings slide, everything else fades', () {
      expect(transitionFor(AppScreen.pageList, AppScreen.tracker), StageTransition.morphOpen);
      expect(transitionFor(AppScreen.tracker, AppScreen.pageList), StageTransition.morphClose);
      expect(transitionFor(AppScreen.pageList, AppScreen.settings), StageTransition.slideIn);
      expect(transitionFor(AppScreen.tracker, AppScreen.settings), StageTransition.slideIn);
      expect(transitionFor(AppScreen.settings, AppScreen.pageList), StageTransition.slideOut);
      expect(transitionFor(AppScreen.firstTracker, AppScreen.tracker), StageTransition.fade);
      expect(transitionFor(AppScreen.login, AppScreen.register), StageTransition.fade);
    });

    test('only the open morph arms the tracker\'s reveal', () {
      expect(trackerEntranceFor(StageTransition.morphOpen), TrackerEntrance.morph);
      expect(trackerEntranceFor(StageTransition.fade), TrackerEntrance.none);
      expect(trackerEntranceFor(StageTransition.morphClose), TrackerEntrance.none);
    });
  });

  group('BackSwipe', () {
    Widget host(void Function() onBack) => MaterialApp(
          home: BackSwipe(onBack: onBack, child: const SizedBox.expand()),
        );

    testWidgets('a swipe from the left edge calls onBack once', (tester) async {
      var calls = 0;
      await tester.pumpWidget(host(() => calls++));
      await tester.dragFrom(const Offset(10, 300), const Offset(120, 0));
      await tester.pump();
      expect(calls, 1);
    });

    testWidgets('a swipe that starts away from the edge does nothing', (tester) async {
      var calls = 0;
      await tester.pumpWidget(host(() => calls++));
      await tester.dragFrom(const Offset(200, 300), const Offset(120, 0));
      await tester.pump();
      expect(calls, 0);
    });

    testWidgets('a short or mostly vertical drag from the edge does nothing', (tester) async {
      var calls = 0;
      await tester.pumpWidget(host(() => calls++));
      await tester.dragFrom(const Offset(10, 300), const Offset(30, 0));
      await tester.dragFrom(const Offset(10, 100), const Offset(80, 200));
      await tester.pump();
      expect(calls, 0);
    });
  });
}

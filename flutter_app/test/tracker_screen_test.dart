import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/providers/cells_provider.dart';
import 'package:dian_dian/providers/language_provider.dart';
import 'package:dian_dian/providers/legends_provider.dart';
import 'package:dian_dian/providers/pages_provider.dart';
import 'package:dian_dian/providers/premium_provider.dart';
import 'package:dian_dian/screens/tracker_screen.dart';
import 'package:dian_dian/services/ad_service.dart';
import 'package:dian_dian/services/api_service.dart';
import 'package:dian_dian/services/audio_service.dart';
import 'package:dian_dian/services/sync_service.dart';
import 'package:dian_dian/services/ws_service.dart';
import 'package:dian_dian/theme/motion.dart';
import 'package:dian_dian/widgets/press_scale.dart';
import 'package:dian_dian/widgets/swipe_nav.dart';
import 'package:dian_dian/widgets/tracker_grid.dart';

import 'helpers.dart';

/// Providers, a server that answers nothing, and a [TrackerScreen] on
/// tracker p0 for 2026 (its cells loaded, so no bootstrap request).
class TrackerHarness {
  late final Widget widget;

  TrackerHarness({TrackerEntrance entrance = TrackerEntrance.none, AudioService? audio}) {
    final client = MockClient((req) async => http.Response('{"error":"x"}', 404));
    final api = ApiService.custom(client: client, tokens: FakeTokens());
    final rows = [pageJson('p0', title: 'Mood')];
    final pages = PagesProvider(api: api)..applyBootstrap(rows);
    final legends = LegendsProvider(api: api)
      ..applyBootstrap({
        'p0': [
          {'id': 'l1', 'pageId': 'p0', 'color': '#FFEC99', 'label': 'Sport', 'position': 0, 'createdAt': ''},
        ],
      })
      ..setPageId('p0');
    // The same service as the screen's, as the app's singleton is.
    final cells = CellsProvider(api: api, audio: audio ?? AudioService.silent())
      ..applyBootstrap(2026, {'p0': <dynamic>[]})
      ..setContext(pageId: 'p0', year: 2026); // as the shell does before showing a tracker
    final sync = SyncService(
      api: api,
      pages: pages,
      cells: cells,
      legends: legends,
      ws: WsService(),
      snapshots: MemorySnapshots(),
      observeLifecycle: false,
    );
    widget = MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider.value(value: pages),
        ChangeNotifierProvider.value(value: cells),
        ChangeNotifierProvider.value(value: legends),
        ChangeNotifierProvider(create: (_) => PremiumProvider()),
        Provider<SyncService>.value(value: sync),
        if (audio != null) ChangeNotifierProvider<AudioService>.value(value: audio),
      ],
      child: MaterialApp(
        home: TrackerScreen(pageId: 'p0', initialYear: 2026, onBack: () {}, onOpenSettings: () {}, entrance: entrance),
      ),
    );
  }
}

/// The nearest fade over the first match of [of]: 1 when nothing fades it.
double opacityOver(WidgetTester tester, Finder of) => tester
    .widget<FadeTransition>(find.ancestor(of: of.first, matching: find.byType(FadeTransition)).first)
    .opacity
    .value;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AdService().disable();
  });

  // A day number (the grid's chrome); the sidebar's collapse chevron (its
  // year sits in a switcher with a fade of its own); the bar's back button.
  final grid = find.text('15');
  final sidebar = find.byIcon(Icons.chevron_left);
  final bar = find.text('<');
  final groups = {'grid': grid, 'sidebar': sidebar, 'bar': bar};

  testWidgets('arriving by the morph, the chrome is unseen until the handover, then comes in by groups', (tester) async {
    tabletPortrait(tester);
    // Clock from the first frame, the one the stage's morph starts on too.
    var elapsed = Duration.zero;
    Future<void> pumpTo(Duration target) async {
      await tester.pump(target - elapsed);
      elapsed = target;
    }

    final handover = AppMotion.screen * AppMotion.morphHandover;
    const frame = Duration(milliseconds: 16);
    await tester.pumpWidget(TrackerHarness(entrance: TrackerEntrance.morph).widget);
    for (final g in groups.entries) {
      expect(opacityOver(tester, g.value), 0, reason: '${g.key} on the first frame');
    }
    await pumpTo(handover - frame);
    for (final g in groups.entries) {
      expect(opacityOver(tester, g.value), 0, reason: '${g.key} just before the handover');
    }
    // Three staggers past the handover: the grid's chrome leads, the sidebar
    // follows a stagger behind, the bar another one behind — and is on its way.
    await pumpTo(handover + AppMotion.stagger * 3);
    final a = opacityOver(tester, grid);
    final b = opacityOver(tester, sidebar);
    final c = opacityOver(tester, bar);
    expect(a, greaterThan(b));
    expect(b, greaterThan(c));
    expect(c, greaterThan(0));
    // Each group is a short entrance: the last is over `quick` after it
    // started, two staggers past the handover.
    await pumpTo(handover + AppMotion.stagger * 2 + AppMotion.quick + frame);
    for (final g in groups.entries) {
      expect(opacityOver(tester, g.value), 1, reason: '${g.key} once the reveal is over');
    }
  });

  testWidgets('in landscape, the title\'s pencil sits on the title\'s line, to its right, not under it', (tester) async {
    landscape(tester);
    ignoreOverflowUnderTestFont(tester);
    await tester.pumpWidget(TrackerHarness().widget);
    await tester.pumpAndSettle();
    final title = tester.getRect(find.text('Mood').first);
    final pencil = find.byWidgetPredicate((w) => w is Icon && w.icon == Icons.edit && w.size == 14);
    expect(pencil, findsOneWidget);
    final p = tester.getRect(pencil);
    expect(p.left, greaterThanOrEqualTo(title.right), reason: 'to the right of the title');
    expect((p.center.dy - title.center.dy).abs(), lessThan(title.height / 2), reason: 'on the title\'s line');
  });

  testWidgets('without the morph, the chrome is there on the first frame', (tester) async {
    tabletPortrait(tester);
    await tester.pumpWidget(TrackerHarness().widget);
    for (final g in groups.entries) {
      expect(opacityOver(tester, g.value), 1, reason: g.key);
    }
  });

  testWidgets('under reduced motion, the chrome is there on the first frame', (tester) async {
    tabletPortrait(tester);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(TrackerHarness(entrance: TrackerEntrance.morph).widget);
    for (final g in groups.entries) {
      expect(opacityOver(tester, g.value), 1, reason: g.key);
    }
  });

  testWidgets('a year change after the reveal does not replay it', (tester) async {
    tabletPortrait(tester);
    await tester.pumpWidget(TrackerHarness(entrance: TrackerEntrance.morph).widget);
    await tester.pump(AppMotion.screen + AppMotion.base + AppMotion.stagger * 2);
    expect(opacityOver(tester, grid), 1);
    tester.widget<SwipeNav>(find.byType(SwipeNav).first).onNext();
    await tester.pump();
    // The slide is over, the new grid stands alone — and its labels are there
    // (a replay would still be in its handover delay).
    await tester.pump(AppMotion.base + const Duration(milliseconds: 50));
    expect(find.text('2027'), findsOneWidget);
    expect(opacityOver(tester, grid), 1);
  });

  testWidgets('a year change plays stepNext', (tester) async {
    tabletPortrait(tester);
    final rec = await recordingAudio();
    await tester.pumpWidget(TrackerHarness(audio: rec.service).widget);
    tester.widget<SwipeNav>(find.byType(SwipeNav).first).onNext();
    await tester.pump();
    expect(rec.players.played, [SoundCue.stepNext]);
    await tester.pump(AppMotion.base + const Duration(milliseconds: 50));
  });

  testWidgets('the side panel arrow plays panelClose when folding and panelOpen when unfolding', (tester) async {
    tabletPortrait(tester);
    final rec = await recordingAudio();
    await tester.pumpWidget(TrackerHarness(audio: rec.service).widget);
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(rec.players.played, [SoundCue.panelClose]);
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(rec.players.played, [SoundCue.panelClose, SoundCue.panelOpen]);
  });

  testWidgets('picking a legend as the brush plays select', (tester) async {
    tabletPortrait(tester);
    final rec = await recordingAudio();
    await tester.pumpWidget(TrackerHarness(audio: rec.service).widget);
    await tester.tap(find.text('Sport'));
    await tester.pump();
    expect(rec.players.played, [SoundCue.select]);
  });

  testWidgets('in the cell editor, choosing a legend plays select after the dialog opened', (tester) async {
    tabletPortrait(tester);
    final rec = await recordingAudio();
    await tester.pumpWidget(TrackerHarness(audio: rec.service).widget);
    await tester.tap(find.descendant(of: find.byType(TrackerGrid), matching: find.byType(GestureDetector)).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sport').last);
    await tester.pump();
    expect(rec.players.played, [SoundCue.dialogOpen, SoundCue.select]);
  });

  testWidgets('in the cell editor, the day arrows play stepNext and stepPrev, like the year arrows', (tester) async {
    tabletPortrait(tester);
    final rec = await recordingAudio();
    await tester.pumpWidget(TrackerHarness(audio: rec.service).widget);
    await tester.tap(find.descendant(of: find.byType(TrackerGrid), matching: find.byType(GestureDetector)).first);
    await tester.pumpAndSettle();
    final nav = find.byType(SwipeNav).last; // the sidebar has the year's, the dialog the day's
    tester.widget<SwipeNav>(nav).onNext();
    await tester.pump();
    tester.widget<SwipeNav>(nav).onPrev();
    await tester.pump();
    expect(rec.players.played, [SoundCue.dialogOpen, SoundCue.stepNext, SoundCue.stepPrev]);
  });

  testWidgets('saving a cell from the editor plays the fill, not the close that follows the server', (tester) async {
    tabletPortrait(tester);
    final rec = await recordingAudio();
    await tester.pumpWidget(TrackerHarness(audio: rec.service).widget);
    await tester.tap(find.descendant(of: find.byType(TrackerGrid), matching: find.byType(GestureDetector)).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sport').last);
    await tester.pump();
    await tester.tap(find.widgetWithText(PressScale, 'OK'));
    await tester.pumpAndSettle();
    expect(find.text('OK'), findsNothing, reason: 'the editor closed');
    expect(rec.players.played, [SoundCue.dialogOpen, SoundCue.select, SoundCue.dotFill]);
  });
}

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
import 'package:dian_dian/screens/page_list_screen.dart';
import 'package:dian_dian/services/ad_service.dart';
import 'package:dian_dian/services/api_service.dart';
import 'package:dian_dian/services/audio_service.dart';
import 'package:dian_dian/services/sync_service.dart';
import 'package:dian_dian/services/ws_service.dart';
import 'package:dian_dian/widgets/press_scale.dart';

import 'helpers.dart';

/// Providers, a server that answers nothing, and a [PageListScreen] with
/// [pageCount] trackers (cells of 2026 loaded, so no bootstrap request).
class ListHarness {
  late final PagesProvider pages;
  late final CellsProvider cells;
  late final LegendsProvider legends;
  late final PremiumProvider premium;
  late final SyncService sync;
  final selected = <String>[];
  late final Widget widget;

  ListHarness({int pageCount = 2, bool vip = false, String? revealPageId, AudioService? audio}) {
    final client = MockClient((req) async => http.Response('{"error":"x"}', 404));
    final api = ApiService.custom(client: client, tokens: FakeTokens());
    final rows = [for (var i = 0; i < pageCount; i++) pageJson('p$i', position: i, title: 'T$i')];
    pages = PagesProvider(api: api)..applyBootstrap(rows);
    legends = LegendsProvider(api: api)..applyBootstrap({});
    cells = CellsProvider(api: api, audio: AudioService.silent())
      ..applyBootstrap(2026, {for (final r in rows) r['id'] as String: <dynamic>[]});
    premium = PremiumProvider();
    if (vip) premium.setVip(true);
    sync = SyncService(
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
        ChangeNotifierProvider.value(value: premium),
        Provider<SyncService>.value(value: sync),
        if (audio != null) ChangeNotifierProvider<AudioService>.value(value: audio),
      ],
      child: MaterialApp(
        home: PageListScreen(
          selectedYear: 2026,
          onYearChanged: (_) {},
          onSelectPage: (id, _) => selected.add(id),
          onOpenSettings: () {},
          revealPageId: revealPageId,
          entrance: ListEntrance.none,
        ),
      ),
    );
  }
}

/// The grid's own scroll position (the first Scrollable under it; the card
/// titles have marquee scrollables of their own).
ScrollPosition gridPosition(WidgetTester tester) =>
    tester.state<ScrollableState>(find.descendant(of: find.byType(GridView), matching: find.byType(Scrollable)).first).position;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AdService().disable();
  });

  testWidgets('a year change keeps where the list was scrolled', (tester) async {
    phone(tester);
    final h = ListHarness(pageCount: 10, vip: true);
    await tester.pumpWidget(h.widget);
    await tester.pumpAndSettle();
    expect(gridPosition(tester).maxScrollExtent, greaterThan(300));
    await tester.drag(find.byType(GridView), const Offset(0, -500));
    await tester.pumpAndSettle();
    final before = gridPosition(tester).pixels;
    expect(before, greaterThan(100));
    await tester.tap(find.text('>'));
    await tester.pumpAndSettle();
    expect(gridPosition(tester).pixels, closeTo(before, 1));
  });

  testWidgets('a confirmed deletion is committed even if the list unmounts during the shrink', (tester) async {
    final h = ListHarness();
    await tester.pumpWidget(h.widget);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PressScale, 'Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50)); // mid-shrink
    await tester.pumpWidget(const SizedBox()); // the list goes away
    await tester.pump(const Duration(milliseconds: 300));
    expect(h.pages.pendingDeletePage?.id, 'p0');
    expect(h.pages.pages.map((p) => p.id), ['p1']);
    h.pages.undoDeletePage(); // stops the 8 s undo timer before the test ends
  });

  testWidgets('a tap on a card that is shrinking away opens nothing', (tester) async {
    final h = ListHarness();
    await tester.pumpWidget(h.widget);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PressScale, 'Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byType(PageCard).first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(h.selected, isEmpty);
    expect(h.pages.pages.map((p) => p.id), ['p1']);
    h.pages.undoDeletePage(); // stops the 8 s undo timer before the test ends
  });

  testWidgets('confirming a deletion plays trackerDelete alone: not the dialog\'s close, not the button\'s tic', (tester) async {
    final rec = await recordingAudio();
    final h = ListHarness(audio: rec.service);
    await tester.pumpWidget(h.widget);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();
    expect(rec.players.played, [SoundCue.dialogOpen]);
    await tester.tap(find.widgetWithText(PressScale, 'Delete'));
    await tester.pumpAndSettle();
    expect(rec.players.played, [SoundCue.dialogOpen, SoundCue.trackerDelete]);
    h.pages.undoDeletePage(); // stops the 8 s undo timer before the test ends
  });

  testWidgets('dragging a card onto another plays dragPick, dragHover and dragDrop', (tester) async {
    phone(tester);
    final rec = await recordingAudio();
    final h = ListHarness(pageCount: 3, audio: rec.service);
    await tester.pumpWidget(h.widget);
    await tester.pumpAndSettle();
    final handle = find.byType(Draggable<int>).first;
    final target = tester.getCenter(find.byType(PageCard).at(1));
    await tester.drag(handle, target - tester.getCenter(handle));
    await tester.pumpAndSettle();
    expect(rec.players.played.first, SoundCue.dragPick);
    expect(rec.players.played, contains(SoundCue.dragHover));
    expect(rec.players.played.last, SoundCue.dragDrop);
  });

  testWidgets('the new-tracker dialog shows at once and focuses its field only once its entrance is over', (tester) async {
    phone(tester);
    final h = ListHarness();
    await tester.pumpWidget(h.widget);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50)); // mid-entrance
    bool fieldFocused() => tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus;
    expect(find.byType(TextField), findsOneWidget);
    expect(fieldFocused(), isFalse, reason: 'the keyboard must not load while the dialog is still appearing');
    await tester.pumpAndSettle();
    expect(fieldFocused(), isTrue);
  });
}

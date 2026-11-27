import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/providers/cells_provider.dart';
import 'package:dian_dian/providers/language_provider.dart';
import 'package:dian_dian/providers/legends_provider.dart';
import 'package:dian_dian/providers/pages_provider.dart';
import 'package:dian_dian/screens/first_tracker_screen.dart';
import 'package:dian_dian/services/audio_service.dart';

import 'helpers.dart';

/// Providers writing to a [RecordingSink] around a [FirstTrackerScreen].
class Harness {
  final sink = RecordingSink();
  late final PagesProvider pages;
  late final LegendsProvider legends;
  late final CellsProvider cells;
  late final Widget widget;

  Harness({
    required DateTime Function() now,
    VoidCallback? onLater,
    void Function(String pageId, int year)? onOpen,
    List<Map<String, dynamic>> pageRows = const [],
    Map<String, dynamic> legendRows = const {},
    int maxTrackers = 3,
  }) {
    pages = PagesProvider(audio: AudioService.silent(), sink: sink)..applyBootstrap(pageRows);
    legends = LegendsProvider(audio: AudioService.silent(), sink: sink)..applyBootstrap(legendRows);
    cells = CellsProvider(audio: AudioService.silent(), sink: sink)
      ..applyBootstrap(now().year, {for (final p in pageRows) p['id'] as String: <dynamic>[]});
    widget = MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider.value(value: pages),
        ChangeNotifierProvider.value(value: legends),
        ChangeNotifierProvider.value(value: cells),
      ],
      child: MaterialApp(
        home: FirstTrackerScreen(
          userId: 'u1',
          maxTrackers: maxTrackers,
          now: now,
          onLater: onLater ?? () {},
          onOpenTracker: onOpen ?? (_, _) {},
        ),
      ),
    );
  }

  List<Map<String, dynamic>> of(String kind) => [for (final c in sink.changes) if (c.$1 == kind) c.$2];
  List<Map<String, dynamic>> get creations => of('page.create');
  List<Map<String, dynamic>> get days => of('cell.set');
  String get createdId => creations.single['id'] as String;
}

final _uuidV4 = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

/// A phone-sized surface (390 × 844 logical): the default 800 × 600 test
/// window puts the lower buttons of screen 2 below the fold.
void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final oct15 = DateTime(2026, 10, 15, 9);

  testWidgets('Mood → Great creates the page with five legends and sets today\'s cell', (tester) async {
    phone(tester);
    final h = Harness(now: () => oct15);
    await tester.pumpWidget(h.widget);
    await tester.pump();
    expect(find.text('What do you want to track?'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);

    await tester.tap(find.text('Mood'));
    await tester.pumpAndSettle();
    expect(find.text('Thursday, October 15'), findsOneWidget);
    expect(find.text('And today?'), findsOneWidget);
    expect(find.text('Not today'), findsOneWidget);
    expect(h.sink.changes, isEmpty, reason: 'nothing is created before a choice');

    await tester.tap(find.text('Great'));
    await tester.pumpAndSettle();

    final body = h.creations.single;
    expect(body['title'], 'Mood');
    expect(h.createdId, matches(_uuidV4), reason: 'the app makes the id');
    expect((body['legends'] as List).map((l) => l['label']), ['Great', 'Good', 'Okay', 'Meh', 'Low']);
    expect(h.sink.kinds, ['page.create', 'cell.set'], reason: 'the tracker, then its day');
    expect(h.days.single, {'pageId': h.createdId, 'year': 2026, 'month': 10, 'day': 15, 'color': '#FFEC99', 'comment': null});
    expect(h.legends.legendsFor(h.createdId).length, 5);
    expect(h.cells.getCell(10, 15)!.color, '#FFEC99');
    expect(find.text('Open my tracker'), findsOneWidget);
    expect(find.text('Not today'), findsNothing);
    expect((await SharedPreferences.getInstance()).getBool('first_tracker_done_u1'), isTrue);
  });

  testWidgets('Open my tracker hands the created page and the current year to the parent', (tester) async {
    phone(tester);
    String? opened;
    final h = Harness(now: () => oct15, onOpen: (id, year) => opened = '$id/$year');
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Mood'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Great'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open my tracker'));
    await tester.pump();
    expect(opened, '${h.createdId}/2026');
  });

  testWidgets('a copy that could not be written still makes the tracker and today\'s colour (nothing to retry)', (tester) async {
    phone(tester);
    final h = Harness(now: () => oct15);
    h.sink.fail = true;
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Mood'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Great'));
    await tester.pumpAndSettle();
    expect(h.pages.pages.length, 1);
    expect(h.cells.getCell(10, 15)!.color, '#FFEC99');
    expect(find.text("Can't reach the server, try again"), findsNothing);
    expect(find.text('Open my tracker'), findsOneWidget);
  });

  testWidgets('the date is read at tap time (midnight while the screen is open)', (tester) async {
    phone(tester);
    var clock = DateTime(2026, 10, 15, 23, 59);
    final h = Harness(now: () => clock);
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Mood'));
    await tester.pumpAndSettle();
    expect(find.text('Thursday, October 15'), findsOneWidget);

    clock = DateTime(2026, 10, 16, 0, 1);
    await tester.tap(find.text('Great'));
    await tester.pumpAndSettle();
    expect(h.days.single, {'pageId': h.createdId, 'year': 2026, 'month': 10, 'day': 16, 'color': '#FFEC99', 'comment': null});
    expect(find.text('Friday, October 16'), findsOneWidget);
  });

  testWidgets('Other… needs a non-blank title before continuing', (tester) async {
    phone(tester);
    final h = Harness(now: () => oct15);
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Other…'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('And today?'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Water');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Water'), findsOneWidget);
    expect(find.text('Yes'), findsOneWidget);
    expect(find.text('A little'), findsOneWidget);
    expect(find.text('No'), findsOneWidget);

    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(h.creations.single['title'], 'Water');
  });

  testWidgets('Not today creates the tracker without a cell and opens it', (tester) async {
    phone(tester);
    String? opened;
    final h = Harness(now: () => oct15, onOpen: (id, year) => opened = '$id/$year');
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Sleep'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not today'));
    await tester.pumpAndSettle();
    expect(h.sink.kinds, ['page.create']);
    expect(opened, '${h.createdId}/2026');
    expect((await SharedPreferences.getInstance()).getBool('first_tracker_done_u1'), isTrue);
  });

  testWidgets('a dormant account\'s empty page is replaced, not doubled', (tester) async {
    phone(tester);
    final h = Harness(
      now: () => oct15,
      pageRows: [pageJson('old', title: 'My Tracker')],
      legendRows: {'old': <dynamic>[]},
    );
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Habits'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(h.sink.kinds, ['page.delete', 'page.create', 'pages.reorder', 'cell.set']);
    expect(h.of('page.delete').single, {'id': 'old'});
    expect(h.pages.pages.map((p) => p.id), [h.createdId]);
  });

  testWidgets('Later leaves without a request and is remembered for this account on this device', (tester) async {
    phone(tester);
    var later = false;
    final h = Harness(now: () => oct15, onLater: () => later = true);
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(later, isTrue);
    expect(h.sink.changes, isEmpty);
    expect((await SharedPreferences.getInstance()).getBool('first_tracker_done_u1'), isTrue);
    expect(await FirstTrackerScreen.isDone('u1'), isTrue);
    expect(await FirstTrackerScreen.isDone('u2'), isFalse);
  });

  testWidgets('at the free limit, the empty tracker is replaced in its place: still three trackers', (tester) async {
    phone(tester);
    final h = Harness(
      now: () => oct15,
      pageRows: [pageJson('old', title: 'My Tracker'), pageJson('p2', position: 1), pageJson('p3', position: 2)],
      legendRows: {
        'old': <dynamic>[],
        'p2': [legendJson('l2', 'p2', '#111111', 0)],
        'p3': [legendJson('l3', 'p3', '#222222', 0)],
      },
      maxTrackers: 3,
    );
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Habits'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(h.pages.pages.map((p) => p.id), [h.createdId, 'p2', 'p3']);
    expect(h.of('pages.reorder').single, {'ids': [h.createdId, 'p2', 'p3']});
    expect(find.text('Open my tracker'), findsOneWidget);
  });

  testWidgets('a custom title is capped at 35 UTF-16 units, like the server', (tester) async {
    phone(tester);
    final h = Harness(now: () => oct15);
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Other…'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '😀' * 18); // 36 units: refused as a whole
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '');
    await tester.enterText(find.byType(TextField), '😀' * 17); // 34 units: fine
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('And today?'), findsOneWidget);
  });

  testWidgets('tappable controls are announced as buttons', (tester) async {
    phone(tester);
    final handle = tester.ensureSemantics();
    final h = Harness(now: () => oct15);
    await tester.pumpWidget(h.widget);
    expect(tester.getSemantics(find.text('Later')), isSemantics(isButton: true, hasTapAction: true, label: 'Later'));
    expect(tester.getSemantics(find.text('Mood')), isSemantics(isButton: true, hasTapAction: true, label: 'Mood'));
    await tester.tap(find.text('Mood'));
    await tester.pumpAndSettle();
    expect(tester.getSemantics(find.text('Great')), isSemantics(isButton: true, hasTapAction: true, label: 'Great'));
    expect(tester.getSemantics(find.text('Not today')), isSemantics(isButton: true, hasTapAction: true, label: 'Not today'));
    await tester.tap(find.text('Great'));
    await tester.pumpAndSettle();
    expect(tester.getSemantics(find.text('Open my tracker')), isSemantics(isButton: true, hasTapAction: true, label: 'Open my tracker'));
    handle.dispose();
  });

  testWidgets('screen 2 teaches renaming: tap the title, type, and the new title is used at creation', (tester) async {
    phone(tester);
    final h = Harness(now: () => oct15);
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Mood'));
    await tester.pumpAndSettle();
    expect(find.text('Tap the title to rename it, here and in the tracker.'), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsOneWidget, reason: 'a pencil next to the title');

    await tester.tap(find.text('Mood'));
    await tester.pumpAndSettle();
    final field = find.byKey(const Key('firstTracker.title'));
    expect(field, findsOneWidget);
    expect(tester.widget<TextField>(field).controller!.text, 'Mood');
    await tester.enterText(field, 'Vibes');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('firstTracker.title')), findsNothing);
    expect(find.text('Vibes'), findsOneWidget);

    await tester.tap(find.text('Great'));
    await tester.pumpAndSettle();
    expect(h.creations.single['title'], 'Vibes');
    expect(h.of('page.update'), isEmpty);
  });

  testWidgets('renaming after the page exists writes its new title', (tester) async {
    phone(tester);
    final h = Harness(now: () => oct15);
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Sleep'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('8 h+'));
    await tester.pumpAndSettle();
    expect(h.creations.length, 1);

    await tester.tap(find.text('Sleep'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('firstTracker.title')), 'Nights');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(h.of('page.update').single, {'id': h.createdId, 'title': 'Nights'});
    expect(h.pages.pages.single.title, 'Nights');
    expect(find.text('Nights'), findsOneWidget);
  });

  testWidgets('a blank rename keeps the previous title', (tester) async {
    phone(tester);
    final h = Harness(now: () => oct15);
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('Mood'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mood'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('firstTracker.title')), '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Mood'), findsOneWidget);
  });
}

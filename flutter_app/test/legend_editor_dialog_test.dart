import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/providers/cells_provider.dart';
import 'package:dian_dian/providers/language_provider.dart';
import 'package:dian_dian/providers/legends_provider.dart';
import 'package:dian_dian/services/api_service.dart';
import 'package:dian_dian/services/audio_service.dart';
import 'package:dian_dian/widgets/legend_editor_dialog.dart';

import 'helpers.dart';

http.Response _json(String body, int status) =>
    http.Response(body, status, headers: const {'content-type': 'application/json; charset=utf-8'});

class Harness {
  final List<http.Request> requests = [];
  late final LegendsProvider legends;
  late final CellsProvider cells;
  late final Widget widget;

  Harness() {
    final client = MockClient((req) async {
      requests.add(req);
      if (req.method == 'PATCH' && req.url.path.startsWith('/api/legends/')) {
        final id = req.url.pathSegments.last;
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        final current = legends.legendsFor('p').firstWhere((l) => l.id == id);
        return _json(jsonEncode({
          'id': id, 'pageId': 'p', 'position': current.position, 'createdAt': '',
          'color': body['color'] ?? current.color,
          'label': body['label'] ?? current.label,
        }), 200);
      }
      if (req.method == 'PATCH' && req.url.path == '/api/cells/p/recolor') return _json('{"ok":true}', 200);
      if (req.method == 'PUT' && req.url.path == '/api/legends/p/reorder') return _json('{"ok":true}', 200);
      return _json('{"error":"unexpected ${req.method} ${req.url.path}"}', 404);
    });
    final api = ApiService.custom(client: client, tokens: FakeTokens());
    legends = LegendsProvider(api: api)
      ..applyBootstrap({
        'p': [legendJson('l1', 'p', '#FFEC99', 0, label: 'Great'), legendJson('l2', 'p', '#FFD43B', 1, label: 'Good')],
      })
      ..setPageId('p');
    cells = CellsProvider(api: api, audio: AudioService.silent())
      ..applyBootstrap(2026, {'p': [[1, 1, '#FFEC99']]})
      ..setContext(pageId: 'p', year: 2026);
    widget = MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider.value(value: legends),
        ChangeNotifierProvider.value(value: cells),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => LegendEditorDialog.show(context, pageId: 'p'),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  List<http.Request> get patches => requests.where((r) => r.method == 'PATCH').toList();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<Harness> open(WidgetTester tester) async {
    final h = Harness();
    await tester.pumpWidget(h.widget);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return h;
  }

  testWidgets('the list has no inline label editing: one field only, the add field', (tester) async {
    await open(tester);
    expect(find.text('Great'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byKey(const Key('legend.editLabel')), findsNothing);
  });

  testWidgets('tapping a legend shows only its label field and the picker', (tester) async {
    final h = await open(tester);
    await tester.tap(find.text('Great'));
    await tester.pumpAndSettle();
    final field = find.byKey(const Key('legend.editLabel'));
    expect(field, findsOneWidget);
    expect(tester.widget<TextField>(field).controller!.text, 'Great');
    expect(find.byType(TextField), findsOneWidget, reason: 'the add field is gone');
    expect(find.text('Good'), findsNothing, reason: 'the list is gone');
    expect(find.text('Pick a color'), findsOneWidget);
    expect(h.patches, isEmpty);
  });

  testWidgets('a palette tap recolors the legend and its cells, staying in the editor', (tester) async {
    final h = await open(tester);
    await tester.tap(find.text('Great'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('palette.0,3')));
    await tester.pumpAndSettle();
    expect(h.patches.map((r) => r.url.path), ['/api/legends/l1', '/api/cells/p/recolor']);
    expect(jsonDecode(h.patches[0].body), {'color': '#E6F4EA'});
    expect(jsonDecode(h.patches[1].body), {'colorMap': {'#FFEC99': '#E6F4EA'}});
    expect(h.legends.legendsFor('p').first.color, '#E6F4EA');
    expect(h.cells.getCell(1, 1)!.color, '#E6F4EA');
    expect(find.byKey(const Key('legend.editLabel')), findsOneWidget, reason: 'still editing');
  });

  testWidgets('OK saves the new label and returns to the list', (tester) async {
    final h = await open(tester);
    await tester.tap(find.text('Great'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('legend.editLabel')), 'Superb');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(h.patches.single.url.path, '/api/legends/l1');
    expect(jsonDecode(h.patches.single.body), {'label': 'Superb'});
    expect(find.text('Superb'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget, reason: 'back on the list');
    expect(find.byKey(const Key('legend.editLabel')), findsNothing);
  });

  testWidgets('OK with an unchanged or blank label sends nothing', (tester) async {
    final h = await open(tester);
    await tester.tap(find.text('Great'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('legend.editLabel')), '   ');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(h.patches, isEmpty);
    expect(find.text('Great'), findsOneWidget, reason: 'label kept');
  });

  testWidgets('the handle and the cross do not open the editor', (tester) async {
    await open(tester);
    await tester.tap(find.byIcon(Icons.drag_handle).first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('legend.editLabel')), findsNothing, reason: 'handle: nothing');
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('legend.editLabel')), findsNothing, reason: 'cross: delete, not edit');
    expect(find.text('Delete'), findsWidgets, reason: 'the delete confirmation is up');
  });

  testWidgets('dragging the handle reorders at once, no long press needed', (tester) async {
    await open(tester);
    final handle = tester.getCenter(find.byIcon(Icons.drag_handle).first);
    final gesture = await tester.startGesture(handle);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    expect(find.text('≡'), findsOneWidget, reason: 'the chip follows the finger');
    expect(
      tester.widget<Opacity>(find.ancestor(of: find.text('Great'), matching: find.byType(Opacity)).first).opacity,
      0.3,
      reason: 'the dragged row is the ghost',
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('≡'), findsNothing);
    expect(find.byKey(const Key('legend.editLabel')), findsNothing);
  });

  testWidgets('dropping the handle on another legend reorders (PUT reorder with the new ids)', (tester) async {
    final h = await open(tester);
    final handle = tester.getCenter(find.byIcon(Icons.drag_handle).first);
    final target = tester.getCenter(find.text('Good'));
    final gesture = await tester.startGesture(handle);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(target);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    final put = h.requests.where((r) => r.method == 'PUT').single;
    expect(put.url.path, '/api/legends/p/reorder');
    expect(jsonDecode(put.body), {'ids': ['l2', 'l1']});
  });

  testWidgets('a handle drag dropped back where it started leaves the row normal, not greyed', (tester) async {
    await open(tester);
    double opacityOf(String label) =>
        tester.widget<Opacity>(find.ancestor(of: find.text(label), matching: find.byType(Opacity)).first).opacity;
    final handle = tester.getCenter(find.byIcon(Icons.drag_handle).at(1)); // "Good"
    final gesture = await tester.startGesture(handle);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveBy(const Offset(0, 30));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -30));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Good'), findsOneWidget);
    expect(opacityOf('Good'), 1.0, reason: 'the ghost style must go away when the drag ends');
  });
}

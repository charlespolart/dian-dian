import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dian_dian/models/year_cells.dart';
import 'package:dian_dian/providers/cells_provider.dart';
import 'package:dian_dian/providers/language_provider.dart';
import 'package:dian_dian/providers/pages_provider.dart';
import 'package:dian_dian/services/audio_service.dart';
import 'package:dian_dian/widgets/global_stats_dialog.dart';

import 'helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('"all time" counts every year of the phone\'s copy, without asking the server', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final pages = PagesProvider(audio: AudioService.silent())
      ..applyBootstrap([pageJson('a', title: 'Mood'), pageJson('b', title: 'Sleep', position: 1)]);
    final cells = CellsProvider(audio: AudioService.silent())
      ..applyCopy({
        'a': {
          2024: YearCells.fromCompact('a', 2024, [[3, 1, '#AAAAAA'], [3, 2, '#AAAAAA'], [3, 3, '#AAAAAA'], [3, 4, '#AAAAAA']]),
          2026: YearCells.fromCompact('a', 2026, [[1, 1, '#AAAAAA']]),
        },
        'b': {2026: YearCells.fromCompact('b', 2026, [[2, 1, '#AAAAAA'], [2, 3, '#AAAAAA']])},
      });
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider.value(value: pages),
        ChangeNotifierProvider.value(value: cells),
      ],
      child: const MaterialApp(home: Scaffold(body: GlobalStatsDialog(year: 2026))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('7'), findsNothing, reason: 'this year: 3 days');
    expect(find.text('3'), findsWidgets);

    await tester.tap(find.text('All time'));
    await tester.pumpAndSettle();
    expect(find.text('7'), findsOneWidget, reason: '4 days of 2024 + 3 of 2026, all on the phone');
    expect(find.text('4'), findsWidgets, reason: 'the best streak, in 2024');
  });
}

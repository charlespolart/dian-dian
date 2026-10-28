import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/widgets/undo_delete_bar.dart';

void main() {
  testWidgets(
    'the undo bar, shown beside the screens under no Scaffold, never inherits the MaterialApp fallback style (the yellow double underline)',
    (tester) async {
      // The real tree: the bar is a sibling of the stage in the shell's Stack.
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: UndoDeleteBar(
                  pageName: 'Mood',
                  onUndo: () {},
                  duration: const Duration(seconds: 8),
                ),
              ),
            ],
          ),
        ),
      );
      final riches = tester.widgetList<RichText>(
        find.descendant(
          of: find.byType(UndoDeleteBar),
          matching: find.byType(RichText),
        ),
      );
      expect(riches.length, 2, reason: 'the label and the Undo button');
      for (final rich in riches) {
        final style = rich.text.style!;
        expect(
          style.decoration,
          TextDecoration.none,
          reason: rich.text.toPlainText(),
        );
        expect(style.debugLabel ?? '', isNot(contains('fallback')));
      }
    },
  );
}

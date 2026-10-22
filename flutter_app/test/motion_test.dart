import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/theme/motion.dart';

void main() {
  testWidgets('AppMotion.of is the duration normally and zero when the system reduces animations', (tester) async {
    late Duration normal;
    late Duration reduced;
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(),
      child: Builder(builder: (context) {
        normal = AppMotion.of(context, AppMotion.base);
        return const SizedBox();
      }),
    ));
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Builder(builder: (context) {
        reduced = AppMotion.of(context, AppMotion.base);
        return const SizedBox();
      }),
    ));
    expect(normal, AppMotion.base);
    expect(reduced, Duration.zero);
  });

  test('an entrance lasts longer than its exit', () {
    expect(AppMotion.base > AppMotion.quick, isTrue);
    expect(AppMotion.screen > AppMotion.base, isTrue);
  });
}

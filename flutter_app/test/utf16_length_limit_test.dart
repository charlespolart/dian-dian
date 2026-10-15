import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/widgets/utf16_length_limit.dart';

TextEditingValue v(String s) => TextEditingValue(text: s, selection: TextSelection.collapsed(offset: s.length));

void main() {
  final limit = Utf16LengthLimit(35);

  test('accepts up to 35 UTF-16 code units', () {
    final thirtyFive = 'a' * 35;
    expect(limit.formatEditUpdate(v(''), v(thirtyFive)).text, thirtyFive);
  });

  test('rejects an edit that exceeds 35 UTF-16 code units, keeping the old value', () {
    expect(limit.formatEditUpdate(v('abc'), v('a' * 36)).text, 'abc');
  });

  test('counts emoji the way the server does (2 units each), not as one character', () {
    final eighteenEmoji = '😀' * 18; // 36 UTF-16 units, 18 characters
    expect(eighteenEmoji.characters.length, 18);
    expect(limit.formatEditUpdate(v(''), v(eighteenEmoji)).text, '');
    final seventeenEmoji = '😀' * 17; // 34 units
    expect(limit.formatEditUpdate(v(''), v(seventeenEmoji)).text, seventeenEmoji);
  });
}

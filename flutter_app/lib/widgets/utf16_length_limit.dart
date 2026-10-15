import 'package:flutter/services.dart';

/// Caps a field at [max] UTF-16 code units — what the server's zod `.max()`
/// and Dart's `String.length` count — rather than at [max] characters like
/// `TextField.maxLength` (grapheme clusters: 18 emoji would pass a "35
/// character" field and be refused by the server as 36 units).
class Utf16LengthLimit extends TextInputFormatter {
  final int max;
  const Utf16LengthLimit(this.max);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.text.length > max ? oldValue : newValue;
}

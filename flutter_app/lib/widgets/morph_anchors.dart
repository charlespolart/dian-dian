import 'package:flutter/widgets.dart';

/// The rectangles the card → tracker morph animates between: one key per
/// tracker card in the list (on the card inside the grid only, never on a
/// drag copy) and one on the tracker's book shell. Owned by `AppShell`, which
/// hands it to both screens. Only one list and one tracker live in the stage
/// at a time, so no key is ever mounted twice.
class MorphAnchors {
  final GlobalKey shell = GlobalKey(debugLabel: 'tracker shell');
  final Map<String, GlobalKey> _cards = {};

  GlobalKey cardKey(String pageId) => _cards.putIfAbsent(pageId, () => GlobalKey(debugLabel: 'card $pageId'));

  /// The card's rect in [ancestor]'s coordinates (global without one); null
  /// when the card is not laid out (off screen, deleted, list not shown).
  Rect? cardRect(String pageId, {RenderBox? ancestor}) => rectOf(_cards[pageId], ancestor: ancestor);

  Rect? shellRect({RenderBox? ancestor}) => rectOf(shell, ancestor: ancestor);

  static Rect? rectOf(GlobalKey? key, {RenderBox? ancestor}) {
    final box = key?.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero, ancestor: ancestor) & box.size;
  }
}

import 'package:flutter/widgets.dart';

/// The rectangles the card → tracker morph animates between: one anchor per
/// tracker card in the list (on the card inside the grid only, never on a
/// drag copy) and one on the tracker's book shell. Owned by `AppShell`, which
/// hands it to both screens.
///
/// Anchors are registered by [MorphAnchor] while it is mounted, not held by
/// `GlobalKey`s: the list's year slide keeps two grids alive for 220 ms and
/// both carry the same cards, which a `GlobalKey` would refuse. The newest
/// registration wins, and a registration is only dropped by its own owner.
class MorphAnchors {
  final Map<String, BuildContext> _cards = {};
  BuildContext? _shell;

  void registerCard(String pageId, BuildContext context) => _cards[pageId] = context;

  void unregisterCard(String pageId, BuildContext context) {
    if (identical(_cards[pageId], context)) _cards.remove(pageId);
  }

  void registerShell(BuildContext context) => _shell = context;

  void unregisterShell(BuildContext context) {
    if (identical(_shell, context)) _shell = null;
  }

  /// The card's rect in [ancestor]'s coordinates (global without one); null
  /// when the card is not laid out (off screen, deleted, list not shown).
  Rect? cardRect(String pageId, {RenderBox? ancestor}) => rectOf(_cards[pageId], ancestor: ancestor);

  Rect? shellRect({RenderBox? ancestor}) => rectOf(_shell, ancestor: ancestor);

  static Rect? rectOf(BuildContext? context, {RenderBox? ancestor}) {
    if (context == null || !context.mounted) return null;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero, ancestor: ancestor) & box.size;
  }
}

/// Registers its child's render box with [anchors] while mounted: as the
/// card of [pageId], or as the tracker shell.
class MorphAnchor extends StatefulWidget {
  final MorphAnchors anchors;
  final String? pageId;
  final Widget child;

  const MorphAnchor.card({super.key, required this.anchors, required this.pageId, required this.child});

  const MorphAnchor.shell({super.key, required this.anchors, required this.child}) : pageId = null;

  @override
  State<MorphAnchor> createState() => _MorphAnchorState();
}

class _MorphAnchorState extends State<MorphAnchor> {
  void _register() {
    final id = widget.pageId;
    if (id == null) {
      widget.anchors.registerShell(context);
    } else {
      widget.anchors.registerCard(id, context);
    }
  }

  void _unregister(MorphAnchor from) {
    final id = from.pageId;
    if (id == null) {
      from.anchors.unregisterShell(context);
    } else {
      from.anchors.unregisterCard(id, context);
    }
  }

  @override
  void initState() {
    super.initState();
    _register();
  }

  @override
  void didUpdateWidget(MorphAnchor old) {
    super.didUpdateWidget(old);
    if (old.pageId != widget.pageId || !identical(old.anchors, widget.anchors)) {
      _unregister(old);
      _register();
    }
  }

  @override
  void dispose() {
    _unregister(widget);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

import 'package:flutter/widgets.dart';

import 'grid_geometry.dart';

/// The rectangles the card → tracker morph animates between, registered by
/// [MorphAnchor] widgets while they are mounted and read by key. Owned by
/// `AppShell`, which hands it to both screens.
///
/// Registration, not `GlobalKey`s: the list's year slide keeps two grids
/// alive for 220 ms and both carry the same cards, which a `GlobalKey` would
/// refuse. The newest registration wins, and one is only dropped by its own
/// owner.
class MorphAnchors {
  // Tracker side.
  static const shell = 'shell';
  static const screen = 'screen';
  static const grid = 'grid';
  static const barTitle = 'barTitle';

  // Card side, per page.
  static String card(String pageId) => 'card:$pageId';
  static String cardScreen(String pageId) => 'cardScreen:$pageId';
  static String cardGrid(String pageId) => 'cardGrid:$pageId';
  static String cardTitle(String pageId) => 'cardTitle:$pageId';
  static String cardLegends(String pageId) => 'cardLegends:$pageId';

  final Map<String, BuildContext> _contexts = {};
  TrackerGridGeometry? _gridGeometry;

  void register(String key, BuildContext context) => _contexts[key] = context;

  void unregister(String key, BuildContext context) {
    if (identical(_contexts[key], context)) _contexts.remove(key);
  }

  void registerGrid(BuildContext context, TrackerGridGeometry geometry) {
    _contexts[grid] = context;
    _gridGeometry = geometry;
  }

  void unregisterGrid(BuildContext context) {
    if (identical(_contexts[grid], context)) {
      _contexts.remove(grid);
      _gridGeometry = null;
    }
  }

  /// The layout of the mounted tracker grid, or null.
  TrackerGridGeometry? get gridGeometry => _contexts.containsKey(grid) ? _gridGeometry : null;

  /// The rect of [key] in [ancestor]'s coordinates (global without one);
  /// null when nothing is mounted under that key.
  Rect? rect(String key, {RenderBox? ancestor}) => rectOf(_contexts[key], ancestor: ancestor);

  static Rect? rectOf(BuildContext? context, {RenderBox? ancestor}) {
    if (context == null || !context.mounted) return null;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero, ancestor: ancestor) & box.size;
  }
}

/// Registers its child's render box with [anchors] under [anchorKey] while
/// mounted; [MorphAnchor.grid] also carries the tracker grid's geometry.
class MorphAnchor extends StatefulWidget {
  final MorphAnchors anchors;
  final String anchorKey;
  final TrackerGridGeometry? geometry;
  final Widget child;

  const MorphAnchor({super.key, required this.anchors, required this.anchorKey, required this.child}) : geometry = null;

  const MorphAnchor.grid({super.key, required this.anchors, required TrackerGridGeometry this.geometry, required this.child})
      : anchorKey = MorphAnchors.grid;

  @override
  State<MorphAnchor> createState() => _MorphAnchorState();
}

class _MorphAnchorState extends State<MorphAnchor> {
  void _register(MorphAnchor w) {
    final geometry = w.geometry;
    if (geometry != null) {
      w.anchors.registerGrid(context, geometry);
    } else {
      w.anchors.register(w.anchorKey, context);
    }
  }

  void _unregister(MorphAnchor w) {
    if (w.geometry != null) {
      w.anchors.unregisterGrid(context);
    } else {
      w.anchors.unregister(w.anchorKey, context);
    }
  }

  @override
  void initState() {
    super.initState();
    _register(widget);
  }

  @override
  void didUpdateWidget(MorphAnchor old) {
    super.didUpdateWidget(old);
    if (old.anchorKey != widget.anchorKey || !identical(old.anchors, widget.anchors)) {
      _unregister(old);
      _register(widget);
    } else if (!identical(old.geometry, widget.geometry) && widget.geometry != null) {
      // The grid laid out again (rotation, sidebar): keep the geometry fresh.
      _register(widget);
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

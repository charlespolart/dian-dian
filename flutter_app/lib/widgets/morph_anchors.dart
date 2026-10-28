import 'package:flutter/widgets.dart';

import 'grid_geometry.dart';

/// How the title is set at the tracker end of the morph: the bar's 16 px,
/// pinned left on one line (portrait), or the landscape panel's fitted size,
/// centred, which may wrap. Registered with the title's anchor so the layer
/// scales and aligns its run to land on it.
class MorphTitleEnd {
  final double fontSize;

  /// The title's own letter spacing; null = whatever the theme gives it.
  final double? letterSpacing;
  final bool centred;

  /// The real title spans several lines: the layer's one-line run cannot
  /// land on it and dissolves into it instead.
  final bool wraps;

  const MorphTitleEnd({required this.fontSize, this.letterSpacing, required this.centred, required this.wraps});

  @override
  bool operator ==(Object other) =>
      other is MorphTitleEnd &&
      other.fontSize == fontSize &&
      other.letterSpacing == letterSpacing &&
      other.centred == centred &&
      other.wraps == wraps;

  @override
  int get hashCode => Object.hash(fontSize, letterSpacing, centred, wraps);

  /// The portrait bar.
  static const bar = MorphTitleEnd(fontSize: 16, centred: false, wraps: false);
}

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
  MorphTitleEnd? _titleEnd;

  void register(String key, BuildContext context) {
    _contexts[key] = context;
    // A plain title anchor (the portrait bar) carries the default end.
    if (key == barTitle) _titleEnd = null;
  }

  /// The landscape panel's title: its box, plus how it is set.
  void registerTitle(BuildContext context, MorphTitleEnd end) {
    _contexts[barTitle] = context;
    _titleEnd = end;
  }

  void unregisterTitle(BuildContext context) {
    if (identical(_contexts[barTitle], context)) {
      _contexts.remove(barTitle);
      _titleEnd = null;
    }
  }

  /// How the mounted tracker's title is set; null = the portrait bar, or no
  /// title mounted.
  MorphTitleEnd? get titleEnd => _contexts.containsKey(barTitle) ? _titleEnd : null;

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
  final MorphTitleEnd? titleEnd;
  final Widget child;

  const MorphAnchor({super.key, required this.anchors, required this.anchorKey, required this.child})
      : geometry = null,
        titleEnd = null;

  const MorphAnchor.grid({super.key, required this.anchors, required TrackerGridGeometry this.geometry, required this.child})
      : anchorKey = MorphAnchors.grid,
        titleEnd = null;

  /// The landscape title, with how it is set ([MorphTitleEnd]).
  const MorphAnchor.title({super.key, required this.anchors, required MorphTitleEnd end, required this.child})
      : anchorKey = MorphAnchors.barTitle,
        geometry = null,
        titleEnd = end;

  @override
  State<MorphAnchor> createState() => _MorphAnchorState();
}

class _MorphAnchorState extends State<MorphAnchor> {
  void _register(MorphAnchor w) {
    final geometry = w.geometry;
    final titleEnd = w.titleEnd;
    if (geometry != null) {
      w.anchors.registerGrid(context, geometry);
    } else if (titleEnd != null) {
      w.anchors.registerTitle(context, titleEnd);
    } else {
      w.anchors.register(w.anchorKey, context);
    }
  }

  void _unregister(MorphAnchor w) {
    if (w.geometry != null) {
      w.anchors.unregisterGrid(context);
    } else if (w.titleEnd != null) {
      w.anchors.unregisterTitle(context);
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
    } else if (widget.titleEnd != null && old.titleEnd != widget.titleEnd) {
      // The title refitted (a rename, a resize): keep its end fresh.
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

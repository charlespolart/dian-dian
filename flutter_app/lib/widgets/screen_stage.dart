import 'package:flutter/material.dart';

import '../theme/motion.dart';
import 'grid_geometry.dart';
import 'morph_anchors.dart';
import 'morph_layer.dart';

enum StageTransition {
  /// Cross-fade over [AppMotion.base].
  fade,
  /// Fade plus an 8 % slide from the right (into the settings).
  slideIn,
  /// Fade plus an 8 % slide from the left (back from the settings).
  slideOut,
  /// The tracker grows out of its card over [AppMotion.screen].
  morphOpen,
  /// The tracker shrinks back into its card.
  morphClose,
}

typedef _CardSide = ({Rect card, Rect screen, Rect grid, Rect? title, Rect? legends});
typedef _TrackerSide = ({Rect shell, Rect screen, Rect grid, TrackerGridGeometry geometry, Rect? title, MorphTitleEnd titleEnd});

/// The app's screen switcher: the previous screen leaves while the new one
/// arrives, the way [transition] says. The two morphs are a shared element:
/// a [MorphLayer] draws the card's frame, inner screen, dots and title at a
/// geometry interpolated towards the tracker's, measured through [anchors]
/// (the screen still on stage at once, the other after one frame where it
/// is laid out invisible, while the animation already runs). The real
/// tracker only appears once the dots have landed. A navigation during a
/// transition ends it at once and the next one plays as a fade. A size
/// change (rotation, keyboard) ends it too. Under reduced motion the screens
/// are simply swapped.
class ScreenStage extends StatefulWidget {
  /// The current screen; its key tells one screen from the next.
  final Widget child;
  final StageTransition transition;
  final MorphAnchors anchors;
  /// The card to morph from (open) or to (close).
  final String? morphPageId;
  /// What the morph draws: the tracker's title, cells and legend colours.
  final MorphContent? morphContent;
  final VoidCallback? onSettled;

  static const double slideFraction = 0.08;

  const ScreenStage({
    super.key,
    required this.child,
    required this.transition,
    required this.anchors,
    this.morphPageId,
    this.morphContent,
    this.onSettled,
  });

  @override
  State<ScreenStage> createState() => _ScreenStageState();
}

class _ScreenStageState extends State<ScreenStage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this)..addStatusListener(_onStatus);

  Widget? _outgoing;
  StageTransition _running = StageTransition.fade;
  /// The frame where the incoming screen is laid out at opacity 0 so its
  /// anchors can be measured.
  bool _measuring = false;
  _CardSide? _cardSide;
  _TrackerSide? _trackerSide;
  MorphEnds? _ends;
  Size? _lastSize;

  bool get _animating => _outgoing != null;
  bool get _isMorph => _running == StageTransition.morphOpen || _running == StageTransition.morphClose;
  RenderBox? get _box => context.findRenderObject() as RenderBox?;

  @override
  void didUpdateWidget(ScreenStage old) {
    super.didUpdateWidget(old);
    if (widget.child.key == old.child.key) return;
    final interrupted = _animating;
    if (interrupted) _finish(notify: false);
    if (AppMotion.reduced(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onSettled?.call());
      return;
    }
    _start(old.child, interrupted ? StageTransition.fade : widget.transition);
  }

  void _start(Widget outgoing, StageTransition transition) {
    _outgoing = outgoing;
    _running = transition;
    _cardSide = null;
    _trackerSide = null;
    _ends = null;
    _controller.duration = _isMorph ? AppMotion.screen * AppMotion.debugMorphSlowdown : AppMotion.base;
    if (_isMorph) {
      final pageId = widget.morphPageId;
      if (pageId == null || widget.morphContent == null) {
        _running = StageTransition.fade;
        _controller.duration = AppMotion.base;
      } else {
        // The side still laid out is read now, the other after the measure
        // frame; the animation starts at once so the tap gets its answer on
        // the very next frame instead of after that (heavy) frame.
        if (transition == StageTransition.morphOpen) {
          _cardSide = _readCard(pageId);
        } else {
          _trackerSide = _readTracker();
        }
        _measuring = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _afterMeasure());
      }
    }
    _controller.forward(from: 0);
  }

  _CardSide? _readCard(String pageId) {
    final a = widget.anchors;
    final card = a.rect(MorphAnchors.card(pageId), ancestor: _box);
    final screen = a.rect(MorphAnchors.cardScreen(pageId), ancestor: _box);
    final grid = a.rect(MorphAnchors.cardGrid(pageId), ancestor: _box);
    if (card == null || screen == null || grid == null) return null;
    return (
      card: card,
      screen: screen,
      grid: grid,
      title: a.rect(MorphAnchors.cardTitle(pageId), ancestor: _box),
      legends: a.rect(MorphAnchors.cardLegends(pageId), ancestor: _box),
    );
  }

  _TrackerSide? _readTracker() {
    final a = widget.anchors;
    final shell = a.rect(MorphAnchors.shell, ancestor: _box);
    final screen = a.rect(MorphAnchors.screen, ancestor: _box);
    final grid = a.rect(MorphAnchors.grid, ancestor: _box);
    final geometry = a.gridGeometry;
    if (shell == null || screen == null || grid == null || geometry == null) return null;
    return (
      shell: shell,
      screen: screen,
      grid: grid,
      geometry: geometry,
      title: a.rect(MorphAnchors.barTitle, ancestor: _box),
      titleEnd: a.titleEnd ?? MorphTitleEnd.bar,
    );
  }

  void _afterMeasure() {
    if (!mounted || !_measuring) return;
    _measuring = false;
    final pageId = widget.morphPageId;
    if (_running == StageTransition.morphOpen) {
      _trackerSide = _readTracker();
    } else if (pageId != null) {
      _cardSide = _readCard(pageId);
    }
    final c = _cardSide;
    final tr = _trackerSide;
    if (c == null || tr == null) {
      // An end is missing (the tracker left at its first build, the card is
      // off screen or gone): the running animation carries on as a fade.
      _running = StageTransition.fade;
    } else {
      _ends = MorphEnds(
        card: c.card,
        cardScreen: c.screen,
        cardGrid: c.grid,
        cardTitle: c.title,
        cardLegends: c.legends,
        shell: tr.shell,
        screen: tr.screen,
        grid: tr.grid,
        gridGeometry: tr.geometry,
        barTitle: tr.title,
        barTitleEnd: tr.titleEnd,
      );
    }
    setState(() {});
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _finish(notify: true);
  }

  void _finish({required bool notify}) {
    _controller.stop();
    _outgoing = null;
    _measuring = false;
    _cardSide = null;
    _trackerSide = null;
    _ends = null;
    if (mounted) setState(() {});
    if (notify) widget.onSettled?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      if (_lastSize != null && _lastSize != size && _animating) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _animating) _finish(notify: true);
        });
      }
      _lastSize = size;
      // One stable tree whatever the phase, so a screen keeps its element
      // (and its state) while it goes from current to outgoing: the Stack
      // reorders its keyed children instead of inflating them again.
      return IgnorePointer(
        ignoring: _animating,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Stack(fit: StackFit.expand, children: _layers(size)),
        ),
      );
    });
  }

  /// A screen in the stack: the same wrapper chain in every phase, keyed on
  /// the screen's own key.
  static Widget _layer(Widget screen, {double opacity = 1, Offset offset = Offset.zero, bool ignoring = false}) {
    return KeyedSubtree(
      key: ValueKey<Key?>(screen.key),
      child: IgnorePointer(
        ignoring: ignoring,
        child: Opacity(
          opacity: opacity,
          child: Transform.translate(offset: offset, child: screen),
        ),
      ),
    );
  }

  static double _window(double t, double from, double to) => ((t - from) / (to - from)).clamp(0.0, 1.0);

  static const _morphKey = ValueKey('morph-layer');

  List<Widget> _layers(Size size) {
    final incoming = widget.child;
    final outgoing = _outgoing;
    if (outgoing == null) return [_layer(incoming)];
    final t = _controller.value;
    // During the measure frame the incoming screen is laid out but unseen.
    final measuring = _measuring;
    final ends = _ends;
    final content = widget.morphContent;
    switch (_running) {
      case StageTransition.fade:
        final e = AppMotion.enter.transform(t);
        return [_layer(outgoing, opacity: 1 - e), _layer(incoming, opacity: measuring ? 0 : e, ignoring: measuring)];
      case StageTransition.slideIn:
      case StageTransition.slideOut:
        final e = AppMotion.enter.transform(t);
        final sign = _running == StageTransition.slideIn ? 1.0 : -1.0;
        final shift = size.width * ScreenStage.slideFraction;
        return [
          _layer(outgoing, opacity: 1 - e, offset: Offset(-sign * shift * e, 0)),
          _layer(incoming, opacity: measuring ? 0 : e, offset: Offset(sign * shift * (1 - e), 0), ignoring: measuring),
        ];
      case StageTransition.morphOpen:
        if (measuring || ends == null || content == null) {
          return [_layer(outgoing), _layer(incoming, opacity: 0, ignoring: true)];
        }
        // The list fades under the growing frame; the real tracker takes
        // over from the layer once the dots have landed.
        return [
          _layer(outgoing, opacity: 1 - _window(t, 0, 0.5)),
          Opacity(
            key: _morphKey,
            opacity: 1 - _window(t, AppMotion.morphHandover, 1),
            child: MorphLayer(
              ends: ends,
              content: content,
              g: AppMotion.morph.transform(t),
              legendsOpacity: 1 - _window(t, 0, 0.25),
            ),
          ),
          _layer(incoming, opacity: _window(t, AppMotion.morphHandover, 1)),
        ];
      case StageTransition.morphClose:
        if (measuring || ends == null || content == null) {
          return [_layer(incoming, opacity: 0, ignoring: true), _layer(outgoing)];
        }
        // The layer, identical to the tracker, takes over at once; the list
        // comes back under the shrinking frame.
        return [
          _layer(incoming, opacity: _window(t, 0.5, 1)),
          MorphLayer(
            key: _morphKey,
            ends: ends,
            content: content,
            g: 1 - AppMotion.morph.transform(t),
            legendsOpacity: _window(t, 0.75, 1),
          ),
          _layer(outgoing, opacity: 1 - _window(t, 0, 1 - AppMotion.morphHandover)),
        ];
    }
  }
}

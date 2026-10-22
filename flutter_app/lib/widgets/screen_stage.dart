import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/motion.dart';
import 'morph_anchors.dart';

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

/// The app's screen switcher: the previous screen leaves while the new one
/// arrives, the way [transition] says. For the two morphs a [MorphShell]
/// animates between the card's rect and the tracker shell's rect, both
/// measured through [anchors] after one frame where the incoming screen is
/// laid out invisible. A navigation during a transition ends it at once and
/// the next one plays as a fade. A size change (rotation, keyboard) ends it
/// too. Under reduced motion the screens are simply swapped.
class ScreenStage extends StatefulWidget {
  /// The current screen; its key tells one screen from the next.
  final Widget child;
  final StageTransition transition;
  final MorphAnchors anchors;
  /// The card to morph from (open) or to (close).
  final String? morphPageId;
  /// A static copy of that card, stretched inside the shell.
  final WidgetBuilder? morphCard;
  final VoidCallback? onSettled;

  /// Where the shell comes from or goes to when no card rect is known.
  static const Size fallbackSize = Size(120, 260);
  static const double slideFraction = 0.08;

  const ScreenStage({
    super.key,
    required this.child,
    required this.transition,
    required this.anchors,
    this.morphPageId,
    this.morphCard,
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
  /// anchor can be measured.
  bool _measuring = false;
  Rect? _cardRect;
  Rect? _shellRect;
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
    _cardRect = null;
    _shellRect = null;
    if (!_isMorph) {
      _controller.duration = AppMotion.base;
      _controller.forward(from: 0);
      return;
    }
    final pageId = widget.morphPageId;
    if (transition == StageTransition.morphOpen && pageId != null) {
      // The list is still laid out: read the card now.
      _cardRect = widget.anchors.cardRect(pageId, ancestor: _box);
    }
    _measuring = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _afterMeasure());
  }

  void _afterMeasure() {
    if (!mounted || !_measuring) return;
    _measuring = false;
    final pageId = widget.morphPageId;
    _shellRect = widget.anchors.shellRect(ancestor: _box);
    if (_running == StageTransition.morphClose && pageId != null) {
      _cardRect = widget.anchors.cardRect(pageId, ancestor: _box);
    }
    if (_shellRect == null) {
      // Nothing to morph (the tracker left at its first build): a fade.
      _running = StageTransition.fade;
      _controller.duration = AppMotion.base;
    } else {
      _controller.duration = AppMotion.screen;
    }
    setState(() {});
    _controller.forward(from: 0);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _finish(notify: true);
  }

  void _finish({required bool notify}) {
    _controller.stop();
    _outgoing = null;
    _measuring = false;
    _cardRect = null;
    _shellRect = null;
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

  static double _window(double e, double from, double to) => ((e - from) / (to - from)).clamp(0.0, 1.0);

  static const _shellKey = ValueKey('morph-shell');

  List<Widget> _layers(Size size) {
    final incoming = widget.child;
    final outgoing = _outgoing;
    if (outgoing == null) return [_layer(incoming)];
    if (_measuring) return [_layer(outgoing), _layer(incoming, opacity: 0, ignoring: true)];
    final t = _controller.value;
    switch (_running) {
      case StageTransition.fade:
        final e = AppMotion.enter.transform(t);
        return [_layer(outgoing, opacity: 1 - e), _layer(incoming, opacity: e)];
      case StageTransition.slideIn:
      case StageTransition.slideOut:
        final e = AppMotion.enter.transform(t);
        final sign = _running == StageTransition.slideIn ? 1.0 : -1.0;
        final shift = size.width * ScreenStage.slideFraction;
        return [
          _layer(outgoing, opacity: 1 - e, offset: Offset(-sign * shift * e, 0)),
          _layer(incoming, opacity: e, offset: Offset(sign * shift * (1 - e), 0)),
        ];
      case StageTransition.morphOpen:
        final e = AppMotion.enter.transform(t);
        final fallback = _cardRect == null;
        final card = _cardRect ?? _centered(size);
        return [
          _layer(outgoing, opacity: 1 - _window(e, 0, 0.6)),
          MorphShell(
            key: _shellKey,
            rect: Rect.lerp(card, _shellRect, e)!,
            radius: lerpDouble(10, 14, e)!,
            opacity: fallback ? _window(e, 0, 0.4) : 1,
            cardSize: card.size,
            cardOpacity: 1 - _window(e, 0, 0.4),
            card: widget.morphCard,
          ),
          _layer(incoming, opacity: _window(e, 0.4, 1)),
        ];
      case StageTransition.morphClose:
        final e = AppMotion.exit.transform(t);
        final fallback = _cardRect == null;
        final card = _cardRect ?? _centered(size);
        return [
          _layer(incoming, opacity: _window(e, 0.4, 1)),
          MorphShell(
            key: _shellKey,
            rect: Rect.lerp(_shellRect, card, e)!,
            radius: lerpDouble(14, 10, e)!,
            opacity: fallback ? 1 - _window(e, 0.6, 1) : 1,
            cardSize: card.size,
            cardOpacity: fallback ? 0 : _window(e, 0.6, 1),
            card: widget.morphCard,
          ),
          _layer(outgoing, opacity: 1 - _window(e, 0, 0.4)),
        ];
    }
  }

  static Rect _centered(Size size) => Rect.fromCenter(
        center: size.center(Offset.zero),
        width: ScreenStage.fallbackSize.width,
        height: ScreenStage.fallbackSize.height,
      );
}

/// The shell that grows from the card to the tracker (and back): the shell
/// colour and border, the radius in between, and inside it the card's copy
/// stretched to the shell's width.
class MorphShell extends StatelessWidget {
  final Rect rect;
  final double radius;
  final double opacity;
  final Size cardSize;
  final double cardOpacity;
  final WidgetBuilder? card;

  const MorphShell({
    super.key,
    required this.rect,
    required this.radius,
    required this.opacity,
    required this.cardSize,
    required this.cardOpacity,
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    final card = this.card;
    return Positioned.fromRect(
      rect: rect,
      child: Opacity(
        opacity: opacity,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.shell,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.shellBorder),
          ),
          child: card == null || cardOpacity == 0
              ? null
              : Opacity(
                  opacity: cardOpacity,
                  child: FittedBox(
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: cardSize.width,
                      height: cardSize.height,
                      child: Builder(builder: card),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

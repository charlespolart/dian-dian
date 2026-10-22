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
/// measured through [anchors]: the one still on screen at once, the other
/// after one frame where the incoming screen is laid out invisible, while
/// the animation is already running. A navigation during a transition ends it at once and
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
    _controller.duration = _isMorph ? AppMotion.screen * AppMotion.debugMorphSlowdown : AppMotion.base;
    if (_isMorph) {
      // The rect of the screen that is still laid out is read now; the other
      // one after a frame where the incoming screen is laid out invisible.
      // The animation starts at once, so the tap gets its answer on the very
      // next frame instead of after that (heavy) measure frame.
      final pageId = widget.morphPageId;
      if (transition == StageTransition.morphOpen && pageId != null) {
        _cardRect = widget.anchors.cardRect(pageId, ancestor: _box);
      }
      if (transition == StageTransition.morphClose) {
        _shellRect = widget.anchors.shellRect(ancestor: _box);
      }
      _measuring = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _afterMeasure());
    }
    _controller.forward(from: 0);
  }

  void _afterMeasure() {
    if (!mounted || !_measuring) return;
    _measuring = false;
    final pageId = widget.morphPageId;
    if (_running == StageTransition.morphOpen) {
      _shellRect = widget.anchors.shellRect(ancestor: _box);
    }
    if (_running == StageTransition.morphClose && pageId != null) {
      _cardRect = widget.anchors.cardRect(pageId, ancestor: _box);
    }
    if (_shellRect == null) {
      // Nothing to morph (the tracker left at its first build): the running
      // animation carries on as a fade.
      _running = StageTransition.fade;
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
    final t = _controller.value;
    // During the measure frame the incoming screen is laid out but unseen.
    final measuring = _measuring;
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
        final e = AppMotion.enter.transform(t);
        final fallback = _cardRect == null;
        final card = _cardRect ?? _centered(size);
        // Until the tracker shell is measured, the shell stays on the card.
        final target = _shellRect ?? card;
        return [
          _layer(outgoing, opacity: 1 - _window(e, 0, 0.6)),
          MorphShell(
            key: _shellKey,
            rect: Rect.lerp(card, target, e)!,
            radius: lerpDouble(10, 14, e)!,
            opacity: fallback ? _window(e, 0, 0.4) : 1,
            cardSize: card.size,
            cardOpacity: 1 - _window(e, 0, 0.4),
            card: widget.morphCard,
          ),
          _layer(incoming, opacity: measuring ? 0 : _window(e, 0.4, 1), ignoring: measuring),
        ];
      case StageTransition.morphClose:
        final e = AppMotion.exit.transform(t);
        final shell = _shellRect;
        // Until the card is measured, the shell stays on the tracker shell;
        // with no card at all it shrinks towards the centre and fades.
        final fallback = !measuring && _cardRect == null;
        final card = _cardRect ?? (measuring ? shell : _centered(size));
        return [
          _layer(incoming, opacity: measuring ? 0 : _window(e, 0.4, 1), ignoring: measuring),
          if (shell != null && card != null)
            MorphShell(
              key: _shellKey,
              rect: Rect.lerp(shell, card, e)!,
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

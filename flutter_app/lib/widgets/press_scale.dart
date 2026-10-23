import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/audio_service.dart';
import '../theme/motion.dart';

/// Press feedback for the app's hand-drawn buttons: the child shrinks to
/// [scale] under the finger and springs back on release or cancel. It
/// replaces the `GestureDetector(onTap:)` that wrapped the button; any
/// `Semantics(button: true)` stays outside. [onTapAt] receives the global
/// position of the release, for a dialog that should be born there. With
/// neither callback the widget is inert. A tap plays `press` when an
/// [AudioService] is provided (it yields to any cue the tap itself raises).
class PressScale extends StatefulWidget {
  final VoidCallback? onTap;
  final ValueChanged<Offset>? onTapAt;
  final Widget child;
  final HitTestBehavior behavior;

  static const double scale = 0.96;

  const PressScale({
    super.key,
    this.onTap,
    this.onTapAt,
    required this.child,
    this.behavior = HitTestBehavior.opaque,
  });

  bool get enabled => onTap != null || onTapAt != null;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _set(bool pressed) {
    if (_pressed != pressed && mounted) setState(() => _pressed = pressed);
  }

  void _sound() => context.read<AudioService?>()?.play(SoundCue.press);

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled
          ? (details) {
              _set(false);
              // The sound goes with whichever callback this widget has.
              if (widget.onTap == null) _sound();
              widget.onTapAt?.call(details.globalPosition);
            }
          : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onTap == null
          ? null
          : () {
              _sound();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _pressed ? PressScale.scale : 1,
        duration: AppMotion.of(context, AppMotion.press),
        curve: AppMotion.enter,
        child: widget.child,
      ),
    );
  }
}

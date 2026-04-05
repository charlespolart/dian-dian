import 'dart:async';
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/premium_provider.dart';
import 'cursor_picker_dialog.dart';

/// Global animated GIF cursor overlay.
/// Only active when user is authenticated and premium.
class CustomCursorOverlay extends StatefulWidget {
  final Widget child;

  const CustomCursorOverlay({super.key, required this.child});

  @override
  State<CustomCursorOverlay> createState() => _CustomCursorOverlayState();
}

class _CustomCursorOverlayState extends State<CustomCursorOverlay> {
  Offset _position = Offset.zero;
  bool _visible = false;
  Timer? _hideTimer;
  bool _isTouchInput = false;

  static const _size = 36.0;
  static const _hideDelay = Duration(milliseconds: 1500);

  String? _getCursorAsset(String cursorId) {
    final option = cursorOptions.cast<CursorOption?>().firstWhere(
      (o) => o!.id == cursorId,
      orElse: () => null,
    );
    return option?.asset;
  }

  @override
  void initState() {
    super.initState();
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onGlobalPointerEvent);
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onGlobalPointerEvent);
    _hideTimer?.cancel();
    super.dispose();
  }

  bool _precached = false;
  void _precacheIfNeeded(BuildContext context, String asset) {
    if (_precached) return;
    _precached = true;
    precacheImage(AssetImage(asset), context);
  }

  bool _isTouch(PointerEvent event) =>
      event.kind == PointerDeviceKind.touch ||
      event.kind == PointerDeviceKind.unknown;

  void _onGlobalPointerEvent(PointerEvent event) {
    if (event is PointerHoverEvent) {
      // Mouse hover: show cursor, no auto-hide
      _isTouchInput = false;
      _showAt(event.position, autoHide: false);
    } else if (event is PointerDownEvent || event is PointerMoveEvent) {
      _isTouchInput = _isTouch(event);
      _showAt(event.position, autoHide: _isTouchInput);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      if (_isTouchInput) _startHideTimer();
    } else if (event is PointerRemovedEvent) {
      // Mouse left the window: hide cursor
      if (!_isTouchInput) {
        setState(() => _visible = false);
      }
    }
  }

  void _showAt(Offset position, {required bool autoHide}) {
    if (!mounted) return;
    if (_visible && (_position - position).distance < 1) return;
    setState(() {
      _position = position;
      _visible = true;
    });
    _hideTimer?.cancel();
    if (autoHide) {
      _hideTimer = Timer(_hideDelay, () {
        if (mounted) setState(() => _visible = false);
      });
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_hideDelay, () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAuth = context.watch<AuthProvider>().isAuthenticated;
    final premium = context.watch<PremiumProvider>();
    final active = isAuth && premium.canUseAnimatedCursor;

    if (!active) return widget.child;

    final cursorAsset = _getCursorAsset(premium.cursorId);
    if (cursorAsset == null) return widget.child;

    _precacheIfNeeded(context, cursorAsset);

    return Stack(
      children: [
        // Hide system cursor when GIF cursor is active
        MouseRegion(
          cursor: SystemMouseCursors.none,
          hitTestBehavior: HitTestBehavior.translucent,
          child: widget.child,
        ),
        // Full-screen transparent touch/pointer catcher
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (e) {
              _isTouchInput = _isTouch(e);
              _showAt(e.position, autoHide: _isTouchInput);
            },
            onPointerMove: (e) => _showAt(e.position, autoHide: _isTouchInput),
            onPointerHover: (e) {
              _isTouchInput = false;
              _showAt(e.position, autoHide: false);
            },
            onPointerUp: (_) {
              if (_isTouchInput) _startHideTimer();
            },
            onPointerCancel: (_) {
              if (_isTouchInput) _startHideTimer();
            },
            child: const SizedBox.expand(),
          ),
        ),
        // Cursor image
        if (_visible)
          Positioned(
            left: _position.dx - _size / 2,
            top: _position.dy - _size / 2,
            child: IgnorePointer(
              child: Image.asset(
                cursorAsset,
                width: _size,
                height: _size,
                gaplessPlayback: true,
              ),
            ),
          ),
      ],
    );
  }
}

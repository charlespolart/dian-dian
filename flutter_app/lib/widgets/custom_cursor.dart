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
    // Global route captures ALL pointer events (reliable on native + web)
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onGlobalPointerEvent);
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onGlobalPointerEvent);
    _hideTimer?.cancel();
    super.dispose();
  }

  void _onGlobalPointerEvent(PointerEvent event) {
    if (event is PointerDownEvent || event is PointerMoveEvent || event is PointerHoverEvent) {
      _showAt(event.position);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _startHideTimer();
    }
  }

  // Listener callbacks as fallback (helps on some web platforms)
  void _onPointerDown(PointerDownEvent event) => _showAt(event.position);
  void _onPointerMove(PointerMoveEvent event) => _showAt(event.position);
  void _onPointerHover(PointerHoverEvent event) => _showAt(event.position);
  void _onPointerUp(PointerUpEvent event) => _startHideTimer();

  void _showAt(Offset position) {
    if (!mounted) return;
    setState(() {
      _position = position;
      _visible = true;
    });
    // Always restart hide timer — on touch it auto-hides,
    // on mouse the timer resets on each hover so it stays visible.
    _hideTimer?.cancel();
    _hideTimer = Timer(_hideDelay, () {
      if (mounted) setState(() => _visible = false);
    });
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

    // Resolve cursor asset from cursorId
    final cursorAsset = _getCursorAsset(premium.cursorId);
    if (cursorAsset == null) return widget.child;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerHover: _onPointerHover,
      onPointerUp: _onPointerUp,
      child: Stack(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.none,
            hitTestBehavior: HitTestBehavior.translucent,
            child: widget.child,
          ),
          if (_visible)
            Positioned(
              left: _position.dx - _size / 2,
              top: _position.dy - _size / 2,
              child: IgnorePointer(
                child: Image.asset(
                  cursorAsset,
                  width: _size,
                  height: _size,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

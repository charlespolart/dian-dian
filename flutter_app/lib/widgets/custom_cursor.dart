import 'dart:async';
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/premium_provider.dart';
import '../services/web_touch_handler_stub.dart'
    if (dart.library.html) '../services/web_touch_handler_web.dart';
import 'cursor_picker_dialog.dart';

/// Global animated GIF cursor overlay.
/// Uses three event sources for maximum compatibility:
/// - Global pointer route (reliable on native iOS/Android)
/// - Global pointer route (reliable on desktop web for mouse)
/// - Raw browser touch events via JS interop (reliable on mobile web)
class CustomCursorOverlay extends StatefulWidget {
  final Widget child;

  const CustomCursorOverlay({super.key, required this.child});

  @override
  State<CustomCursorOverlay> createState() => _CustomCursorOverlayState();
}

class _CustomCursorOverlayState extends State<CustomCursorOverlay> {
  Offset _position = Offset.zero;
  bool _visible = false;
  bool _active = false;
  Timer? _hideTimer;
  bool _isTouchInput = false;
  void Function()? _disposeWebTouch;

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
    // Native + desktop web: global pointer route
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onGlobalPointerEvent);
    // Mobile web: raw browser touch events (bypasses Flutter's broken pipeline)
    _disposeWebTouch = setupWebTouchListeners(
      onTouch: (x, y) {
        if (!_active) return;
        _isTouchInput = true;
        _showAt(Offset(x, y), autoHide: true);
      },
      onTouchEnd: () {
        if (!_active) return;
        _startHideTimer();
      },
    );
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onGlobalPointerEvent);
    _disposeWebTouch?.call();
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
    if (!_active) return;

    if (event is PointerHoverEvent) {
      _isTouchInput = false;
      _showAt(event.position, autoHide: false);
    } else if (event is PointerDownEvent || event is PointerMoveEvent) {
      _isTouchInput = _isTouch(event);
      _showAt(event.position, autoHide: _isTouchInput);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      if (_isTouchInput) _startHideTimer();
    } else if (event is PointerRemovedEvent) {
      if (!_isTouchInput) {
        if (mounted) setState(() => _visible = false);
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
    final cursorAsset = isAuth && premium.canUseAnimatedCursor
        ? _getCursorAsset(premium.cursorId)
        : null;

    _active = cursorAsset != null;

    if (!_active) return widget.child;

    _precacheIfNeeded(context, cursorAsset!);

    return Stack(
      children: [
        // Hide system cursor on desktop
        MouseRegion(
          cursor: SystemMouseCursors.none,
          hitTestBehavior: HitTestBehavior.translucent,
          child: widget.child,
        ),
        // Cursor image (no Listener overlay — it breaks mobile web)
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

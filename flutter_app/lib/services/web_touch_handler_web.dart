import 'dart:js_interop';

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external void addEventListener(String type, JSFunction callback);
  external void removeEventListener(String type, JSFunction callback);
}

extension type _TouchEvent(JSObject _) implements JSObject {
  external _TouchList get touches;
}

extension type _TouchList(JSObject _) implements JSObject {
  external int get length;
  external _Touch? item(int index);
}

extension type _Touch(JSObject _) implements JSObject {
  external num get clientX;
  external num get clientY;
}

/// Listen to raw browser touch events — bypasses Flutter's broken
/// pointer pipeline on mobile web (iOS Safari).
/// Returns a dispose function to remove the listeners.
void Function()? setupWebTouchListeners({
  required void Function(double x, double y) onTouch,
  required void Function() onTouchEnd,
}) {
  final startFn = ((JSObject event) {
    final te = _TouchEvent(event);
    if (te.touches.length > 0) {
      final t = te.touches.item(0);
      if (t != null) onTouch(t.clientX.toDouble(), t.clientY.toDouble());
    }
  }).toJS;

  final moveFn = ((JSObject event) {
    final te = _TouchEvent(event);
    if (te.touches.length > 0) {
      final t = te.touches.item(0);
      if (t != null) onTouch(t.clientX.toDouble(), t.clientY.toDouble());
    }
  }).toJS;

  final endFn = ((JSObject event) {
    onTouchEnd();
  }).toJS;

  _document.addEventListener('touchstart', startFn);
  _document.addEventListener('touchmove', moveFn);
  _document.addEventListener('touchend', endFn);

  return () {
    _document.removeEventListener('touchstart', startFn);
    _document.removeEventListener('touchmove', moveFn);
    _document.removeEventListener('touchend', endFn);
  };
}

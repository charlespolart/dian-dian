import 'dart:js_interop';

@JS('_onFlutterTouch')
external set _onFlutterTouch(JSFunction? fn);

/// Register a Dart callback for browser touch events.
/// The JS side (in index.html) captures touchstart/move/end
/// and calls this callback with (x, y, type).
/// type: 0 = start, 1 = move, 2 = end
void Function()? setupWebTouchListeners({
  required void Function(double x, double y) onTouch,
  required void Function() onTouchEnd,
}) {
  _onFlutterTouch = ((JSNumber x, JSNumber y, JSNumber type) {
    if (type.toDartInt == 2) {
      onTouchEnd();
    } else {
      onTouch(x.toDartDouble, y.toDartDouble);
    }
  }).toJS;

  return () {
    _onFlutterTouch = null;
  };
}

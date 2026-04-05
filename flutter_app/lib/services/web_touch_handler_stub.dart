/// Native stub — no browser touch events needed.
void Function()? setupWebTouchListeners({
  required void Function(double x, double y) onTouch,
  required void Function() onTouchEnd,
}) => null;

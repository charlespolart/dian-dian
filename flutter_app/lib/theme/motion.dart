import 'package:flutter/widgets.dart';

/// The app's one timing rule. Every animation reads its duration through
/// [of], which is zero when the system asks for reduced motion (iOS "Reduce
/// Motion", Android animator scale 0). An entrance always lasts longer than
/// its exit; what arrives decelerates ([enter]), what leaves accelerates
/// ([exit]).
class AppMotion {
  AppMotion._();

  /// A button under the finger.
  static const press = Duration(milliseconds: 90);
  /// A dialog leaving, short fades.
  static const quick = Duration(milliseconds: 160);
  /// A dialog arriving, a year change, the list's cascade.
  static const base = Duration(milliseconds: 220);
  /// The dot that fills in.
  static const pop = Duration(milliseconds: 280);
  /// Opening and closing a tracker.
  static const screen = Duration(milliseconds: 320);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;

  static bool reduced(BuildContext context) => MediaQuery.disableAnimationsOf(context);

  /// [d], or zero under reduced motion.
  static Duration of(BuildContext context, Duration d) => reduced(context) ? Duration.zero : d;
}

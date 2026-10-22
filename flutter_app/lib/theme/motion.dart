import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/widgets.dart';

/// The app's one timing rule. Every animation reads its duration through
/// [of], which is zero when the system asks for reduced motion (iOS "Reduce
/// Motion", Android animator scale 0). An entrance always lasts longer than
/// its exit; what arrives decelerates ([enter]), what leaves accelerates
/// ([exit]). Tune here and nowhere else: the first on-device pass (2026-10-22)
/// found the initial values (90 / 160 / 220 / 280 / 320 ms) too quick to see.
class AppMotion {
  AppMotion._();

  /// A button under the finger.
  static const press = Duration(milliseconds: 120);
  /// A dialog leaving, short fades.
  static const quick = Duration(milliseconds: 200);
  /// A dialog arriving, a year change, the list's cascade.
  static const base = Duration(milliseconds: 300);
  /// The dot that fills in.
  static const pop = Duration(milliseconds: 360);
  /// Opening and closing a tracker.
  static const screen = Duration(milliseconds: 420);

  /// Debug only, an inspection aid: stretches the tracker open / close morph
  /// by this factor so every phase can be watched (8 → about 3.4 s). Always 1
  /// in release; set it back to 1 here once the morph is validated.
  static double debugMorphSlowdown = kDebugMode ? 8 : 1;

  static const Curve enter = Curves.easeOutCubic;
  /// The shared-element morph: symmetrical, reads as a transformation.
  static const Curve morph = Curves.easeInOutCubic;
  static const Curve exit = Curves.easeInCubic;

  static bool reduced(BuildContext context) => MediaQuery.disableAnimationsOf(context);

  /// [d], or zero under reduced motion.
  static Duration of(BuildContext context, Duration d) => reduced(context) ? Duration.zero : d;
}

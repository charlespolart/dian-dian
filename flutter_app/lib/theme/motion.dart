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
  /// Between two groups that enter one after the other (the tracker's
  /// reveal): a couple of frames, felt as one sweep, never as steps.
  static const stagger = Duration(milliseconds: 30);
  /// Where, in the open morph, the real tracker takes over from the layer
  /// (its dots have landed within a few px); the tracker's reveal starts
  /// there. The close morph hands over at 1 − this.
  static const morphHandover = 0.85;

  /// An inspection aid, 1 in normal use: raise it on a debug build to
  /// stretch the tracker open / close morph so every phase can be watched
  /// (8 → about 3.4 s). Never ship it above 1.
  static double debugMorphSlowdown = 1;

  static const Curve enter = Curves.easeOutCubic;
  /// The shared-element morph: symmetrical, reads as a transformation.
  static const Curve morph = Curves.easeInOutCubic;
  static const Curve exit = Curves.easeInCubic;

  static bool reduced(BuildContext context) => MediaQuery.disableAnimationsOf(context);

  /// [d], or zero under reduced motion.
  static Duration of(BuildContext context, Duration d) => reduced(context) ? Duration.zero : d;
}

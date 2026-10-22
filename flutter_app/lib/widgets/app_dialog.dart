import 'dart:ui' show SemanticsHitTestBehavior, lerpDouble;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/motion.dart';

/// Where a dialog's scale is anchored for a tap at [origin] on a screen of
/// [size]: born under the finger, settling at the centre.
Alignment originAlignment(Offset origin, Size size) => Alignment(
      ((origin.dx / size.width) * 2 - 1).clamp(-1.0, 1.0),
      ((origin.dy / size.height) * 2 - 1).clamp(-1.0, 1.0),
    );

/// The app's `showDialog`: same shape, plus the entrance (scale 0.92 → 1,
/// fade, 8 px rise over [AppMotion.base]) and the exit (scale 1 → 0.96 and
/// fade over [AppMotion.quick]). [origin], a global position, makes the box
/// seem to come from the tap. Always on the root navigator.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Offset? origin,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  return navigator.push<T>(AppDialogRoute<T>(
    context: context,
    builder: builder,
    themes: InheritedTheme.capture(from: context, to: navigator.context),
    barrierDismissible: barrierDismissible,
    origin: origin,
    reduced: AppMotion.reduced(context),
  ));
}

class AppDialogRoute<T> extends RawDialogRoute<T> {
  final Offset? origin;
  final bool reduced;

  AppDialogRoute({
    required BuildContext context,
    required WidgetBuilder builder,
    required CapturedThemes themes,
    required this.origin,
    required this.reduced,
    super.barrierDismissible,
  }) : super(
          barrierColor: Colors.black54,
          barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
          transitionDuration: reduced ? Duration.zero : AppMotion.base,
          pageBuilder: (buildContext, animation, secondaryAnimation) {
            final child = themes.wrap(Builder(builder: builder));
            // Like DialogRoute: safe area, and taps inside never reach the barrier.
            return Semantics(
              hitTestBehavior: SemanticsHitTestBehavior.opaque,
              child: SafeArea(child: child),
            );
          },
        );

  @override
  Duration get reverseTransitionDuration => reduced ? Duration.zero : AppMotion.quick;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final alignment = origin == null ? Alignment.center : originAlignment(origin!, MediaQuery.sizeOf(context));
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final closing = animation.status == AnimationStatus.reverse;
        // Entering: value 0 → 1 through `enter`. Leaving: value 1 → 0, and
        // `exit` is applied on elapsed time so the box accelerates away.
        final t = closing
            ? 1 - AppMotion.exit.transform(1 - animation.value)
            : AppMotion.enter.transform(animation.value);
        final scale = closing ? lerpDouble(0.96, 1, t)! : lerpDouble(0.92, 1, t)!;
        final rise = closing ? 0.0 : 8 * (1 - t);
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, rise),
            child: Transform.scale(scale: scale, alignment: alignment, child: child),
          ),
        );
      },
    );
  }
}

/// App-wide dialog wrapper.
///
/// The dialog grows with its content up to the space the screen leaves
/// (minus the keyboard); only then does the body scroll. [footer] — the
/// action buttons — is pinned under the body and never scrolls away or
/// gets cut; [header] (a close cross, a toolbar) is pinned above it the same
/// way. Bodies bring their own padding; the footer gets 20 px sides and
/// bottom, the header none.
class AppDialog extends StatelessWidget {
  final Widget child;
  final Widget? header;
  final Widget? footer;
  final double maxWidth;

  const AppDialog({
    super.key,
    required this.child,
    this.header,
    this.footer,
    this.maxWidth = 400,
  });

  @override
  Widget build(BuildContext context) {
    final header = this.header;
    final footer = this.footer;
    return Dialog(
      backgroundColor: AppColors.shell,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.shellBorder),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ?header,
            Flexible(child: SingleChildScrollView(child: child)),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}

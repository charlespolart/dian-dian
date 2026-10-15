import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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

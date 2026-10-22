import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import 'app_dialog.dart';
import 'press_scale.dart';

/// "What's new in X.Y.Z": the bullets of `lib/data/whats_new.dart`, once
/// after an update (see `_maybeShowWhatsNew` in main.dart).
class WhatsNewDialog extends StatelessWidget {
  final String version;
  final List<String> bullets;

  const WhatsNewDialog({super.key, required this.version, required this.bullets});

  static Future<void> show(BuildContext context, {required String version, required List<String> bullets}) {
    return showAppDialog(
      context: context,
      builder: (_) => WhatsNewDialog(version: version, bullets: bullets),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return AppDialog(
      footer: Center(
        child: Semantics(
          button: true,
          child: PressScale(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.btnAdd,
                border: Border.all(color: AppColors.btnAddBorder),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(lang.t('common.ok'), style: AppFonts.pixel(fontSize: 12, color: AppColors.btnAddText)),
            ),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                '✨ ${lang.t('whatsNew.title').replaceFirst('{v}', version)}',
                style: AppFonts.pixel(fontSize: 16, color: AppColors.title),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 14),
            // One after another: each bullet waits its turn (140 ms apart),
            // then fades in while rising 14 px over 380 ms. Light, but seen.
            for (var i = 0; i < bullets.length; i++)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: AppMotion.base.inMilliseconds + 380 + 140 * i),
                curve: Interval(
                  (AppMotion.base.inMilliseconds + 140 * i) / (AppMotion.base.inMilliseconds + 380 + 140 * i),
                  1,
                  curve: AppMotion.enter,
                ),
                builder: (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: child),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 6, right: 10),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent),
                      ),
                      Expanded(
                        child: Text(
                          bullets[i],
                          style: AppFonts.dot(fontSize: 14, color: AppColors.text).copyWith(height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

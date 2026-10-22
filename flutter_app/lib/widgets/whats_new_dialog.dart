import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import 'app_dialog.dart';

/// "What's new in X.Y.Z": the bullets of `lib/data/whats_new.dart`, once
/// after an update (see `_maybeShowWhatsNew` in main.dart).
class WhatsNewDialog extends StatelessWidget {
  final String version;
  final List<String> bullets;

  const WhatsNewDialog({super.key, required this.version, required this.bullets});

  static Future<void> show(BuildContext context, {required String version, required List<String> bullets}) {
    return showDialog(
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
          child: GestureDetector(
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
                lang.t('whatsNew.title').replaceFirst('{v}', version),
                style: AppFonts.pixel(fontSize: 16, color: AppColors.title),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 14),
            for (final b in bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
                      child: Text(b, style: AppFonts.dot(fontSize: 14, color: AppColors.text)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

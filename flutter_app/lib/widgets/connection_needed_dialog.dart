import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import 'app_dialog.dart';
import 'press_scale.dart';

/// A change refused on the first launch after the update from 1.4.0 while
/// offline: the phone does not have the full copy of the account yet (H15).
class ConnectionNeededDialog extends StatelessWidget {
  const ConnectionNeededDialog({super.key});

  static Future<void> show(BuildContext context) =>
      showAppDialog(context: context, builder: (_) => const ConnectionNeededDialog());

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
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
        child: Text(
          lang.t('sync.needsConnection'),
          style: AppFonts.dot(fontSize: 12, color: AppColors.title),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

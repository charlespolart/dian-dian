import 'package:flutter/material.dart';

import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import 'language_picker_dialog.dart';
import 'press_scale.dart';

/// Compact language button used on auth screens.
/// Taps opens the shared language picker dialog.
class LanguageDropdown extends StatelessWidget {
  final LanguageProvider lang;

  const LanguageDropdown({super.key, required this.lang});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () => showLanguagePickerDialog(context, lang),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.shell,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.shellBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              languageShortLabels[lang.lang] ?? 'EN',
              style: AppFonts.pixel(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

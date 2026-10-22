import 'package:flutter/material.dart';

import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import 'app_dialog.dart';

/// Shows a dialog to pick a language. Returns when a language is selected.
Future<void> showLanguagePickerDialog(BuildContext context, LanguageProvider lang) {
  return showAppDialog(
    context: context,
    builder: (ctx) => AppDialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lang.t('settings.language'),
              style: AppFonts.pixel(fontSize: 16, color: AppColors.title),
            ),
            const SizedBox(height: 16),
            ...Language.values.map((language) {
              final isActive = lang.lang == language;
              return GestureDetector(
                onTap: () {
                  lang.setLang(language);
                  Navigator.of(ctx).pop();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.tabActive : Colors.transparent,
                    border: isActive
                        ? Border.all(color: AppColors.tabActiveBorder)
                        : null,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Text(
                        languageShortLabels[language]!,
                        style: AppFonts.pixel(
                          fontSize: 11,
                          color: isActive ? AppColors.accent : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        lang.t(languageNameKeys[language]!),
                        style: AppFonts.dot(
                          fontSize: 14,
                          color: isActive ? AppColors.accent : AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    ),
  );
}

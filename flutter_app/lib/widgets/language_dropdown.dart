import 'package:flutter/material.dart';

import '../providers/language_provider.dart';
import '../theme/app_theme.dart';

/// Compact language dropdown used on auth screens.
class LanguageDropdown extends StatelessWidget {
  final LanguageProvider lang;

  const LanguageDropdown({super.key, required this.lang});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Language>(
      onSelected: (l) => lang.setLang(l),
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.shellBorder),
      ),
      color: AppColors.shell,
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
      itemBuilder: (_) => Language.values.map((l) {
        final isActive = lang.lang == l;
        return PopupMenuItem<Language>(
          value: l,
          child: Text(
            languageShortLabels[l]!,
            style: AppFonts.pixel(
              fontSize: 11,
              color: isActive ? AppColors.accent : AppColors.text,
            ),
          ),
        );
      }).toList(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/premium_provider.dart';
import '../theme/app_theme.dart';
import 'app_dialog.dart';
import 'premium_gate_dialog.dart';

/// Available cursors. Add new entries here when adding new cursor GIFs.
const cursorOptions = [
  CursorOption(id: 'none', nameKey: 'cursor.none', asset: null),
  CursorOption(id: 'cat', nameKey: 'cursor.cat', asset: 'assets/cursors/cursor_cat.gif'),
  CursorOption(id: 'dance', nameKey: 'cursor.dance', asset: 'assets/cursors/cursor_dance.gif'),
  CursorOption(id: 'bunny', nameKey: 'cursor.bunny', asset: 'assets/cursors/cursor_bunny.gif'),
  CursorOption(id: 'heart_cat', nameKey: 'cursor.heart_cat', asset: 'assets/cursors/cursor_heart_cat.gif'),
  CursorOption(id: 'wave', nameKey: 'cursor.wave', asset: 'assets/cursors/cursor_wave.gif'),
  CursorOption(id: 'paw', nameKey: 'cursor.paw', asset: 'assets/cursors/cursor_paw.gif'),
  CursorOption(id: 'hi', nameKey: 'cursor.hi', asset: 'assets/cursors/cursor_hi.gif'),
  CursorOption(id: 'nyan', nameKey: 'cursor.nyan', asset: 'assets/cursors/cursor_nyan.gif'),
  CursorOption(id: 'molang', nameKey: 'cursor.molang', asset: 'assets/cursors/cursor_molang.gif'),
  CursorOption(id: 'mochi', nameKey: 'cursor.mochi', asset: 'assets/cursors/cursor_mochi.gif', vipOnly: true),
];

class CursorOption {
  final String id;
  final String nameKey;
  final String? asset;
  final bool vipOnly;

  const CursorOption({required this.id, required this.nameKey, this.asset, this.vipOnly = false});
}

Future<void> showCursorPickerDialog(BuildContext context) {
  final premium = context.read<PremiumProvider>();
  if (!premium.isPremium) {
    final lang = context.read<LanguageProvider>();
    PremiumGateDialog.show(context, feature: lang.t('premium.feature.cursor'));
    return Future.value();
  }
  return showDialog(
    context: context,
    builder: (_) => const _CursorPickerDialog(),
  );
}

class _CursorPickerDialog extends StatelessWidget {
  const _CursorPickerDialog();

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    final premium = context.watch<PremiumProvider>();
    final isVip = context.read<AuthProvider>().isVip;
    final currentId = premium.cursorEnabled ? premium.cursorId : 'none';

    // Filter out VIP-only cursors for non-VIP users
    final visibleCursors = cursorOptions.where((o) => !o.vipOnly || isVip).toList();

    return AppDialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lang.t('settings.cursor'),
              style: AppFonts.pixel(fontSize: 16, color: AppColors.title),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: visibleCursors.map((option) {
                final isActive = currentId == option.id;
                return GestureDetector(
                  onTap: () {
                    if (option.id == 'none') {
                      premium.setCursorEnabled(false);
                    } else {
                      premium.setCursorEnabled(true);
                      premium.setCursorId(option.id);
                    }
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.shell,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive ? AppColors.accent : AppColors.shellBorder,
                        width: isActive ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: option.asset != null
                          ? Image.asset(option.asset!, width: 40, height: 40, fit: BoxFit.contain)
                          : Icon(Icons.mouse, size: 28, color: AppColors.textMuted),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

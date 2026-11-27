import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import 'app_dialog.dart';
import 'press_scale.dart';

/// A message with one button: an optional title, the text, OK (or [button]).
class MessageDialog extends StatelessWidget {
  const MessageDialog({super.key, this.title, required this.message, this.button});

  final String? title;
  final String message;
  final String? button;

  static Future<void> show(BuildContext context, {String? title, required String message, String? button}) =>
      showAppDialog(context: context, builder: (_) => MessageDialog(title: title, message: message, button: button));

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final title = this.title;
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
              child: Text(button ?? lang.t('common.ok'), style: AppFonts.pixel(fontSize: 12, color: AppColors.btnAddText)),
            ),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Text(title, style: AppFonts.pixel(fontSize: 13, color: AppColors.title), textAlign: TextAlign.center),
              const SizedBox(height: 10),
            ],
            Text(message, style: AppFonts.dot(fontSize: 12, color: AppColors.text), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

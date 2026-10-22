import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_dialog.dart';
import 'press_scale.dart';

/// A custom confirmation dialog that matches the warm cream pixel aesthetic.
///
/// Returns `true` when the user confirms, `false` or `null` when cancelled.
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    this.destructive = false,
  });

  /// Convenience helper to show the dialog and return the result.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildButton(
            context,
            label: cancelLabel,
            bgColor: AppColors.inputBg,
            borderColor: AppColors.inputBorder,
            textColor: AppColors.textMuted,
            onTap: () => Navigator.of(context).pop(false),
          ),
          const SizedBox(width: 12),
          _buildButton(
            context,
            label: confirmLabel,
            bgColor: destructive ? AppColors.btnReset : AppColors.btnAdd,
            borderColor: destructive ? AppColors.btnResetBorder : AppColors.btnAddBorder,
            textColor: destructive ? AppColors.btnResetText : AppColors.btnAddText,
            onTap: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: AppFonts.pixel(fontSize: 16, color: AppColors.title),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppFonts.dot(fontSize: 14, color: AppColors.text),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String label,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: AppFonts.pixel(fontSize: 12, color: textColor),
        ),
      ),
    );
  }
}

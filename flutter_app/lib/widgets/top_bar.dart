import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared top bar with back button and title, used on tracker and settings screens.
class TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final String title;
  final Widget? trailing;

  const TopBar({
    super.key,
    required this.onBack,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBack,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '<',
                style: AppFonts.pixel(
                  fontSize: 20,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: AppFonts.pixel(
                fontSize: 16,
                color: AppColors.title,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

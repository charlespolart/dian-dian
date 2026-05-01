import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../providers/premium_provider.dart';
import '../services/store_links.dart';
import '../theme/app_theme.dart';
import 'app_dialog.dart';
import 'custom_paywall_dialog.dart';

/// Dialog shown when a free user tries to access a premium feature.
/// Shows what premium includes, then opens the RevenueCat paywall on upgrade.
class PremiumGateDialog extends StatelessWidget {
  final String feature;

  const PremiumGateDialog({super.key, required this.feature});

  /// Shows the dialog. Returns true if the user is now premium.
  static Future<bool> show(BuildContext context, {required String feature}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => PremiumGateDialog(feature: feature),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>();

    return AppDialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium, size: 36, color: AppColors.accent),
            const SizedBox(height: 12),

            Text(
              lang.t('premium.title'),
              style: AppFonts.pixel(fontSize: 18, color: AppColors.title),
            ),
            const SizedBox(height: 16),

            // Feature being gated
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.screen,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.screenBorder),
              ),
              child: Text(
                feature,
                style: AppFonts.dot(fontSize: 13, color: AppColors.text),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            _buildBenefit(Icons.grid_view, lang.t('premium.feature.trackers')),
            _buildBenefit(Icons.palette, lang.t('premium.feature.themes')),
            _buildBenefit(Icons.pets, lang.t('premium.feature.cursor')),
            _buildBenefit(Icons.image, lang.t('premium.feature.export')),
            _buildBenefit(Icons.bar_chart, lang.t('premium.feature.stats')),
            _buildBenefit(Icons.block, lang.t('premium.feature.noAds')),

            const SizedBox(height: 20),

            if (kIsWeb) ...[
              Text(
                lang.t('premium.downloadApp'),
                style: AppFonts.dot(fontSize: 12, color: AppColors.text),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              _buildStoreButtons(),
            ] else ...[
              _UpgradeButton(),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: () async {
                  final premium = context.read<PremiumProvider>();
                  final restored = await premium.restorePurchases();
                  if (context.mounted) Navigator.of(context).pop(restored);
                },
                child: Text(
                  lang.t('premium.restore'),
                  style: AppFonts.dot(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ],
            const SizedBox(height: 8),

            GestureDetector(
              onTap: () => Navigator.of(context).pop(false),
              child: Text(
                lang.t('common.cancel'),
                style: AppFonts.pixel(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreButtons() {
    final platform = defaultTargetPlatform;
    final isIOS = platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    final isAndroid = platform == TargetPlatform.android;

    final buttons = <Widget>[];

    if (!isAndroid) {
      buttons.add(_StoreButton(icon: Icons.apple, label: 'App Store', onOpen: StoreLinks.openAppStore));
    }
    if (!isIOS) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(width: 12));
      buttons.add(_StoreButton(icon: Icons.shop, label: 'Google Play', onOpen: StoreLinks.openPlayStore));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: buttons,
    );
  }

  static Widget _buildBenefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppFonts.dot(fontSize: 13, color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the in-app pixel-art paywall. Pops `true` if the user becomes premium.
class _UpgradeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>();

    return GestureDetector(
      onTap: () async {
        final premium = await CustomPaywallDialog.show(context);
        if (!context.mounted) return;
        if (premium) Navigator.of(context).pop(true);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            lang.t('premium.upgrade'),
            style: AppFonts.pixel(fontSize: 12, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _StoreButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Future<void> Function() onOpen;

  const _StoreButton({required this.icon, required this.label, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          border: Border.all(color: AppColors.inputBorder),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(label, style: AppFonts.dot(fontSize: 12, color: AppColors.accent)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/language_provider.dart';
import '../providers/premium_provider.dart';
import '../theme/app_theme.dart';
import 'app_dialog.dart';

/// Dialog shown when a free user tries to access a premium feature.
/// Shows what premium includes and an upgrade button.
class PremiumGateDialog extends StatelessWidget {
  final String feature;

  const PremiumGateDialog({super.key, required this.feature});

  /// Shows the dialog. Returns true if the user upgraded (for testing).
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
            // Crown icon
            Icon(Icons.workspace_premium, size: 36, color: AppColors.accent),
            const SizedBox(height: 12),

            // Title
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

            // Benefits list
            _buildBenefit(Icons.grid_view, lang.t('premium.feature.trackers')),
            _buildBenefit(Icons.palette, lang.t('premium.feature.themes')),
            _buildBenefit(Icons.pets, lang.t('premium.feature.cursor')),
            _buildBenefit(Icons.image, lang.t('premium.feature.export')),
            _buildBenefit(Icons.block, lang.t('premium.feature.noAds')),

            const SizedBox(height: 20),

            if (kIsWeb) ...[
              // On web: download the app
              Text(
                lang.t('premium.downloadApp'),
                style: AppFonts.dot(fontSize: 12, color: AppColors.text),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              _buildStoreButtons(),
            ] else ...[
              // On mobile: upgrade button(s)
              _PurchaseButtons(),
              const SizedBox(height: 12),

              // Restore purchases
              GestureDetector(
                onTap: () async {
                  await context.read<PremiumProvider>().restorePurchases();
                  if (context.mounted) Navigator.of(context).pop(false);
                },
                child: Text(
                  lang.t('premium.restore'),
                  style: AppFonts.dot(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ],
            const SizedBox(height: 8),

            // Cancel
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

  static const _appStoreUrl = 'https://apps.apple.com/app/dian-dian-year-tracker/id000000000';
  static const _playStoreUrl = 'https://play.google.com/store/apps/details?id=app.mydiandian.dian_dian';

  Widget _buildStoreButtons() {
    final platform = defaultTargetPlatform;
    final isIOS = platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    final isAndroid = platform == TargetPlatform.android;

    final buttons = <Widget>[];

    if (!isAndroid) {
      buttons.add(_StoreButton(icon: Icons.apple, label: 'App Store', url: _appStoreUrl));
    }
    if (!isIOS) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(width: 12));
      buttons.add(_StoreButton(icon: Icons.shop, label: 'Google Play', url: _playStoreUrl));
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

/// Shows available subscription products on mobile.
class _PurchaseButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final premium = context.read<PremiumProvider>();
    final products = premium.purchaseService.products;
    final lang = context.read<LanguageProvider>();

    if (products.isEmpty) {
      // No products loaded — show a generic upgrade button (fallback)
      return GestureDetector(
        onTap: () async {
          final success = await premium.buyPremium();
          if (!success && context.mounted) {
            // Store not available or no products — toggle for testing
            await premium.setPremium(true);
            if (context.mounted) Navigator.of(context).pop(true);
          }
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

    // Show each product as a button
    return Column(
      children: products.map((product) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: GestureDetector(
            onTap: () async {
              await premium.buyPremium(productId: product.id);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product.title,
                    style: AppFonts.pixel(fontSize: 11, color: Colors.white),
                  ),
                  Text(
                    product.price,
                    style: AppFonts.pixel(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StoreButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;

  const _StoreButton({required this.icon, required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
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

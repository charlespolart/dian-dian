import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../providers/premium_provider.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import 'premium_gate_dialog.dart';

/// A banner ad shown only for free users on mobile.
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (kIsWeb || AdService().isDisabled) return;
    if (_bannerAd == null) _loadAd();
  }

  void _loadAd() {
    final adUnitId = AdService.bannerAdUnitId;
    if (adUnitId.isEmpty) return;

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: ${error.message}');
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || AdService().isDisabled) return const SizedBox.shrink();

    final isPremium = context.watch<PremiumProvider>().isPremium;
    if (isPremium) return const SizedBox.shrink();

    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();

    final lang = context.read<LanguageProvider>();

    return Stack(
        children: [
          // Ad banner
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 2),
            child: Center(
              child: SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
          ),
          // Close button
          Positioned(
            top: 2,
            right: 6,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => PremiumGateDialog.show(context, feature: lang.t('premium.feature.noAds')),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.shellBorder),
                  ),
                  child: Center(
                    child: Icon(Icons.close_rounded, size: 10, color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
          ),
        ],
    );
  }
}

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../providers/premium_provider.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import 'premium_gate_dialog.dart';

/// A banner ad shown only for free users on mobile. With a [width] (the
/// space it may fill, landscape tablets), the banner is the anchored
/// adaptive size for that width — wider and taller than the 320 × 50 one —
/// and reloads when the width changes (a rotation).
class AdBannerWidget extends StatefulWidget {
  final double? width;

  const AdBannerWidget({super.key, this.width});

  /// The room a portrait screen keeps free at its bottom, above the system
  /// bar, for the banner of a free account: the standard 320 × 50 banner and
  /// its margins. Kept whether or not an ad has loaded, so the screen does
  /// not jump when one arrives; 0 when no banner can show.
  static double reservedHeight({required bool premium}) =>
      kIsWeb || AdService().isDisabled || premium ? 0 : AdSize.banner.height + 4.0;

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

  @override
  void didUpdateWidget(AdBannerWidget old) {
    super.didUpdateWidget(old);
    final was = old.width, now = widget.width;
    if (was == now || (was != null && now != null && (was - now).abs() < 1)) return;
    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;
    if (!kIsWeb && !AdService().isDisabled) _loadAd();
  }

  Future<void> _loadAd() async {
    final adUnitId = AdService.bannerAdUnitId;
    if (adUnitId.isEmpty) return;

    final width = widget.width;
    AdSize size = AdSize.banner;
    if (width != null && width >= AdSize.banner.width) {
      size = await AdSize.getLargeAnchoredAdaptiveBannerAdSizeWithOrientation(Orientation.landscape, width.truncate()) ??
          AdSize.banner;
      if (!mounted || _bannerAd != null) return;
    }
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: size,
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
    return AdBannerFrame(
      adSize: Size(_bannerAd!.size.width.toDouble(), _bannerAd!.size.height.toDouble()),
      ad: AdWidget(ad: _bannerAd!),
      onClose: () => PremiumGateDialog.show(context, feature: lang.t('premium.feature.noAds'), event: 'no_ads'),
    );
  }
}

/// The loaded banner and its close button, pinned to the bottom of a screen
/// above the system bar: the screens draw edge to edge (Android 15+, iPhone),
/// so without it the three-button navigation bar or the home indicator would
/// cover the ad. Only the system bar counts (`viewPadding`), not the keyboard.
class AdBannerFrame extends StatelessWidget {
  final Size adSize;
  final Widget ad;
  final VoidCallback onClose;

  const AdBannerFrame({super.key, required this.adSize, required this.ad, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final systemBar = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: systemBar),
      child: Stack(
        children: [
          // Ad banner
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 2),
            child: Center(
              child: SizedBox(width: adSize.width, height: adSize.height, child: ad),
            ),
          ),
          // Close button
          Positioned(
            top: 2,
            right: 6,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
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
      ),
    );
  }
}

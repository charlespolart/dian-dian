import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/language_provider.dart';
import '../providers/premium_provider.dart';
import '../services/purchase_service.dart';
import '../theme/app_theme.dart';
import 'app_dialog.dart';

/// Pixel-art paywall that uses RevenueCat under the hood for offerings,
/// purchases, and restore — but renders the UI in Dian Dian's own style.
///
/// Apple §3.1.2(a) compliance is handled by:
///  - Listing the benefits and the price per period above the CTA
///  - Showing the auto-renewal disclaimer in the footer
///  - Linking Terms and Privacy
///  - Surfacing "Restore Purchases"
class CustomPaywallDialog extends StatefulWidget {
  const CustomPaywallDialog({super.key});

  /// Returns true if the user is now premium when the dialog closes.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const CustomPaywallDialog(),
    );
    return result ?? false;
  }

  @override
  State<CustomPaywallDialog> createState() => _CustomPaywallDialogState();
}

class _CustomPaywallDialogState extends State<CustomPaywallDialog> {
  static const _termsUrl = 'https://diandian.overridedev.com/terms';
  static const _privacyUrl = 'https://diandian.overridedev.com/privacy';

  final PurchaseService _purchases = PurchaseService();
  List<Package> _packages = [];
  Package? _selected;
  bool _loading = true;
  bool _purchasing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    setState(() => _loading = true);
    if (!_purchases.isInitialized) {
      await _purchases.init();
    }
    Offerings? offerings = _purchases.offerings;
    if (offerings == null) {
      try {
        offerings = await Purchases.getOfferings();
      } catch (e) {
        debugPrint('CustomPaywallDialog: getOfferings failed: $e');
      }
    }

    if (!mounted) return;
    final current = offerings?.current;
    final packages = _orderedPackages(current?.availablePackages ?? []);
    setState(() {
      _packages = packages;
      _selected = _defaultSelection(packages);
      _loading = false;
      if (packages.isEmpty) {
        _error = 'No packages available';
      }
    });
  }

  /// Orders packages so the user sees Monthly → Yearly → Lifetime, ignoring
  /// any other package types (e.g. weekly) that we don't sell here.
  List<Package> _orderedPackages(List<Package> all) {
    final byType = {for (final p in all) p.packageType: p};
    return [
      if (byType.containsKey(PackageType.monthly)) byType[PackageType.monthly]!,
      if (byType.containsKey(PackageType.annual)) byType[PackageType.annual]!,
      if (byType.containsKey(PackageType.lifetime)) byType[PackageType.lifetime]!,
    ];
  }

  Package? _defaultSelection(List<Package> packages) {
    if (packages.isEmpty) return null;
    for (final p in packages) {
      if (p.packageType == PackageType.annual) return p;
    }
    return packages.first;
  }

  /// "Save X%" applies to the annual vs monthly comparison only.
  int? _yearlySavingsPercent() {
    Package? monthly;
    Package? annual;
    for (final p in _packages) {
      if (p.packageType == PackageType.monthly) monthly = p;
      if (p.packageType == PackageType.annual) annual = p;
    }
    if (monthly == null || annual == null) return null;
    final monthlyTotal = monthly.storeProduct.price * 12;
    if (monthlyTotal <= 0) return null;
    final ratio = 1 - annual.storeProduct.price / monthlyTotal;
    if (ratio <= 0) return null;
    return (ratio * 100).round();
  }

  Future<void> _buy() async {
    final pkg = _selected;
    if (pkg == null || _purchasing) return;
    setState(() {
      _purchasing = true;
      _error = null;
    });
    final ok = await context.read<PremiumProvider>().purchasePackage(pkg);
    if (!mounted) return;
    setState(() => _purchasing = false);
    if (ok) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _restore() async {
    if (_purchasing) return;
    setState(() => _purchasing = true);
    final ok = await context.read<PremiumProvider>().restorePurchases();
    if (!mounted) return;
    setState(() => _purchasing = false);
    if (ok) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _openLegalUrl(String base) async {
    final lang = context.read<LanguageProvider>();
    const langCodes = {
      Language.fr: 'fr',
      Language.en: 'en',
      Language.zhCN: 'zh-CN',
      Language.zhTW: 'zh-TW',
    };
    final code = langCodes[lang.lang] ?? 'en';
    final sep = base.contains('?') ? '&' : '?';
    final uri = Uri.parse('$base${sep}lang=$code');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>();

    return AppDialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: _loading
            ? _buildLoading()
            : _packages.isEmpty
                ? _buildError(lang)
                : _buildContent(lang),
      ),
    );
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
        ),
      ),
    );
  }

  Widget _buildError(LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 28, color: AppColors.btnResetText),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Error',
            style: AppFonts.dot(fontSize: 13, color: AppColors.text),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(false),
            child: Text(
              lang.t('common.cancel'),
              style: AppFonts.pixel(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(LanguageProvider lang) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium, size: 32, color: AppColors.accent),
              const SizedBox(height: 8),
              Text(
                lang.t('premium.title'),
                style: AppFonts.pixel(fontSize: 18, color: AppColors.title),
              ),
              const SizedBox(height: 18),

              _benefitsList(lang),
              const SizedBox(height: 18),

              ..._packages.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PackageTile(
                      package: p,
                      selected: identical(p, _selected),
                      onTap: () => setState(() => _selected = p),
                      label: _packageLabel(lang, p),
                      detailLabel: _packageDetail(lang, p),
                      badge: _packageBadge(lang, p),
                    ),
                  )),

              if (_introTrial(lang) != null) ...[
                const SizedBox(height: 4),
                _TrialBanner(info: _introTrial(lang)!),
              ],

              const SizedBox(height: 16),
              GestureDetector(
                onTap: _purchasing ? null : _buy,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _purchasing ? AppColors.dotEmpty : AppColors.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      _selected?.packageType == PackageType.lifetime
                          ? lang.t('premium.purchase')
                          : lang.t('premium.subscribe'),
                      style: AppFonts.pixel(fontSize: 13, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _footerLink(lang.t('premium.restore'), _restore),
                  _dot(),
                  _footerLink(lang.t('premium.terms'), () => _openLegalUrl(_termsUrl)),
                  _dot(),
                  _footerLink(lang.t('premium.privacy'), () => _openLegalUrl(_privacyUrl)),
                ],
              ),
              const SizedBox(height: 14),

              Text(
                lang.t('premium.disclaimer'),
                style: AppFonts.dot(fontSize: 9, color: AppColors.textMuted)
                    .copyWith(height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // Close X
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(false),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.close, size: 16, color: AppColors.textMuted),
            ),
          ),
        ),

        // Overlay spinner during purchase
        if (_purchasing)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.shell.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _benefitsList(LanguageProvider lang) {
    final items = [
      (Icons.grid_view, lang.t('premium.feature.trackers')),
      (Icons.palette, lang.t('premium.feature.themes')),
      (Icons.pets, lang.t('premium.feature.cursor')),
      (Icons.image, lang.t('premium.feature.export')),
      (Icons.bar_chart, lang.t('premium.feature.stats')),
      (Icons.block, lang.t('premium.feature.noAds')),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map((it) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(it.$1, size: 14, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        it.$2,
                        style: AppFonts.dot(fontSize: 12, color: AppColors.text),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _footerLink(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text(
          label,
          style: AppFonts.dot(fontSize: 11, color: AppColors.textMuted),
        ),
      ),
    );
  }

  Widget _dot() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          '·',
          style: AppFonts.pixel(fontSize: 10, color: AppColors.textMuted),
        ),
      );

  String _packageLabel(LanguageProvider lang, Package p) {
    switch (p.packageType) {
      case PackageType.monthly:
        return lang.t('premium.monthly');
      case PackageType.annual:
        return lang.t('premium.yearly');
      case PackageType.lifetime:
        return lang.t('premium.lifetime');
      default:
        return p.storeProduct.title;
    }
  }

  String _packageDetail(LanguageProvider lang, Package p) {
    final price = p.storeProduct.priceString;
    switch (p.packageType) {
      case PackageType.monthly:
        return '$price${lang.t('premium.perMonth')}';
      case PackageType.annual:
        return '$price${lang.t('premium.perYear')}';
      case PackageType.lifetime:
        return price;
      default:
        return price;
    }
  }

  String? _packageBadge(LanguageProvider lang, Package p) {
    if (p.packageType == PackageType.annual) {
      final pct = _yearlySavingsPercent();
      if (pct != null && pct > 0) {
        return lang.t('premium.savePercent').replaceAll('{percent}', '$pct');
      }
      return lang.t('premium.bestValue');
    }
    return null;
  }

  /// Returns trial info for the selected package, or null when there's
  /// no configured free trial. Used to render the highlighted banner above
  /// the CTA so the user can't miss that it's an actual trial they can
  /// cancel — not just bonus days that lock them in.
  _TrialInfo? _introTrial(LanguageProvider lang) {
    final pkg = _selected;
    if (pkg == null) return null;
    final intro = pkg.storeProduct.introductoryPrice;
    if (intro == null) return null;
    if (intro.price > 0) return null; // paid intro, not a free trial

    final days = _periodDays(intro.period);
    if (days == null || days <= 0) return null;

    final detail = _packageDetail(lang, pkg);
    return _TrialInfo(
      headline: lang.t('premium.freeTrialDays').replaceAll('{days}', '$days'),
      cancelHint: lang.t('premium.cancelAnytime'),
      thenLine: lang.t('premium.thenPrice').replaceAll('{price}', detail),
    );
  }

  /// Parses an ISO-8601 duration like `P1W`, `P3D`, `P1M` into a day count.
  /// Returns null if we can't make sense of it (caller hides the trial line).
  int? _periodDays(String period) {
    final match = RegExp(r'^P(\d+)([DWMY])$').firstMatch(period);
    if (match == null) return null;
    final n = int.parse(match.group(1)!);
    switch (match.group(2)) {
      case 'D':
        return n;
      case 'W':
        return n * 7;
      case 'M':
        return n * 30;
      case 'Y':
        return n * 365;
      default:
        return null;
    }
  }
}

class _TrialInfo {
  final String headline;
  final String cancelHint;
  final String thenLine;

  const _TrialInfo({
    required this.headline,
    required this.cancelHint,
    required this.thenLine,
  });
}

class _TrialBanner extends StatelessWidget {
  final _TrialInfo info;

  const _TrialBanner({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.10),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, size: 12, color: AppColors.accent),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  info.headline,
                  style: AppFonts.pixel(fontSize: 11, color: AppColors.accent),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '${info.thenLine}  ·  ${info.cancelHint}',
            style: AppFonts.dot(fontSize: 11, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  final Package package;
  final bool selected;
  final VoidCallback onTap;
  final String label;
  final String detailLabel;
  final String? badge;

  const _PackageTile({
    required this.package,
    required this.selected,
    required this.onTap,
    required this.label,
    required this.detailLabel,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withValues(alpha: 0.12) : AppColors.shell,
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.shellBorder,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.accent : AppColors.dotBorder,
                  width: 1.5,
                ),
                color: selected ? AppColors.accent : Colors.transparent,
              ),
              child: selected
                  ? Icon(Icons.check, size: 9, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppFonts.pixel(fontSize: 12, color: AppColors.text),
                  ),
                  if (badge != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      badge!,
                      style: AppFonts.dot(fontSize: 10, color: AppColors.accent),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              detailLabel,
              style: AppFonts.pixel(fontSize: 12, color: AppColors.title),
            ),
          ],
        ),
      ),
    );
  }
}

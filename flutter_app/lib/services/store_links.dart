import 'package:url_launcher/url_launcher.dart';

/// Canonical store URLs and helpers to open them.
///
/// Apple's redirector handles region + locale automatically with the short
/// `app/idXXXXX` form. Android uses the `market://` scheme for a direct hop
/// into the Play Store app, falling back to the web URL.
class StoreLinks {
  static const String appStoreId = '6761432329';
  static const String androidPackage = 'app.mydiandian.dian_dian';

  static const String appStoreUrl = 'https://apps.apple.com/app/id$appStoreId';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=$androidPackage';

  static Future<void> openAppStore() async {
    await launchUrl(Uri.parse(appStoreUrl), mode: LaunchMode.externalApplication);
  }

  static Future<void> openPlayStore() async {
    final market = Uri.parse('market://details?id=$androidPackage');
    if (await canLaunchUrl(market)) {
      await launchUrl(market, mode: LaunchMode.externalApplication);
      return;
    }
    await launchUrl(Uri.parse(playStoreUrl), mode: LaunchMode.externalApplication);
  }
}

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

/// Banner shown only on web to invite users to download the native app.
class DownloadAppBanner extends StatefulWidget {
  final VoidCallback? onDismissed;

  const DownloadAppBanner({super.key, this.onDismissed});

  @override
  State<DownloadAppBanner> createState() => _DownloadAppBannerState();
}

class _DownloadAppBannerState extends State<DownloadAppBanner> {
  bool _dismissed = false;

  // TODO: replace with real store URLs once published
  static const _appStoreUrl = 'https://apps.apple.com/app/dian-dian-year-tracker/id6761432329';
  static const _playStoreUrl = 'https://play.google.com/store/apps/details?id=app.mydiandian.dian_dian';

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<Widget> _buildStoreLinks() {
    final platform = defaultTargetPlatform;
    final isIOS = platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    final isAndroid = platform == TargetPlatform.android;

    final links = <Widget>[];

    if (!isAndroid) {
      links.add(_storeLink(Icons.apple, 'App Store', _appStoreUrl));
    }
    if (!isIOS) {
      if (links.isNotEmpty) links.add(const SizedBox(width: 16));
      links.add(_storeLink(Icons.shop, 'Google Play', _playStoreUrl));
    }

    return links;
  }

  Widget _storeLink(IconData icon, String label, String url) {
    return GestureDetector(
      onTap: () => _openUrl(url),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accent),
          const SizedBox(width: 3),
          Text(label, style: AppFonts.dot(fontSize: 11, color: AppColors.accent)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || _dismissed) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.shell,
        border: Border(
          top: BorderSide(color: AppColors.shellBorder, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Get the app',
                  style: AppFonts.pixel(fontSize: 10, color: AppColors.title),
                ),
                const SizedBox(height: 2),
                Row(
                  children: _buildStoreLinks(),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() => _dismissed = true);
              widget.onDismissed?.call();
            },
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close, size: 14, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

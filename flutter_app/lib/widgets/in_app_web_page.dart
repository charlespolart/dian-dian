import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import 'top_bar.dart';

/// Appends `?lang=<code>` to a dian-dian legal/about URL so the backend can
/// serve the page in the active locale. The path stays the same; the server
/// reads the query param.
Uri localizedDianDianUri(String baseUrl, Language lang) {
  const codes = {
    Language.fr: 'fr',
    Language.en: 'en',
    Language.zhCN: 'zh-CN',
    Language.zhTW: 'zh-TW',
  };
  final code = codes[lang] ?? 'en';
  final sep = baseUrl.contains('?') ? '&' : '?';
  return Uri.parse('$baseUrl${sep}lang=$code');
}

/// Pushes a fullscreen route that renders [uri] inside an embedded WebView.
///
/// Use for self-hosted documents (Terms, Privacy, About, Contact, Legal).
/// For URLs that should hand off to another app — App Store / Play Store
/// deep links, mailto:, tel: — keep `launchUrl` with externalApplication.
Future<void> showInAppWebPage(
  BuildContext context, {
  required Uri uri,
  String? title,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _InAppWebPage(uri: uri, title: title ?? uri.host),
    ),
  );
}

class _InAppWebPage extends StatefulWidget {
  const _InAppWebPage({required this.uri, required this.title});

  final Uri uri;
  final String title;

  @override
  State<_InAppWebPage> createState() => _InAppWebPageState();
}

class _InAppWebPageState extends State<_InAppWebPage> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.bg)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(widget.uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              onBack: () => Navigator.of(context).pop(),
              title: widget.title,
            ),
            if (_loading)
              SizedBox(
                height: 2,
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.accent,
                  backgroundColor: AppColors.bgDot,
                ),
              ),
            Expanded(child: WebViewWidget(controller: _controller)),
          ],
        ),
      ),
    );
  }
}

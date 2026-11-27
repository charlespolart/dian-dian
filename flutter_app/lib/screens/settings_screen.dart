import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/premium_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/sounds_settings.dart';
import '../widgets/confirm_dialog.dart';
import '../providers/theme_provider.dart';
import '../widgets/language_picker_dialog.dart';
import '../widgets/cursor_picker_dialog.dart';
import '../widgets/in_app_web_page.dart';
import '../widgets/premium_gate_dialog.dart';
import '../widgets/theme_picker_dialog.dart';
import '../widgets/top_bar.dart';
import '../widgets/contact_dialog.dart';
import '../widgets/press_scale.dart';
import '../services/sync_service.dart';
import '../widgets/connection_needed_dialog.dart';
import '../widgets/session_dialogs.dart';
import '../widgets/account_section.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onBack;

  const SettingsScreen({super.key, required this.onBack});

  static final Future<String> _versionFuture = PackageInfo.fromPlatform().then(
    (info) => info.version,
  );
  static const String _aboutUrl = 'https://diandian.overridedev.com/about';
  static const String _privacyUrl = 'https://diandian.overridedev.com/privacy';
  static const String _termsUrl = 'https://diandian.overridedev.com/terms';
  static const String _legalUrl = 'https://diandian.overridedev.com/legal';

  /// Opens a self-hosted legal/about page inside the app via WebView.
  void _openLegal(BuildContext context, String url, String title) {
    final lang = context.read<LanguageProvider>();
    showInAppWebPage(
      context,
      uri: localizedDianDianUri(url, lang.lang),
      title: title,
    );
  }

  /// Hands off to another app (App Store subscription page) — stays external.
  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    context.watch<ThemeProvider>(); // rebuild when theme changes

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(onBack: onBack, title: lang.t('settings.title')),

            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Language section
                        _buildSectionTitle(lang.t('settings.language')),
                        const SizedBox(height: 8),
                        _buildLanguageSelector(context, lang),

                        const SizedBox(height: 24),

                        // Premium section
                        _buildSectionTitle(lang.t('settings.premium')),
                        const SizedBox(height: 8),
                        _buildPremiumTile(context, lang),

                        const SizedBox(height: 24),

                        // Theme section
                        _buildSectionTitle(lang.t('settings.theme')),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            final themeProv = context.watch<ThemeProvider>();
                            return _buildLinkTile(
                              label: appThemeNames[themeProv.currentTheme]!,
                              onTap: () => showThemePickerDialog(context),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Cursor section
                        _buildSectionTitle(lang.t('settings.cursor')),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            final premium = context.watch<PremiumProvider>();
                            return _buildLinkTile(
                              label: premium.cursorEnabled
                                  ? lang.t('settings.cursorAnimated')
                                  : lang.t('cursor.none'),
                              onTap: () => showCursorPickerDialog(context),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Sounds section
                        const SoundsSettings(),

                        const SizedBox(height: 24),

                        // Links section
                        _buildSectionTitle('Links'),
                        const SizedBox(height: 8),
                        _buildLinkTile(
                          label: lang.t('settings.about'),
                          onTap: () => _openLegal(
                            context,
                            _aboutUrl,
                            lang.t('settings.about'),
                          ),
                        ),
                        _buildLinkTile(
                          label: lang.t('settings.contact'),
                          onTap: () {
                            final auth = context.read<AuthProvider>();
                            ContactDialog.show(
                              context,
                              email: auth.email,
                              userId: auth.userId,
                              version: _versionFuture,
                            );
                          },
                        ),
                        _buildLinkTile(
                          label: lang.t('settings.privacy'),
                          onTap: () => _openLegal(
                            context,
                            _privacyUrl,
                            lang.t('settings.privacy'),
                          ),
                        ),
                        _buildLinkTile(
                          label: lang.t('settings.terms'),
                          onTap: () => _openLegal(
                            context,
                            _termsUrl,
                            lang.t('settings.terms'),
                          ),
                        ),
                        _buildLinkTile(
                          label: lang.t('settings.legal'),
                          onTap: () => _openLegal(
                            context,
                            _legalUrl,
                            lang.t('settings.legal'),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Version
                        Center(
                          child: FutureBuilder<String>(
                            future: _versionFuture,
                            builder: (context, snapshot) {
                              final version = snapshot.data ?? '';
                              return Text(
                                '${lang.t('settings.version')} $version',
                                style: AppFonts.dot(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Account section: its two forms (chantier 9, case 10)
                        AccountSection(onLogout: () => _handleLogout(context, lang)),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppFonts.pixel(fontSize: 13, color: AppColors.subtitle),
    );
  }

  Widget _buildPremiumTile(BuildContext context, LanguageProvider lang) {
    final premium = context.watch<PremiumProvider>();

    if (premium.isPremium) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.shell,
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.star_rounded, size: 18, color: AppColors.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                lang.t('premium.active'),
                style: AppFonts.pixel(fontSize: 13, color: AppColors.accent),
              ),
            ),
            PressScale(
              onTap: () async {
                if (kIsWeb) {
                  _openExternal('https://apps.apple.com/account/subscriptions');
                } else if (!await ConnectionNeededDialog.blockIfOffline(context)) {
                  RevenueCatUI.presentCustomerCenter();
                }
              },
              child: Text(
                lang.t('premium.manage'),
                style: AppFonts.dot(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      );
    }

    return _buildLinkTile(
      label: lang.t('premium.free'),
      onTap: () =>
          PremiumGateDialog.show(context, feature: lang.t('premium.upgrade'), event: 'settings_upgrade'),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, LanguageProvider lang) {
    return _buildLinkTile(
      label: lang.t(languageNameKeys[lang.lang]!),
      onTap: () => showLanguagePickerDialog(context, lang),
    );
  }

  Widget _buildLinkTile({required String label, required VoidCallback onTap}) {
    return PressScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: AppColors.shell,
          border: Border.all(color: AppColors.shellBorder),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppFonts.dot(fontSize: 14, color: AppColors.text),
            ),
            Text(
              '>',
              style: AppFonts.pixel(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(
    BuildContext context,
    LanguageProvider lang,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: lang.t('settings.logout'),
      message: lang.t('settings.logoutConfirm'),
      confirmLabel: lang.t('common.yes'),
      cancelLabel: lang.t('common.cancel'),
    );

    if (confirmed != true || !context.mounted) return;
    // H10: the queue leaves first; offline with changes waiting, ask.
    final engine = context.read<SyncService>().engine.value;
    final go = await SessionDialogs.confirmSignOut(
      context,
      flush: () async => engine == null || await engine.flush(timeout: const Duration(seconds: 10)),
      pending: () => engine?.pendingCount ?? 0,
    );
    if (go && context.mounted) await context.read<AuthProvider>().logout();
  }
}

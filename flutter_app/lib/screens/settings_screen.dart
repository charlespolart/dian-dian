import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/premium_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialog.dart';
import '../widgets/confirm_dialog.dart';
import '../providers/theme_provider.dart';
import '../widgets/language_picker_dialog.dart';
import '../widgets/cursor_picker_dialog.dart';
import '../widgets/premium_gate_dialog.dart';
import '../widgets/theme_picker_dialog.dart';
import '../widgets/top_bar.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onBack;

  const SettingsScreen({
    super.key,
    required this.onBack,
  });

  static const String _version = '1.0.0';
  static const String _aboutUrl = 'https://mydiandian.app/about';
  static const String _contactUrl = 'https://mydiandian.app/contact';
  static const String _privacyUrl = 'https://mydiandian.app/privacy';
  static const String _termsUrl = 'https://mydiandian.app/terms';

  Future<void> _openUrl(String url) async {
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
            TopBar(
              onBack: onBack,
              title: lang.t('settings.title'),
            ),

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
                    Builder(builder: (context) {
                      final themeProv = context.watch<ThemeProvider>();
                      return _buildLinkTile(
                        label: appThemeNames[themeProv.currentTheme]!,
                        onTap: () => showThemePickerDialog(context),
                      );
                    }),

                    const SizedBox(height: 24),

                    // Cursor section
                    _buildSectionTitle(lang.t('settings.cursor')),
                    const SizedBox(height: 8),
                    Builder(builder: (context) {
                      final premium = context.watch<PremiumProvider>();
                      return _buildLinkTile(
                        label: premium.cursorEnabled
                            ? lang.t('settings.cursorAnimated')
                            : lang.t('cursor.none'),
                        onTap: () => showCursorPickerDialog(context),
                      );
                    }),

                    const SizedBox(height: 24),

                    // Links section
                    _buildSectionTitle('Links'),
                    const SizedBox(height: 8),
                    _buildLinkTile(
                      label: lang.t('settings.about'),
                      onTap: () => _openUrl(_aboutUrl),
                    ),
                    _buildLinkTile(
                      label: lang.t('settings.contact'),
                      onTap: () => _openUrl(_contactUrl),
                    ),
                    _buildLinkTile(
                      label: lang.t('settings.privacy'),
                      onTap: () => _openUrl(_privacyUrl),
                    ),
                    _buildLinkTile(
                      label: lang.t('settings.terms'),
                      onTap: () => _openUrl(_termsUrl),
                    ),

                    const SizedBox(height: 24),

                    // Version
                    Center(
                      child: Text(
                        '${lang.t('settings.version')} $_version',
                        style: AppFonts.dot(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Account section

                    // Logout
                    _buildActionButton(
                      context: context,
                      label: lang.t('settings.logout'),
                      bgColor: AppColors.inputBg,
                      borderColor: AppColors.inputBorder,
                      textColor: AppColors.text,
                      onTap: () => _handleLogout(context, lang),
                    ),
                    const SizedBox(height: 12),

                    // Delete account
                    _buildActionButton(
                      context: context,
                      label: lang.t('settings.deleteAccount'),
                      bgColor: AppColors.btnReset,
                      borderColor: AppColors.btnResetBorder,
                      textColor: AppColors.btnResetText,
                      onTap: () => _handleDeleteAccount(context, lang),
                    ),

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
    return _buildLinkTile(
      label: premium.isPremium ? lang.t('premium.active') : lang.t('premium.free'),
      onTap: () {
        if (premium.isPremium) return;
        PremiumGateDialog.show(context, feature: lang.t('premium.upgrade'));
      },
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    LanguageProvider lang,
  ) {
    return _buildLinkTile(
      label: lang.t(languageNameKeys[lang.lang]!),
      onTap: () => showLanguagePickerDialog(context, lang),
    );
  }

  Widget _buildLinkTile({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
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

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            label,
            style: AppFonts.pixel(fontSize: 13, color: textColor),
          ),
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

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }

  Future<void> _handleDeleteAccount(
    BuildContext context,
    LanguageProvider lang,
  ) async {
    final email = context.read<AuthProvider>().email;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteAccountDialog(lang: lang, email: email),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ApiService().apiFetch('/api/auth/account', method: 'DELETE');
        if (context.mounted) {
          await context.read<AuthProvider>().logout();
        }
      } catch (e) {
        debugPrint('Delete account failed: $e');
      }
    }
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  final LanguageProvider lang;
  final String? email;

  const _DeleteAccountDialog({required this.lang, this.email});

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _controller = TextEditingController();
  bool _canConfirm = false;

  String get _confirmText => widget.email ?? 'DELETE';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final match = _controller.text.trim() == _confirmText;
      if (match != _canConfirm) setState(() => _canConfirm = match);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;

    return AppDialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lang.t('settings.deleteAccount'),
              style: AppFonts.pixel(fontSize: 16, color: AppColors.btnResetText),
            ),
            const SizedBox(height: 12),
            Text(
              lang.t('settings.deleteAccountConfirm'),
              style: AppFonts.dot(fontSize: 13, color: AppColors.text),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              widget.email != null
                  ? lang.t('settings.typeEmail')
                  : lang.t('settings.typeDelete'),
              style: AppFonts.dot(fontSize: 12, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              style: AppFonts.dot(fontSize: 14, color: AppColors.inputText),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: _confirmText,
                hintStyle: AppFonts.dot(fontSize: 14, color: AppColors.textMuted),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Text(
                    lang.t('common.cancel'),
                    style: AppFonts.pixel(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: _canConfirm
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _canConfirm ? AppColors.btnReset : AppColors.dotEmpty,
                      border: Border.all(
                        color: _canConfirm
                            ? AppColors.btnResetBorder
                            : AppColors.dotBorder,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 14,
                          color: _canConfirm
                              ? AppColors.btnResetText
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          lang.t('common.delete'),
                          style: AppFonts.pixel(
                            fontSize: 12,
                            color: _canConfirm
                                ? AppColors.btnResetText
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

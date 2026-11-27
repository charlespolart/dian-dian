import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/connection_needed_dialog.dart';
import '../widgets/language_dropdown.dart';
import '../widgets/oauth_buttons.dart';

/// The first screen without a session (chantier 9): Apple (iPhone only),
/// Google, e-mail and « Continuer sans compte », four buttons of the same
/// size and weight — the account is offered, never a wall. Without a
/// network, the three ways into an account say so; « sans compte » enters
/// all the same (case 5).
class WelcomeScreen extends StatefulWidget {
  /// « Continuer avec un e-mail »: the e-mail screen.
  final VoidCallback onEmail;
  final IdentityWindows windows;

  const WelcomeScreen({super.key, required this.onEmail, this.windows = const IdentityWindows()});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String? _error;
  bool _entering = false;

  /// True, after saying so, when there is no network to reach an account.
  Future<bool> _blocked() async {
    setState(() => _error = null);
    return ConnectionNeededDialog.blockIfOffline(context, message: context.read<LanguageProvider>().t('welcome.offline'));
  }

  Future<void> _email() async {
    if (await _blocked()) return;
    widget.onEmail();
  }

  Future<void> _withoutAccount() async {
    if (_entering) return;
    setState(() {
      _entering = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().continueWithoutAccount();
    } catch (e) {
      // The phone could not keep the account's key: nothing was begun.
      if (mounted) setState(() => _error = context.read<LanguageProvider>().t('welcome.keyFailed'));
    } finally {
      if (mounted) setState(() => _entering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(top: 8, right: 16, child: LanguageDropdown(lang: lang)),
            Center(
              child: SingleChildScrollView(
                // Narrower margins than the e-mail screen's: the buttons'
                // labels keep their size on a 360-point phone.
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('点点', style: AppFonts.pixel(fontSize: 36, color: AppColors.title)),
                      const SizedBox(height: 4),
                      Text('Dian Dian', style: AppFonts.pixel(fontSize: 14, color: AppColors.subtitle)),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.shell,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.shellBorder),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OAuthButtons(
                              windows: widget.windows,
                              blocked: _blocked,
                              onError: (msg) => setState(() => _error = msg),
                              trailing: [
                                AuthChoice(
                                  key: const ValueKey('welcome.email'),
                                  icon: const Icon(Icons.mail_outline, size: 20, color: Colors.black),
                                  label: lang.t('welcome.email'),
                                  onPressed: _email,
                                ),
                                AuthChoice(
                                  key: const ValueKey('welcome.noAccount'),
                                  icon: const Icon(Icons.smartphone_outlined, size: 20, color: Colors.black),
                                  label: lang.t('welcome.noAccount'),
                                  onPressed: _entering ? null : _withoutAccount,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              lang.t('welcome.note'),
                              textAlign: TextAlign.center,
                              style: AppFonts.dot(fontSize: 12, color: AppColors.textMuted),
                            ),
                            if (_error != null)
                              Padding(
                                key: const ValueKey('welcome.error'),
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: AppFonts.dot(fontSize: 12, color: AppColors.btnResetText),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

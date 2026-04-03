import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ForgotPasswordScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _loading = true;
    });

    try {
      await ApiService().forgotPassword(email);
    } catch (_) {
      // Show success regardless to prevent email enumeration
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _sent = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Chinese title
              Text(
                '\u70B9\u70B9',
                style: AppFonts.pixel(fontSize: 36, color: AppColors.title),
              ),
              const SizedBox(height: 4),

              // Subtitle
              Text(
                'Dian Dian',
                style: AppFonts.pixel(fontSize: 14, color: AppColors.subtitle),
              ),
              const SizedBox(height: 32),

              // Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.shell,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.shellBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      lang.t('auth.forgotPassword'),
                      style: AppFonts.pixel(
                        fontSize: 16,
                        color: AppColors.title,
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_sent) ...[
                      // Success message
                      Text(
                        lang.t('auth.forgotPasswordSent'),
                        style: AppFonts.dot(
                          fontSize: 13,
                          color: AppColors.text,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      // Email field
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        style: AppFonts.dot(
                          fontSize: 14,
                          color: AppColors.inputText,
                        ),
                        decoration: InputDecoration(
                          labelText: lang.t('auth.email'),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendResetLink(),
                      ),
                      const SizedBox(height: 16),

                      // Send button
                      GestureDetector(
                        onTap: _loading ? null : _sendResetLink,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.btnAdd,
                            border: Border.all(color: AppColors.btnAddBorder),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: _loading
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.btnAddText,
                                    ),
                                  )
                                : Text(
                                    lang.t('auth.forgotPasswordBtn'),
                                    style: AppFonts.pixel(
                                      fontSize: 13,
                                      color: AppColors.btnAddText,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Back to login
              GestureDetector(
                onTap: widget.onBack,
                child: Text(
                  lang.t('auth.backToLogin'),
                  style: AppFonts.dot(fontSize: 13, color: AppColors.accent),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

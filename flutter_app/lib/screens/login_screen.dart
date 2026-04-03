import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/language_dropdown.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onSwitchToRegister;
  final VoidCallback onForgotPassword;

  const LoginScreen({
    super.key,
    required this.onSwitchToRegister,
    required this.onForgotPassword,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await context.read<AuthProvider>().login(email, password);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        final lang = context.read<LanguageProvider>();
        setState(() => _error = lang.t('auth.loginError'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
            // Language selector top-right
            Positioned(
              top: 8,
              right: 16,
              child: LanguageDropdown(lang: lang),
            ),
            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Stars decoration
              Text(
                '. * . . * .',
                style: AppFonts.pixel(
                  fontSize: 12,
                  color: AppColors.star,
                ),
              ),
              const SizedBox(height: 16),

              // Chinese title
              Text(
                '\u70B9\u70B9',
                style: AppFonts.pixel(
                  fontSize: 36,
                  color: AppColors.title,
                ),
              ),
              const SizedBox(height: 4),

              // Subtitle
              Text(
                'Dian Dian',
                style: AppFonts.pixel(
                  fontSize: 14,
                  color: AppColors.subtitle,
                ),
              ),
              const SizedBox(height: 8),

              // Stars decoration
              Text(
                '*  .  *  .  *',
                style: AppFonts.pixel(
                  fontSize: 10,
                  color: AppColors.star,
                ),
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
                      lang.t('auth.login'),
                      style: AppFonts.pixel(
                        fontSize: 16,
                        color: AppColors.title,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Email
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
                    ),
                    const SizedBox(height: 12),

                    // Password
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: AppFonts.dot(
                        fontSize: 14,
                        color: AppColors.inputText,
                      ),
                      decoration: InputDecoration(
                        labelText: lang.t('auth.password'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 8),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: widget.onForgotPassword,
                        child: Text(
                          lang.t('auth.forgotPassword'),
                          style: AppFonts.dot(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Error
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _error!,
                          style: AppFonts.dot(
                            fontSize: 12,
                            color: AppColors.btnResetText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Login button
                    GestureDetector(
                      onTap: _loading ? null : _login,
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
                                  lang.t('auth.loginBtn'),
                                  style: AppFonts.pixel(
                                    fontSize: 13,
                                    color: AppColors.btnAddText,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Switch to register
              GestureDetector(
                onTap: widget.onSwitchToRegister,
                child: Text(
                  lang.t('auth.switchToRegister'),
                  style: AppFonts.dot(
                    fontSize: 13,
                    color: AppColors.accent,
                  ),
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


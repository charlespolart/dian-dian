import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/language_dropdown.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onSwitchToLogin;

  const RegisterScreen({
    super.key,
    required this.onSwitchToLogin,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final lang = context.read<LanguageProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty) return;

    if (password.length < 8) {
      setState(() => _error = lang.t('auth.passwordMin'));
      return;
    }

    if (password != confirm) {
      setState(() => _error = lang.t('auth.passwordMismatch'));
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await context.read<AuthProvider>().register(email, password);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = lang.t('auth.registerError'));
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
                style: AppFonts.pixel(fontSize: 12, color: AppColors.star),
              ),
              const SizedBox(height: 16),

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
              const SizedBox(height: 8),

              // Stars decoration
              Text(
                '*  .  *  .  *',
                style: AppFonts.pixel(fontSize: 10, color: AppColors.star),
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
                      lang.t('auth.register'),
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
                    ),
                    const SizedBox(height: 12),

                    // Confirm password
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      style: AppFonts.dot(
                        fontSize: 14,
                        color: AppColors.inputText,
                      ),
                      decoration: InputDecoration(
                        labelText: lang.t('auth.confirmPassword'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _register(),
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

                    // Register button
                    GestureDetector(
                      onTap: _loading ? null : _register,
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
                                  lang.t('auth.registerBtn'),
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

              // Switch to login
              GestureDetector(
                onTap: widget.onSwitchToLogin,
                child: Text(
                  lang.t('auth.switchToLogin'),
                  style: AppFonts.dot(fontSize: 13, color: AppColors.accent),
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


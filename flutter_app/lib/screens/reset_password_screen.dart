import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;
  final VoidCallback onBackToLogin;

  const ResetPasswordScreen({
    super.key,
    required this.token,
    required this.onBackToLogin,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  bool _success = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final lang = context.read<LanguageProvider>();
    final p1 = _passwordController.text;
    final p2 = _confirmController.text;
    if (p1.length < 8) {
      setState(() => _error = lang.t('auth.passwordMin'));
      return;
    }
    if (p1 != p2) {
      setState(() => _error = lang.t('auth.passwordMismatch'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ApiService().resetPassword(widget.token, p1);
      if (mounted) {
        setState(() {
          _loading = false;
          _success = true;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
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
                Text(
                  '点点',
                  style: AppFonts.pixel(fontSize: 36, color: AppColors.title),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dian Dian',
                  style: AppFonts.pixel(fontSize: 14, color: AppColors.subtitle),
                ),
                const SizedBox(height: 32),
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
                      Text(
                        lang.t('auth.resetPassword'),
                        style: AppFonts.pixel(fontSize: 16, color: AppColors.title),
                      ),
                      const SizedBox(height: 20),
                      if (_success) ...[
                        Text(
                          lang.t('auth.resetPasswordSuccess'),
                          style: AppFonts.dot(fontSize: 13, color: AppColors.text),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: widget.onBackToLogin,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.btnAdd,
                              border: Border.all(color: AppColors.btnAddBorder),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                lang.t('auth.login'),
                                style: AppFonts.pixel(
                                  fontSize: 13,
                                  color: AppColors.btnAddText,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          autocorrect: false,
                          style: AppFonts.dot(fontSize: 14, color: AppColors.inputText),
                          decoration: InputDecoration(
                            labelText: lang.t('auth.password'),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _confirmController,
                          obscureText: true,
                          autocorrect: false,
                          style: AppFonts.dot(fontSize: 14, color: AppColors.inputText),
                          decoration: InputDecoration(
                            labelText: lang.t('auth.confirmPassword'),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: AppFonts.dot(fontSize: 12, color: AppColors.btnResetText),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _loading ? null : _submit,
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
                                      lang.t('auth.resetPasswordBtn'),
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
                if (!_success)
                  GestureDetector(
                    onTap: widget.onBackToLogin,
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

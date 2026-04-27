import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/password_field.dart';

enum _Step { email, code }

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
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  _Step _step = _Step.email;
  bool _loading = false;
  bool _success = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ApiService().forgotPassword(email);
      if (mounted) {
        setState(() {
          _loading = false;
          _step = _Step.code;
        });
      }
    } catch (_) {
      // Always advance — backend doesn't reveal whether the email exists.
      if (mounted) {
        setState(() {
          _loading = false;
          _step = _Step.code;
        });
      }
    }
  }

  Future<void> _submitCode() async {
    final lang = context.read<LanguageProvider>();
    final code = _codeController.text.trim();
    final p1 = _passwordController.text;
    final p2 = _confirmController.text;

    if (code.length != 6) {
      setState(() => _error = lang.t('auth.codeInvalid'));
      return;
    }
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
      await ApiService().resetPassword(
        email: _emailController.text.trim(),
        code: code,
        password: p1,
      );
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
                        _step == _Step.email
                            ? lang.t('auth.forgotPassword')
                            : lang.t('auth.resetPassword'),
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
                        _primaryButton(
                          label: lang.t('auth.login'),
                          onTap: widget.onBack,
                        ),
                      ] else if (_step == _Step.email)
                        ..._buildEmailStep(lang)
                      else
                        ..._buildCodeStep(lang),
                    ],
                  ),
                ),
                if (!_success) ...[
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: widget.onBack,
                    child: Text(
                      lang.t('auth.backToLogin'),
                      style: AppFonts.dot(fontSize: 13, color: AppColors.accent),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEmailStep(LanguageProvider lang) {
    return [
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        style: AppFonts.dot(fontSize: 14, color: AppColors.inputText),
        decoration: InputDecoration(
          labelText: lang.t('auth.email'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        onSubmitted: (_) => _sendCode(),
      ),
      const SizedBox(height: 16),
      _primaryButton(
        label: lang.t('auth.forgotPasswordBtn'),
        onTap: _loading ? null : _sendCode,
      ),
    ];
  }

  List<Widget> _buildCodeStep(LanguageProvider lang) {
    return [
      Text(
        '${lang.t('auth.enterCode')} (${_emailController.text.trim()})',
        style: AppFonts.dot(fontSize: 12, color: AppColors.textMuted),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _codeController,
        keyboardType: TextInputType.number,
        autocorrect: false,
        maxLength: 6,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: AppFonts.pixel(fontSize: 18, color: AppColors.inputText),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: lang.t('auth.codeLabel'),
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
      const SizedBox(height: 12),
      PasswordField(
        controller: _passwordController,
        labelText: lang.t('auth.password'),
      ),
      const SizedBox(height: 12),
      PasswordField(
        controller: _confirmController,
        labelText: lang.t('auth.confirmPassword'),
        onSubmitted: (_) => _submitCode(),
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
      _primaryButton(
        label: lang.t('auth.resetPasswordBtn'),
        onTap: _loading ? null : _submitCode,
      ),
    ];
  }

  Widget _primaryButton({required String label, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
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
                  label,
                  style: AppFonts.pixel(fontSize: 13, color: AppColors.btnAddText),
                ),
        ),
      ),
    );
  }
}

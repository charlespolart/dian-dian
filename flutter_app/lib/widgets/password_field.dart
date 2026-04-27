import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Standard password TextField with an eye toggle to reveal the value.
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  const PasswordField({
    super.key,
    required this.controller,
    this.labelText,
    this.onSubmitted,
    this.autofillHints,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscured,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: widget.autofillHints,
      onSubmitted: widget.onSubmitted,
      style: AppFonts.dot(fontSize: 14, color: AppColors.inputText),
      decoration: InputDecoration(
        labelText: widget.labelText,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        suffixIcon: IconButton(
          splashRadius: 18,
          icon: Icon(
            _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 18,
            color: AppColors.textMuted,
          ),
          onPressed: () => setState(() => _obscured = !_obscured),
        ),
      ),
    );
  }
}

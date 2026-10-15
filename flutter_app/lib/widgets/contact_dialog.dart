import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'app_dialog.dart';
import 'utf16_length_limit.dart';

enum ContactReason { idea, bug, question }

extension on ContactReason {
  /// Mail-side tag, always English (it is for us, not the user).
  String get tag => switch (this) {
        ContactReason.idea => 'Idea',
        ContactReason.bug => 'Bug',
        ContactReason.question => 'Question',
      };

  String get labelKey => switch (this) {
        ContactReason.idea => 'contact.reasonIdea',
        ContactReason.bug => 'contact.reasonBug',
        ContactReason.question => 'contact.reasonQuestion',
      };
}

/// In-app contact form: idea, bug or question, sent through the existing
/// `POST /api/contact` (mail to contact@…). The reply address is the
/// account email, editable; user id, app version, platform and language are
/// appended for us so nobody has to type them.
class ContactDialog extends StatefulWidget {
  final String? email;
  final String? userId;
  final Future<String> version;
  final ApiService api;

  const ContactDialog({
    super.key,
    required this.email,
    required this.userId,
    required this.version,
    required this.api,
  });

  static Future<void> show(
    BuildContext context, {
    required String? email,
    required String? userId,
    required Future<String> version,
    ApiService? api,
  }) {
    return showDialog(
      context: context,
      builder: (_) => ContactDialog(email: email, userId: userId, version: version, api: api ?? ApiService()),
    );
  }

  @override
  State<ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<ContactDialog> {
  static final _emailShape = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  ContactReason _reason = ContactReason.idea;
  late final TextEditingController _message = TextEditingController();
  late final TextEditingController _email = TextEditingController(text: widget.email ?? '');
  bool _busy = false;
  bool _sent = false;
  String? _errorKey;

  @override
  void dispose() {
    _message.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _send(LanguageProvider lang) async {
    if (_busy) return;
    final text = _message.text.trim();
    final email = _email.text.trim();
    if (text.isEmpty) return;
    if (!_emailShape.hasMatch(email)) {
      setState(() => _errorKey = 'auth.invalidEmail');
      return;
    }
    setState(() {
      _busy = true;
      _errorKey = null;
    });
    final version = await widget.version;
    final trailer = [
      '',
      '—',
      'user: ${widget.userId ?? 'unknown'}',
      'app: $version · ${defaultTargetPlatform.name} ${Platform.operatingSystemVersion}',
      'lang: ${lang.lang.name}',
    ].join('\n');
    var ok = false;
    try {
      final response = await widget.api.apiFetch(
        '/api/contact',
        method: 'POST',
        body: {
          'name': 'App · ${_reason.tag}',
          'email': email,
          'message': '[${_reason.tag}] $text\n$trailer',
        },
      );
      ok = response.statusCode == 200;
      if (!ok) debugPrint('ContactDialog: ${response.statusCode} ${response.body}');
    } catch (e) {
      debugPrint('ContactDialog: send failed: $e');
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _sent = ok;
      _errorKey = ok ? null : 'contact.error';
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return AppDialog(
      footer: _sent
          ? Center(child: _button(lang.t('common.ok'), () => Navigator.of(context).pop()))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  button: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _busy ? null : () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text(
                        lang.t('common.cancel'),
                        style: AppFonts.pixel(fontSize: 12, color: _busy ? AppColors.dotEmpty : AppColors.textMuted),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                _button(lang.t('contact.send'), () => _send(lang), busy: _busy),
              ],
            ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: _sent ? _buildSent(lang) : _buildForm(lang),
      ),
    );
  }

  Widget _buildSent(LanguageProvider lang) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(lang.t('contact.title'), style: AppFonts.pixel(fontSize: 16, color: AppColors.title)),
        const SizedBox(height: 16),
        Text(
          lang.t('contact.sent'),
          style: AppFonts.dot(fontSize: 14, color: AppColors.text),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm(LanguageProvider lang) {
    final errorKey = _errorKey;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          lang.t('contact.title'),
          style: AppFonts.pixel(fontSize: 16, color: AppColors.title),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          lang.t('contact.intro'),
          style: AppFonts.dot(fontSize: 13, color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final r in ContactReason.values) ...[
              _ReasonChip(
                label: lang.t(r.labelKey),
                selected: _reason == r,
                onTap: _busy ? null : () => setState(() => _reason = r),
              ),
              if (r != ContactReason.values.last) const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('contact.message'),
          controller: _message,
          autofocus: true,
          enabled: !_busy,
          minLines: 3,
          maxLines: 6,
          inputFormatters: const [Utf16LengthLimit(2000)],
          style: AppFonts.dot(fontSize: 14, color: AppColors.inputText),
          decoration: InputDecoration(
            hintText: lang.t('contact.messageHint'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('contact.email'),
          controller: _email,
          enabled: !_busy,
          keyboardType: TextInputType.emailAddress,
          enableSuggestions: false,
          autocorrect: false,
          style: AppFonts.dot(fontSize: 14, color: AppColors.inputText),
          decoration: InputDecoration(
            hintText: lang.t('contact.emailHint'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
        ),
        if (errorKey != null) ...[
          const SizedBox(height: 8),
          Text(
            lang.t(errorKey),
            style: AppFonts.dot(fontSize: 13, color: AppColors.btnResetText),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _button(String label, VoidCallback onTap, {bool busy = false}) {
    return Semantics(
      button: true,
      enabled: !busy,
      child: GestureDetector(
        onTap: busy ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.btnAdd,
            border: Border.all(color: AppColors.btnAddBorder),
            borderRadius: BorderRadius.circular(6),
          ),
          child: busy
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.btnAddText),
                )
              : Text(label, style: AppFonts.pixel(fontSize: 12, color: AppColors.btnAddText)),
        ),
      ),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _ReasonChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent.withValues(alpha: 0.12) : AppColors.inputBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.inputBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(label, style: AppFonts.dot(fontSize: 13, color: selected ? AppColors.accent : AppColors.text)),
        ),
      ),
    );
  }
}

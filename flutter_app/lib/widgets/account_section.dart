import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/cells_provider.dart';
import '../providers/language_provider.dart';
import '../providers/pages_provider.dart';
import '../providers/premium_provider.dart';
import '../theme/app_theme.dart';
import 'app_dialog.dart';
import 'confirm_dialog.dart';
import 'connection_needed_dialog.dart';
import 'message_dialog.dart';
import 'press_scale.dart';

/// The account part of the settings, in its two forms (chantier 9, case
/// 10), as the server says what the account is. An attached account: its
/// address, « Se déconnecter », « Déconnecter mes autres appareils »,
/// « Supprimer mon compte et mes données ». An invisible account: the
/// sentence of case 10, no sign-out (there would be no safe way back),
/// « Supprimer mes données ». Both: « Restaurer les achats ».
class AccountSection extends StatelessWidget {
  /// « Se déconnecter »: the settings' own flow (the queue leaves first, H10).
  final Future<void> Function() onLogout;

  const AccountSection({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>();
    final invisible = auth.isInvisible;
    final email = auth.email;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(lang.t('settings.account'), style: AppFonts.pixel(fontSize: 13, color: AppColors.subtitle)),
        const SizedBox(height: 8),
        if (invisible)
          Text(lang.t('account.invisible.note'), style: AppFonts.dot(fontSize: 13, color: AppColors.text))
        else if (email != null)
          Text(email, style: AppFonts.dot(fontSize: 14, color: AppColors.text)),
        const SizedBox(height: 12),
        _tile(label: lang.t('account.restore'), onTap: () => _restore(context)),
        const SizedBox(height: 12),
        if (!invisible) ...[
          _button(label: lang.t('account.logout'), onTap: onLogout),
          const SizedBox(height: 12),
          _button(label: lang.t('account.closeOthers'), onTap: () => _closeOthers(context)),
          const SizedBox(height: 12),
        ],
        _button(
          label: lang.t(invisible ? 'account.delete.invisible' : 'account.delete.attached'),
          destructive: true,
          onTap: () => _delete(context, invisible: invisible, email: email),
        ),
      ],
    );
  }

  Widget _tile({required String label, required VoidCallback onTap}) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.shell,
          border: Border.all(color: AppColors.shellBorder),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(label, style: AppFonts.dot(fontSize: 14, color: AppColors.text))),
            Text('>', style: AppFonts.pixel(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _button({required String label, required VoidCallback onTap, bool destructive = false}) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: destructive ? AppColors.btnReset : AppColors.inputBg,
          border: Border.all(color: destructive ? AppColors.btnResetBorder : AppColors.inputBorder),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppFonts.pixel(fontSize: 13, color: destructive ? AppColors.btnResetText : AppColors.text),
          ),
        ),
      ),
    );
  }

  Future<void> _restore(BuildContext context) async {
    if (await ConnectionNeededDialog.blockIfOffline(context)) return;
    if (!context.mounted) return;
    final lang = context.read<LanguageProvider>();
    final restored = await context.read<PremiumProvider>().restorePurchases();
    if (context.mounted) await MessageDialog.show(context, message: lang.t(restored ? 'account.restore.found' : 'account.restore.none'));
  }

  Future<void> _closeOthers(BuildContext context) async {
    final lang = context.read<LanguageProvider>();
    final go = await ConfirmDialog.show(
      context,
      title: lang.t('account.closeOthers'),
      message: lang.t('account.closeOthers.confirm'),
      confirmLabel: lang.t('account.closeOthers.go'),
      cancelLabel: lang.t('common.cancel'),
      destructive: true,
    );
    if (go != true || !context.mounted) return;
    if (await ConnectionNeededDialog.blockIfOffline(context)) return;
    if (!context.mounted) return;
    var done = false;
    try {
      await context.read<AuthProvider>().closeOtherSessions();
      done = true;
    } catch (e) {
      debugPrint('Close other sessions failed: $e');
    }
    if (context.mounted) await MessageDialog.show(context, message: lang.t(done ? 'account.closeOthers.done' : 'account.retry'));
  }

  Future<void> _delete(BuildContext context, {required bool invisible, required String? email}) async {
    // Deleting needs the server (H6): nothing is begun offline.
    if (await ConnectionNeededDialog.blockIfOffline(context)) return;
    if (!context.mounted) return;
    final lang = context.read<LanguageProvider>();
    final pages = context.read<PagesProvider>().pages;
    final cells = context.read<CellsProvider>();
    final premium = context.read<PremiumProvider>();
    final message = deletionMessage(
      lang,
      attached: !invisible,
      trackers: pages.length,
      points: cells.totalDots,
      purchase: premium.hasPurchase,
      apple: defaultTargetPlatform == TargetPlatform.iOS,
    );
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (_) => _DeleteDialog(
        lang: lang,
        title: lang.t(invisible ? 'account.delete.invisible' : 'account.delete.attached'),
        message: message,
        email: invisible ? null : email,
      ),
    );
    if (confirmed != true || !context.mounted) return;
    // Signed out only once the server confirms: a deletion that failed must
    // not look done (the account and its data would still be there). Done,
    // the session ends and the app says « Vos données ont été supprimées ».
    final gone = await context.read<AuthProvider>().deleteAccount();
    if (!gone && context.mounted) await MessageDialog.show(context, message: lang.t('account.delete.failed'));
  }

  /// What the confirmation of a deletion says (case 65): what goes, with its
  /// numbers, that it goes everywhere — including where the server cannot
  /// know it — and, with a purchase, where a subscription is cancelled.
  @visibleForTesting
  static String deletionMessage(
    LanguageProvider lang, {
    required bool attached,
    required int trackers,
    required int points,
    required bool purchase,
    required bool apple,
  }) {
    final who = attached ? 'attached' : 'invisible';
    final form = trackers == 0
        ? 'none'
        : '${trackers == 1 ? 'one' : 'many'}${points > 0 ? 'Points' : ''}';
    final pointsText = (points == 1 ? lang.t('account.points.one') : lang.t('account.points.other')).replaceAll('{n}', '$points');
    final subject = lang.t('account.delete.subject.$who.$form').replaceAll('{t}', '$trackers').replaceAll('{p}', pointsText);
    final rest = switch ((attached, form)) {
      (false, 'none') => 'account.delete.rest.data',
      (false, 'one') => 'account.delete.rest.singular',
      _ => 'account.delete.rest.plural',
    };
    final text = '$subject${lang.t(rest)}';
    if (!purchase) return text;
    return '$text\n\n${lang.t(apple ? 'account.delete.purchase.apple' : 'account.delete.purchase.google')}';
  }
}

/// The confirmation of a deletion: what goes, then the address (or DELETE)
/// typed again.
class _DeleteDialog extends StatefulWidget {
  final LanguageProvider lang;
  final String title;
  final String message;
  final String? email;

  const _DeleteDialog({required this.lang, required this.title, required this.message, this.email});

  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
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
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PressScale(
            onTap: () => Navigator.of(context).pop(false),
            child: Text(lang.t('common.cancel'), style: AppFonts.pixel(fontSize: 12, color: AppColors.textMuted)),
          ),
          const SizedBox(width: 20),
          PressScale(
            onTap: _canConfirm ? () => Navigator.of(context).pop(true) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _canConfirm ? AppColors.btnReset : AppColors.dotEmpty,
                border: Border.all(color: _canConfirm ? AppColors.btnResetBorder : AppColors.dotBorder),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_outline, size: 14, color: _canConfirm ? AppColors.btnResetText : AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    lang.t('common.delete'),
                    style: AppFonts.pixel(fontSize: 12, color: _canConfirm ? AppColors.btnResetText : AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title, textAlign: TextAlign.center, style: AppFonts.pixel(fontSize: 16, color: AppColors.btnResetText)),
            const SizedBox(height: 12),
            Text(widget.message, style: AppFonts.dot(fontSize: 13, color: AppColors.text), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(
              widget.email != null ? lang.t('settings.typeEmail') : lang.t('settings.typeDelete'),
              style: AppFonts.dot(fontSize: 12, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              // The user retypes their email (or DELETE): no keyboard "help".
              keyboardType: widget.email != null ? TextInputType.emailAddress : TextInputType.text,
              autocorrect: false,
              enableSuggestions: false,
              style: AppFonts.dot(fontSize: 14, color: AppColors.inputText),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: _confirmText,
                hintStyle: AppFonts.dot(fontSize: 14, color: AppColors.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

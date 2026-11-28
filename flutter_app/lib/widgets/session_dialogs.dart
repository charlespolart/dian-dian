import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../services/api_service.dart';
import 'confirm_dialog.dart';
import 'message_dialog.dart';

/// What the app says when a session ends with changes still on the phone
/// (offline sync: H10, H24, H25).
class SessionDialogs {
  SessionDialogs._();

  /// The texts this file shows (every language has them, see its test).
  static const textKeys = [
    'logout.pending.title.one', 'logout.pending.title.other', 'logout.pending.body.one', 'logout.pending.body.other',
    'logout.stay', 'logout.anyway',
    'session.deleted.body.zero', 'session.deleted.body.one', 'session.deleted.body.other',
    'session.closed.title', 'session.closed.body.zero', 'session.closed.body.one', 'session.closed.body.other', 'session.reconnect',
    'session.password.title', 'session.password.body.zero', 'session.revoked.title', 'session.deletedHere.body',
    'session.otherAccount.title.one', 'session.otherAccount.title.other', 'session.otherAccount.body', 'session.otherAccount.continue',
  ];

  static String _n(LanguageProvider lang, String key, int n) =>
      n == 1 ? lang.t('$key.one') : lang.t('$key.other').replaceAll('{n}', '$n');

  /// H10: before signing out, the queue leaves ([flush], true when nothing
  /// is left waiting). Offline with changes waiting, the user chooses:
  /// « Rester connecté » (false) or « Me déconnecter quand même » (true).
  static Future<bool> confirmSignOut(BuildContext context, {required Future<bool> Function() flush, required int Function() pending}) async {
    if (await flush()) return true;
    final n = pending();
    if (n == 0 || !context.mounted) return true;
    final lang = context.read<LanguageProvider>();
    final go = await ConfirmDialog.show(
      context,
      title: _n(lang, 'logout.pending.title', n),
      message: _n(lang, 'logout.pending.body', n),
      confirmLabel: lang.t('logout.anyway'),
      cancelLabel: lang.t('logout.stay'),
      destructive: true,
    );
    return go == true;
  }

  /// Why the session ended, always said: the welcome screen never comes
  /// back without a word (chantier 9, case 7). A deleted account's changes
  /// are lost (H24, case 50); the others wait for the reconnection (H25,
  /// cases 51 and 52).
  static Future<void> sessionEnded(BuildContext context, SessionEnd end, {required int pending}) {
    final lang = context.read<LanguageProvider>();
    // « Reconnectez-vous » and what waits for it.
    String reconnect(String zeroKey) => pending == 0 ? lang.t(zeroKey) : _n(lang, 'session.closed.body', pending);
    switch (end) {
      case SessionEnd.accountDeleted:
        // Case 50, in the spec's words, and what was not sent (H24).
        return MessageDialog.show(
          context,
          message: pending == 0 ? lang.t('session.deleted.body.zero') : _n(lang, 'session.deleted.body', pending),
        );
      case SessionEnd.deletedHere:
        return MessageDialog.show(context, message: lang.t('session.deletedHere.body'));
      case SessionEnd.passwordChanged:
        return MessageDialog.show(
          context,
          title: lang.t('session.password.title'),
          message: reconnect('session.password.body.zero'),
          button: lang.t('session.reconnect'),
        );
      case SessionEnd.revoked:
        return MessageDialog.show(
          context,
          title: lang.t('session.revoked.title'),
          message: reconnect('session.closed.body.zero'),
          button: lang.t('session.reconnect'),
        );
      case SessionEnd.reconnect:
        return MessageDialog.show(
          context,
          title: lang.t('session.closed.title'),
          message: reconnect('session.closed.body.zero'),
          button: lang.t('session.reconnect'),
        );
    }
  }

  /// H25: signing in to another account while the copy of a closed session
  /// still waits to be sent. True to go on (those changes are erased).
  static Future<bool> confirmOtherAccount(BuildContext context, {required int pending}) async {
    final lang = context.read<LanguageProvider>();
    final go = await ConfirmDialog.show(
      context,
      title: _n(lang, 'session.otherAccount.title', pending),
      message: lang.t('session.otherAccount.body'),
      confirmLabel: lang.t('session.otherAccount.continue'),
      cancelLabel: lang.t('common.cancel'),
      destructive: true,
    );
    return go == true;
  }
}

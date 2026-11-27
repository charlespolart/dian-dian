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
    'session.deleted.title', 'session.deleted.body.zero', 'session.deleted.body.one', 'session.deleted.body.other',
    'session.closed.title', 'session.closed.body.one', 'session.closed.body.other', 'session.reconnect',
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

  /// Whether the end of a session is told: a deleted account always (H24),
  /// a closed session when changes wait for the reconnection (H25).
  static bool tellsSessionEnd(SessionEnd end, {required int pending}) => end == SessionEnd.accountDeleted || pending > 0;

  static Future<void> sessionEnded(BuildContext context, SessionEnd end, {required int pending}) {
    final lang = context.read<LanguageProvider>();
    if (end == SessionEnd.accountDeleted) {
      return MessageDialog.show(
        context,
        title: lang.t('session.deleted.title'),
        message: pending == 0 ? lang.t('session.deleted.body.zero') : _n(lang, 'session.deleted.body', pending),
      );
    }
    return MessageDialog.show(
      context,
      title: lang.t('session.closed.title'),
      message: _n(lang, 'session.closed.body', pending),
      button: lang.t('session.reconnect'),
    );
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

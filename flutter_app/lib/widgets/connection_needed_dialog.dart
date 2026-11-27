import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../data/network_gate.dart';
import '../providers/language_provider.dart';
import 'message_dialog.dart';

/// What the app says when the network is missing for what was asked.
class ConnectionNeededDialog {
  ConnectionNeededDialog._();

  /// A change refused on the first launch after the update from 1.4.0
  /// while offline: the phone does not have the full copy yet (H15).
  static Future<void> show(BuildContext context) =>
      MessageDialog.show(context, message: context.read<LanguageProvider>().t('sync.needsConnection'));

  /// A gesture that needs the server, asked offline (H6): « Il faut une
  /// connexion. … Vos trackers restent utilisables. »
  static Future<void> showForGesture(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    return MessageDialog.show(context, title: lang.t('net.required.title'), message: lang.t('net.required.body'));
  }

  /// True, after telling the user, when the gesture must not start (H6):
  /// nothing is begun halfway. [message] replaces the general one (the
  /// welcome screen's, chantier 9 case 5).
  static Future<bool> blockIfOffline(BuildContext context, {String? message}) async {
    if (!await NetworkGate.isOffline()) return false;
    if (context.mounted) await (message == null ? showForGesture(context) : MessageDialog.show(context, message: message));
    return true;
  }
}

/// Where the providers write their changes (offline sync, chantier 10): the
/// phone's copy and its queue (SyncService), or a recorder in tests. A
/// provider updates what the screen shows at once, then records the change
/// here; nothing waits for the network and nothing is undone when it is
/// missing.
abstract class ChangeSink {
  /// Writes the change on the phone and queues it for the server. [kind] and
  /// [data] are those of `lib/data/mutation.dart`.
  Future<void> record(String kind, Map<String, dynamic> data);
}

/// The settings (theme, language, cursor) are written by providers that
/// live outside a session; SyncService points this at the session's sink.
class SettingsSink {
  SettingsSink._();

  static ChangeSink? sink;

  /// Records a setting of the account: `theme` (a name), `language` (a code
  /// or null), `cursor` ({id, enabled}). Without a session, nothing is sent.
  static Future<void> record(String key, Object? value) async {
    await sink?.record('setting.set', {'key': key, 'value': value});
  }
}

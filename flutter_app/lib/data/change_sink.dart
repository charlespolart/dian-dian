/// Where the providers write their changes (offline sync, chantier 10): the
/// phone's copy and its queue (SyncService), or a recorder in tests. A
/// provider updates what the screen shows at once, then records the change
/// here; nothing waits for the network and nothing is undone when it is
/// missing.
abstract class ChangeSink {
  /// False while the phone has no full copy of the account (the first launch
  /// after the update from 1.4.0, offline, H15): nothing can be written, the
  /// numbers the changes need are not on the phone yet.
  bool get canWrite;

  /// A change was not made because [canWrite] is false: tell the user.
  void refused();

  /// Writes the change on the phone and queues it for the server. [kind] and
  /// [data] are those of `lib/data/mutation.dart`.
  Future<void> record(String kind, Map<String, dynamic> data);

  /// A tracker deletion that can still be undone, kept on the phone so that
  /// an app killed meanwhile finds it done when reopened (H14). Writing the
  /// `page.delete` lets it go in the same step.
  Future<void> holdDelete(String pageId);

  /// The deletion was undone.
  Future<void> releaseDelete(String pageId);
}

/// The settings (theme, language, cursor) are written by providers that
/// live outside a session; SyncService points this at the session's sink.
class SettingsSink {
  SettingsSink._();

  static ChangeSink? sink;

  /// True when a setting can be changed; otherwise the user is told (H15)
  /// and the setting stays as it was. Without a session, always true.
  static bool allows() {
    final s = sink;
    if (s == null || s.canWrite) return true;
    s.refused();
    return false;
  }

  /// Records a setting of the account: `theme` (a name), `language` (a code
  /// or null), `cursor` ({id, enabled}). Without a session, nothing is sent.
  static Future<void> record(String key, Object? value) async {
    await sink?.record('setting.set', {'key': key, 'value': value});
  }
}

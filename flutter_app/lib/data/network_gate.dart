import 'package:connectivity_plus/connectivity_plus.dart';

/// Whether a gesture that needs the server can start now (offline sync, H6):
/// buying or restoring Premium, creating an account or signing in,
/// deleting one's data, writing to support. Offline means the phone has no
/// network, or — within a session — the server does not answer (H16).
class NetworkGate {
  NetworkGate._();

  /// True when the phone has no network at all.
  static Future<bool> Function() deviceOffline = _deviceOffline;

  /// Set by the session (SyncService): tries the server now, true when it
  /// answered. Null without a session: the gesture then simply tries.
  static Future<bool> Function()? serverReachable;

  /// Set by the session: whether the last attempt failed (no waiting).
  static bool Function()? serverUnreachableNow;

  /// What the phone knows now, without trying the server: for what a screen
  /// says (H7), not for letting a gesture start.
  static Future<bool> seemsOffline() async => await deviceOffline() || (serverUnreachableNow?.call() ?? false);

  static Future<bool> isOffline() async {
    if (await deviceOffline()) return true;
    final reach = serverReachable;
    return reach != null && !await reach();
  }

  static Future<bool> _deviceOffline() async {
    try {
      final now = await Connectivity().checkConnectivity();
      return now.isEmpty || now.every((c) => c == ConnectivityResult.none);
    } catch (e) {
      // No plugin (tests, an unknown platform): assume a network, the gesture tries.
      return false;
    }
  }
}

import 'package:connectivity_plus/connectivity_plus.dart';

/// Tells when the phone's network changed (Wi-Fi, mobile data, none), so
/// that the queue leaves without waiting for a gesture (offline sync). A
/// change says nothing about the server: only reaching it does.
abstract class NetworkWatcher {
  Stream<void> get onChange;
}

class DeviceNetwork implements NetworkWatcher {
  DeviceNetwork([Connectivity? connectivity]) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Stream<void> get onChange => _connectivity.onConnectivityChanged.map((_) {});
}

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'api_service.dart';

/// Reports product events to the server (`POST /api/events`): a counter
/// for what the data does not show otherwise, e.g. how often the free
/// tracker limit is hit. Fire-and-forget: never throws, never blocks.
///
/// Each event says where it comes from, the platform and the app's version
/// (a backend older than this app ignores them), so the iOS and Android
/// funnels can be compared. An origin that cannot be read is left out: the
/// event goes anyway.
class EventsService {
  final ApiService _api;
  final String? Function() _platform;
  final Future<String?> Function() _appVersion;

  /// [platform] and [appVersion] are the injection seams for tests; by
  /// default they read this device ([currentPlatform]) and the installed
  /// version.
  EventsService({ApiService? api, String? Function()? platform, Future<String?> Function()? appVersion})
      : _api = api ?? ApiService(),
        _platform = platform ?? currentPlatform,
        _appVersion = appVersion ?? _installedVersion;

  /// `ios`, `android` or `web` — the names the server keeps; null anywhere
  /// else (a desktop debug run).
  static String? currentPlatform() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => null,
    };
  }

  // Read once per launch: the version cannot change while the app runs.
  static Future<String?>? _version;
  static Future<String?> _installedVersion() => _version ??= _readInstalledVersion();
  static Future<String?> _readInstalledVersion() async {
    try {
      return (await PackageInfo.fromPlatform()).version;
    } catch (e) {
      debugPrint('EventsService: no app version: $e');
      return null;
    }
  }

  Future<void> track(String name) async {
    try {
      final response = await _api.apiFetch(
        '/api/events',
        method: 'POST',
        body: {'name': name, 'platform': ?_platform(), 'appVersion': ?await _readVersion()},
      );
      if (response.statusCode != 204) debugPrint('EventsService: $name → ${response.statusCode}');
    } catch (e) {
      debugPrint('EventsService: $name failed: $e');
    }
  }

  /// The version, or null when its lookup fails: never a reason to lose the
  /// event.
  Future<String?> _readVersion() async {
    try {
      return await _appVersion();
    } catch (e) {
      debugPrint('EventsService: no app version: $e');
      return null;
    }
  }
}

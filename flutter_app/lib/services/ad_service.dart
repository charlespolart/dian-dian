import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _initialized = false;
  bool _disabled = false;

  void disable() {
    _disabled = true;
  }

  void enable() {
    _disabled = false;
  }

  bool get isDisabled => _disabled;

  static String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isIOS) {
      return 'ca-app-pub-7932342939488027/9720432799';
    }
    return 'ca-app-pub-3940256099942544/6300978111'; // Android test banner
  }

  Future<void> init() async {
    if (kIsWeb || _initialized || _disabled) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }
}

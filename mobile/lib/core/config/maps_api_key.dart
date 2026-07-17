import 'package:flutter/services.dart';

/// Resolves the Google Maps / Places / Directions API key.
///
/// Order:
/// 1. `--dart-define=MAPS_API_KEY=...` (optional override / CI)
/// 2. Native config — Android `local.properties` → manifest meta-data,
///    iOS `MapsSecrets.xcconfig` → Info.plist `GMSApiKey`
class MapsApiKey {
  MapsApiKey._();

  static const _channelName = 'com.radaralert.radar_alert/maps_api_key';
  static const _fromDefine = String.fromEnvironment('MAPS_API_KEY');
  static const _fromDefineLegacy =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static String _value = '';
  static Future<void>? _loading;

  /// Current key (may be empty until [ensureLoaded] finishes).
  static String get value {
    if (_value.isNotEmpty) return _value;
    if (_fromDefine.isNotEmpty) return _fromDefine;
    if (_fromDefineLegacy.isNotEmpty) return _fromDefineLegacy;
    return '';
  }

  /// Loads the key from the platform. Safe to call repeatedly; retries while
  /// the Android/iOS method channel is still registering at startup.
  static Future<void> ensureLoaded() async {
    if (value.isNotEmpty) return;

    final inFlight = _loading;
    if (inFlight != null) {
      await inFlight;
      if (value.isNotEmpty) return;
    }

    final future = _load();
    _loading = future;
    try {
      await future;
    } finally {
      // Allow another attempt if the channel was not ready yet.
      if (value.isEmpty) {
        _loading = null;
      }
    }
  }

  static Future<void> _load() async {
    if (_fromDefine.isNotEmpty) {
      _value = _fromDefine;
      return;
    }
    if (_fromDefineLegacy.isNotEmpty) {
      _value = _fromDefineLegacy;
      return;
    }

    const channel = MethodChannel(_channelName);
    // Channel is registered in MainActivity / AppDelegate after the engine
    // attaches — retry briefly instead of failing on the first frame.
    for (var attempt = 0; attempt < 40; attempt++) {
      try {
        final key = await channel.invokeMethod<String>('getMapsApiKey');
        if (key != null && key.trim().isNotEmpty) {
          _value = key.trim();
          return;
        }
        // Channel answered with empty — key truly missing; stop retrying.
        return;
      } on MissingPluginException {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      } on PlatformException {
        return;
      }
    }
  }
}

import 'package:flutter/services.dart';

class MapsApiKey {
  MapsApiKey._();

  static const _channelName = 'com.radaralert.radar_alert/maps_api_key';
  static const _fromDefine = String.fromEnvironment('MAPS_API_KEY');
  static const _fromDefineLegacy =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static String _value = '';
  static Future<void>? _loading;

  static String get value {
    if (_value.isNotEmpty) return _value;
    if (_fromDefine.isNotEmpty) return _fromDefine;
    if (_fromDefineLegacy.isNotEmpty) return _fromDefineLegacy;
    return '';
  }

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

    // Channel registers after engine attach; retry briefly on MissingPluginException.
    const channel = MethodChannel(_channelName);
    for (var attempt = 0; attempt < 40; attempt++) {
      try {
        final key = await channel.invokeMethod<String>('getMapsApiKey');
        if (key != null && key.trim().isNotEmpty) {
          _value = key.trim();
          return;
        }
        return;
      } on MissingPluginException {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      } on PlatformException {
        return;
      }
    }
  }
}

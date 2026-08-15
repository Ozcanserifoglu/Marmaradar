import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:radar_alert/core/config/maps_api_key.dart';

class GoogleGeocodingClient {
  GoogleGeocodingClient({
    String? apiKey,
    http.Client? httpClient,
  })  : _apiKeyOverride = apiKey,
        _http = httpClient ?? http.Client();

  static const _geocodePath = '/maps/api/geocode/json';
  static const _timeout = Duration(seconds: 8);
  static const maxDriveNameLen = 120;

  final String? _apiKeyOverride;
  final http.Client _http;

  Future<String> _apiKey() async {
    final override = _apiKeyOverride;
    if (override != null && override.isNotEmpty) {
      return override;
    }
    await MapsApiKey.ensureLoaded();
    return MapsApiKey.value;
  }

  Future<String?> reverseGeocodeDriveTitle({
    required double lat,
    required double lon,
  }) async {
    try {
      final apiKey = await _apiKey();
      if (apiKey.isEmpty) return null;

      final uri = Uri.https('maps.googleapis.com', _geocodePath, {
        'latlng': '$lat,$lon',
        'language': 'tr',
        'key': apiKey,
      });

      final resp = await _http.get(uri).timeout(_timeout);
      if (resp.statusCode != 200) return null;

      final decoded = jsonDecode(resp.body);
      if (decoded is! Map<String, dynamic>) return null;

      final status = decoded['status'] as String? ?? 'UNKNOWN';
      if (status != 'OK') return null;

      final results = decoded['results'] as List<dynamic>? ?? const [];
      if (results.isEmpty) return null;

      final first = results.first;
      if (first is! Map<String, dynamic>) return null;

      final components = first['address_components'] as List<dynamic>? ?? const [];
      return formatDriveLocationName(components);
    } on SocketException {
      return null;
    } on http.ClientException {
      return null;
    } on Exception {
      return null;
    }
  }
}

String? formatDriveLocationName(List<dynamic> components) {
  String? place;
  String? region;

  for (final raw in components) {
    if (raw is! Map<String, dynamic>) continue;
    final longName = (raw['long_name'] as String?)?.trim();
    if (longName == null || longName.isEmpty) continue;

    final types = (raw['types'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toSet();

    if (place == null && types.contains('locality')) {
      place = longName;
    } else if (place == null &&
        types.contains('administrative_area_level_2')) {
      place = longName;
    }

    if (region == null && types.contains('administrative_area_level_1')) {
      region = longName;
    }
  }

  String? title;
  if (place != null && region != null && place != region) {
    title = '$place, $region Sürüşü';
  } else if (place != null) {
    title = '$place Sürüşü';
  } else if (region != null) {
    title = '$region Sürüşü';
  }

  if (title == null) return null;

  final runes = title.runes.toList();
  if (runes.length > GoogleGeocodingClient.maxDriveNameLen) {
    title = String.fromCharCodes(
      runes.take(GoogleGeocodingClient.maxDriveNameLen),
    ).trim();
  }
  return title.isEmpty ? null : title;
}

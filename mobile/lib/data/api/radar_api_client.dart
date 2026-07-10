import 'dart:convert';

import 'package:http/http.dart' as http;

class RadarApiClient {
  RadarApiClient({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBaseUrl;

  /// Overridable at build time, e.g. for a physical phone on the same Wi-Fi:
  ///   flutter build apk --dart-define=RADAR_API_URL=http://192.168.1.105:8081
  /// The fallback 10.0.2.2 only works from the Android emulator.
  static const _defaultBaseUrl = String.fromEnvironment(
    'RADAR_API_URL',
    defaultValue: 'http://10.0.2.2:8081',
  );

  final String baseUrl;

  Future<List<Map<String, dynamic>>> fetchCamerasNearby({
    required double lat,
    required double lon,
    double radiusM = 1000,
    String region = 'bursa',
  }) async {
    final uri = Uri.parse('$baseUrl/v1/cameras/nearby').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'radius_m': radiusM.toString(),
        'region': region,
      },
    );
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('cameras/nearby failed: ${resp.statusCode}');
    }
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> syncRegion({
    required String region,
    required String bbox,
    DateTime? since,
  }) async {
    final params = <String, String>{
      'region': region,
      'bbox': bbox,
    };
    if (since != null) {
      params['since'] = since.toUtc().toIso8601String();
    }
    final uri = Uri.parse('$baseUrl/v1/sync').replace(queryParameters: params);
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('sync failed: ${resp.statusCode}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}

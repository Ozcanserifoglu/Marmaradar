import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class RadarApiClient {
  RadarApiClient({String? baseUrl}) : baseUrl = baseUrl ?? _resolveBaseUrl();

  static const _productionBaseUrl = 'https://marmaradar-gateway.onrender.com';
  static const _emulatorBaseUrl = 'http://10.0.2.2:8081';

  /// Override at build time, e.g. for local dev on a physical device:
  ///   flutter run --dart-define=RADAR_API_URL=http://192.168.1.105:8081
  ///
  /// Release builds default to production; debug builds default to the
  /// Android emulator host (10.0.2.2:8081).
  static String _resolveBaseUrl() {
    const fromEnv = String.fromEnvironment('RADAR_API_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return kReleaseMode ? _productionBaseUrl : _emulatorBaseUrl;
  }

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

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// HTTP failure that survived all retries. [statusCode] is null when the
/// request never reached the server (no connectivity, DNS failure, ...).
class ApiException implements Exception {
  const ApiException(this.endpoint, this.statusCode, [this.cause]);

  final String endpoint;
  final int? statusCode;
  final Object? cause;

  /// The Render free tier answers 502/503 while the service is waking up.
  bool get isServerWakingUp =>
      statusCode == 502 || statusCode == 503 || statusCode == 504;

  bool get isNetworkError => statusCode == null;

  @override
  String toString() =>
      'ApiException($endpoint, status: $statusCode, cause: $cause)';
}

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

  /// Delays between retries. Sized for Render's free-tier cold start, which
  /// typically takes 10-15 s: waiting a few seconds and retrying usually
  /// turns a 502 into a 200 without the user doing anything.
  static const _retryDelays = [
    Duration(seconds: 3),
    Duration(seconds: 6),
    Duration(seconds: 10),
  ];

  Future<http.Response> _getWithRetry(Uri uri, String endpoint) async {
    Object? lastError;
    int? lastStatus;

    for (var attempt = 0; attempt <= _retryDelays.length; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(_retryDelays[attempt - 1]);
      }
      try {
        final resp = await http.get(uri).timeout(const Duration(seconds: 25));
        if (resp.statusCode == 200) return resp;
        lastStatus = resp.statusCode;
        lastError = null;
        // Only gateway errors are worth retrying; a 4xx won't fix itself.
        if (resp.statusCode < 500) break;
      } on SocketException catch (e) {
        lastError = e;
        lastStatus = null;
      } on http.ClientException catch (e) {
        lastError = e;
        lastStatus = null;
      } on Exception catch (e) {
        // TimeoutException and friends: retry, the server may be waking up.
        lastError = e;
        lastStatus = null;
      }
    }
    throw ApiException(endpoint, lastStatus, lastError);
  }

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
    final resp = await _getWithRetry(uri, 'cameras/nearby');
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
    final resp = await _getWithRetry(uri, 'sync');
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}

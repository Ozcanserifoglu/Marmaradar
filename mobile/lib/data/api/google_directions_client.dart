import 'dart:convert';
import 'dart:io';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:radar_alert/core/config/maps_api_key.dart';
import 'package:radar_alert/core/geo/encoded_polyline.dart';
import 'package:radar_alert/features/directions/directions_models.dart';

class GoogleDirectionsClient {
  GoogleDirectionsClient({
    String? apiKey,
    http.Client? httpClient,
  })  : _apiKeyOverride = apiKey,
        _http = httpClient ?? http.Client();

  static const _path = '/maps/api/directions/json';
  static const _timeout = Duration(seconds: 20);

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

  Future<RouteResult> route({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final apiKey = await _apiKey();
    if (apiKey.isEmpty) {
      throw const DirectionsException(
        'Google API anahtarı eksik',
        status: 'REQUEST_DENIED',
      );
    }

    final uri = Uri.https('maps.googleapis.com', _path, {
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'mode': 'driving',
      'language': 'tr',
      'alternatives': 'false',
      'key': apiKey,
    });

    final json = await _getJson(uri);
    final status = json['status'] as String? ?? 'UNKNOWN';
    if (status != 'OK') {
      throw DirectionsException(
        _statusMessage(status),
        status: status,
      );
    }

    final routes = json['routes'] as List<dynamic>? ?? const [];
    if (routes.isEmpty) {
      throw const DirectionsException(
        'Rota bulunamadı',
        status: 'ZERO_RESULTS',
      );
    }

    final route = routes.first as Map<String, dynamic>;
    final overview = route['overview_polyline'] as Map<String, dynamic>?;
    final encoded = overview?['points'] as String?;
    if (encoded == null || encoded.isEmpty) {
      throw const DirectionsException(
        'Rota geometrisi alınamadı',
        status: 'UNKNOWN',
      );
    }

    final points = decodePolyline(encoded);
    if (points.length < 2) {
      throw const DirectionsException(
        'Rota geometrisi alınamadı',
        status: 'UNKNOWN',
      );
    }

    final legs = route['legs'] as List<dynamic>? ?? const [];
    if (legs.isEmpty) {
      throw const DirectionsException(
        'Rota bilgisi alınamadı',
        status: 'UNKNOWN',
      );
    }

    final leg = legs.first as Map<String, dynamic>;
    final distanceM =
        (leg['distance'] as Map<String, dynamic>?)?['value'] as int? ?? 0;
    final durationSec =
        (leg['duration'] as Map<String, dynamic>?)?['value'] as int? ?? 0;

    return RouteResult(
      points: points,
      distanceM: distanceM,
      durationSec: durationSec,
    );
  }

  static RouteResult parseRouteResponse(Map<String, dynamic> json) {
    final status = json['status'] as String? ?? 'UNKNOWN';
    if (status != 'OK') {
      throw DirectionsException(
        _statusMessage(status),
        status: status,
      );
    }

    final routes = json['routes'] as List<dynamic>? ?? const [];
    if (routes.isEmpty) {
      throw const DirectionsException(
        'Rota bulunamadı',
        status: 'ZERO_RESULTS',
      );
    }

    final route = routes.first as Map<String, dynamic>;
    final overview = route['overview_polyline'] as Map<String, dynamic>?;
    final encoded = overview?['points'] as String?;
    if (encoded == null || encoded.isEmpty) {
      throw const DirectionsException(
        'Rota geometrisi alınamadı',
        status: 'UNKNOWN',
      );
    }

    final points = decodePolyline(encoded);
    final legs = route['legs'] as List<dynamic>? ?? const [];
    final leg = legs.isNotEmpty ? legs.first as Map<String, dynamic> : null;
    final distanceM =
        (leg?['distance'] as Map<String, dynamic>?)?['value'] as int? ?? 0;
    final durationSec =
        (leg?['duration'] as Map<String, dynamic>?)?['value'] as int? ?? 0;

    return RouteResult(
      points: points,
      distanceM: distanceM,
      durationSec: durationSec,
    );
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final resp = await _http.get(uri).timeout(_timeout);
      if (resp.statusCode != 200) {
        throw DirectionsException(
          'Ağ hatası (directions)',
          status: 'NETWORK',
          cause: 'HTTP ${resp.statusCode}',
        );
      }
      final decoded = jsonDecode(resp.body);
      if (decoded is! Map<String, dynamic>) {
        throw const DirectionsException(
          'Geçersiz yanıt (directions)',
          status: 'UNKNOWN',
        );
      }
      return decoded;
    } on DirectionsException {
      rethrow;
    } on SocketException catch (e) {
      throw DirectionsException(
        'İnternet bağlantısı yok',
        status: 'NETWORK',
        cause: e,
      );
    } on http.ClientException catch (e) {
      throw DirectionsException(
        'İnternet bağlantısı yok',
        status: 'NETWORK',
        cause: e,
      );
    } on Exception catch (e) {
      throw DirectionsException(
        'İstek zaman aşımına uğradı',
        status: 'NETWORK',
        cause: e,
      );
    }
  }

  static String _statusMessage(String status) {
    switch (status) {
      case 'ZERO_RESULTS':
        return 'Bu hedefe sürüş rotası bulunamadı';
      case 'REQUEST_DENIED':
        return 'API anahtarı reddedildi';
      case 'INVALID_REQUEST':
        return 'Geçersiz rota isteği';
      case 'OVER_QUERY_LIMIT':
        return 'Sorgu limiti aşıldı';
      case 'NOT_FOUND':
        return 'Konum bulunamadı';
      default:
        return 'Rota alınamadı ($status)';
    }
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:radar_alert/features/directions/directions_models.dart';

/// Classic Places Autocomplete + Place Details over REST.
class GooglePlacesClient {
  GooglePlacesClient({
    String? apiKey,
    http.Client? httpClient,
  })  : apiKey = apiKey ?? _resolveApiKey(),
        _http = httpClient ?? http.Client();

  static const _autocompletePath =
      '/maps/api/place/autocomplete/json';
  static const _detailsPath = '/maps/api/place/details/json';
  static const _timeout = Duration(seconds: 15);

  /// Bias radius (meters) around the driver's current location.
  static const _biasRadiusM = 50000;

  final String apiKey;
  final http.Client _http;

  static String _resolveApiKey() {
    const fromEnv = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
    return fromEnv;
  }

  Future<List<PlacePrediction>> autocomplete({
    required String input,
    LatLng? bias,
  }) async {
    if (apiKey.isEmpty) {
      throw const DirectionsException(
        'Google API anahtarı eksik',
        status: 'REQUEST_DENIED',
      );
    }
    final trimmed = input.trim();
    if (trimmed.isEmpty) return const [];

    final params = <String, String>{
      'input': trimmed,
      'key': apiKey,
      'language': 'tr',
      'components': 'country:tr',
    };
    if (bias != null) {
      params['location'] = '${bias.latitude},${bias.longitude}';
      params['radius'] = '$_biasRadiusM';
    }

    final uri = Uri.https('maps.googleapis.com', _autocompletePath, params);
    final json = await _getJson(uri, 'places/autocomplete');
    final status = json['status'] as String? ?? 'UNKNOWN';
    if (status == 'ZERO_RESULTS' || status == 'OK') {
      final raw = json['predictions'] as List<dynamic>? ?? const [];
      return [
        for (final item in raw)
          if (item is Map<String, dynamic>)
            PlacePrediction(
              placeId: item['place_id'] as String? ?? '',
              description: item['description'] as String? ?? '',
            ),
      ].where((p) => p.placeId.isNotEmpty).toList();
    }
    throw DirectionsException(
      _statusMessage(status),
      status: status,
    );
  }

  Future<PlaceResult> details({required String placeId}) async {
    if (apiKey.isEmpty) {
      throw const DirectionsException(
        'Google API anahtarı eksik',
        status: 'REQUEST_DENIED',
      );
    }

    final uri = Uri.https('maps.googleapis.com', _detailsPath, {
      'place_id': placeId,
      'fields': 'geometry,name,formatted_address',
      'key': apiKey,
      'language': 'tr',
    });
    final json = await _getJson(uri, 'places/details');
    final status = json['status'] as String? ?? 'UNKNOWN';
    if (status != 'OK') {
      throw DirectionsException(
        _statusMessage(status),
        status: status,
      );
    }

    final result = json['result'] as Map<String, dynamic>?;
    if (result == null) {
      throw const DirectionsException(
        'Yer bilgisi alınamadı',
        status: 'UNKNOWN',
      );
    }

    final geometry = result['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final lat = (location?['lat'] as num?)?.toDouble();
    final lng = (location?['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) {
      throw const DirectionsException(
        'Yer konumu bulunamadı',
        status: 'UNKNOWN',
      );
    }

    final name = result['name'] as String? ??
        result['formatted_address'] as String? ??
        'Hedef';

    return PlaceResult(
      placeId: placeId,
      name: name,
      latLng: LatLng(lat, lng),
      formattedAddress: result['formatted_address'] as String?,
    );
  }

  Future<Map<String, dynamic>> _getJson(Uri uri, String endpoint) async {
    try {
      final resp = await _http.get(uri).timeout(_timeout);
      if (resp.statusCode != 200) {
        throw DirectionsException(
          'Ağ hatası ($endpoint)',
          status: 'NETWORK',
          cause: 'HTTP ${resp.statusCode}',
        );
      }
      final decoded = jsonDecode(resp.body);
      if (decoded is! Map<String, dynamic>) {
        throw DirectionsException(
          'Geçersiz yanıt ($endpoint)',
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
        return 'Sonuç bulunamadı';
      case 'REQUEST_DENIED':
        return 'API anahtarı reddedildi';
      case 'INVALID_REQUEST':
        return 'Geçersiz istek';
      case 'OVER_QUERY_LIMIT':
        return 'Sorgu limiti aşıldı';
      default:
        return 'Arama başarısız ($status)';
    }
  }
}

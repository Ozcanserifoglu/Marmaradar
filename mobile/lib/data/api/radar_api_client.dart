import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:radar_alert/data/api/auth_models.dart';
import 'package:radar_alert/data/auth/token_store.dart';
import 'package:radar_alert/features/alerts/road_eta_models.dart';
import 'package:radar_alert/features/amenities/amenity_models.dart';
import 'package:radar_alert/features/profile/profile_models.dart';

class ApiException implements Exception {
  const ApiException(this.endpoint, this.statusCode, [this.cause, this.body]);

  final String endpoint;
  final int? statusCode;
  final Object? cause;
  final String? body;

  bool get isServerWakingUp =>
      statusCode == 502 || statusCode == 503 || statusCode == 504;

  bool get isNetworkError => statusCode == null;

  bool get isUnauthorized => statusCode == 401;

  String get message {
    if (statusCode == 429) {
      return 'Çok fazla deneme. Lütfen bir dakika bekleyip tekrar deneyin.';
    }
    if (body != null && body!.isNotEmpty) {
      try {
        final map = jsonDecode(body!) as Map<String, dynamic>;
        final err = map['error'];
        if (err is String && err.isNotEmpty) return err;
      } catch (_) {}
    }
    return toString();
  }

  @override
  String toString() =>
      'ApiException($endpoint, status: $statusCode, cause: $cause)';
}

class RadarApiClient {
  RadarApiClient({
    String? baseUrl,
    TokenStore? tokenStore,
  })  : baseUrl = baseUrl ?? _resolveBaseUrl(),
        _tokens = tokenStore ?? SecureTokenStore();

  static const _productionBaseUrl = 'https://marmaradar-gateway.onrender.com';

  // Override: --dart-define=RADAR_API_URL=http://10.0.2.2:8081
  static String _resolveBaseUrl() {
    const fromEnv = String.fromEnvironment('RADAR_API_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return _productionBaseUrl;
  }

  final String baseUrl;
  final TokenStore _tokens;

  TokenStore get tokenStore => _tokens;

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
        if (resp.statusCode < 500) break;
      } on SocketException catch (e) {
        lastError = e;
        lastStatus = null;
      } on http.ClientException catch (e) {
        lastError = e;
        lastStatus = null;
      } on Exception catch (e) {
        lastError = e;
        lastStatus = null;
      }
    }
    throw ApiException(endpoint, lastStatus, lastError);
  }

  Future<http.Response> _postJson(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
    bool retryOnUnauthorized = true,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final access = await _tokens.accessToken;
      if (access != null && access.isNotEmpty) {
        headers['Authorization'] = 'Bearer $access';
      }
    }

    final resp = await http
        .post(uri, headers: headers, body: jsonEncode(body))
        .timeout(timeout);

    if (resp.statusCode == 401 && auth && retryOnUnauthorized) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        return _postJson(
          path,
          body,
          auth: true,
          retryOnUnauthorized: false,
          timeout: timeout,
        );
      }
    }
    return resp;
  }

  Future<http.Response> _getAuthed(
    Uri uri, {
    bool retryOnUnauthorized = true,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    final access = await _tokens.accessToken;
    if (access != null && access.isNotEmpty) {
      headers['Authorization'] = 'Bearer $access';
    }

    final resp =
        await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));

    if (resp.statusCode == 401 && retryOnUnauthorized) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        return _getAuthed(uri, retryOnUnauthorized: false);
      }
    }
    return resp;
  }

  Future<http.Response> _patchJson(
    Uri uri,
    Map<String, dynamic> body, {
    bool retryOnUnauthorized = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final access = await _tokens.accessToken;
    if (access != null && access.isNotEmpty) {
      headers['Authorization'] = 'Bearer $access';
    }

    final resp = await http
        .patch(uri, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));

    if (resp.statusCode == 401 && retryOnUnauthorized) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        return _patchJson(uri, body, retryOnUnauthorized: false);
      }
    }
    return resp;
  }

  Future<bool> _tryRefresh() async {
    final refresh = await _tokens.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final tokens = await refreshSession(refresh);
      await _tokens.saveSession(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        userId: tokens.userId,
        email: tokens.email,
      );
      return true;
    } catch (_) {
      await _tokens.clear();
      return false;
    }
  }

  Future<AuthTokens> register({
    required String email,
    required String password,
  }) async {
    final resp = await _postJson('/v1/auth/register', {
      'email': email,
      'password': password,
    });
    if (resp.statusCode != 201 && resp.statusCode != 200) {
      throw ApiException('auth/register', resp.statusCode, null, resp.body);
    }
    return AuthTokens.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final resp = await _postJson('/v1/auth/login', {
      'email': email,
      'password': password,
    });
    if (resp.statusCode != 200) {
      throw ApiException('auth/login', resp.statusCode, null, resp.body);
    }
    return AuthTokens.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<AuthTokens> refreshSession(String refreshToken) async {
    final resp = await _postJson('/v1/auth/refresh', {
      'refresh_token': refreshToken,
    });
    if (resp.statusCode != 200) {
      throw ApiException('auth/refresh', resp.statusCode, null, resp.body);
    }
    return AuthTokens.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<DriveUploadResult> uploadDrive({
    required DateTime startedAt,
    required DateTime endedAt,
    required List<DrivePointPayload> points,
    String? name,
  }) async {
    final body = <String, dynamic>{
      'started_at': startedAt.toUtc().toIso8601String(),
      'ended_at': endedAt.toUtc().toIso8601String(),
      'points': points.map((p) => p.toJson()).toList(),
    };
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      body['name'] = trimmedName;
    }
    final resp = await _postJson(
      '/v1/drives',
      body,
      auth: true,
    );
    if (resp.statusCode != 201 && resp.statusCode != 200) {
      throw ApiException('drives', resp.statusCode, null, resp.body);
    }
    return DriveUploadResult.fromJson(
      jsonDecode(resp.body) as Map<String, dynamic>,
    );
  }

  Future<List<DriveSummary>> fetchDrives() async {
    final uri = Uri.parse('$baseUrl/v1/drives');
    final resp = await _getAuthed(uri);
    if (resp.statusCode != 200) {
      throw ApiException('drives', resp.statusCode, null, resp.body);
    }
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(DriveSummary.fromJson)
        .toList();
  }

  Future<DriveDetail> fetchDrive(String id) async {
    final uri = Uri.parse('$baseUrl/v1/drives/$id');
    final resp = await _getAuthed(uri);
    if (resp.statusCode != 200) {
      throw ApiException('drives/$id', resp.statusCode, null, resp.body);
    }
    return DriveDetail.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<void> renameDrive(String id, String name) async {
    final uri = Uri.parse('$baseUrl/v1/drives/$id');
    final resp = await _patchJson(uri, {'name': name});
    if (resp.statusCode != 204 && resp.statusCode != 200) {
      throw ApiException('drives/$id', resp.statusCode, null, resp.body);
    }
  }

  Future<UserStats> fetchMyStats() async {
    final uri = Uri.parse('$baseUrl/v1/users/me/stats');
    final resp = await _getAuthed(uri);
    if (resp.statusCode != 200) {
      throw ApiException('users/me/stats', resp.statusCode, null, resp.body);
    }
    return UserStats.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
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

  Future<List<RoadEtaResult>> fetchCameraEtas({
    required double originLat,
    required double originLon,
    required List<RoadEtaDestination> destinations,
  }) async {
    final resp = await _postJson(
      '/v1/eta/cameras',
      {
        'origin': {'lat': originLat, 'lon': originLon},
        'destinations': destinations.map((d) => d.toJson()).toList(),
      },
      auth: true,
      timeout: RoadEtaConstants.requestTimeout,
    );
    if (resp.statusCode != 200) {
      throw ApiException('eta/cameras', resp.statusCode, null, resp.body);
    }
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(RoadEtaResult.fromJson)
        .toList();
  }

  Future<List<AmenityPlace>> fetchAmenityCells({
    required List<AmenityCellRef> cells,
    List<String> types = AmenityConstants.defaultTypes,
  }) async {
    final resp = await _postJson(
      '/v1/amenities/cells',
      {
        'cells': cells.map((c) => c.toJson()).toList(),
        'types': types,
      },
      auth: true,
      timeout: AmenityConstants.requestTimeout,
    );
    if (resp.statusCode != 200) {
      throw ApiException('amenities/cells', resp.statusCode, null, resp.body);
    }
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(AmenityPlace.fromJson)
        .toList();
  }
}

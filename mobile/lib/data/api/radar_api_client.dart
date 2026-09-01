import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:http/http.dart' as http;
import 'package:radar_alert/data/api/auth_models.dart';
import 'package:radar_alert/data/auth/token_store.dart';
import 'package:radar_alert/features/alerts/road_eta_models.dart';
import 'package:radar_alert/features/amenities/amenity_models.dart';
import 'package:radar_alert/features/profile/profile_models.dart';
import 'package:radar_alert/features/profile/vehicle_models.dart';
import 'package:radar_alert/features/reports/live_report_models.dart';

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
    if (isNetworkError) {
      return 'Sunucuya ulaşılamadı. İnternet bağlantınızı kontrol edip tekrar deneyin.';
    }
    if (statusCode == 429) {
      return 'Çok fazla deneme. Lütfen bir dakika bekleyip tekrar deneyin.';
    }
    if (body != null && body!.isNotEmpty) {
      try {
        final map = jsonDecode(body!) as Map<String, dynamic>;
        final err = map['error'];
        if (err is String && err.isNotEmpty) {
          if (err.contains('oauth provider is not configured')) {
            return 'Google/Apple girişi sunucuda yapılandırılmamış.';
          }
          return err;
        }
      } catch (_) {}
    }
    if (isServerWakingUp) {
      return 'Sunucu uyanıyor. Lütfen birkaç saniye sonra tekrar deneyin.';
    }
    return 'Bir hata oluştu. Lütfen tekrar deneyin.';
  }

  @override
  String toString() =>
      'ApiException($endpoint, status: $statusCode, cause: $cause)';
}

class RadarApiClient {
  RadarApiClient({
    String? baseUrl,
    TokenStore? tokenStore,
    this.onAuthLost,
  })  : baseUrl = baseUrl ?? _resolveBaseUrl(),
        _tokens = tokenStore ?? SecureTokenStore();

  void Function()? onAuthLost;

  static const _productionBaseUrl = 'http://35.239.129.237:8081';
  static const _androidEmulatorLocalBaseUrl = 'http://10.0.2.2:8081';
  static const _localhostBaseUrl = 'http://127.0.0.1:8081';

  // Release builds always use production API.
  // Debug/profile builds default to local API and can be overridden via RADAR_API_URL.
  static String _resolveBaseUrl() {
    if (kReleaseMode) return _productionBaseUrl;

    const fromEnv = String.fromEnvironment('RADAR_API_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    // Android emulator cannot reach host localhost directly.
    if (Platform.isAndroid) return _androidEmulatorLocalBaseUrl;
    return _localhostBaseUrl;
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
    bool retryOnWake = true,
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

    http.Response? lastResp;
    for (var attempt = 0; attempt <= (retryOnWake ? _retryDelays.length : 0); attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(_retryDelays[attempt - 1]);
      }
      lastResp = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(timeout);
      final waking = lastResp.statusCode == 502 ||
          lastResp.statusCode == 503 ||
          lastResp.statusCode == 504;
      if (!waking || !retryOnWake) break;
    }
    final resp = lastResp!;

    if (resp.statusCode == 401 && auth && retryOnUnauthorized) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        return _postJson(
          path,
          body,
          auth: true,
          retryOnUnauthorized: false,
          retryOnWake: false,
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
        expiresIn: tokens.expiresIn,
      );
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await _tokens.clear();
        onAuthLost?.call();
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> ensureFreshAccess() async {
    final expires = await _tokens.accessExpiresAt;
    if (expires != null) {
      final stillValid =
          DateTime.now().toUtc().isBefore(expires.subtract(const Duration(minutes: 1)));
      if (stillValid) return true;
    }
    final access = await _tokens.accessToken;
    if (access != null && access.isNotEmpty && expires == null) {
      return true;
    }
    return _tryRefresh();
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

  Future<void> forgotPassword({required String email}) async {
    try {
      final resp = await _postJson('/v1/auth/forgot-password', {
        'email': email,
      });
      if (resp.statusCode != 200) {
        throw ApiException(
          'auth/forgot-password',
          resp.statusCode,
          null,
          resp.body,
        );
      }
    } on ApiException {
      rethrow;
    } on SocketException catch (e) {
      throw ApiException('auth/forgot-password', null, e);
    } on http.ClientException catch (e) {
      throw ApiException('auth/forgot-password', null, e);
    } on TimeoutException catch (e) {
      throw ApiException('auth/forgot-password', null, e);
    }
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      final resp = await _postJson('/v1/auth/reset-password', {
        'token': token,
        'password': password,
      });
      if (resp.statusCode != 200) {
        throw ApiException(
          'auth/reset-password',
          resp.statusCode,
          null,
          resp.body,
        );
      }
    } on ApiException {
      rethrow;
    } on SocketException catch (e) {
      throw ApiException('auth/reset-password', null, e);
    } on http.ClientException catch (e) {
      throw ApiException('auth/reset-password', null, e);
    } on TimeoutException catch (e) {
      throw ApiException('auth/reset-password', null, e);
    }
  }

  Future<AuthTokens> oauthLogin({
    required String provider,
    required String idToken,
    String? nonce,
  }) async {
    final body = <String, dynamic>{
      'provider': provider,
      'id_token': idToken,
    };
    if (nonce != null && nonce.isNotEmpty) {
      body['nonce'] = nonce;
    }
    final resp = await _postJson('/v1/auth/oauth', body);
    if (resp.statusCode != 200) {
      throw ApiException('auth/oauth', resp.statusCode, null, resp.body);
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

  Future<UserProfile> fetchMyProfile() async {
    final uri = Uri.parse('$baseUrl/v1/users/me');
    final resp = await _getAuthed(uri);
    if (resp.statusCode != 200) {
      throw ApiException('users/me', resp.statusCode, null, resp.body);
    }
    return UserProfile.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<UserProfile> updateMyPreferences({
    VehicleType? vehicleType,
    Color? vehicleColor,
  }) async {
    final body = <String, dynamic>{};
    if (vehicleType != null) {
      body['vehicle_type'] = vehicleType.apiValue;
    }
    if (vehicleColor != null) {
      body['vehicle_color'] = vehicleColorToHex(vehicleColor);
    }
    final uri = Uri.parse('$baseUrl/v1/users/me');
    final resp = await _patchJson(uri, body);
    if (resp.statusCode != 200) {
      throw ApiException('users/me', resp.statusCode, null, resp.body);
    }
    return UserProfile.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<UserProfile> uploadProfilePicture(String filePath) async {
    final uri = Uri.parse('$baseUrl/v1/users/me/profile-picture');
    Future<http.Response> send() async {
      final request = http.MultipartRequest('POST', uri);
      final access = await _tokens.accessToken;
      if (access != null && access.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $access';
      }
      request.headers['Accept'] = 'application/json';
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      final streamed =
          await request.send().timeout(const Duration(seconds: 60));
      return http.Response.fromStream(streamed);
    }

    var resp = await send();
    if (resp.statusCode == 401) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        resp = await send();
      }
    }
    if (resp.statusCode != 200) {
      throw ApiException(
        'users/me/profile-picture',
        resp.statusCode,
        null,
        resp.body,
      );
    }
    return UserProfile.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<ReportResult> createReport({
    required double lat,
    required double lon,
    double? headingDeg,
    String region = 'bursa',
  }) async {
    final body = <String, dynamic>{
      'lat': lat,
      'lon': lon,
      'region': region,
    };
    if (headingDeg != null) {
      body['heading_deg'] = headingDeg;
    }
    final resp = await _postJson('/v1/reports', body, auth: true);
    if (resp.statusCode != 201 && resp.statusCode != 200) {
      throw ApiException('reports', resp.statusCode, null, resp.body);
    }
    return ReportResult.fromJson(
      jsonDecode(resp.body) as Map<String, dynamic>,
    );
  }

  Future<ReportResult> voteReport({
    required int reportId,
    required int value,
    required double lat,
    required double lon,
  }) async {
    final resp = await _postJson(
      '/v1/reports/$reportId/votes',
      {
        'value': value,
        'lat': lat,
        'lon': lon,
      },
      auth: true,
    );
    if (resp.statusCode != 200) {
      throw ApiException(
        'reports/$reportId/votes',
        resp.statusCode,
        null,
        resp.body,
      );
    }
    return ReportResult.fromJson(
      jsonDecode(resp.body) as Map<String, dynamic>,
    );
  }

  Future<LiveReport> createLiveReport({
    required double lat,
    required double lng,
    required String reportType,
  }) async {
    final resp = await _postJson(
      '/v1/live-reports',
      {
        'lat': lat,
        'lng': lng,
        'report_type': reportType,
      },
      auth: true,
    );
    if (resp.statusCode != 201 && resp.statusCode != 200) {
      throw ApiException('live-reports', resp.statusCode, null, resp.body);
    }
    return LiveReport.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<List<LiveReport>> fetchActiveLiveReports() async {
    final uri = Uri.parse('$baseUrl/v1/live-reports/active');
    final resp = await _getWithRetry(uri, 'live-reports/active');
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(LiveReport.fromJson)
        .toList();
  }

  Future<void> voteLiveReport({
    required String reportId,
    required bool isUpvote,
  }) async {
    final resp = await _postJson(
      '/v1/live-reports/$reportId/vote',
      {
        'is_upvote': isUpvote,
      },
      auth: true,
    );
    if (resp.statusCode != 200) {
      throw ApiException(
        'live-reports/$reportId/vote',
        resp.statusCode,
        null,
        resp.body,
      );
    }
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

  Future<Uint8List> speakTts({
    required String phraseKey,
    Map<String, dynamic> params = const {},
  }) async {
    final resp = await _postJson(
      '/v1/tts/speak',
      {
        'phrase_key': phraseKey,
        'params': params,
      },
      auth: true,
      timeout: const Duration(seconds: 20),
    );
    if (resp.statusCode != 200) {
      throw ApiException('tts/speak', resp.statusCode, null, resp.body);
    }
    return resp.bodyBytes;
  }

  Future<List<TtsCatalogEntry>> fetchTtsCatalog() async {
    final uri = Uri.parse('$baseUrl/v1/tts/catalog');
    final resp = await _getAuthed(uri);
    if (resp.statusCode != 200) {
      throw ApiException('tts/catalog', resp.statusCode, null, resp.body);
    }
    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    final list = map['entries'] as List<dynamic>? ?? const [];
    return list
        .cast<Map<String, dynamic>>()
        .map(TtsCatalogEntry.fromJson)
        .toList();
  }
}

class TtsCatalogEntry {
  const TtsCatalogEntry({
    required this.phraseKey,
    this.distanceM,
  });

  final String phraseKey;
  final int? distanceM;

  factory TtsCatalogEntry.fromJson(Map<String, dynamic> json) {
    return TtsCatalogEntry(
      phraseKey: json['phrase_key'] as String? ?? '',
      distanceM: (json['distance_m'] as num?)?.toInt(),
    );
  }
}

class ReportResult {
  const ReportResult({
    required this.id,
    required this.lat,
    required this.lon,
    required this.regionCode,
    required this.status,
    required this.confidenceScore,
    required this.upvotes,
    required this.downvotes,
    required this.expiresAt,
    required this.merged,
    required this.source,
  });

  final int id;
  final double lat;
  final double lon;
  final String regionCode;
  final String status;
  final double confidenceScore;
  final int upvotes;
  final int downvotes;
  final DateTime expiresAt;
  final bool merged;
  final String source;

  /// Local cache / map id uses a negative namespace to avoid colliding with imports.
  int get localCameraId => -id;

  factory ReportResult.fromJson(Map<String, dynamic> json) {
    return ReportResult(
      id: json['id'] as int,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      regionCode: (json['region_code'] as String?) ?? 'bursa',
      status: (json['status'] as String?) ?? 'active',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.35,
      upvotes: (json['upvotes'] as num?)?.toInt() ?? 0,
      downvotes: (json['downvotes'] as num?)?.toInt() ?? 0,
      expiresAt: DateTime.parse(json['expires_at'] as String).toLocal(),
      merged: json['merged'] as bool? ?? false,
      source: (json['source'] as String?) ?? 'crowd',
    );
  }
}

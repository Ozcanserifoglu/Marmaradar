import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenStore {
  Future<String?> get accessToken;
  Future<String?> get refreshToken;
  Future<String?> get userId;
  Future<String?> get email;
  Future<DateTime?> get accessExpiresAt;

  Future<bool> get hasSession;

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String email,
    int? expiresIn,
  });

  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _emailKey = 'user_email';
  static const _expiresKey = 'access_expires_at';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> get accessToken => _storage.read(key: _accessKey);

  @override
  Future<String?> get refreshToken => _storage.read(key: _refreshKey);

  @override
  Future<String?> get userId => _storage.read(key: _userIdKey);

  @override
  Future<String?> get email => _storage.read(key: _emailKey);

  @override
  Future<DateTime?> get accessExpiresAt async {
    final raw = await _storage.read(key: _expiresKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  @override
  Future<bool> get hasSession async {
    final access = await accessToken;
    final refresh = await refreshToken;
    return (access != null && access.isNotEmpty) ||
        (refresh != null && refresh.isNotEmpty);
  }

  @override
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String email,
    int? expiresIn,
  }) async {
    final expiry = expiresIn == null
        ? null
        : DateTime.now().toUtc().add(Duration(seconds: expiresIn)).toIso8601String();
    await Future.wait([
      _storage.write(key: _accessKey, value: accessToken),
      _storage.write(key: _refreshKey, value: refreshToken),
      _storage.write(key: _userIdKey, value: userId),
      _storage.write(key: _emailKey, value: email),
      if (expiry != null) _storage.write(key: _expiresKey, value: expiry),
    ]);
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessKey),
      _storage.delete(key: _refreshKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _emailKey),
      _storage.delete(key: _expiresKey),
    ]);
  }
}

class MemoryTokenStore implements TokenStore {
  String? _accessToken;
  String? _refreshToken;
  String? _userId;
  String? _email;
  DateTime? _expiresAt;

  @override
  Future<String?> get accessToken async => _accessToken;

  @override
  Future<String?> get refreshToken async => _refreshToken;

  @override
  Future<String?> get userId async => _userId;

  @override
  Future<String?> get email async => _email;

  @override
  Future<DateTime?> get accessExpiresAt async => _expiresAt;

  @override
  Future<bool> get hasSession async {
    return (_accessToken != null && _accessToken!.isNotEmpty) ||
        (_refreshToken != null && _refreshToken!.isNotEmpty);
  }

  @override
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String email,
    int? expiresIn,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _userId = userId;
    _email = email;
    _expiresAt = expiresIn == null
        ? null
        : DateTime.now().toUtc().add(Duration(seconds: expiresIn));
  }

  @override
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _userId = null;
    _email = null;
    _expiresAt = null;
  }
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists JWT session tokens.
abstract class TokenStore {
  Future<String?> get accessToken;
  Future<String?> get refreshToken;
  Future<String?> get userId;
  Future<String?> get email;
  Future<bool> get hasSession;

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String email,
  });

  Future<void> clear();
}

/// Platform secure storage (Keychain / EncryptedSharedPreferences).
class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _emailKey = 'user_email';

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
  }) async {
    await Future.wait([
      _storage.write(key: _accessKey, value: accessToken),
      _storage.write(key: _refreshKey, value: refreshToken),
      _storage.write(key: _userIdKey, value: userId),
      _storage.write(key: _emailKey, value: email),
    ]);
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessKey),
      _storage.delete(key: _refreshKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _emailKey),
    ]);
  }
}

/// In-memory store for widget/unit tests (no platform plugins).
class MemoryTokenStore implements TokenStore {
  String? _accessToken;
  String? _refreshToken;
  String? _userId;
  String? _email;

  @override
  Future<String?> get accessToken async => _accessToken;

  @override
  Future<String?> get refreshToken async => _refreshToken;

  @override
  Future<String?> get userId async => _userId;

  @override
  Future<String?> get email async => _email;

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
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _userId = userId;
    _email = email;
  }

  @override
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _userId = null;
    _email = null;
  }
}

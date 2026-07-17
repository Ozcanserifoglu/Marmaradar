import 'package:flutter/foundation.dart';
import 'package:radar_alert/data/api/auth_models.dart';
import 'package:radar_alert/data/api/radar_api_client.dart';
import 'package:radar_alert/data/auth/token_store.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required TokenStore tokenStore,
    required RadarApiClient apiClient,
  })  : _tokens = tokenStore,
        _api = apiClient;

  final TokenStore _tokens;
  final RadarApiClient _api;

  bool _booting = true;
  bool _busy = false;
  bool _authenticated = false;
  String? _email;
  String? _userId;
  String? _error;

  bool get isBooting => _booting;
  bool get isBusy => _busy;
  bool get isAuthenticated => _authenticated;
  String? get email => _email;
  String? get userId => _userId;
  String? get error => _error;
  RadarApiClient get api => _api;
  TokenStore get tokenStore => _tokens;

  Future<void> bootstrap() async {
    _booting = true;
    notifyListeners();
    try {
      final has = await _tokens.hasSession;
      if (!has) {
        _authenticated = false;
        return;
      }
      _email = await _tokens.email;
      _userId = await _tokens.userId;
      final access = await _tokens.accessToken;
      if (access == null || access.isEmpty) {
        final refresh = await _tokens.refreshToken;
        if (refresh != null && refresh.isNotEmpty) {
          final tokens = await _api.refreshSession(refresh);
          await _persist(tokens);
        }
      }
      _authenticated = await _tokens.hasSession;
    } catch (_) {
      await _tokens.clear();
      _authenticated = false;
      _email = null;
      _userId = null;
    } finally {
      _booting = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    return _authenticate(() => _api.login(email: email, password: password));
  }

  Future<bool> register(String email, String password) async {
    return _authenticate(
      () => _api.register(email: email, password: password),
    );
  }

  Future<bool> _authenticate(Future<AuthTokens> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final tokens = await action();
      await _persist(tokens);
      _authenticated = true;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _persist(AuthTokens tokens) async {
    await _tokens.saveSession(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      userId: tokens.userId,
      email: tokens.email,
    );
    _email = tokens.email;
    _userId = tokens.userId;
  }

  Future<void> logout() async {
    await _tokens.clear();
    _authenticated = false;
    _email = null;
    _userId = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:radar_alert/data/api/auth_models.dart';
import 'package:radar_alert/data/api/radar_api_client.dart';
import 'package:radar_alert/data/auth/oauth_config.dart';
import 'package:radar_alert/data/auth/token_store.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required TokenStore tokenStore,
    required RadarApiClient apiClient,
    GoogleSignIn? googleSignIn,
  })  : _tokens = tokenStore,
        _api = apiClient,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email', 'openid'],
              serverClientId: OAuthConfig.hasGoogleServerClientId
                  ? OAuthConfig.googleServerClientId
                  : null,
              clientId: (!kIsWeb &&
                      Platform.isIOS &&
                      OAuthConfig.googleIosClientId.isNotEmpty)
                  ? OAuthConfig.googleIosClientId
                  : null,
            );

  final TokenStore _tokens;
  final RadarApiClient _api;
  final GoogleSignIn _googleSignIn;

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

  bool get canUseGoogleSignIn => OAuthConfig.hasGoogleServerClientId;
  bool get showAppleSignIn => !kIsWeb && Platform.isIOS;

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

  Future<bool> loginWithGoogle() async {
    if (!canUseGoogleSignIn) {
      _error =
          'Google Sign-In yapılandırılmamış (GOOGLE_SERVER_CLIENT_ID eksik).';
      notifyListeners();
      return false;
    }
    return _authenticate(() async {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw const ApiException('auth/oauth', null, 'Google sign-in cancelled');
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const ApiException(
          'auth/oauth',
          null,
          'Google ID token alınamadı',
        );
      }
      return _api.oauthLogin(provider: 'google', idToken: idToken);
    });
  }

  Future<bool> loginWithApple() async {
    if (!showAppleSignIn) {
      _error = 'Apple ile giriş yalnızca iOS üzerinde kullanılabilir.';
      notifyListeners();
      return false;
    }
    return _authenticate(() async {
      final rawNonce = _generateNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw const ApiException(
          'auth/oauth',
          null,
          'Apple kimlik jetonu alınamadı',
        );
      }
      return _api.oauthLogin(
        provider: 'apple',
        idToken: idToken,
        nonce: rawNonce,
      );
    });
  }

  Future<bool> _authenticate(Future<AuthTokens> Function() action) async {
    if (_busy) return false;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final tokens = await action();
      await _persist(tokens);
      _authenticated = true;
      return true;
    } on ApiException catch (e) {
      // User cancelled native sheet — keep silent.
      if (e.cause == 'Google sign-in cancelled' ||
          e.message.contains('canceled') ||
          e.message.contains('cancelled')) {
        _error = null;
        return false;
      }
      _error = e.message;
      return false;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        _error = null;
        return false;
      }
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
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
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

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}

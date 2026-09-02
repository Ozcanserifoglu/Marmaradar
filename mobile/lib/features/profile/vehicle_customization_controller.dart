import 'package:flutter/material.dart';
import 'package:radar_alert/data/api/radar_api_client.dart';
import 'package:radar_alert/features/profile/vehicle_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VehicleCustomizationController extends ChangeNotifier {
  VehicleCustomizationController({required RadarApiClient apiClient})
      : _api = apiClient;

  static const _typeKey = 'vehicle_type';
  static const _colorKey = 'vehicle_color';
  static const _pictureKey = 'profile_picture_url';
  static const _usernameKey = 'username';

  final RadarApiClient _api;

  VehicleType vehicleType = VehicleType.sedan;
  Color vehicleColor = kDefaultVehicleColor;
  String? profilePictureUrl;
  String? username;
  bool saving = false;
  bool savingUsername = false;
  bool uploadingPicture = false;
  String? error;

  Future<void> loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    vehicleType = VehicleType.fromApi(prefs.getString(_typeKey));
    vehicleColor = parseVehicleColor(prefs.getString(_colorKey));
    profilePictureUrl = prefs.getString(_pictureKey);
    username = prefs.getString(_usernameKey);
    notifyListeners();
  }

  Future<void> syncFromServer() async {
    try {
      final profile = await _api.fetchMyProfile();
      vehicleType = profile.vehicleType;
      vehicleColor = profile.vehicleColor;
      profilePictureUrl = profile.profilePictureUrl;
      username = profile.username;
      error = null;
      await _persistLocal();
      notifyListeners();
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
    } catch (_) {
      // Keep cached prefs when offline.
    }
  }

  Future<void> setVehicleType(VehicleType type) async {
    if (vehicleType == type) return;
    vehicleType = type;
    notifyListeners();
    await _persistLocal();
  }

  Future<void> setVehicleColor(Color color) async {
    if (vehicleColor == color) return;
    vehicleColor = color;
    notifyListeners();
    await _persistLocal();
  }

  Future<bool> saveToServer() async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      final profile = await _api.updateMyPreferences(
        vehicleType: vehicleType,
        vehicleColor: vehicleColor,
      );
      vehicleType = profile.vehicleType;
      vehicleColor = profile.vehicleColor;
      profilePictureUrl = profile.profilePictureUrl ?? profilePictureUrl;
      username = profile.username ?? username;
      await _persistLocal();
      saving = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      saving = false;
      notifyListeners();
      return false;
    } catch (_) {
      error = 'Tercihler kaydedilemedi.';
      saving = false;
      notifyListeners();
      return false;
    }
  }

  /// Saves [nextUsername] after local regex validation. Returns null on success,
  /// or a Turkish error message on failure (including 409 taken).
  Future<String?> saveUsername(String nextUsername) async {
    final normalized = nextUsername.trim().toLowerCase();
    if (!isValidUsername(normalized)) {
      return 'Kullanıcı adı 3–20 karakter olmalı (a-z, 0-9, _).';
    }
    if (username == normalized) {
      return null;
    }

    savingUsername = true;
    error = null;
    notifyListeners();
    try {
      final profile = await _api.updateMyPreferences(username: normalized);
      username = profile.username;
      vehicleType = profile.vehicleType;
      vehicleColor = profile.vehicleColor;
      profilePictureUrl = profile.profilePictureUrl ?? profilePictureUrl;
      await _persistLocal();
      savingUsername = false;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      final msg = e.statusCode == 409
          ? 'Bu kullanıcı adı zaten alınmış.'
          : e.message;
      error = msg;
      savingUsername = false;
      notifyListeners();
      return msg;
    } catch (_) {
      error = 'Kullanıcı adı kaydedilemedi.';
      savingUsername = false;
      notifyListeners();
      return error;
    }
  }

  Future<bool> uploadProfilePicture(String filePath) async {
    uploadingPicture = true;
    error = null;
    notifyListeners();
    try {
      final profile = await _api.uploadProfilePicture(filePath);
      profilePictureUrl = profile.profilePictureUrl;
      vehicleType = profile.vehicleType;
      vehicleColor = profile.vehicleColor;
      username = profile.username ?? username;
      await _persistLocal();
      uploadingPicture = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      uploadingPicture = false;
      notifyListeners();
      return false;
    } catch (_) {
      error = 'Profil fotoğrafı yüklenemedi.';
      uploadingPicture = false;
      notifyListeners();
      return false;
    }
  }

  void clear() {
    vehicleType = VehicleType.sedan;
    vehicleColor = kDefaultVehicleColor;
    profilePictureUrl = null;
    username = null;
    error = null;
    notifyListeners();
  }

  Future<void> _persistLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_typeKey, vehicleType.apiValue);
    await prefs.setString(_colorKey, vehicleColorToHex(vehicleColor));
    if (profilePictureUrl == null || profilePictureUrl!.isEmpty) {
      await prefs.remove(_pictureKey);
    } else {
      await prefs.setString(_pictureKey, profilePictureUrl!);
    }
    if (username == null || username!.isEmpty) {
      await prefs.remove(_usernameKey);
    } else {
      await prefs.setString(_usernameKey, username!);
    }
  }

  String? get absolutePictureUrl {
    final url = profilePictureUrl;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '${_api.baseUrl}$url';
    return '${_api.baseUrl}/$url';
  }
}

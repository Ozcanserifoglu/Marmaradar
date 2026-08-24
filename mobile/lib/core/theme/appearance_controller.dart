import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:radar_alert/features/tracking/widgets/radar_map_view.dart';

enum MapBasemapPreference { follow, dark, light }

class AppearanceController extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _mapKey = 'map_style';

  ThemeMode themeMode = ThemeMode.dark;
  MapBasemapPreference mapBasemap = MapBasemapPreference.follow;

  MapStyle get resolvedMapStyle {
    switch (mapBasemap) {
      case MapBasemapPreference.light:
        return MapStyle.light;
      case MapBasemapPreference.dark:
        return MapStyle.dark;
      case MapBasemapPreference.follow:
        return themeMode == ThemeMode.light ? MapStyle.light : MapStyle.dark;
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    themeMode = prefs.getString(_themeKey) == 'light'
        ? ThemeMode.light
        : ThemeMode.dark;
    mapBasemap = switch (prefs.getString(_mapKey)) {
      'light' => MapBasemapPreference.light,
      'dark' => MapBasemapPreference.dark,
      _ => MapBasemapPreference.follow,
    };
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (themeMode == mode) return;
    themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode == ThemeMode.light ? 'light' : 'dark');
  }

  Future<void> toggleMapOverride() async {
    mapBasemap = resolvedMapStyle == MapStyle.dark
        ? MapBasemapPreference.light
        : MapBasemapPreference.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _mapKey,
      mapBasemap == MapBasemapPreference.light ? 'light' : 'dark',
    );
  }
}

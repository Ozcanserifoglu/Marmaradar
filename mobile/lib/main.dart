import 'package:flutter/material.dart';
import 'package:radar_alert/app.dart';
import 'package:radar_alert/core/config/maps_api_key.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initLatestMapRenderer();
  runApp(const MarmaradarRoot());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    MapsApiKey.ensureLoaded();
  });
}

Future<void> _initLatestMapRenderer() async {
  final maps = GoogleMapsFlutterPlatform.instance;
  if (maps is GoogleMapsFlutterAndroid) {
    await maps.initializeWithRenderer(AndroidMapRenderer.latest);
  }
}

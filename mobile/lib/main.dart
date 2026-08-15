import 'package:flutter/material.dart';
import 'package:radar_alert/app.dart';
import 'package:radar_alert/core/config/maps_api_key.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MarmaradarRoot());
  // After first frame the native method channel can read MAPS_API_KEY.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    MapsApiKey.ensureLoaded();
  });
}

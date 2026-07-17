import 'package:flutter/material.dart';
import 'package:radar_alert/app.dart';
import 'package:radar_alert/core/config/maps_api_key.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MarmaradarApp());
  // After the first frame the Android/iOS method channel is registered and
  // can read MAPS_API_KEY from local.properties / MapsSecrets.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    MapsApiKey.ensureLoaded();
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:radar_alert/core/theme/app_theme.dart';
import 'package:radar_alert/features/directions/directions_controller.dart';
import 'package:radar_alert/features/tracking/tracking_controller.dart';
import 'package:radar_alert/features/tracking/tracking_screen.dart';

class MarmaradarApp extends StatelessWidget {
  const MarmaradarApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.night,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return ProviderScope(
      child: MaterialApp(
        title: 'Marmaradar',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const TrackingScreen(),
      ),
    );
  }
}

final trackingControllerProvider =
    ChangeNotifierProvider<TrackingController>((ref) {
  return TrackingController();
});

final directionsControllerProvider =
    ChangeNotifierProvider<DirectionsController>((ref) {
  return DirectionsController();
});

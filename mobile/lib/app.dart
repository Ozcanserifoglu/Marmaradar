import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:radar_alert/features/tracking/tracking_controller.dart';
import 'package:radar_alert/features/tracking/tracking_screen.dart';

class RadarAlertApp extends StatelessWidget {
  const RadarAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Radar Alert',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
          useMaterial3: true,
        ),
        home: const TrackingScreen(),
      ),
    );
  }
}

final trackingControllerProvider =
    ChangeNotifierProvider<TrackingController>((ref) {
  return TrackingController();
});

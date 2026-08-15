import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:radar_alert/core/theme/app_theme.dart';
import 'package:radar_alert/data/api/radar_api_client.dart';
import 'package:radar_alert/data/auth/token_store.dart';
import 'package:radar_alert/features/auth/auth_controller.dart';
import 'package:radar_alert/features/directions/directions_controller.dart';
import 'package:radar_alert/features/drives/drives_controller.dart';
import 'package:radar_alert/features/tracking/tracking_controller.dart';
import 'package:radar_alert/features/tracking/tracking_screen.dart';

final _sharedTokenStore = SecureTokenStore();
final _sharedApiClient = RadarApiClient(tokenStore: _sharedTokenStore);

class MarmaradarApp extends ConsumerStatefulWidget {
  const MarmaradarApp({super.key});

  @override
  ConsumerState<MarmaradarApp> createState() => _MarmaradarAppState();
}

class _MarmaradarAppState extends ConsumerState<MarmaradarApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authControllerProvider);
      if (auth.isBooting) {
        auth.bootstrap();
      }
    });
  }

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

    final auth = ref.watch(authControllerProvider);

    final Widget home = auth.isBooting
        ? const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          )
        : const TrackingScreen();

    return MaterialApp(
      title: 'Marmaradar',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: home,
    );
  }
}

class MarmaradarRoot extends StatelessWidget {
  const MarmaradarRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: MarmaradarApp());
  }
}

final authControllerProvider =
    ChangeNotifierProvider<AuthController>((ref) {
  return AuthController(
    tokenStore: _sharedTokenStore,
    apiClient: _sharedApiClient,
  );
});

final trackingControllerProvider =
    ChangeNotifierProvider<TrackingController>((ref) {
  return TrackingController(apiClient: _sharedApiClient);
});

final directionsControllerProvider =
    ChangeNotifierProvider<DirectionsController>((ref) {
  return DirectionsController();
});

final drivesControllerProvider =
    ChangeNotifierProvider<DrivesController>((ref) {
  return DrivesController(apiClient: _sharedApiClient);
});

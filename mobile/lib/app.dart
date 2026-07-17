import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:radar_alert/core/theme/app_theme.dart';
import 'package:radar_alert/data/api/radar_api_client.dart';
import 'package:radar_alert/data/auth/token_store.dart';
import 'package:radar_alert/features/auth/auth_controller.dart';
import 'package:radar_alert/features/auth/auth_screen.dart';
import 'package:radar_alert/features/directions/directions_controller.dart';
import 'package:radar_alert/features/tracking/tracking_controller.dart';
import 'package:radar_alert/features/tracking/tracking_screen.dart';

final _sharedTokenStore = TokenStore();
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
      ref.read(authControllerProvider).bootstrap();
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

    Widget home;
    if (auth.isBooting) {
      home = const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (!auth.isAuthenticated) {
      home = const AuthScreen();
    } else {
      home = const TrackingScreen();
    }

    return MaterialApp(
      title: 'Marmaradar',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: home,
    );
  }
}

/// Root widget that provides Riverpod scope around [MarmaradarApp].
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

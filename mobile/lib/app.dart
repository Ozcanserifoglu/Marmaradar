import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:radar_alert/core/theme/app_theme.dart';
import 'package:radar_alert/core/theme/appearance_controller.dart';
import 'package:radar_alert/data/api/radar_api_client.dart';
import 'package:radar_alert/data/auth/token_store.dart';
import 'package:radar_alert/data/local/app_database.dart';
import 'package:radar_alert/features/auth/auth_controller.dart';
import 'package:radar_alert/features/directions/directions_controller.dart';
import 'package:radar_alert/features/drives/drives_controller.dart';
import 'package:radar_alert/features/leaderboard/leaderboard_controller.dart';
import 'package:radar_alert/features/profile/profile_controller.dart';
import 'package:radar_alert/features/profile/vehicle_customization_controller.dart';
import 'package:radar_alert/features/tracking/tracking_controller.dart';
import 'package:radar_alert/features/tracking/tracking_screen.dart';

final _sharedTokenStore = SecureTokenStore();
final _sharedApiClient = RadarApiClient(tokenStore: _sharedTokenStore);
final _sharedDb = AppDatabase();

class MarmaradarApp extends ConsumerStatefulWidget {
  const MarmaradarApp({super.key});

  @override
  ConsumerState<MarmaradarApp> createState() => _MarmaradarAppState();
}

class _MarmaradarAppState extends ConsumerState<MarmaradarApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = ref.read(authControllerProvider);
      if (auth.isBooting) {
        await auth.bootstrap();
      }
      if (auth.isAuthenticated) {
        unawaited(
          ref.read(trackingControllerProvider).syncPendingDriveUploads(),
        );
        unawaited(
          ref.read(vehicleCustomizationControllerProvider).syncFromServer(),
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(() async {
        await ref.read(authControllerProvider).ensureSession();
        if (ref.read(authControllerProvider).isAuthenticated) {
          await ref.read(trackingControllerProvider).syncPendingDriveUploads();
        }
      }());
    }
  }

  @override
  Widget build(BuildContext context) {
    final appearance = ref.watch(appearanceControllerProvider);
    final brightness = appearance.themeMode == ThemeMode.light
        ? Brightness.light
        : Brightness.dark;
    final scaffold = brightness == Brightness.light
        ? AppColors.paper
        : AppColors.night;
    final iconBrightness = brightness == Brightness.light
        ? Brightness.dark
        : Brightness.light;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        systemNavigationBarColor: scaffold,
        systemNavigationBarIconBrightness: iconBrightness,
      ),
    );

    final auth = ref.watch(authControllerProvider);
    ref.listen<bool>(
      authControllerProvider.select((a) => a.isAuthenticated),
      (previous, next) {
        if (next) {
          ref.read(trackingControllerProvider).prefetchVoiceAlerts();
          unawaited(
            ref.read(trackingControllerProvider).syncPendingDriveUploads(),
          );
          unawaited(
            ref.read(vehicleCustomizationControllerProvider).syncFromServer(),
          );
        } else {
          ref.read(vehicleCustomizationControllerProvider).clear();
          ref.read(leaderboardControllerProvider).clear();
        }
      },
    );

    final Widget home = auth.isBooting
        ? const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          )
        : const TrackingScreen();

    return MaterialApp(
      title: 'Marmaradar',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: appearance.themeMode,
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

final appearanceControllerProvider =
    ChangeNotifierProvider<AppearanceController>((ref) {
  final controller = AppearanceController();
  controller.load();
  return controller;
});

final vehicleCustomizationControllerProvider =
    ChangeNotifierProvider<VehicleCustomizationController>((ref) {
  final controller =
      VehicleCustomizationController(apiClient: _sharedApiClient);
  controller.loadLocal();
  return controller;
});

final authControllerProvider =
    ChangeNotifierProvider<AuthController>((ref) {
  return AuthController(
    tokenStore: _sharedTokenStore,
    apiClient: _sharedApiClient,
  );
});

final drivesControllerProvider =
    ChangeNotifierProvider<DrivesController>((ref) {
  return DrivesController(apiClient: _sharedApiClient, db: _sharedDb);
});

final profileControllerProvider =
    ChangeNotifierProvider<ProfileController>((ref) {
  return ProfileController(apiClient: _sharedApiClient);
});

final leaderboardControllerProvider =
    ChangeNotifierProvider<LeaderboardController>((ref) {
  return LeaderboardController(apiClient: _sharedApiClient);
});

final trackingControllerProvider =
    ChangeNotifierProvider<TrackingController>((ref) {
  return TrackingController(
    apiClient: _sharedApiClient,
    database: _sharedDb,
    onDriveUploaded: () {
      ref.read(profileControllerProvider).invalidate();
      unawaited(
        ref.read(drivesControllerProvider).load(
              authenticated:
                  ref.read(authControllerProvider).isAuthenticated,
            ),
      );
    },
  );
});

final directionsControllerProvider =
    ChangeNotifierProvider<DirectionsController>((ref) {
  return DirectionsController();
});

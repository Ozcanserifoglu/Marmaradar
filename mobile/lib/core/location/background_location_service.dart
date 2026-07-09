import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

typedef LocationCallback = void Function(DriverSnapshot snapshot);

class DriverSnapshot {
  final double lat;
  final double lon;
  final double speedMps;
  final double headingDeg;
  final DateTime recordedAt;

  const DriverSnapshot({
    required this.lat,
    required this.lon,
    required this.speedMps,
    required this.headingDeg,
    required this.recordedAt,
  });
}

class BackgroundLocationService {
  StreamSubscription<Position>? _sub;

  Future<bool> ensurePermissions() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      return false;
    }
    if (perm == LocationPermission.whileInUse) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  Future<void> start(LocationCallback onUpdate) async {
    final settings = defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 5,
            intervalDuration: const Duration(seconds: 1),
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'Radar Alert aktif',
              notificationText: 'Hız kamerası uyarıları arka planda çalışıyor',
              enableWakeLock: true,
            ),
          )
        : AppleSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 5,
            activityType: ActivityType.automotiveNavigation,
            pauseLocationUpdatesAutomatically: false,
            showBackgroundLocationIndicator: true,
          );

    await _sub?.cancel();
    _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (pos) {
        onUpdate(
          DriverSnapshot(
            lat: pos.latitude,
            lon: pos.longitude,
            speedMps: pos.speed < 0 ? 0 : pos.speed,
            headingDeg: pos.heading < 0 ? 0 : pos.heading,
            recordedAt: pos.timestamp,
          ),
        );
      },
    );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}

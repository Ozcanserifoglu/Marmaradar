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

DriverSnapshot _toSnapshot(Position pos) {
  return DriverSnapshot(
    lat: pos.latitude,
    lon: pos.longitude,
    speedMps: pos.speed < 0 ? 0 : pos.speed,
    headingDeg: pos.heading < 0 ? 0 : pos.heading,
    recordedAt: pos.timestamp,
  );
}

class BackgroundLocationService {
  StreamSubscription<Position>? _sub;
  StreamSubscription<Position>? _idleSub;

  /// Foreground ("while in use") permission — enough to show the user on the
  /// map and detect driving while the app is open.
  Future<bool> ensureBasicPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

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

  /// One-shot position for centering the map on launch. Uses the last known
  /// fix when available (instant), otherwise waits for a fresh one.
  Future<DriverSnapshot?> currentSnapshot() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return _toSnapshot(last);
      final pos = await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 12));
      return _toSnapshot(pos);
    } catch (_) {
      return null;
    }
  }

  /// Lightweight position stream used while not driving: keeps the map
  /// marker fresh and feeds drive auto-detection. No foreground service.
  Future<void> startIdleWatch(
    LocationCallback onUpdate, {
    void Function(Object error)? onError,
  }) async {
    await _listenIdle(onUpdate, onError, forceLocationManager: false);
  }

  Future<void> stopIdleWatch() async {
    await _idleSub?.cancel();
    _idleSub = null;
  }

  Future<void> start(
    LocationCallback onUpdate, {
    void Function(Object error)? onError,
  }) async {
    await _listen(onUpdate, onError, forceLocationManager: false);
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> _listenIdle(
    LocationCallback onUpdate,
    void Function(Object error)? onError, {
    required bool forceLocationManager,
  }) async {
    final settings = defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
            forceLocationManager: forceLocationManager,
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          );

    await _idleSub?.cancel();
    _idleSub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (pos) => onUpdate(_toSnapshot(pos)),
      onError: (Object error) {
        if (_canFallBack(error, forceLocationManager)) {
          _listenIdle(onUpdate, onError, forceLocationManager: true);
        } else {
          onError?.call(error);
        }
      },
    );
  }

  Future<void> _listen(
    LocationCallback onUpdate,
    void Function(Object error)? onError, {
    required bool forceLocationManager,
  }) async {
    final settings = defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 5,
            intervalDuration: const Duration(seconds: 1),
            // Fallback path: bypass Google Play services (fused provider)
            // when its settings check wrongly reports location as disabled
            // (common on emulators and de-Googled devices).
            forceLocationManager: forceLocationManager,
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'Marmaradar aktif',
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
      (pos) => onUpdate(_toSnapshot(pos)),
      onError: (Object error) {
        if (_canFallBack(error, forceLocationManager)) {
          _listen(onUpdate, onError, forceLocationManager: true);
        } else {
          onError?.call(error);
        }
      },
    );
  }

  bool _canFallBack(Object error, bool alreadyForced) {
    return !alreadyForced &&
        defaultTargetPlatform == TargetPlatform.android &&
        error is LocationServiceDisabledException;
  }
}

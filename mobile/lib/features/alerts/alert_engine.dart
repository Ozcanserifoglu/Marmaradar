import 'package:radar_alert/core/geo/bearing.dart';
import 'package:radar_alert/core/location/background_location_service.dart';
import 'package:radar_alert/data/local/app_database.dart';

typedef RoadMetricsLookup = ({double distanceM, double durationSec})? Function(
  int cameraId,
);

/// Crowdsourced mobile cameras use negative local ids (API id * -1).
bool isCrowdCameraId(int id) => id < 0;

int crowdReportIdFromLocal(int localId) => -localId;

class AlertEngine {
  final Set<int> _alertedCameraIds = {};
  static const minSpeedMps = 5.0;
  static const ttaThresholdSec = 45.0;

  void onLocation(
    DriverSnapshot snap,
    List<CachedCamera> cameras,
    void Function(CachedCamera camera, double distanceM, double ttaSec) fire, {
    RoadMetricsLookup? roadMetrics,
    void Function(CachedCamera camera)? onLeftAlerted,
  }) {
    for (final cam in cameras) {
      final haversineDist = haversineM(snap.lat, snap.lon, cam.lat, cam.lon);
      if (haversineDist > cam.alertRadiusM) {
        if (haversineDist > cam.alertRadiusM * 1.2) {
          if (_alertedCameraIds.remove(cam.id)) {
            onLeftAlerted?.call(cam);
          }
        }
        continue;
      }

      if (!isAhead(
        snap.headingDeg,
        snap.lat,
        snap.lon,
        cam.lat,
        cam.lon,
        cam.directionDeg,
        cam.directionToleranceDeg,
      )) {
        continue;
      }

      final road = roadMetrics?.call(cam.id);
      final dist = road?.distanceM ?? haversineDist;
      final speed = snap.speedMps < minSpeedMps ? minSpeedMps : snap.speedMps;
      final tta = road?.durationSec ?? (dist / speed);

      if (tta <= ttaThresholdSec && !_alertedCameraIds.contains(cam.id)) {
        _alertedCameraIds.add(cam.id);
        fire(cam, dist, tta);
      }
    }
  }

  void reset() => _alertedCameraIds.clear();
}

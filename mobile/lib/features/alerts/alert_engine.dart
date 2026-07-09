import 'package:radar_alert/core/geo/bearing.dart';
import 'package:radar_alert/core/location/background_location_service.dart';
import 'package:radar_alert/data/local/app_database.dart';

class AlertEngine {
  final Set<int> _alertedCameraIds = {};
  static const minSpeedMps = 5.0;
  static const ttaThresholdSec = 45.0;

  void onLocation(
    DriverSnapshot snap,
    List<CachedCamera> cameras,
    void Function(CachedCamera camera, double distanceM, double ttaSec) fire,
  ) {
    for (final cam in cameras) {
      final dist = haversineM(snap.lat, snap.lon, cam.lat, cam.lon);
      if (dist > cam.alertRadiusM) {
        if (dist > cam.alertRadiusM * 1.2) {
          _alertedCameraIds.remove(cam.id);
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

      final speed = snap.speedMps < minSpeedMps ? minSpeedMps : snap.speedMps;
      final tta = dist / speed;
      if (tta <= ttaThresholdSec && !_alertedCameraIds.contains(cam.id)) {
        _alertedCameraIds.add(cam.id);
        fire(cam, dist, tta);
      }

      if (dist > cam.alertRadiusM * 1.2) {
        _alertedCameraIds.remove(cam.id);
      }
    }
  }

  void reset() => _alertedCameraIds.clear();
}

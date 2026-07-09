import 'dart:math';

const double earthRadiusM = 6371000;

double haversineM(double lat1, double lon1, double lat2, double lon2) {
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusM * c;
}

double bearingDeg(double lat1, double lon1, double lat2, double lon2) {
  final dLon = _toRad(lon2 - lon1);
  final y = sin(dLon) * cos(_toRad(lat2));
  final x = cos(_toRad(lat1)) * sin(_toRad(lat2)) -
      sin(_toRad(lat1)) * cos(_toRad(lat2)) * cos(dLon);
  return (_toDeg(atan2(y, x)) + 360) % 360;
}

bool isAhead(
  double headingDeg,
  double userLat,
  double userLon,
  double targetLat,
  double targetLon,
  int? cameraDirectionDeg,
  int directionToleranceDeg,
) {
  final bearingToTarget = bearingDeg(userLat, userLon, targetLat, targetLon);
  if (!_withinCone(headingDeg, bearingToTarget, directionToleranceDeg)) {
    return false;
  }
  if (cameraDirectionDeg != null) {
    return _withinCone(
      cameraDirectionDeg.toDouble(),
      bearingToTarget,
      directionToleranceDeg,
    );
  }
  return true;
}

bool _withinCone(double centerDeg, double targetDeg, int toleranceDeg) {
  final diff = (targetDeg - centerDeg + 540) % 360 - 180;
  return diff.abs() <= toleranceDeg;
}

double _toRad(double deg) => deg * pi / 180;
double _toDeg(double rad) => rad * 180 / pi;

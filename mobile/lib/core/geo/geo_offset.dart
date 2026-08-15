import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

LatLng offsetByMeters(LatLng from, double meters, double bearingDeg) {
  const earthRadiusM = 6371000.0;
  final bearing = bearingDeg * math.pi / 180;
  final lat1 = from.latitude * math.pi / 180;
  final lon1 = from.longitude * math.pi / 180;
  final angDist = meters / earthRadiusM;

  final lat2 = math.asin(
    math.sin(lat1) * math.cos(angDist) +
        math.cos(lat1) * math.sin(angDist) * math.cos(bearing),
  );
  final lon2 = lon1 +
      math.atan2(
        math.sin(bearing) * math.sin(angDist) * math.cos(lat1),
        math.cos(angDist) - math.sin(lat1) * math.sin(lat2),
      );

  return LatLng(lat2 * 180 / math.pi, lon2 * 180 / math.pi);
}

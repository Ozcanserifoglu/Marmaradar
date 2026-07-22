import 'dart:math';

import 'package:radar_alert/core/geo/bearing.dart';
import 'package:radar_alert/features/amenities/amenity_models.dart';

/// Pure selection helpers for which amenities to draw on the map.
class AmenityVisibility {
  AmenityVisibility._();

  /// Returns up to [maxCount] places nearest the driver that lie ahead
  /// (heading cone) or inside an optional viewport bbox.
  static List<AmenityPlace> selectVisible({
    required List<AmenityPlace> places,
    required double driverLat,
    required double driverLon,
    required double headingDeg,
    double? south,
    double? west,
    double? north,
    double? east,
    int maxCount = AmenityConstants.maxVisibleMarkers,
    double aheadRadiusM = AmenityConstants.aheadRadiusM,
    int aheadToleranceDeg = AmenityConstants.aheadToleranceDeg,
  }) {
    if (places.isEmpty || maxCount <= 0) return const [];

    final ranked = <({AmenityPlace place, double dist})>[];
    for (final p in places) {
      final dist = haversineM(driverLat, driverLon, p.lat, p.lon);
      final inViewport = south != null &&
          west != null &&
          north != null &&
          east != null &&
          p.lat >= south &&
          p.lat <= north &&
          p.lon >= west &&
          p.lon <= east;

      final bearing = bearingDeg(driverLat, driverLon, p.lat, p.lon);
      final ahead = dist <= aheadRadiusM &&
          _withinCone(headingDeg, bearing, aheadToleranceDeg);

      if (!inViewport && !ahead) continue;
      ranked.add((place: p, dist: dist));
    }

    ranked.sort((a, b) => a.dist.compareTo(b.dist));
    return ranked.take(maxCount).map((e) => e.place).toList(growable: false);
  }

  static bool _withinCone(double centerDeg, double targetDeg, int toleranceDeg) {
    final diff = (targetDeg - centerDeg + 540) % 360 - 180;
    return diff.abs() <= toleranceDeg;
  }
}

/// Resolves the current cell plus look-ahead cells along [headingDeg].
List<AmenityCellRef> amenityCellsAlongHeading({
  required double lat,
  required double lon,
  required double headingDeg,
  int lookAhead = AmenityConstants.lookAheadCells,
}) {
  final current = AmenityCellRef.fromLatLon(lat, lon);
  final seen = <String>{current.key};
  final out = <AmenityCellRef>[current];

  // One cell step ≈ cellDeg × 111 km.
  const stepM = AmenityConstants.cellDeg * 111000;
  for (var i = 1; i <= lookAhead; i++) {
    final point = offsetByHeading(lat, lon, headingDeg, stepM * i);
    final cell = AmenityCellRef.fromLatLon(point.lat, point.lon);
    if (!seen.add(cell.key)) continue;
    out.add(cell);
  }
  return out;
}

/// Moves [distanceM] from [lat]/[lon] along [headingDeg] (0 = north).
({double lat, double lon}) offsetByHeading(
  double lat,
  double lon,
  double headingDeg,
  double distanceM,
) {
  final rad = headingDeg * pi / 180;
  final northM = distanceM * cos(rad);
  final eastM = distanceM * sin(rad);
  final lat2 = lat + northM / 111320;
  final cosLat = cos(lat * pi / 180).abs().clamp(0.2, 1.0);
  final lon2 = lon + eastM / (111320 * cosLat);
  return (lat: lat2, lon: lon2);
}

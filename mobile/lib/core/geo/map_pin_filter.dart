import 'dart:math';

import 'package:radar_alert/core/geo/bearing.dart';

typedef GeoPoint = ({double lat, double lng});

class MapPinFilter {
  MapPinFilter._();

  static const freeRoamRadiusM = 10000.0;
  static const routeBufferM = 1500.0;
  static const routeLocalProximityM = 2000.0;

  static const _metersPerDegLat = 111320.0;

  static List<T> filterMapPins<T>({
    required List<T> pins,
    required double Function(T pin) latOf,
    required double Function(T pin) lngOf,
    double? originLat,
    double? originLng,
    List<GeoPoint>? routePoints,
    double freeRoamRadiusM = MapPinFilter.freeRoamRadiusM,
    double routeBufferM = MapPinFilter.routeBufferM,
    double routeLocalProximityM = MapPinFilter.routeLocalProximityM,
  }) {
    if (pins.isEmpty) return const [];

    final route = (routePoints != null && routePoints.length >= 2)
        ? routePoints
        : null;
    if (route == null && (originLat == null || originLng == null)) {
      return const [];
    }

    final routeBbox = route == null
        ? null
        : _expandBbox(_bboxOf(route), routeBufferM);

    final out = <T>[];
    for (final pin in pins) {
      final lat = latOf(pin);
      final lng = lngOf(pin);

      if (originLat != null && originLng != null) {
        final toOrigin = haversineM(originLat, originLng, lat, lng);
        if (route == null) {
          if (toOrigin <= freeRoamRadiusM) out.add(pin);
          continue;
        }
        if (toOrigin <= routeLocalProximityM) {
          out.add(pin);
          continue;
        }
      }

      if (route != null) {
        if (routeBbox != null && !_inBbox(lat, lng, routeBbox)) continue;
        if (distanceToPolylineM(lat, lng, route) <= routeBufferM) {
          out.add(pin);
        }
      }
    }
    return out;
  }

  static double distanceToPolylineM(
    double lat,
    double lng,
    List<GeoPoint> points,
  ) {
    if (points.isEmpty) return double.infinity;
    if (points.length == 1) {
      return haversineM(lat, lng, points.first.lat, points.first.lng);
    }

    var minDist = double.infinity;
    for (var i = 0; i < points.length - 1; i++) {
      final d = _distanceToSegmentM(lat, lng, points[i], points[i + 1]);
      if (d < minDist) minDist = d;
    }
    return minDist;
  }
}

({double south, double west, double north, double east}) _bboxOf(
  List<GeoPoint> points,
) {
  var south = points.first.lat;
  var north = points.first.lat;
  var west = points.first.lng;
  var east = points.first.lng;
  for (final p in points) {
    if (p.lat < south) south = p.lat;
    if (p.lat > north) north = p.lat;
    if (p.lng < west) west = p.lng;
    if (p.lng > east) east = p.lng;
  }
  return (south: south, west: west, north: north, east: east);
}

({double south, double west, double north, double east}) _expandBbox(
  ({double south, double west, double north, double east}) bbox,
  double meters,
) {
  final midLat = (bbox.south + bbox.north) / 2;
  final dLat = meters / MapPinFilter._metersPerDegLat;
  final dLng = meters / _metersPerDegLng(midLat);
  return (
    south: bbox.south - dLat,
    west: bbox.west - dLng,
    north: bbox.north + dLat,
    east: bbox.east + dLng,
  );
}

bool _inBbox(
  double lat,
  double lng,
  ({double south, double west, double north, double east}) bbox,
) {
  return lat >= bbox.south &&
      lat <= bbox.north &&
      lng >= bbox.west &&
      lng <= bbox.east;
}

double _metersPerDegLng(double lat) {
  return MapPinFilter._metersPerDegLat * cos(lat * pi / 180);
}

double _distanceToSegmentM(
  double lat,
  double lng,
  GeoPoint a,
  GeoPoint b,
) {
  final meanLat = ((a.lat + b.lat + lat) / 3) * pi / 180;
  final cosLat = cos(meanLat);
  final mPerDegLng = MapPinFilter._metersPerDegLat * cosLat;

  final ax = a.lng * mPerDegLng;
  final ay = a.lat * MapPinFilter._metersPerDegLat;
  final bx = b.lng * mPerDegLng;
  final by = b.lat * MapPinFilter._metersPerDegLat;
  final px = lng * mPerDegLng;
  final py = lat * MapPinFilter._metersPerDegLat;

  final abx = bx - ax;
  final aby = by - ay;
  final apx = px - ax;
  final apy = py - ay;
  final abLen2 = abx * abx + aby * aby;
  if (abLen2 == 0) {
    return sqrt(apx * apx + apy * apy);
  }

  final t = ((apx * abx + apy * aby) / abLen2).clamp(0.0, 1.0);
  final dx = px - (ax + t * abx);
  final dy = py - (ay + t * aby);
  return sqrt(dx * dx + dy * dy);
}

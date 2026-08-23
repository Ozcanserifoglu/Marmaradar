import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;
import 'package:radar_alert/core/config/maps_api_key.dart';
import 'package:radar_alert/data/api/auth_models.dart';

class StaticMapBackdrop {
  StaticMapBackdrop._({
    required this.image,
    required this.centerLat,
    required this.centerLon,
    required this.zoom,
    required this.logicalSize,
  });

  final ui.Image image;
  final double centerLat;
  final double centerLon;
  final double zoom;
  final int logicalSize;

  int get size => image.width;

  static Future<StaticMapBackdrop?> fetch(List<SnappedPoint> route) async {
    if (route.length < 2) return null;
    await MapsApiKey.ensureLoaded();
    final key = MapsApiKey.value;
    if (key.isEmpty) return null;

    var minLat = route.first.lat, maxLat = route.first.lat;
    var minLon = route.first.lon, maxLon = route.first.lon;
    for (final p in route) {
      minLat = math.min(minLat, p.lat);
      maxLat = math.max(maxLat, p.lat);
      minLon = math.min(minLon, p.lon);
      maxLon = math.max(maxLon, p.lon);
    }
    final padLat = math.max((maxLat - minLat) * 0.28, 0.012);
    final padLon = math.max((maxLon - minLon) * 0.28, 0.012);
    minLat -= padLat;
    maxLat += padLat;
    minLon -= padLon;
    maxLon += padLon;

    final centerLat = (minLat + maxLat) / 2;
    final centerLon = (minLon + maxLon) / 2;
    const tileSize = 640;
    final zoom = _zoomForBounds(
      minLat,
      minLon,
      maxLat,
      maxLon,
      tileSize,
    );

    final styles = [
      'element:geometry|color:0x121216',
      'element:labels.text.fill|color:0xb9b9c0',
      'element:labels.text.stroke|color:0x121216',
      'feature:road|element:geometry.fill|color:0x3a3a44',
      'feature:road.highway|element:geometry.fill|color:0x5c5c6a',
      'feature:water|element:geometry|color:0x0a121c',
      'feature:poi|visibility:simplified',
      'feature:transit|visibility:off',
    ];
    final q = StringBuffer(
      'center=$centerLat,$centerLon&zoom=${zoom.round()}&size=${tileSize}x$tileSize'
      '&scale=2&maptype=roadmap&language=tr&key=${Uri.encodeQueryComponent(key)}',
    );
    for (final style in styles) {
      q.write('&style=${Uri.encodeQueryComponent(style)}');
    }
    final uri = Uri.parse('https://maps.googleapis.com/maps/api/staticmap?$q');
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200 || resp.bodyBytes.length < 200) return null;
      final codec = await ui.instantiateImageCodec(resp.bodyBytes);
      final frame = await codec.getNextFrame();
      return StaticMapBackdrop._(
        image: frame.image,
        centerLat: centerLat,
        centerLon: centerLon,
        zoom: zoom.roundToDouble(),
        logicalSize: tileSize,
      );
    } catch (_) {
      return null;
    }
  }

  ui.Offset project(double lat, double lon) {
    final worldScale = 256 * math.pow(2, zoom);
    final cx = _lonToX(centerLon, worldScale);
    final cy = _latToY(centerLat, worldScale);
    final x = _lonToX(lon, worldScale);
    final y = _latToY(lat, worldScale);
    final pxPerWorld = size / logicalSize;
    return ui.Offset(
      size / 2 + (x - cx) * pxPerWorld,
      size / 2 + (y - cy) * pxPerWorld,
    );
  }

  static double _lonToX(double lon, num scale) =>
      (lon + 180.0) / 360.0 * scale;

  static double _latToY(double lat, num scale) {
    final siny = math.sin(lat * math.pi / 180);
    final clamped = siny.clamp(-0.9999, 0.9999);
    return (0.5 - math.log((1 + clamped) / (1 - clamped)) / (4 * math.pi)) *
        scale;
  }

  static double _zoomForBounds(
    double minLat,
    double minLon,
    double maxLat,
    double maxLon,
    int sizePx,
  ) {
    for (var z = 14.0; z >= 6; z -= 1) {
      final scale = 256 * math.pow(2, z);
      final w = (_lonToX(maxLon, scale) - _lonToX(minLon, scale)).abs();
      final h = (_latToY(minLat, scale) - _latToY(maxLat, scale)).abs();
      if (w <= sizePx * 0.9 && h <= sizePx * 0.9) return z;
    }
    return 6;
  }
}

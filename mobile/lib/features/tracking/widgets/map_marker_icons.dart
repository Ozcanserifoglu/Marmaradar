import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:radar_alert/core/theme/app_theme.dart';

/// Builds and caches [BitmapDescriptor]s for map markers painted with Canvas.
class MapMarkerIcons {
  MapMarkerIcons._();

  static final Map<String, BitmapDescriptor> _cache = {};

  static Future<BitmapDescriptor> user() => _cached('user', () {
        return _paint(52, (canvas, size) {
          final center = Offset(size / 2, size / 2);
          final radius = size / 2 - 4;
          canvas.drawCircle(
            center,
            radius + 2,
            Paint()
              ..color = AppColors.red.withValues(alpha: 0.45)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
          );
          canvas.drawCircle(center, radius, Paint()..color = AppColors.red);
          canvas.drawCircle(
            center,
            radius,
            Paint()
              ..color = AppColors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
          // Arrow pointing up (north); Marker.rotation applies heading.
          final path = Path()
            ..moveTo(center.dx, center.dy - 11)
            ..lineTo(center.dx + 8, center.dy + 8)
            ..lineTo(center.dx, center.dy + 3)
            ..lineTo(center.dx - 8, center.dy + 8)
            ..close();
          canvas.drawPath(path, Paint()..color = AppColors.white);
        });
      });

  /// Top-down car used for drive replay. Points up (north); the marker's
  /// [Marker.rotation] applies the travel heading.
  static Future<BitmapDescriptor> car() => _cached('car', () {
        return _paint(46, (canvas, size) {
          final center = Offset(size / 2, size / 2);
          // Soft glow so the car stands out over the route line.
          canvas.drawCircle(
            center,
            size / 2 - 2,
            Paint()
              ..color = AppColors.red.withValues(alpha: 0.35)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
          );

          final body = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center,
              width: size * 0.42,
              height: size * 0.7,
            ),
            Radius.circular(size * 0.14),
          );
          canvas.drawRRect(body, Paint()..color = AppColors.red);
          canvas.drawRRect(
            body,
            Paint()
              ..color = AppColors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5,
          );

          // Windshield near the front (top) to convey direction.
          final windshield = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center.translate(0, -size * 0.16),
              width: size * 0.3,
              height: size * 0.16,
            ),
            Radius.circular(size * 0.05),
          );
          canvas.drawRRect(
            windshield,
            Paint()..color = AppColors.white.withValues(alpha: 0.9),
          );
        });
      });

  static Future<BitmapDescriptor> cameraDot() => _cached('dot', () {
        return _paint(16, (canvas, size) {
          canvas.drawCircle(
            Offset(size / 2, size / 2),
            size / 2 - 1,
            Paint()..color = AppColors.red.withValues(alpha: 0.85),
          );
        });
      });

  static Future<BitmapDescriptor> camera({
    required int? maxspeedKmh,
    required bool highlighted,
  }) {
    final key = 'cam_${maxspeedKmh ?? 'x'}_$highlighted';
    return _cached(key, () {
      return _paint(highlighted ? 50 : 40, (canvas, size) {
        final center = Offset(size / 2, size / 2);
        final radius = size / 2 - (highlighted ? 4 : 2);
        if (highlighted) {
          canvas.drawCircle(
            center,
            radius + 2,
            Paint()
              ..color = AppColors.red.withValues(alpha: 0.55)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
          );
        }
        final fill = maxspeedKmh != null ? AppColors.white : AppColors.night;
        canvas.drawCircle(center, radius, Paint()..color = fill);
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = AppColors.red
            ..style = PaintingStyle.stroke
            ..strokeWidth = maxspeedKmh != null ? 4 : 2.5,
        );
        if (maxspeedKmh != null) {
          final builder = ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textAlign: TextAlign.center,
              fontSize: size * 0.35,
              fontWeight: FontWeight.w900,
            ),
          )
            ..pushStyle(ui.TextStyle(color: Colors.black))
            ..addText('$maxspeedKmh');
          final paragraph = builder.build()
            ..layout(ui.ParagraphConstraints(width: size));
          canvas.drawParagraph(
            paragraph,
            Offset(0, (size - paragraph.height) / 2),
          );
        } else {
          // Simple camera glyph: rounded body + lens.
          final body = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center.translate(0, 1),
              width: size * 0.42,
              height: size * 0.28,
            ),
            const Radius.circular(3),
          );
          canvas.drawRRect(body, Paint()..color = AppColors.white);
          canvas.drawCircle(
            center.translate(0, 1),
            size * 0.1,
            Paint()..color = AppColors.night,
          );
        }
      });
    });
  }

  /// Compact fuel-pump marker for gas stations (below camera z-index).
  static Future<BitmapDescriptor> gasStation() => _cached('amenity_gas', () {
        return _paint(28, (canvas, size) {
          final center = Offset(size / 2, size / 2);
          final radius = size / 2 - 1;
          canvas.drawCircle(center, radius, Paint()..color = AppColors.route);
          canvas.drawCircle(
            center,
            radius,
            Paint()
              ..color = AppColors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
          // Pump body
          final body = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center.translate(-1, 1),
              width: size * 0.28,
              height: size * 0.42,
            ),
            const Radius.circular(2),
          );
          canvas.drawRRect(body, Paint()..color = AppColors.white);
          // Hose hook
          canvas.drawCircle(
            center.translate(size * 0.18, -size * 0.05),
            size * 0.07,
            Paint()..color = AppColors.white,
          );
        });
      });

  /// Compact rest-stop marker (bed / rest glyph).
  static Future<BitmapDescriptor> restStop() => _cached('amenity_rest', () {
        return _paint(28, (canvas, size) {
          final center = Offset(size / 2, size / 2);
          final radius = size / 2 - 1;
          canvas.drawCircle(center, radius, Paint()..color = AppColors.warning);
          canvas.drawCircle(
            center,
            radius,
            Paint()
              ..color = AppColors.night
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
          // Simple building roof triangle + base
          final roof = Path()
            ..moveTo(center.dx, center.dy - size * 0.22)
            ..lineTo(center.dx + size * 0.2, center.dy - size * 0.02)
            ..lineTo(center.dx - size * 0.2, center.dy - size * 0.02)
            ..close();
          canvas.drawPath(roof, Paint()..color = AppColors.night);
          canvas.drawRect(
            Rect.fromCenter(
              center: center.translate(0, size * 0.1),
              width: size * 0.32,
              height: size * 0.2,
            ),
            Paint()..color = AppColors.night,
          );
        });
      });

  static Future<BitmapDescriptor> gate({required bool isEntry}) {
    final key = isEntry ? 'gate_in' : 'gate_out';
    return _cached(key, () {
      return _paint(30, (canvas, size) {
        final center = Offset(size / 2, size / 2);
        final radius = size / 2 - 1;
        canvas.drawCircle(
          center,
          radius,
          Paint()..color = isEntry ? AppColors.white : AppColors.red,
        );
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = isEntry ? AppColors.red : AppColors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        final color = isEntry ? AppColors.red : AppColors.white;
        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round;
        if (isEntry) {
          // Arrow into circle (login).
          canvas.drawLine(
            Offset(center.dx - 5, center.dy),
            Offset(center.dx + 4, center.dy),
            paint,
          );
          canvas.drawLine(
            Offset(center.dx + 1, center.dy - 4),
            Offset(center.dx + 5, center.dy),
            paint,
          );
          canvas.drawLine(
            Offset(center.dx + 1, center.dy + 4),
            Offset(center.dx + 5, center.dy),
            paint,
          );
        } else {
          // Arrow out of circle (logout).
          canvas.drawLine(
            Offset(center.dx - 4, center.dy),
            Offset(center.dx + 5, center.dy),
            paint,
          );
          canvas.drawLine(
            Offset(center.dx + 1, center.dy - 4),
            Offset(center.dx + 5, center.dy),
            paint,
          );
          canvas.drawLine(
            Offset(center.dx + 1, center.dy + 4),
            Offset(center.dx + 5, center.dy),
            paint,
          );
        }
      });
    });
  }

  static Future<BitmapDescriptor> _cached(
    String key,
    Future<BitmapDescriptor> Function() build,
  ) async {
    final existing = _cache[key];
    if (existing != null) return existing;
    final icon = await build();
    _cache[key] = icon;
    return icon;
  }

  static Future<BitmapDescriptor> _paint(
    double logicalSize,
    void Function(Canvas canvas, double size) draw,
  ) async {
    const pixelRatio = 3.0;
    final size = logicalSize * pixelRatio;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(pixelRatio);
    draw(canvas, logicalSize);
    final image = await recorder.endRecording().toImage(
          size.ceil(),
          size.ceil(),
        );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: pixelRatio,
    );
  }
}

/// Dark basemap: roads stay lighter than land; POIs stay visible like light mode.
const googleMapsDarkStyleJson = '''
[
  {"elementType":"geometry","stylers":[{"color":"#121216"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#b9b9c0"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#121216"},{"weight":2}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#2e2e34"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#f7f7f8"}]},
  {"featureType":"landscape.man_made","elementType":"geometry","stylers":[{"color":"#161619"}]},
  {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#101814"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#1e1e24"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#d4d4dc"}]},
  {"featureType":"poi","elementType":"labels.text.stroke","stylers":[{"color":"#121216"},{"weight":2}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#142018"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#8cbc9a"}]},
  {"featureType":"poi.medical","elementType":"labels.text.fill","stylers":[{"color":"#f0a0a0"}]},
  {"featureType":"poi.business","elementType":"labels.text.fill","stylers":[{"color":"#e0c090"}]},
  {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#3a3a44"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#1c1c20"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#c8c8d0"}]},
  {"featureType":"road.arterial","elementType":"geometry.fill","stylers":[{"color":"#4a4a56"}]},
  {"featureType":"road.highway","elementType":"geometry.fill","stylers":[{"color":"#5c5c6a"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#1c1c20"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#e8e8ee"}]},
  {"featureType":"road.local","elementType":"geometry.fill","stylers":[{"color":"#32323a"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#1e2430"}]},
  {"featureType":"transit.station","elementType":"labels.text.fill","stylers":[{"color":"#a8b8d0"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0a121c"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#6a7380"}]}
]
''';

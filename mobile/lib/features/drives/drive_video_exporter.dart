import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_quick_video_encoder/flutter_quick_video_encoder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:radar_alert/core/geo/bearing.dart';
import 'package:radar_alert/core/theme/app_theme.dart';
import 'package:radar_alert/data/api/auth_models.dart';
import 'package:radar_alert/features/drives/drive_format.dart';

/// Renders a stylized replay of a recorded drive (route line + moving car on
/// the app's dark background) and encodes it to an MP4 file on-device.
///
/// Google Maps' native surface can't be captured frame-by-frame, so the video
/// uses a tile-less canvas rendering rather than the live map.
class DriveVideoExporter {
  DriveVideoExporter._();

  static const int size = 720;
  static const int fps = 30;
  static const double travelSeconds = 8.0;
  static const double tailSeconds = 1.4;

  static int get _travelFrames => (travelSeconds * fps).round();
  static int get _tailFrames => (tailSeconds * fps).round();
  static int get _totalFrames => _travelFrames + _tailFrames;

  /// Encodes the drive to an MP4 and returns the output file path.
  /// [onProgress] is called with a 0..1 fraction as frames are written.
  ///
  /// [displayPoints] is the road-snapped (or raw fallback) geometry for the
  /// route line and car path. [points] is required for validation / API parity
  /// with the live replay (raw telemetry retained on the server).
  static Future<String> export({
    required List<DrivePoint> points,
    required List<SnappedPoint> displayPoints,
    required String title,
    required double lengthM,
    required Duration duration,
    void Function(double progress)? onProgress,
  }) async {
    final route = displayPoints.length >= 2
        ? displayPoints
        : [
            for (final p in points) SnappedPoint(lat: p.lat, lon: p.lon),
          ];
    if (route.length < 2 || points.length < 2) {
      throw StateError('Not enough points to render a video.');
    }

    final projector = _RouteProjector(route, size.toDouble(), size * 0.14);
    final routeSampler = _RouteSampler(route);
    final projected = [
      for (final p in route) projector.project(p.lat, p.lon),
    ];

    final dir = await getTemporaryDirectory();
    final filepath =
        '${dir.path}/drive_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final subtitle = '${formatDistance(lengthM)}  -  ${formatDuration(duration)}';

    await FlutterQuickVideoEncoder.setup(
      width: size,
      height: size,
      fps: fps,
      videoBitrate: 5000000,
      profileLevel: ProfileLevel.any,
      audioChannels: 0,
      audioBitrate: 0,
      sampleRate: 0,
      filepath: filepath,
    );

    try {
      for (var frame = 0; frame < _totalFrames; frame++) {
        final travel = frame < _travelFrames
            ? frame / (_travelFrames - 1)
            : 1.0;
        final rgba = await _renderFrame(
          projected: projected,
          routeSampler: routeSampler,
          projector: projector,
          travelFraction: travel.clamp(0.0, 1.0),
          title: title,
          subtitle: subtitle,
        );
        await FlutterQuickVideoEncoder.appendVideoFrame(rgba);
        onProgress?.call((frame + 1) / _totalFrames);
      }
      await FlutterQuickVideoEncoder.finish();
    } catch (e) {
      await FlutterQuickVideoEncoder.finish();
      rethrow;
    }

    return filepath;
  }

  static Future<Uint8List> _renderFrame({
    required List<Offset> projected,
    required _RouteSampler routeSampler,
    required _RouteProjector projector,
    required double travelFraction,
    required String title,
    required String subtitle,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final s = size.toDouble();

    canvas.drawRect(
      Rect.fromLTWH(0, 0, s, s),
      Paint()..color = AppColors.night,
    );

    // Full route (faint).
    final fullPath = Path()..moveTo(projected.first.dx, projected.first.dy);
    for (final o in projected.skip(1)) {
      fullPath.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      fullPath,
      Paint()
        ..color = AppColors.whiteMuted.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    final head = routeSampler.at(travelFraction);
    final headOffset = projector.project(head.lat, head.lon);

    // Traveled portion (bright).
    final traveled = Path()..moveTo(projected.first.dx, projected.first.dy);
    for (var i = 1; i <= head.index; i++) {
      traveled.lineTo(projected[i].dx, projected[i].dy);
    }
    traveled.lineTo(headOffset.dx, headOffset.dy);
    canvas.drawPath(
      traveled,
      Paint()
        ..color = AppColors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Start marker.
    canvas.drawCircle(
      projected.first,
      9,
      Paint()..color = AppColors.success,
    );
    canvas.drawCircle(
      projected.first,
      9,
      Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    _drawCar(canvas, headOffset, head.headingDeg);

    _drawText(
      canvas,
      title,
      const Offset(24, 22),
      fontSize: 30,
      weight: FontWeight.w800,
      color: AppColors.white,
      maxWidth: s - 48,
    );
    _drawText(
      canvas,
      subtitle,
      const Offset(24, 62),
      fontSize: 20,
      weight: FontWeight.w600,
      color: AppColors.whiteMuted,
      maxWidth: s - 48,
    );
    _drawText(
      canvas,
      'Marmaradar',
      Offset(24, s - 40),
      fontSize: 18,
      weight: FontWeight.w700,
      color: AppColors.red,
      maxWidth: s - 48,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    picture.dispose();
    return byteData!.buffer.asUint8List();
  }

  static void _drawCar(Canvas canvas, Offset center, double headingDeg) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(headingDeg * math.pi / 180);

    canvas.drawCircle(
      Offset.zero,
      16,
      Paint()
        ..color = AppColors.red.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(Offset.zero, 12, Paint()..color = AppColors.red);
    canvas.drawCircle(
      Offset.zero,
      12,
      Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    // Arrow pointing up (toward travel direction after rotation).
    final arrow = Path()
      ..moveTo(0, -7)
      ..lineTo(5, 5)
      ..lineTo(0, 2)
      ..lineTo(-5, 5)
      ..close();
    canvas.drawPath(arrow, Paint()..color = AppColors.white);
    canvas.restore();
  }

  static void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double fontSize,
    required FontWeight weight,
    required Color color,
    required double maxWidth,
  }) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: fontSize,
        fontWeight: weight,
        maxLines: 1,
        ellipsis: '...',
      ),
    )
      ..pushStyle(ui.TextStyle(
        color: color,
        shadows: const [
          Shadow(color: Colors.black54, blurRadius: 4),
        ],
      ))
      ..addText(text);
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: maxWidth));
    canvas.drawParagraph(paragraph, offset);
  }
}

/// Projects lat/lon into square canvas pixel coordinates, preserving aspect.
class _RouteProjector {
  _RouteProjector(List<SnappedPoint> points, double size, double pad) {
    var minLat = points.first.lat, maxLat = points.first.lat;
    var minLon = points.first.lon, maxLon = points.first.lon;
    for (final p in points) {
      minLat = math.min(minLat, p.lat);
      maxLat = math.max(maxLat, p.lat);
      minLon = math.min(minLon, p.lon);
      maxLon = math.max(maxLon, p.lon);
    }
    _minLat = minLat;
    _minLon = minLon;
    _cosLat = math.cos(((minLat + maxLat) / 2) * math.pi / 180);

    final worldW = (maxLon - minLon) * _cosLat;
    final worldH = (maxLat - minLat);
    var span = math.max(worldW, worldH);
    if (span <= 0) span = 1e-6;

    final avail = size - 2 * pad;
    _scale = avail / span;
    _pad = pad;
    _offsetX = (avail - worldW * _scale) / 2;
    _offsetY = (avail - worldH * _scale) / 2;
    _worldH = worldH;
  }

  late final double _minLat;
  late final double _minLon;
  late final double _cosLat;
  late final double _scale;
  late final double _pad;
  late final double _offsetX;
  late final double _offsetY;
  late final double _worldH;

  Offset project(double lat, double lon) {
    final x = ((lon - _minLon) * _cosLat) * _scale;
    final y = (lat - _minLat) * _scale;
    return Offset(
      _pad + _offsetX + x,
      // Flip Y so north is up.
      _pad + _offsetY + (_worldH * _scale - y),
    );
  }
}

class _HeadSample {
  const _HeadSample(this.index, this.lat, this.lon, this.headingDeg);
  final int index;
  final double lat;
  final double lon;
  final double headingDeg;
}

/// Samples a position along [route] by cumulative geodesic distance fraction.
class _RouteSampler {
  _RouteSampler(this._route) {
    _cum.add(0);
    var total = 0.0;
    for (var i = 1; i < _route.length; i++) {
      final a = _route[i - 1];
      final b = _route[i];
      total += haversineM(a.lat, a.lon, b.lat, b.lon);
      _cum.add(total);
    }
    _total = total;
  }

  final List<SnappedPoint> _route;
  final List<double> _cum = [];
  double _total = 0;

  _HeadSample at(double fraction) {
    if (_route.length < 2) {
      final p = _route.first;
      return _HeadSample(0, p.lat, p.lon, 0);
    }
    if (_total <= 0) {
      final a = _route[0];
      final b = _route[1];
      return _HeadSample(0, a.lat, a.lon, bearingDeg(a.lat, a.lon, b.lat, b.lon));
    }
    final target = fraction.clamp(0.0, 1.0) * _total;
    for (var i = 0; i < _cum.length - 1; i++) {
      if (target <= _cum[i + 1]) {
        final span = _cum[i + 1] - _cum[i];
        final t = span <= 0 ? 0.0 : (target - _cum[i]) / span;
        final a = _route[i];
        final b = _route[i + 1];
        return _HeadSample(
          i,
          a.lat + (b.lat - a.lat) * t,
          a.lon + (b.lon - a.lon) * t,
          bearingDeg(a.lat, a.lon, b.lat, b.lon),
        );
      }
    }
    final n = _route.length;
    final a = _route[n - 2];
    final b = _route[n - 1];
    return _HeadSample(n - 2, b.lat, b.lon, bearingDeg(a.lat, a.lon, b.lat, b.lon));
  }
}

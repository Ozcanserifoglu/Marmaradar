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
import 'package:radar_alert/features/drives/static_map_backdrop.dart';
import 'package:radar_alert/features/profile/vehicle_models.dart';
import 'package:radar_alert/features/tracking/widgets/vehicle_icon_painter.dart';

class DriveVideoExporter {
  DriveVideoExporter._();

  static const int size = 1080;
  static const int fps = 30;
  static const double travelSeconds = 8.0;
  static const double tailSeconds = 1.4;
  static const double brandTopFraction = 0.82;
  static const double hudBottomY = 140;

  static int get _travelFrames => (travelSeconds * fps).round();
  static int get _tailFrames => (tailSeconds * fps).round();
  static int get _totalFrames => _travelFrames + _tailFrames;

  static Future<String> export({
    required List<DrivePoint> points,
    required List<SnappedPoint> displayPoints,
    required String title,
    required double lengthM,
    required Duration duration,
    double? avgSpeedKmh,
    double? minSpeedKmh,
    double? maxSpeedKmh,
    VehicleType vehicleType = VehicleType.sedan,
    Color vehicleColor = kDefaultVehicleColor,
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

    final map = await StaticMapBackdrop.fetch(route);
    final projector = map == null
        ? _RouteProjector(route, size.toDouble(), size * 0.14)
        : _MapProjector(map, size.toDouble());
    final routeSampler = _RouteSampler(route);
    final projected = [
      for (final p in route) projector.project(p.lat, p.lon),
    ];

    final dir = await getTemporaryDirectory();
    final filepath =
        '${dir.path}/drive_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final statsLine =
        '${formatDistance(lengthM)}  ·  ${formatDuration(duration)}'
        '${avgSpeedKmh != null ? '  ·  Ort ${avgSpeedKmh.round()} km/s' : ''}';
    final minMaxLine = (minSpeedKmh != null || maxSpeedKmh != null)
        ? 'Min ${formatSpeedKmh(minSpeedKmh)}   Max ${formatSpeedKmh(maxSpeedKmh)}'
        : null;

    await FlutterQuickVideoEncoder.setup(
      width: size,
      height: size,
      fps: fps,
      videoBitrate: 8000000,
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
          mapImage: map?.image,
          travelFraction: travel.clamp(0.0, 1.0),
          title: title,
          subtitle: statsLine,
          extraLine: minMaxLine,
          vehicleType: vehicleType,
          vehicleColor: vehicleColor,
        );
        await FlutterQuickVideoEncoder.appendVideoFrame(rgba);
        onProgress?.call((frame + 1) / _totalFrames);
      }
      await FlutterQuickVideoEncoder.finish();
    } catch (e) {
      await FlutterQuickVideoEncoder.finish();
      rethrow;
    }

    map?.image.dispose();
    return filepath;
  }

  static Future<Uint8List> _renderFrame({
    required List<Offset> projected,
    required _RouteSampler routeSampler,
    required _GeoProjector projector,
    ui.Image? mapImage,
    required double travelFraction,
    required String title,
    required String subtitle,
    String? extraLine,
    required VehicleType vehicleType,
    required Color vehicleColor,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final s = size.toDouble();

    canvas.drawRect(
      Rect.fromLTWH(0, 0, s, s),
      Paint()..color = AppColors.night,
    );
    if (mapImage != null) {
      paintImage(
        canvas: canvas,
        rect: Rect.fromLTWH(0, 0, s, s),
        image: mapImage,
        fit: BoxFit.cover,
      );
    }

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

    _drawCar(
      canvas,
      headOffset,
      head.headingDeg,
      type: vehicleType,
      color: vehicleColor,
    );
    _drawHud(canvas, s, title, subtitle, extraLine);
    _drawBrandMark(canvas, s);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    picture.dispose();
    return byteData!.buffer.asUint8List();
  }

  static void _drawCar(
    Canvas canvas,
    Offset center,
    double headingDeg, {
    required VehicleType type,
    required Color color,
  }) {
    const glyphSize = 44.0;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(headingDeg * math.pi / 180);
    canvas.translate(-glyphSize / 2, -glyphSize / 2);
    paintVehicle(
      canvas,
      const Size(glyphSize, glyphSize),
      type: type,
      color: color,
    );
    canvas.restore();
  }

  static void _drawHud(
    Canvas canvas,
    double canvasSize,
    String title,
    String subtitle,
    String? extraLine,
  ) {
    const inset = 16.0;
    const padH = 18.0;
    const padV = 14.0;
    const gap = 6.0;
    final maxTextWidth = canvasSize - inset * 2 - padH * 2;

    final titleP = _layoutText(
      title,
      fontSize: 28,
      weight: FontWeight.w800,
      color: AppColors.white,
      maxWidth: maxTextWidth,
    );
    final subtitleP = _layoutText(
      subtitle,
      fontSize: 18,
      weight: FontWeight.w600,
      color: AppColors.white,
      maxWidth: maxTextWidth,
    );
    final extraP = extraLine == null
        ? null
        : _layoutText(
            extraLine,
            fontSize: 16,
            weight: FontWeight.w600,
            color: const Color(0xFFE8E8EE),
            maxWidth: maxTextWidth,
          );

    var textW = math.max(titleP.maxIntrinsicWidth, subtitleP.maxIntrinsicWidth);
    var textH = titleP.height + gap + subtitleP.height;
    if (extraP != null) {
      textW = math.max(textW, extraP.maxIntrinsicWidth);
      textH += gap + extraP.height;
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          inset,
          inset,
          textW + padH * 2,
          textH + padV * 2,
        ),
        const Radius.circular(14),
      ),
      Paint()..color = const Color(0xF20B0B0D),
    );

    var y = inset + padV;
    final x = inset + padH;
    canvas.drawParagraph(titleP, Offset(x, y));
    y += titleP.height + gap;
    canvas.drawParagraph(subtitleP, Offset(x, y));
    if (extraP != null) {
      y += subtitleP.height + gap;
      canvas.drawParagraph(extraP, Offset(x, y));
    }
  }

  static void _drawBrandMark(Canvas canvas, double canvasSize) {
    const wordmark = 'MARMARADAR';
    const fontSize = 30.0;
    const letterSpacing = 2.0;
    const padH = 14.0;
    const padV = 8.0;
    const rightInset = 48.0;
    final top = canvasSize * brandTopFraction;

    ui.Paragraph paragraph({
      required Color color,
      List<ui.Shadow> shadows = const [],
    }) {
      final builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: TextAlign.left,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          maxLines: 1,
        ),
      )
        ..pushStyle(
          ui.TextStyle(
            color: color,
            letterSpacing: letterSpacing,
            shadows: shadows,
          ),
        )
        ..addText(wordmark);
      return builder.build()
        ..layout(ui.ParagraphConstraints(width: canvasSize));
    }

    final fill = paragraph(
      color: AppColors.red.withValues(alpha: 0.92),
    );
    final stroke = paragraph(
      color: AppColors.night,
      shadows: const [
        ui.Shadow(color: AppColors.night, blurRadius: 6),
      ],
    );
    final width = fill.maxIntrinsicWidth;
    final height = fill.height;
    final left = canvasSize - rightInset - width;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          left - padH,
          top - padV,
          width + padH * 2,
          height + padV * 2,
        ),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0x990B0B0D),
    );
    canvas.drawParagraph(stroke, Offset(left, top));
    canvas.drawParagraph(fill, Offset(left, top));
  }

  static ui.Paragraph _layoutText(
    String text, {
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
      ..pushStyle(ui.TextStyle(color: color))
      ..addText(text);
    return builder.build()..layout(ui.ParagraphConstraints(width: maxWidth));
  }
}

abstract class _GeoProjector {
  Offset project(double lat, double lon);
}

class _MapProjector implements _GeoProjector {
  _MapProjector(this._map, this._canvasSize);

  final StaticMapBackdrop _map;
  final double _canvasSize;

  @override
  Offset project(double lat, double lon) {
    final p = _map.project(lat, lon);
    final scale = _canvasSize / _map.size;
    return Offset(p.dx * scale, p.dy * scale);
  }
}

class _RouteProjector implements _GeoProjector {
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

  @override
  Offset project(double lat, double lon) {
    final x = ((lon - _minLon) * _cosLat) * _scale;
    final y = (lat - _minLat) * _scale;
    return Offset(
      _pad + _offsetX + x,
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

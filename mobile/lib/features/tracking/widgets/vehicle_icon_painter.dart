import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:radar_alert/core/theme/app_theme.dart';
import 'package:radar_alert/features/profile/vehicle_models.dart';

/// Shared top-down vehicle glyph used by map markers and video export.
void paintVehicle(
  Canvas canvas,
  Size size, {
  required VehicleType type,
  required Color color,
}) {
  final center = Offset(size.width / 2, size.height / 2);
  final minSide = math.min(size.width, size.height);

  canvas.drawCircle(
    center,
    minSide * 0.42,
    Paint()
      ..color = color.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
  );

  switch (type) {
    case VehicleType.sedan:
      _paintSedanLike(canvas, center, minSide, color, bodyH: 0.70, bodyW: 0.42);
    case VehicleType.hatchback:
      _paintSedanLike(canvas, center, minSide, color, bodyH: 0.62, bodyW: 0.44);
    case VehicleType.stationWagon:
      _paintSedanLike(canvas, center, minSide, color, bodyH: 0.78, bodyW: 0.42);
    case VehicleType.kamyon:
      _paintTruck(canvas, center, minSide, color, trailerH: 0.42);
    case VehicleType.tir:
      _paintTruck(canvas, center, minSide, color, trailerH: 0.55);
  }
}

void _paintSedanLike(
  Canvas canvas,
  Offset center,
  double minSide,
  Color color, {
  required double bodyH,
  required double bodyW,
}) {
  final body = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: center,
      width: minSide * bodyW,
      height: minSide * bodyH,
    ),
    Radius.circular(minSide * 0.14),
  );
  canvas.drawRRect(body, Paint()..color = color);
  canvas.drawRRect(
    body,
    Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, minSide * 0.05),
  );

  final windshield = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: center.translate(0, -minSide * bodyH * 0.22),
      width: minSide * bodyW * 0.72,
      height: minSide * 0.14,
    ),
    Radius.circular(minSide * 0.04),
  );
  canvas.drawRRect(
    windshield,
    Paint()..color = AppColors.white.withValues(alpha: 0.9),
  );

  final rear = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: center.translate(0, minSide * bodyH * 0.28),
      width: minSide * bodyW * 0.62,
      height: minSide * 0.08,
    ),
    Radius.circular(minSide * 0.03),
  );
  canvas.drawRRect(
    rear,
    Paint()..color = AppColors.white.withValues(alpha: 0.45),
  );
}

void _paintTruck(
  Canvas canvas,
  Offset center,
  double minSide,
  Color color, {
  required double trailerH,
}) {
  final cab = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: center.translate(0, -minSide * 0.22),
      width: minSide * 0.40,
      height: minSide * 0.28,
    ),
    Radius.circular(minSide * 0.08),
  );
  final trailer = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: center.translate(0, minSide * (trailerH * 0.18)),
      width: minSide * 0.46,
      height: minSide * trailerH,
    ),
    Radius.circular(minSide * 0.06),
  );

  canvas.drawRRect(trailer, Paint()..color = color);
  canvas.drawRRect(
    trailer,
    Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, minSide * 0.045),
  );
  canvas.drawRRect(cab, Paint()..color = color);
  canvas.drawRRect(
    cab,
    Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, minSide * 0.045),
  );

  final windshield = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: center.translate(0, -minSide * 0.28),
      width: minSide * 0.28,
      height: minSide * 0.10,
    ),
    Radius.circular(minSide * 0.03),
  );
  canvas.drawRRect(
    windshield,
    Paint()..color = AppColors.white.withValues(alpha: 0.9),
  );
}

class VehicleIconPainter extends CustomPainter {
  VehicleIconPainter({required this.type, required this.color});

  final VehicleType type;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    paintVehicle(canvas, size, type: type, color: color);
  }

  @override
  bool shouldRepaint(covariant VehicleIconPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.color != color;
  }
}

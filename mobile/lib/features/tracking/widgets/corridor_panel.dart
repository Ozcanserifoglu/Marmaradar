import 'package:flutter/material.dart';
import 'package:radar_alert/core/theme/app_theme.dart';
import 'package:radar_alert/features/tracking/tracking_controller.dart';

/// Shown while inside an average-speed corridor: running average vs limit.
class CorridorPanel extends StatelessWidget {
  const CorridorPanel({super.key, required this.status});

  final CorridorStatus status;

  @override
  Widget build(BuildContext context) {
    final ratio = status.limitRatio.clamp(0.0, 1.3);
    final over = status.avgKmh >= status.corridor.maxspeedKmh;
    final near = !over && ratio >= 0.9;
    final barColor = over
        ? AppColors.red
        : near
            ? AppColors.warning
            : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: over ? AppColors.red : AppColors.outline,
          width: over ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route, color: AppColors.red, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status.corridor.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AppColors.whiteMuted,
                  ),
                ),
              ),
              Text(
                'LİMİT ${status.corridor.maxspeedKmh}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${status.avgKmh.round()}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  color: over ? AppColors.red : AppColors.white,
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Text(
                  'km/s ortalama',
                  style: TextStyle(fontSize: 12, color: AppColors.whiteMuted),
                ),
              ),
              const Spacer(),
              Text(
                '${(status.distanceM / 1000).toStringAsFixed(1)} km gidildi',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.whiteMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (ratio / 1.3).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.outline,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

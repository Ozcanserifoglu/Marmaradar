import 'package:flutter/material.dart';
import 'package:radar_alert/core/theme/app_theme.dart';

class RouteInfoBanner extends StatelessWidget {
  const RouteInfoBanner({
    super.key,
    required this.destinationName,
    required this.distanceKm,
    required this.durationMin,
    required this.onClear,
  });

  final String destinationName;
  final double distanceKm;
  final int durationMin;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final distanceLabel = distanceKm >= 10
        ? distanceKm.toStringAsFixed(0)
        : distanceKm.toStringAsFixed(1);

    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 6,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.route.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_car,
                color: AppColors.route,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destinationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$distanceLabel km · ~$durationMin dk',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Rotayı temizle',
              onPressed: onClear,
              icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

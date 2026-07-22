import 'package:flutter/material.dart';
import 'package:radar_alert/core/theme/app_theme.dart';
import 'package:radar_alert/features/amenities/amenity_models.dart';

void showAmenityDetailSheet(BuildContext context, AmenityPlace place) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => AmenityDetailSheet(place: place),
  );
}

class AmenityDetailSheet extends StatelessWidget {
  const AmenityDetailSheet({super.key, required this.place});

  final AmenityPlace place;

  @override
  Widget build(BuildContext context) {
    final isGas = place.category == AmenityCategory.gasStation;
    final categoryLabel = isGas ? 'Benzin İstasyonu' : 'Dinlenme Tesisi';
    final icon = isGas ? Icons.local_gas_station : Icons.hotel;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (isGas ? AppColors.route : AppColors.warning)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: isGas ? AppColors.route : AppColors.warning,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        categoryLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.whiteMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (place.openNow != null || place.rating != null) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (place.openNow != null)
                    _Chip(
                      label: place.openNow! ? 'Açık' : 'Kapalı',
                      color: place.openNow! ? AppColors.success : AppColors.red,
                    ),
                  if (place.rating != null)
                    _Chip(
                      label: '${place.rating!.toStringAsFixed(1)} ★',
                      color: AppColors.warning,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

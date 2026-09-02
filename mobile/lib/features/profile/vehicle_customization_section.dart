import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:radar_alert/app.dart';
import 'package:radar_alert/core/theme/app_theme.dart';
import 'package:radar_alert/features/profile/vehicle_models.dart';
import 'package:radar_alert/features/tracking/widgets/vehicle_icon_painter.dart';

class VehicleCustomizationSection extends ConsumerWidget {
  const VehicleCustomizationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(vehicleCustomizationControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Araç Özelleştirme',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: VehicleType.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final type = VehicleType.values[index];
              final selected = type == vehicle.vehicleType;
              return GestureDetector(
                onTap: () => ref
                    .read(vehicleCustomizationControllerProvider)
                    .setVehicleType(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 96,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? AppColors.red : scheme.outline,
                      width: selected ? 2 : 1,
                    ),
                    boxShadow: scheme.brightness == Brightness.light
                        ? [
                            BoxShadow(
                              color: scheme.outline.withValues(alpha: 0.45),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CustomPaint(
                            painter: VehicleIconPainter(
                              type: type,
                              color: vehicle.vehicleColor,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        type.labelTr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Renk',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final swatch in kVehicleColorSwatches)
              GestureDetector(
                onTap: () => ref
                    .read(vehicleCustomizationControllerProvider)
                    .setVehicleColor(swatch),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: swatch,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: vehicle.vehicleColor == swatch
                          ? AppColors.red
                          : scheme.outline,
                      width: vehicle.vehicleColor == swatch ? 3 : 1,
                    ),
                    boxShadow: swatch == const Color(0xFFFFFFFF)
                        ? [
                            BoxShadow(
                              color: scheme.outline.withValues(alpha: 0.35),
                              blurRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: vehicle.saving
                ? null
                : () async {
                    final ok = await ref
                        .read(vehicleCustomizationControllerProvider)
                        .saveToServer();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'Araç tercihleri kaydedildi.'
                              : (ref
                                      .read(
                                        vehicleCustomizationControllerProvider,
                                      )
                                      .error ??
                                  'Kaydedilemedi.'),
                        ),
                      ),
                    );
                  },
            child: vehicle.saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Kaydet'),
          ),
        ),
      ],
    );
  }
}

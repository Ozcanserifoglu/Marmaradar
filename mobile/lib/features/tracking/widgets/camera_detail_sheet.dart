import 'package:flutter/material.dart';
import 'package:radar_alert/core/theme/app_theme.dart';
import 'package:radar_alert/data/local/app_database.dart';

({String title, String description, IconData icon}) cameraTypeInfo(
  CachedCamera camera,
) {
  switch (camera.cameraType) {
    case 'mobile':
      return (
        title: 'Mobil Radar',
        description: 'Taşınabilir hız denetim noktası. Konumu değişebilir.',
        icon: Icons.local_police,
      );
    case 'red_light':
      return (
        title: 'Kırmızı Işık Kamerası',
        description: 'Kırmızı ışık ihlalini denetler.',
        icon: Icons.traffic,
      );
    case 'fixed':
      return camera.maxspeedKmh != null
          ? (
              title: 'Sabit Hız Kamerası',
              description: 'Anlık hızınızı ölçer.',
              icon: Icons.speed,
            )
          : (
              title: 'Denetim Kamerası',
              description:
                  'Trafik denetim noktası. Hız limiti bilgisi bulunmuyor.',
              icon: Icons.videocam,
            );
    default:
      return (
        title: 'Denetim Kamerası',
        description: 'Trafik denetim noktası.',
        icon: Icons.videocam,
      );
  }
}

void showCameraDetailSheet(BuildContext context, CachedCamera camera) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => CameraDetailSheet(camera: camera),
  );
}

class CameraDetailSheet extends StatelessWidget {
  const CameraDetailSheet({super.key, required this.camera});

  final CachedCamera camera;

  @override
  Widget build(BuildContext context) {
    final info = cameraTypeInfo(camera);
    final limit = camera.maxspeedKmh;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.red.withValues(alpha: 0.15),
                    border: Border.all(color: AppColors.red, width: 2),
                  ),
                  child: Icon(info.icon, color: AppColors.red, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                      if (camera.roadName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          camera.roadName!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.whiteMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (limit != null) _SpeedLimitSign(limit: limit),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              info.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.whiteMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeedLimitSign extends StatelessWidget {
  const _SpeedLimitSign({required this.limit});

  final int limit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white,
        border: Border.all(color: AppColors.red, width: 5),
      ),
      child: Text(
        '$limit',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

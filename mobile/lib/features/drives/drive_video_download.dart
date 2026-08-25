import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:radar_alert/core/theme/app_theme.dart';
import 'package:radar_alert/data/api/auth_models.dart';
import 'package:radar_alert/features/drives/drive_format.dart';
import 'package:radar_alert/features/drives/drive_speed_stats.dart';
import 'package:radar_alert/features/drives/drive_video_exporter.dart';
import 'package:share_plus/share_plus.dart';

enum DriveVideoIntent { saveToGallery, share }

Future<void> exportDriveVideo(
  BuildContext context, {
  required DriveDetail detail,
  required DriveVideoIntent intent,
  String? nameOverride,
  Rect? sharePositionOrigin,
}) async {
  final progress = ValueNotifier<double>(0);
  final preparingLabel = intent == DriveVideoIntent.share
      ? 'Paylaşım için video hazırlanıyor...'
      : 'Video hazırlanıyor...';
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ExportProgressDialog(
      progress: progress,
      label: preparingLabel,
    ),
  );

  String? path;
  Object? error;
  final stats = DriveSpeedStats.fromPoints(
    [for (final p in detail.points) (speedMps: p.speedMps)],
    lengthM: detail.summary.lengthM,
    duration: detail.summary.duration,
  );
  try {
    path = await DriveVideoExporter.export(
      points: detail.points,
      displayPoints: detail.displayPoints,
      title: driveDisplayName(
        nameOverride ?? detail.summary.name,
        detail.summary.startedAt,
      ),
      lengthM: detail.summary.lengthM,
      duration: detail.summary.duration,
      avgSpeedKmh: detail.summary.avgSpeedKmh ?? stats.avgKmh,
      minSpeedKmh: detail.summary.minSpeedKmh ?? stats.minKmh,
      maxSpeedKmh: detail.summary.maxSpeedKmh ?? stats.maxKmh,
      onProgress: (p) => progress.value = p,
    );
  } catch (e) {
    error = e;
  }

  if (!context.mounted) {
    progress.dispose();
    return;
  }
  Navigator.of(context, rootNavigator: true).pop();
  progress.dispose();

  if (error != null || path == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video oluşturulamadı.')),
    );
    return;
  }

  switch (intent) {
    case DriveVideoIntent.saveToGallery:
      try {
        await Gal.requestAccess();
        await Gal.putVideo(path);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Galeriye kaydedildi')),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Galeriye kaydedilemedi.')),
          );
        }
      }
      return;
    case DriveVideoIntent.share:
      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path)],
            text: 'Marmaradar sürüş kaydı',
            sharePositionOrigin: sharePositionOrigin,
          ),
        );
      } catch (_) {}
  }
}

class _ExportProgressDialog extends StatelessWidget {
  const _ExportProgressDialog({
    required this.progress,
    required this.label,
  });

  final ValueNotifier<double> progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: AppColors.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder<double>(
              valueListenable: progress,
              builder: (context, value, _) => Column(
                children: [
                  LinearProgressIndicator(
                    value: value == 0 ? null : value,
                    color: AppColors.red,
                    backgroundColor: AppColors.outline,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${(value * 100).round()}%',
                    style: const TextStyle(color: AppColors.whiteMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

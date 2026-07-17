import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:radar_alert/app.dart';
import 'package:radar_alert/core/theme/app_theme.dart';
import 'package:radar_alert/features/tracking/tracking_controller.dart';

/// Bottom control dock: live speed, status and the main actions.
class DrivePanel extends ConsumerWidget {
  const DrivePanel({super.key, required this.controller});

  final TrackingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final running = controller.isRunning;
    final hasFix = controller.lastSnapshot != null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.night.withValues(alpha: 0.94),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: const Border(
          top: BorderSide(color: AppColors.outline),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _SpeedReadout(
                speedKmh: controller.speedKmh,
                hasFix: hasFix,
                active: running,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          running
                              ? 'TAKİP AKTİF'
                              : controller.autoDriveEnabled
                                  ? 'SÜRÜŞ BEKLENİYOR'
                                  : 'TAKİP KAPALI',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: running
                                ? AppColors.success
                                : AppColors.whiteMuted,
                          ),
                        ),
                        const Spacer(),
                        _AutoDriveToggle(controller: controller),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.status,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 16),
          Row(
            children: [
              _SyncButton(controller: controller),
              const SizedBox(width: 12),
              _LogoutButton(
                onLogout: () => ref.read(authControllerProvider).logout(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: running ? controller.stop : controller.start,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        running ? AppColors.surfaceHigh : AppColors.red,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size.fromHeight(56),
                  ),
                  icon: Icon(running ? Icons.stop_rounded : Icons.radar),
                  label: Text(running ? 'Sürüşü Bitir' : 'Sürüşe Başla'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AutoDriveToggle extends StatelessWidget {
  const _AutoDriveToggle({required this.controller});

  final TrackingController controller;

  @override
  Widget build(BuildContext context) {
    final on = controller.autoDriveEnabled;
    return InkWell(
      onTap: controller.toggleAutoDrive,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: on
              ? AppColors.red.withValues(alpha: 0.18)
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: on ? AppColors.red : AppColors.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_mode,
              size: 14,
              color: on ? AppColors.red : AppColors.whiteMuted,
            ),
            const SizedBox(width: 5),
            Text(
              'Otomatik',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: on ? AppColors.white : AppColors.whiteMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeedReadout extends StatelessWidget {
  const _SpeedReadout({
    required this.speedKmh,
    required this.hasFix,
    required this.active,
  });

  final double speedKmh;
  final bool hasFix;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(
          color: active ? AppColors.red : AppColors.outline,
          width: 3,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.red.withValues(alpha: 0.35),
                  blurRadius: 18,
                ),
              ]
            : const [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hasFix ? '${speedKmh.round()}' : '--',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'km/s',
            style: TextStyle(fontSize: 11, color: AppColors.whiteMuted),
          ),
        ],
      ),
    );
  }
}

class _SyncButton extends StatelessWidget {
  const _SyncButton({required this.controller});

  final TrackingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: OutlinedButton(
        onPressed: controller.isSyncing ? null : controller.syncData,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: controller.isSyncing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : const Icon(Icons.cloud_sync, size: 24),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: OutlinedButton(
        onPressed: onLogout,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Icon(Icons.logout, size: 22),
      ),
    );
  }
}

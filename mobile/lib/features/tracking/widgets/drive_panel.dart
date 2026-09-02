import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:radar_alert/app.dart';
import 'package:radar_alert/core/theme/app_theme.dart';
import 'package:radar_alert/features/auth/auth_screen.dart';
import 'package:radar_alert/features/drives/drive_format.dart';
import 'package:radar_alert/features/drives/drives_history_screen.dart';
import 'package:radar_alert/features/leaderboard/leaderboard_screen.dart';
import 'package:radar_alert/features/profile/profile_screen.dart';
import 'package:radar_alert/features/tracking/tracking_controller.dart';

class DrivePanel extends ConsumerWidget {
  const DrivePanel({super.key, required this.controller});

  final TrackingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final running = controller.isRunning;
    final hasFix = controller.lastSnapshot != null;
    final authenticated = ref.watch(authControllerProvider).isAuthenticated;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: scheme.outline),
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
                        Expanded(
                          child: Text(
                            running
                                ? 'TAKİP AKTİF'
                                : controller.autoDriveEnabled
                                    ? 'SÜRÜŞ BEKLENİYOR'
                                    : 'TAKİP KAPALI',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                                  color: running
                                      ? AppColors.success
                                      : scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (running) ...[
                          _AmenitiesToggle(controller: controller),
                          const SizedBox(width: 6),
                        ],
                        _AutoDriveToggle(controller: controller),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.status,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (running)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  _TripStat(
                    label: 'Mesafe',
                    value: formatDistance(controller.tripDistanceM),
                  ),
                  _TripStat(
                    label: 'Ort',
                    value: formatSpeedKmh(controller.tripAvgKmh),
                  ),
                  _TripStat(
                    label: 'Min',
                    value: formatSpeedKmh(controller.tripMinKmh),
                  ),
                  _TripStat(
                    label: 'Max',
                    value: formatSpeedKmh(controller.tripMaxKmh),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(child: _SyncButton(controller: controller)),
              const SizedBox(width: 10),
              const Expanded(child: _LeaderboardButton()),
              const SizedBox(width: 10),
              const Expanded(child: _HistoryButton()),
              const SizedBox(width: 10),
              Expanded(
                child: _AccountButton(
                  authenticated: authenticated,
                  onPressed: () async {
                    if (!authenticated) {
                      final ok = await showAuthModal(context);
                      if (ok && context.mounted) {
                        await ref
                            .read(trackingControllerProvider)
                            .uploadPendingDrive();
                      }
                      return;
                    }
                    if (!context.mounted) return;
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: running ? controller.stop : controller.start,
              style: FilledButton.styleFrom(
                backgroundColor:
                    running ? AppColors.surfaceHigh : AppColors.red,
                foregroundColor: scheme.onSurface,
                minimumSize: const Size.fromHeight(56),
              ),
              icon: Icon(running ? Icons.stop_rounded : Icons.radar),
              label: Text(running ? 'Sürüşü Bitir' : 'Sürüşe Başla'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryButton extends ConsumerWidget {
  const _HistoryButton();

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DrivesHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _open(context, ref),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Icon(Icons.history, size: 24),
      ),
    );
  }
}

class _LeaderboardButton extends ConsumerWidget {
  const _LeaderboardButton();

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final authenticated = ref.read(authControllerProvider).isAuthenticated;
    if (!authenticated) {
      final ok = await showAuthModal(context);
      if (!ok || !context.mounted) return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _open(context, ref),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Icon(Icons.emoji_events_outlined, size: 24),
      ),
    );
  }
}

class _AmenitiesToggle extends StatelessWidget {
  const _AmenitiesToggle({required this.controller});

  final TrackingController controller;

  @override
  Widget build(BuildContext context) {
    final on = controller.amenitiesVisible;
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: on ? 'Durakları gizle' : 'Durakları göster',
      child: InkWell(
        onTap: () => controller.setAmenitiesVisible(!on),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on
                ? AppColors.route.withValues(alpha: 0.2)
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: on ? AppColors.route : scheme.outline,
            ),
          ),
          child: Icon(
            Icons.local_gas_station,
            size: 16,
            color: on ? AppColors.route : scheme.onSurfaceVariant,
          ),
        ),
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
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: controller.toggleAutoDrive,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: on
              ? AppColors.red.withValues(alpha: 0.18)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: on ? AppColors.red : scheme.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_mode,
              size: 14,
              color: on ? AppColors.red : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              'Otomatik',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: on ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripStat extends StatelessWidget {
  const _TripStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 92,
      height: 92,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surface,
        border: Border.all(
          color: active ? AppColors.red : scheme.outline,
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
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'km/s',
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
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
      height: 56,
      width: double.infinity,
      child: GestureDetector(
        onLongPress: kDebugMode && !controller.isSyncing
            ? () => controller.simulateShortDrive()
            : null,
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
      ),
    );
  }
}

class _AccountButton extends StatelessWidget {
  const _AccountButton({
    required this.authenticated,
    required this.onPressed,
  });

  final bool authenticated;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Icon(
          authenticated ? Icons.person : Icons.login,
          size: 22,
        ),
      ),
    );
  }
}

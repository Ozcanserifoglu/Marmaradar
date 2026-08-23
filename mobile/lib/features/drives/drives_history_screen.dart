import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:radar_alert/app.dart';
import 'package:radar_alert/core/theme/app_theme.dart';
import 'package:radar_alert/data/api/auth_models.dart';
import 'package:radar_alert/features/auth/auth_screen.dart';
import 'package:radar_alert/features/drives/drive_detail_screen.dart';
import 'package:radar_alert/features/drives/drive_format.dart';
import 'package:radar_alert/features/drives/drives_controller.dart';
import 'package:radar_alert/features/drives/drive_video_download.dart';
import 'package:radar_alert/features/drives/rename_drive_dialog.dart';

class DrivesHistoryScreen extends ConsumerStatefulWidget {
  const DrivesHistoryScreen({super.key});

  @override
  ConsumerState<DrivesHistoryScreen> createState() =>
      _DrivesHistoryScreenState();
}

class _DrivesHistoryScreenState extends ConsumerState<DrivesHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authenticated = ref.read(authControllerProvider).isAuthenticated;
      ref.read(drivesControllerProvider).load(authenticated: authenticated);
    });
  }

  Future<void> _login() async {
    final ok = await showAuthModal(context);
    if (ok && mounted) {
      await ref.read(drivesControllerProvider).load(authenticated: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authenticated =
        ref.watch(authControllerProvider.select((a) => a.isAuthenticated));
    final controller = ref.watch(drivesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sürüşlerim'),
        backgroundColor: AppColors.night,
        foregroundColor: AppColors.white,
      ),
      body: SafeArea(child: _body(controller, authenticated)),
    );
  }

  Widget _body(DrivesController controller, bool authenticated) {
    switch (controller.state) {
      case DrivesLoadState.idle:
      case DrivesLoadState.loading:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.red),
        );
      case DrivesLoadState.error:
        return _ErrorState(
          message: controller.error ?? 'Sürüşler yüklenemedi.',
          onRetry: () => ref
              .read(drivesControllerProvider)
              .load(authenticated: authenticated),
        );
      case DrivesLoadState.ready:
        if (controller.drives.isEmpty) {
          return authenticated
              ? const _EmptyState()
              : _GuestState(onLogin: _login);
        }
        return RefreshIndicator(
          color: AppColors.red,
          onRefresh: () => ref
              .read(drivesControllerProvider)
              .load(authenticated: authenticated),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.drives.length + (authenticated ? 0 : 1),
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (!authenticated && index == 0) {
                return _LoginBanner(onLogin: _login);
              }
              final drive = controller.drives[authenticated ? index : index - 1];
              return _DriveCard(
                drive: drive,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DriveDetailScreen(driveId: drive.id),
                  ),
                ),
                onRename: drive.isLocal
                    ? null
                    : () => showRenameDriveDialog(
                          context,
                          ref,
                          driveId: drive.id,
                          currentName: drive.name,
                        ),
                onDownload: () async {
                  try {
                    final detail = await ref
                        .read(drivesControllerProvider)
                        .loadDetail(drive.id);
                    if (!context.mounted) return;
                    await downloadDriveVideo(context, detail: detail);
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Video oluşturulamadı.')),
                    );
                  }
                },
              );
            },
          ),
        );
    }
  }
}

class _DriveCard extends StatelessWidget {
  const _DriveCard({
    required this.drive,
    required this.onTap,
    required this.onDownload,
    this.onRename,
  });

  final DriveSummary drive;
  final VoidCallback onTap;
  final VoidCallback onDownload;
  final VoidCallback? onRename;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: AppColors.red,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driveDisplayName(drive.name, drive.startedAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    if (drive.hasName)
                      Text(
                        formatDriveDate(drive.startedAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.whiteMuted,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 14,
                      children: [
                        _Metric(
                          icon: Icons.straighten_rounded,
                          label: formatDistance(drive.lengthM),
                        ),
                        _Metric(
                          icon: Icons.schedule_rounded,
                          label: formatDuration(drive.duration),
                        ),
                        if (drive.avgSpeedKmh != null)
                          _Metric(
                            icon: Icons.speed_rounded,
                            label: formatSpeedKmh(drive.avgSpeedKmh),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.whiteMuted,
                ),
                color: AppColors.surfaceHigh,
                onSelected: (value) {
                  if (value == 'rename') onRename?.call();
                  if (value == 'download') onDownload();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'download',
                    child: Text('Videoyu indir'),
                  ),
                  if (onRename != null)
                    const PopupMenuItem(
                      value: 'rename',
                      child: Text('Yeniden adlandır'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.whiteMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.whiteMuted),
        ),
      ],
    );
  }
}

class _LoginBanner extends StatelessWidget {
  const _LoginBanner({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Buluttaki sürüşler için giriş yapın. Yerel kayıtlar bu cihazda durur.',
                style: TextStyle(color: AppColors.whiteMuted, fontSize: 13),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: onLogin,
              child: const Text('Giriş'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined,
                      size: 64, color: AppColors.whiteMuted),
                  SizedBox(height: 16),
                  Text(
                    'Henüz kayıtlı sürüşünüz yok',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Bir sürüş kaydedip tamamladığınızda burada görünecek.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.whiteMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 56, color: AppColors.whiteMuted),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.whiteMuted),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestState extends StatelessWidget {
  const _GuestState({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded,
                size: 56, color: AppColors.whiteMuted),
            const SizedBox(height: 16),
            const Text(
              'Sürüş geçmişini görmek için giriş yapın',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sürüşleriniz hesabınıza kaydedilir ve tüm cihazlardan erişilebilir.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.whiteMuted),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onLogin,
              icon: const Icon(Icons.login_rounded),
              label: const Text('Giriş yap'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:radar_alert/app.dart';
import 'package:radar_alert/core/theme/app_theme.dart';
import 'package:radar_alert/features/auth/auth_screen.dart';
import 'package:radar_alert/features/drives/drive_format.dart';
import 'package:radar_alert/features/drives/drives_history_screen.dart';
import 'package:radar_alert/features/profile/appearance_section.dart';
import 'package:radar_alert/features/profile/profile_controller.dart';
import 'package:radar_alert/features/profile/profile_models.dart';
import 'package:radar_alert/features/profile/vehicle_customization_section.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authenticated = ref.read(authControllerProvider).isAuthenticated;
      if (authenticated) {
        ref.read(profileControllerProvider).load();
        ref.read(vehicleCustomizationControllerProvider).syncFromServer();
      }
    });
  }

  Future<void> _login() async {
    final ok = await showAuthModal(context);
    if (ok && mounted) {
      await ref.read(profileControllerProvider).load(forceSpinner: true);
      await ref.read(vehicleCustomizationControllerProvider).syncFromServer();
    }
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider).logout();
    ref.read(profileControllerProvider).clear();
    ref.read(vehicleCustomizationControllerProvider).clear();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    final ok = await ref
        .read(vehicleCustomizationControllerProvider)
        .uploadProfilePicture(file.path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Profil fotoğrafı güncellendi.'
              : (ref.read(vehicleCustomizationControllerProvider).error ??
                  'Yükleme başarısız.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final profile = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          if (auth.isAuthenticated)
            TextButton(onPressed: _logout, child: const Text('Çıkış')),
        ],
      ),
      body: SafeArea(
        child: !auth.isAuthenticated
            ? _GuestState(onLogin: _login)
            : _body(auth.email, profile),
      ),
    );
  }

  Widget _body(String? email, ProfileController profile) {
    if (profile.state == ProfileLoadState.error && !profile.hasCache) {
      return _ErrorState(
        message: profile.error ?? 'İstatistikler yüklenemedi.',
        onRetry: () =>
            ref.read(profileControllerProvider).load(forceSpinner: true),
      );
    }

    final stats = profile.stats;
    final showSkeleton =
        stats == null && profile.state == ProfileLoadState.loading;

    return RefreshIndicator(
      color: AppColors.red,
      onRefresh: () async {
        await Future.wait([
          ref.read(profileControllerProvider).refresh(),
          ref.read(vehicleCustomizationControllerProvider).syncFromServer(),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const AppearanceSection(),
          const SizedBox(height: 28),
          const VehicleCustomizationSection(),
          const SizedBox(height: 28),
          _Header(email: email ?? '', stats: stats, onAvatarTap: _pickAvatar),
          const SizedBox(height: 20),
          if (showSkeleton)
            const _MetricsSkeleton()
          else if (stats != null)
            _MetricsGrid(stats: stats)
          else
            const SizedBox.shrink(),
          if (stats != null) ...[
            const SizedBox(height: 16),
            _ReputationSection(stats: stats),
            const SizedBox(height: 16),
            _StreakSection(stats: stats),
          ],
          if (profile.isRefreshing) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.red,
              backgroundColor: AppColors.outline,
            ),
          ],
          const SizedBox(height: 28),
          Text(
            'Başarımlar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (showSkeleton)
            const _BadgesSkeleton()
          else
            _AchievementsSection(unlocked: stats?.unlockedCodes ?? const {}),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DrivesHistoryScreen()),
              );
            },
            icon: const Icon(Icons.history),
            label: const Text('Sürüşlerim'),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.email,
    required this.stats,
    required this.onAvatarTap,
  });

  final String email;
  final UserStats? stats;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final vehicle = ref.watch(vehicleCustomizationControllerProvider);
    final pictureUrl = vehicle.absolutePictureUrl;
    return Row(
      children: [
        GestureDetector(
          onTap: vehicle.uploadingPicture ? null : onAvatarTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: scheme.outline),
                  image: pictureUrl == null
                      ? null
                      : DecorationImage(
                          image: NetworkImage(pictureUrl),
                          fit: BoxFit.cover,
                        ),
                ),
                child: pictureUrl == null
                    ? Icon(Icons.person, color: scheme.onSurface, size: 28)
                    : null,
              ),
              if (vehicle.uploadingPicture)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stats?.rankTitle ?? 'Hesabım',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              if (stats != null)
                Text(
                  '${stats!.rankTitle} • ${stats!.xp} XP',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (stats != null) const SizedBox(height: 4),
              Text(
                email,
                maxLines: 1,
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
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _MetricTile(
          label: 'Mesafe',
          value: formatDistance(stats.totalDistanceM),
          icon: Icons.straighten,
        ),
        _MetricTile(
          label: 'Süre',
          value: formatDuration(stats.totalDriveTime),
          icon: Icons.timer_outlined,
        ),
        _MetricTile(
          label: 'Sürüş',
          value: '${stats.totalDrives}',
          icon: Icons.route,
        ),
        _MetricTile(
          label: 'Radar',
          value: '${stats.radarsEncountered}',
          icon: Icons.radar,
        ),
        _MetricTile(
          label: 'Bildirim',
          value: '${stats.reportsSubmitted + stats.liveReportsSubmitted}',
          icon: Icons.campaign_outlined,
        ),
        _MetricTile(
          label: 'Kurtarılan',
          value: '${stats.totalDriversSaved}',
          icon: Icons.volunteer_activism_outlined,
        ),
        _MetricTile(
          label: 'Doğrulama',
          value: '${stats.confirmationsGiven + stats.liveConfirmationsGiven}',
          icon: Icons.verified_outlined,
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementsSection extends StatelessWidget {
  const _AchievementsSection({required this.unlocked});

  final Set<String> unlocked;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final def in achievementCatalog) ...[
          _AchievementTile(
            definition: def,
            unlocked: unlocked.contains(def.code),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.definition, required this.unlocked});

  final AchievementDefinition definition;
  final bool unlocked;

  IconData get _icon {
    switch (definition.icon) {
      case 'distance':
        return Icons.emoji_events;
      case 'night':
        return Icons.nightlight_round;
      case 'shield':
        return Icons.verified_user;
      case 'radar':
        return Icons.radar;
      case 'report':
        return Icons.campaign;
      case 'helper':
        return Icons.handshake_outlined;
      case 'reporter':
        return Icons.record_voice_over;
      case 'guardian':
        return Icons.shield_moon;
      case 'owl':
        return Icons.dark_mode_outlined;
      case 'responder':
        return Icons.emergency;
      case 'flag':
      default:
        return Icons.flag;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = unlocked ? AppColors.white : AppColors.whiteMuted;
    return Opacity(
      opacity: unlocked ? 1 : 0.45,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked
                ? AppColors.success.withValues(alpha: 0.45)
                : AppColors.outline,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: unlocked
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _icon,
                color: unlocked ? AppColors.success : AppColors.whiteMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    definition.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    definition.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.whiteMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (unlocked)
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricsSkeleton extends StatelessWidget {
  const _MetricsSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: List.generate(
        7,
        (_) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.outline),
          ),
        ),
      ),
    );
  }
}

class _ReputationSection extends StatelessWidget {
  const _ReputationSection({required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    final hasUninitializedReputation =
        stats.rankCode == 'caylak' &&
        stats.xp == 0 &&
        stats.xpToNextRank == 0 &&
        stats.eloRating <= 1000;
    final progressBase = hasUninitializedReputation
        ? 0.0
        : (stats.xpToNextRank <= 0
              ? 1.0
              : 1 -
                    (stats.xpToNextRank /
                        (stats.xp + stats.xpToNextRank).clamp(1, 1 << 30)));
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium, color: scheme.onSurface),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  stats.rankTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Text(
                '${stats.eloRating.toStringAsFixed(0)} ELO',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${stats.xp} XP',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progressBase.toDouble().clamp(0, 1),
              color: AppColors.red,
              backgroundColor: AppColors.surfaceHigh,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasUninitializedReputation
                ? 'Reputasyon verileri senkronize ediliyor'
                : stats.xpToNextRank > 0
                ? 'Sonraki seviyeye ${stats.xpToNextRank} XP kaldı'
                : 'En yüksek rütbedesiniz',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.whiteMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakSection extends StatelessWidget {
  const _StreakSection({required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CompactMetricTile(
            label: 'Sürüş Serisi',
            value: '${stats.driveStreak.current} gün',
            icon: Icons.local_fire_department_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CompactMetricTile(
            label: 'En İyi Seri',
            value: '${stats.driveStreak.best} gün',
            icon: Icons.bolt_outlined,
          ),
        ),
      ],
    );
  }
}

class _CompactMetricTile extends StatelessWidget {
  const _CompactMetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.whiteMuted),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.whiteMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgesSkeleton extends StatelessWidget {
  const _BadgesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outline),
            ),
          ),
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
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const AppearanceSection(),
        const SizedBox(height: 48),
        Icon(Icons.person_outline, size: 48, color: muted),
        const SizedBox(height: 16),
        Text(
          'İstatistiklerinizi görmek için giriş yapın',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: muted),
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: onLogin, child: const Text('Giriş Yap')),
      ],
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.whiteMuted),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Tekrar Dene')),
          ],
        ),
      ),
    );
  }
}

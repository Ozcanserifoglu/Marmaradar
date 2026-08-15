import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:radar_alert/app.dart';
import 'package:radar_alert/core/theme/app_theme.dart';
import 'package:radar_alert/features/auth/auth_screen.dart';
import 'package:radar_alert/features/drives/drive_format.dart';
import 'package:radar_alert/features/drives/drives_history_screen.dart';
import 'package:radar_alert/features/profile/profile_controller.dart';
import 'package:radar_alert/features/profile/profile_models.dart';

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
      }
    });
  }

  Future<void> _login() async {
    final ok = await showAuthModal(context);
    if (ok && mounted) {
      await ref.read(profileControllerProvider).load(forceSpinner: true);
    }
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider).logout();
    ref.read(profileControllerProvider).clear();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final profile = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: AppColors.night,
        foregroundColor: AppColors.white,
        actions: [
          if (auth.isAuthenticated)
            TextButton(
              onPressed: _logout,
              child: const Text('Çıkış'),
            ),
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
      onRefresh: () => ref.read(profileControllerProvider).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _Header(email: email ?? ''),
          const SizedBox(height: 20),
          if (showSkeleton)
            const _MetricsSkeleton()
          else if (stats != null)
            _MetricsGrid(stats: stats)
          else
            const SizedBox.shrink(),
          if (profile.isRefreshing) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.red,
              backgroundColor: AppColors.outline,
            ),
          ],
          const SizedBox(height: 28),
          const Text(
            'Başarımlar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 12),
          if (showSkeleton)
            const _BadgesSkeleton()
          else
            _AchievementsSection(
              unlocked: stats?.unlockedCodes ?? const {},
            ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DrivesHistoryScreen(),
                ),
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

class _Header extends StatelessWidget {
  const _Header({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.outline),
          ),
          child: const Icon(Icons.person, color: AppColors.white, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hesabım',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                maxLines: 1,
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
          value: '${stats.reportsSubmitted}',
          icon: Icons.campaign_outlined,
        ),
        _MetricTile(
          label: 'Kurtarılan',
          value: '${stats.driversSaved}',
          icon: Icons.volunteer_activism_outlined,
        ),
        _MetricTile(
          label: 'Doğrulama',
          value: '${stats.confirmationsGiven}',
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.whiteMuted),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
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
  const _AchievementTile({
    required this.definition,
    required this.unlocked,
  });

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
            color: unlocked ? AppColors.success.withValues(alpha: 0.45) : AppColors.outline,
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
              const Icon(Icons.check_circle, color: AppColors.success, size: 20),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline, size: 48, color: AppColors.whiteMuted),
            const SizedBox(height: 16),
            const Text(
              'İstatistiklerinizi görmek için giriş yapın',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.whiteMuted),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onLogin,
              child: const Text('Giriş Yap'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

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
            FilledButton(
              onPressed: onRetry,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

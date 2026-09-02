import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:radar_alert/app.dart';
import 'package:radar_alert/core/theme/app_theme.dart';
import 'package:radar_alert/features/drives/drive_format.dart';
import 'package:radar_alert/features/leaderboard/leaderboard_controller.dart';
import 'package:radar_alert/features/leaderboard/leaderboard_models.dart';
import 'package:radar_alert/features/tracking/widgets/vehicle_icon_painter.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(leaderboardControllerProvider).load(forceSpinner: true);
    });
  }

  String? _absoluteUrl(String? path) {
    return ref.read(leaderboardControllerProvider).absolutePictureUrl(path);
  }

  String _formatValue(LeaderboardCategory category, double value) {
    if (category == LeaderboardCategory.distance) {
      return formatLeaderboardKm(value);
    }
    return '${formatThousands(value.round())} katkı';
  }

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(leaderboardControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final data = board.current;

    return Scaffold(
      appBar: AppBar(title: const Text('Sıralama')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<LeaderboardCategory>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: LeaderboardCategory.distance,
                    label: Text('Mesafe'),
                    icon: Icon(Icons.route, size: 18),
                  ),
                  ButtonSegment(
                    value: LeaderboardCategory.reports,
                    label: Text('Katkılar'),
                    icon: Icon(Icons.campaign_outlined, size: 18),
                  ),
                ],
                selected: {board.category},
                onSelectionChanged: (next) {
                  ref
                      .read(leaderboardControllerProvider)
                      .setCategory(next.first);
                },
              ),
            ),
          ),
          if (board.isRefreshing)
            LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.red,
              backgroundColor: scheme.outline,
            ),
          Expanded(child: _buildBody(board, data, scheme)),
          if (data != null)
            _MeBar(
              me: data.me,
              valueLabel: _formatValue(board.category, data.me.value),
              pictureUrl: _absoluteUrl(data.me.profilePictureUrl),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(
    LeaderboardController board,
    LeaderboardResponse? data,
    ColorScheme scheme,
  ) {
    if (board.state == LeaderboardLoadState.error && !board.hasCache) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 40, color: scheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                board.error ?? 'Sıralama yüklenemedi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref
                    .read(leaderboardControllerProvider)
                    .load(forceSpinner: true),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (data == null && board.state == LeaderboardLoadState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (data == null) {
      return const SizedBox.shrink();
    }

    final podium = data.entries.take(3).toList();
    final rest = data.entries.length > 3
        ? data.entries.sublist(3)
        : const <LeaderboardEntry>[];

    return RefreshIndicator(
      color: AppColors.red,
      onRefresh: () => ref.read(leaderboardControllerProvider).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (podium.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: _Podium(
                  entries: podium,
                  category: board.category,
                  formatValue: _formatValue,
                  absoluteUrl: _absoluteUrl,
                  myUserId: data.me.userId,
                ),
              ),
            ),
          if (rest.isEmpty && podium.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Henüz sıralama yok.\nİlk mesafe veya katkıyı sen ekle!',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else if (rest.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList.builder(
                itemCount: rest.length,
                itemBuilder: (context, index) {
                  final entry = rest[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: index == rest.length - 1 ? 0 : 8),
                    child: _LeaderboardRow(
                      entry: entry,
                      valueLabel: _formatValue(board.category, entry.value),
                      pictureUrl: _absoluteUrl(entry.profilePictureUrl),
                      isMe: entry.userId == data.me.userId,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({
    required this.entries,
    required this.category,
    required this.formatValue,
    required this.absoluteUrl,
    required this.myUserId,
  });

  final List<LeaderboardEntry> entries;
  final LeaderboardCategory category;
  final String Function(LeaderboardCategory, double) formatValue;
  final String? Function(String?) absoluteUrl;
  final String myUserId;

  @override
  Widget build(BuildContext context) {
    final first = entries.isNotEmpty ? entries[0] : null;
    final second = entries.length > 1 ? entries[1] : null;
    final third = entries.length > 2 ? entries[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: second == null
              ? const SizedBox.shrink()
              : _PodiumCard(
                  entry: second,
                  place: 2,
                  accent: const Color(0xFFB0B0B8),
                  tall: false,
                  valueLabel: formatValue(category, second.value),
                  pictureUrl: absoluteUrl(second.profilePictureUrl),
                  isMe: second.userId == myUserId,
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: first == null
              ? const SizedBox.shrink()
              : _PodiumCard(
                  entry: first,
                  place: 1,
                  accent: const Color(0xFFFFD54F),
                  tall: true,
                  valueLabel: formatValue(category, first.value),
                  pictureUrl: absoluteUrl(first.profilePictureUrl),
                  isMe: first.userId == myUserId,
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: third == null
              ? const SizedBox.shrink()
              : _PodiumCard(
                  entry: third,
                  place: 3,
                  accent: const Color(0xFFCD7F32),
                  tall: false,
                  valueLabel: formatValue(category, third.value),
                  pictureUrl: absoluteUrl(third.profilePictureUrl),
                  isMe: third.userId == myUserId,
                ),
        ),
      ],
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.entry,
    required this.place,
    required this.accent,
    required this.tall,
    required this.valueLabel,
    required this.pictureUrl,
    required this.isMe,
  });

  final LeaderboardEntry entry;
  final int place;
  final Color accent;
  final bool tall;
  final String valueLabel;
  final String? pictureUrl;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avatarSize = tall ? 56.0 : 44.0;

    return Container(
      padding: EdgeInsets.fromLTRB(8, tall ? 14 : 10, 8, 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isMe ? AppColors.red : accent.withValues(alpha: 0.9),
          width: tall || isMe ? 2.5 : 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$place',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          _Avatar(
            size: avatarSize,
            pictureUrl: pictureUrl,
            borderColor: accent,
          ),
          const SizedBox(height: 8),
          Text(
            entry.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 32,
            height: 32,
            child: CustomPaint(
              painter: VehicleIconPainter(
                type: entry.vehicleType,
                color: entry.vehicleColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valueLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.entry,
    required this.valueLabel,
    required this.pictureUrl,
    required this.isMe,
  });

  final LeaderboardEntry entry;
  final String valueLabel;
  final String? pictureUrl;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.red.withValues(alpha: 0.10) : scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? AppColors.red.withValues(alpha: 0.55) : scheme.outline,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _Avatar(size: 40, pictureUrl: pictureUrl, borderColor: scheme.outline),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
          SizedBox(
            width: 34,
            height: 34,
            child: CustomPaint(
              painter: VehicleIconPainter(
                type: entry.vehicleType,
                color: entry.vehicleColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              valueLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeBar extends StatelessWidget {
  const _MeBar({
    required this.me,
    required this.valueLabel,
    required this.pictureUrl,
  });

  final LeaderboardMeEntry me;
  final String valueLabel;
  final String? pictureUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Material(
      elevation: 16,
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + (bottom > 0 ? 0 : 4)),
          decoration: BoxDecoration(
            color: AppColors.red.withValues(alpha: 0.10),
            border: Border(top: BorderSide(color: scheme.outline)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '#${me.rank}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _Avatar(
                size: 40,
                pictureUrl: pictureUrl,
                borderColor: AppColors.red,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      me.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      me.inTop ? 'İlk 100 içindesin' : 'Senin sıran',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 34,
                height: 34,
                child: CustomPaint(
                  painter: VehicleIconPainter(
                    type: me.vehicleType,
                    color: me.vehicleColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                valueLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.size,
    required this.pictureUrl,
    required this.borderColor,
  });

  final double size;
  final String? pictureUrl;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: borderColor, width: 2),
        color: scheme.surfaceContainerHighest,
        image: pictureUrl == null
            ? null
            : DecorationImage(
                image: NetworkImage(pictureUrl!),
                fit: BoxFit.cover,
              ),
      ),
      child: pictureUrl == null
          ? Icon(Icons.person, size: size * 0.5, color: scheme.onSurfaceVariant)
          : null,
    );
  }
}

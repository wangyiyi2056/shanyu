import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/core/theme/app_typography.dart';
import 'package:hiking_assistant/features/tracking/data/models/track_model.dart';
import 'package:hiking_assistant/features/tracking/presentation/providers/tracking_provider.dart';

class TrackListScreen extends ConsumerWidget {
  const TrackListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(tracksProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: Text('历史记录', style: AppTypography.title),
      ),
      body: tracksAsync.when(
        data: (tracks) => _TrackListView(tracks: tracks),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.forest),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text('加载失败: $error', style: AppTypography.body),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackListView extends ConsumerWidget {
  final List<HikingTrack> tracks;

  const _TrackListView({required this.tracks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tracks.isEmpty) {
      return const _EmptyState();
    }

    return RefreshIndicator(
      color: AppColors.forest,
      onRefresh: () async {
        ref.invalidate(tracksProvider);
        await ref.read(tracksProvider.future);
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _DismissibleTrackItem(
              key: ValueKey(track.id),
              track: track,
              onTap: () => context.push('/track/${track.id}'),
              onDelete: () async {
                await ref.read(trackRepositoryProvider).deleteTrack(track.id);
                ref.invalidate(tracksProvider);
              },
            ),
          );
        },
      ),
    );
  }
}

class _DismissibleTrackItem extends StatelessWidget {
  final HikingTrack track;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  const _DismissibleTrackItem({
    super.key,
    required this.track,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: key ?? ValueKey(track.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            title: Text('删除轨迹', style: AppTypography.title),
            content: Text(
              '确定要删除 "${track.name}" 吗？此操作不可恢复。',
              style: AppTypography.body,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: const Text('删除'),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (_) async {
        await onDelete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${track.name}" 已删除')),
          );
        }
      },
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.white),
            SizedBox(width: AppSpacing.xs),
            Text(
              '删除',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      child: _TrackListItem(
        track: track,
        onTap: onTap,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.route,
                    size: 64,
                    color: AppColors.inkMuted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '还没有记录任何轨迹',
                    style: AppTypography.title.copyWith(
                      color: AppColors.inkLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '去地图页面开始你的第一次记录吧',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TrackListItem extends StatelessWidget {
  final HikingTrack track;
  final VoidCallback onTap;

  const _TrackListItem({
    required this.track,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${track.startTime.year}-${track.startTime.month.toString().padLeft(2, '0')}-${track.startTime.day.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppColors.softShadow(blur: 12),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        track.name,
                        style: AppTypography.title.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.straighten,
                      value: track.distanceText,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _StatChip(
                      icon: Icons.timer,
                      value: track.durationText,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _StatChip(
                      icon: Icons.terrain,
                      value: '${track.elevationGain.toStringAsFixed(0)} m',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;

  const _StatChip({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.forest.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.forest),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppTypography.dataSmall.copyWith(
              color: AppColors.forest,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

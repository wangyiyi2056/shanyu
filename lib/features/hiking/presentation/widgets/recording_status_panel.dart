import 'package:flutter/material.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/features/tracking/presentation/providers/tracking_provider.dart';

class RecordingStatusPanel extends StatelessWidget {
  final RecorderState state;
  final VoidCallback onPause;
  final VoidCallback onResume;

  const RecordingStatusPanel({
    super.key,
    required this.state,
    required this.onPause,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final isPaused = state.status == RecordingStatus.paused;
    final track = state.currentTrack;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isPaused
            ? Colors.orange.withValues(alpha: 0.9)
            : Colors.red.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isPaused ? Colors.orange.shade200 : Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                isPaused ? '记录已暂停' : '正在记录轨迹',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (isPaused)
                TextButton.icon(
                  onPressed: onResume,
                  icon: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 18),
                  label:
                      const Text('恢复', style: TextStyle(color: Colors.white)),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
              else
                TextButton.icon(
                  onPressed: onPause,
                  icon: const Icon(Icons.pause, color: Colors.white, size: 18),
                  label:
                      const Text('暂停', style: TextStyle(color: Colors.white)),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('时长', _formatDuration(state.elapsed)),
              _buildStat('距离', track?.distanceText ?? '0 m'),
              _buildStat('点数', '${state.points.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

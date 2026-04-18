import 'package:flutter/material.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/core/theme/app_typography.dart';
import 'package:hiking_assistant/features/hiking/data/models/route_model.dart';
import 'package:hiking_assistant/shared/utils/color_utils.dart';

class NearbyRouteItem extends StatelessWidget {
  final HikingRoute route;
  final VoidCallback onTap;

  const NearbyRouteItem({
    super.key,
    required this.route,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final difficultyColor = hexToColor(route.difficultyColor);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: AppColors.softShadow(blur: 8),
          ),
          child: Row(
            children: [
              // 左侧封面图
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppSpacing.radiusLg),
                ),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: route.imageUrl.isNotEmpty
                      ? Image.network(
                          route.imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: AppColors.paperDark,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.paperDark,
                            child: const Icon(
                              Icons.terrain,
                              size: 32,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.paperDark,
                          child: const Icon(
                            Icons.terrain,
                            size: 32,
                            color: AppColors.inkMuted,
                          ),
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.name,
                        style: AppTypography.title.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: difficultyColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              route.difficultyLabel,
                              style: AppTypography.dataSmall.copyWith(
                                color: difficultyColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.straighten,
                            size: 14,
                            color: AppColors.inkMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${route.distance} km',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 14,
                            color: AppColors.inkMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${route.estimatedDuration} 分钟',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.inkMuted,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 12,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                route.rating.toString(),
                                style: AppTypography.dataSmall.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.chevron_right,
                  color: AppColors.inkMuted,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

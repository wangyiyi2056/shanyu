import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hiking_assistant/core/theme/app_colors.dart';
import 'package:hiking_assistant/core/theme/app_spacing.dart';
import 'package:hiking_assistant/features/hiking/data/models/review_model.dart';
import 'package:hiking_assistant/features/hiking/presentation/widgets/star_rating_widget.dart';
import 'package:hiking_assistant/shared/utils/date_utils.dart';

class RouteReviewsList extends StatelessWidget {
  final AsyncValue<List<RouteReview>> reviewsAsync;

  const RouteReviewsList({super.key, required this.reviewsAsync});

  @override
  Widget build(BuildContext context) {
    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.textHint.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Center(
              child: Text('暂无评价，快来分享您的体验吧！'),
            ),
          );
        }

        return Column(
          children: reviews.map((review) {
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StarRatingWidget(rating: review.rating, size: 16),
                        const Spacer(),
                        Text(
                          review.authorName,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textHint,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      review.comment,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      formatDate(review.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textHint,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('加载评价失败: $error')),
    );
  }
}

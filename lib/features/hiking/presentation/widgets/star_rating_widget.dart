import 'package:flutter/material.dart';

/// 星级评分组件（支持只读和交互模式）
class StarRatingWidget extends StatelessWidget {
  final double rating;
  final double size;
  final bool interactive;
  final ValueChanged<double>? onRatingChanged;

  const StarRatingWidget({
    super.key,
    required this.rating,
    this.size = 24,
    this.interactive = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isHalf = rating >= starValue - 0.5 && rating < starValue;
        final isFull = rating >= starValue;

        return GestureDetector(
          onTap: interactive && onRatingChanged != null
              ? () {
                  final callback = onRatingChanged;
                  if (callback != null) {
                    callback(starValue.toDouble());
                  }
                }
              : null,
          child: Icon(
            isFull
                ? Icons.star
                : isHalf
                    ? Icons.star_half
                    : Icons.star_border,
            color: Colors.amber,
            size: size,
          ),
        );
      }),
    );
  }
}

/// 评价输入对话框
class ReviewInputDialog extends StatefulWidget {
  final String routeName;

  const ReviewInputDialog({super.key, required this.routeName});

  @override
  State<ReviewInputDialog> createState() => _ReviewInputDialogState();
}

class _ReviewInputDialogState extends State<ReviewInputDialog> {
  double _rating = 5;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('评价 ${widget.routeName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StarRatingWidget(
            rating: _rating,
            size: 32,
            interactive: true,
            onRatingChanged: (value) => setState(() => _rating = value),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: '分享您的徒步体验...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'rating': _rating,
              'comment': _commentController.text.trim().isEmpty
                  ? '用户体验不错'
                  : _commentController.text.trim(),
            });
          },
          child: const Text('提交'),
        ),
      ],
    );
  }
}

/// 路线评价模型
class RouteReview {
  final String id;
  final String routeId;
  final double rating; // 1.0 - 5.0
  final String comment;
  final String authorName;
  final DateTime createdAt;

  const RouteReview({
    required this.id,
    required this.routeId,
    required this.rating,
    required this.comment,
    this.authorName = '游客',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routeId': routeId,
      'rating': rating,
      'comment': comment,
      'authorName': authorName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RouteReview.fromJson(Map<String, dynamic> json) {
    return RouteReview(
      id: json['id'] as String,
      routeId: json['routeId'] as String,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String,
      authorName: json['authorName'] as String? ?? '游客',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  RouteReview copyWith({
    String? id,
    String? routeId,
    double? rating,
    String? comment,
    String? authorName,
    DateTime? createdAt,
  }) {
    return RouteReview(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// 路线收藏模型
class RouteFavorite {
  final String routeId;
  final DateTime createdAt;

  const RouteFavorite({
    required this.routeId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'routeId': routeId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RouteFavorite.fromJson(Map<String, dynamic> json) {
    return RouteFavorite(
      routeId: json['routeId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

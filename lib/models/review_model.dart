/// Review model representing a user's review of a service
class Review {
  final int id;
  final int serviceId;
  final int userId;
  final String? supabaseUserId; // UUID string for ownership checks
  final String userName;
  final String? userAvatar;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int helpfulCount;
  final bool isHelpfulByMe;

  const Review({
    required this.id,
    required this.serviceId,
    required this.userId,
    this.supabaseUserId,
    required this.userName,
    this.userAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.updatedAt,
    this.helpfulCount = 0,
    this.isHelpfulByMe = false,
  });

  /// Check if this review belongs to the given Supabase user
  bool isOwnedBy(String? supabaseId) {
    if (supabaseId == null || supabaseUserId == null) return false;
    return supabaseUserId == supabaseId;
  }

  /// Check if review can be edited (within 7 days of creation)
  bool get isEditable {
    final daysSinceCreation = DateTime.now().difference(createdAt).inDays;
    return daysSinceCreation <= 7;
  }

  /// Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? 'year_ago' : 'years_ago:$years';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? 'month_ago' : 'months_ago:$months';
    } else if (difference.inDays > 7) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? 'week_ago' : 'weeks_ago:$weeks';
    } else if (difference.inDays > 0) {
      return difference.inDays == 1 ? 'day_ago' : 'days_ago:${difference.inDays}';
    } else if (difference.inHours > 0) {
      return difference.inHours == 1 ? 'hour_ago' : 'hours_ago:${difference.inHours}';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1 ? 'minute_ago' : 'minutes_ago:${difference.inMinutes}';
    } else {
      return 'just_now';
    }
  }

  /// Get user initials for avatar
  String get userInitials {
    if (userName.isEmpty) return '?';
    final parts = userName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return userName[0].toUpperCase();
  }

  /// Create from JSON
  factory Review.fromJson(Map<String, dynamic> json) {
    // Handle user_id which could be int or UUID string
    final rawUserId = json['user_id'];
    final int userId;
    final String? supabaseUserId;

    if (rawUserId is int) {
      userId = rawUserId;
      supabaseUserId = json['supabase_user_id'] as String?;
    } else if (rawUserId is String) {
      // UUID string from Supabase
      userId = rawUserId.hashCode;
      supabaseUserId = rawUserId;
    } else {
      userId = 0;
      supabaseUserId = null;
    }

    return Review(
      id: json['id'] as int,
      serviceId: json['service_id'] as int,
      userId: userId,
      supabaseUserId: supabaseUserId,
      userName: json['user_name'] ?? json['userName'] ?? 'Anonymous',
      userAvatar: json['user_avatar'] ?? json['userAvatar'],
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      helpfulCount: json['helpful_count'] ?? json['helpfulCount'] ?? 0,
      isHelpfulByMe: json['is_helpful_by_me'] ?? json['isHelpfulByMe'] ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_id': serviceId,
      'user_id': userId,
      'supabase_user_id': supabaseUserId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'helpful_count': helpfulCount,
      'is_helpful_by_me': isHelpfulByMe,
    };
  }

  /// Copy with new values
  Review copyWith({
    int? id,
    int? serviceId,
    int? userId,
    String? supabaseUserId,
    String? userName,
    String? userAvatar,
    double? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? helpfulCount,
    bool? isHelpfulByMe,
  }) {
    return Review(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      userId: userId ?? this.userId,
      supabaseUserId: supabaseUserId ?? this.supabaseUserId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      isHelpfulByMe: isHelpfulByMe ?? this.isHelpfulByMe,
    );
  }

  @override
  String toString() {
    return 'Review(id: $id, serviceId: $serviceId, userId: $userId, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Review && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Rating statistics for a service
class RatingStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> breakdown; // {5: 45, 4: 30, 3: 15, 2: 7, 1: 3}

  const RatingStats({
    required this.averageRating,
    required this.totalReviews,
    required this.breakdown,
  });

  /// Get percentage for a star rating
  double getPercentage(int stars) {
    if (totalReviews == 0) return 0.0;
    final count = breakdown[stars] ?? 0;
    return (count / totalReviews) * 100;
  }

  /// Get count for a star rating
  int getCount(int stars) => breakdown[stars] ?? 0;

  /// Get formatted average rating (e.g., "4.5")
  String get formattedRating {
    if (totalReviews == 0) return '0.0';
    return averageRating.toStringAsFixed(1);
  }

  /// Get display string (e.g., "4.5 (128 reviews)")
  String get displayString => '$formattedRating ($totalReviews)';

  /// Check if there are any reviews
  bool get hasReviews => totalReviews > 0;

  /// Create from JSON
  factory RatingStats.fromJson(Map<String, dynamic> json) {
    final breakdownJson = json['breakdown'] ?? json['rating_breakdown'] ?? {};
    final Map<int, int> breakdown = {};

    breakdownJson.forEach((key, value) {
      breakdown[int.parse(key.toString())] = value as int;
    });

    return RatingStats(
      averageRating: (json['average_rating'] ?? json['averageRating'] ?? 0.0).toDouble(),
      totalReviews: json['total_reviews'] ?? json['totalReviews'] ?? 0,
      breakdown: breakdown,
    );
  }

  /// Create from list of reviews
  factory RatingStats.fromReviews(List<Review> reviews) {
    if (reviews.isEmpty) {
      return const RatingStats(
        averageRating: 0.0,
        totalReviews: 0,
        breakdown: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      );
    }

    final breakdown = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    double totalRating = 0;

    for (final review in reviews) {
      totalRating += review.rating;
      // Round to nearest integer for breakdown
      final roundedRating = review.rating.round().clamp(1, 5);
      breakdown[roundedRating] = (breakdown[roundedRating] ?? 0) + 1;
    }

    return RatingStats(
      averageRating: totalRating / reviews.length,
      totalReviews: reviews.length,
      breakdown: breakdown,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'breakdown': breakdown.map((k, v) => MapEntry(k.toString(), v)),
    };
  }

  /// Empty rating stats
  static const empty = RatingStats(
    averageRating: 0.0,
    totalReviews: 0,
    breakdown: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
  );

  @override
  String toString() {
    return 'RatingStats(average: $formattedRating, total: $totalReviews)';
  }
}

/// Response wrapper for reviews API
class ReviewsResponse {
  final String status;
  final String message;
  final List<Review> reviews;
  final RatingStats? stats;

  const ReviewsResponse({
    required this.status,
    required this.message,
    required this.reviews,
    this.stats,
  });

  factory ReviewsResponse.fromJson(Map<String, dynamic> json) {
    List<Review> reviewsList = [];

    if (json['data'] != null) {
      if (json['data'] is List) {
        reviewsList = (json['data'] as List)
            .map((item) => Review.fromJson(item))
            .toList();
      } else if (json['data']['reviews'] is List) {
        reviewsList = (json['data']['reviews'] as List)
            .map((item) => Review.fromJson(item))
            .toList();
      }
    } else if (json['reviews'] is List) {
      reviewsList = (json['reviews'] as List)
          .map((item) => Review.fromJson(item))
          .toList();
    }

    RatingStats? stats;
    if (json['stats'] != null) {
      stats = RatingStats.fromJson(json['stats']);
    } else if (json['data']?['stats'] != null) {
      stats = RatingStats.fromJson(json['data']['stats']);
    }

    return ReviewsResponse(
      status: json['status'] ?? 'success',
      message: json['message'] ?? '',
      reviews: reviewsList,
      stats: stats ?? RatingStats.fromReviews(reviewsList),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'reviews': reviews.map((r) => r.toJson()).toList(),
      'stats': stats?.toJson(),
    };
  }
}

import 'package:tour_guid/models/review_model.dart';

/// Factory for creating Review instances for testing
class ReviewFixtures {
  /// Create a Review with sensible defaults and optional overrides
  static Review createReview({
    int id = 1,
    int serviceId = 1,
    int userId = 100,
    String? supabaseUserId = 'user-uuid-123',
    String userName = 'Test User',
    String? userAvatar,
    double rating = 4.5,
    String comment = 'Great service!',
    DateTime? createdAt,
    DateTime? updatedAt,
    int helpfulCount = 0,
    bool isHelpfulByMe = false,
  }) {
    return Review(
      id: id,
      serviceId: serviceId,
      userId: userId,
      supabaseUserId: supabaseUserId,
      userName: userName,
      userAvatar: userAvatar,
      rating: rating,
      comment: comment,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt,
      helpfulCount: helpfulCount,
      isHelpfulByMe: isHelpfulByMe,
    );
  }

  /// Create a review from N days ago
  static Review createReviewDaysAgo(int days, {
    int id = 1,
    String? supabaseUserId = 'user-uuid-123',
  }) {
    return createReview(
      id: id,
      supabaseUserId: supabaseUserId,
      createdAt: DateTime.now().subtract(Duration(days: days)),
    );
  }

  /// Create a review from N hours ago
  static Review createReviewHoursAgo(int hours, {int id = 1}) {
    return createReview(
      id: id,
      createdAt: DateTime.now().subtract(Duration(hours: hours)),
    );
  }

  /// Create a review from N minutes ago
  static Review createReviewMinutesAgo(int minutes, {int id = 1}) {
    return createReview(
      id: id,
      createdAt: DateTime.now().subtract(Duration(minutes: minutes)),
    );
  }

  /// Create a review from N months ago
  static Review createReviewMonthsAgo(int months, {int id = 1}) {
    return createReview(
      id: id,
      createdAt: DateTime.now().subtract(Duration(days: months * 30)),
    );
  }

  /// Create a review from N years ago
  static Review createReviewYearsAgo(int years, {int id = 1}) {
    return createReview(
      id: id,
      createdAt: DateTime.now().subtract(Duration(days: years * 365)),
    );
  }

  /// Create complete JSON for Review.fromJson testing
  static Map<String, dynamic> createReviewJson({
    int id = 1,
    int serviceId = 1,
    dynamic userId = 'user-uuid-123',
    String? supabaseUserId,
    String userName = 'Test User',
    String? userAvatar,
    double rating = 4.5,
    String comment = 'Great service!',
    String? createdAt,
    String? updatedAt,
    int helpfulCount = 0,
    bool isHelpfulByMe = false,
  }) {
    final json = <String, dynamic>{
      'id': id,
      'service_id': serviceId,
      'user_id': userId,
      'user_name': userName,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'helpful_count': helpfulCount,
      'is_helpful_by_me': isHelpfulByMe,
    };

    if (supabaseUserId != null) json['supabase_user_id'] = supabaseUserId;
    if (userAvatar != null) json['user_avatar'] = userAvatar;
    if (updatedAt != null) json['updated_at'] = updatedAt;

    return json;
  }

  /// Create a list of reviews for testing aggregation
  static List<Review> createReviewsForStats({
    int count5Stars = 5,
    int count4Stars = 4,
    int count3Stars = 2,
    int count2Stars = 1,
    int count1Stars = 0,
  }) {
    final reviews = <Review>[];
    int id = 1;

    for (int i = 0; i < count5Stars; i++) {
      reviews.add(createReview(id: id++, rating: 5.0));
    }
    for (int i = 0; i < count4Stars; i++) {
      reviews.add(createReview(id: id++, rating: 4.0));
    }
    for (int i = 0; i < count3Stars; i++) {
      reviews.add(createReview(id: id++, rating: 3.0));
    }
    for (int i = 0; i < count2Stars; i++) {
      reviews.add(createReview(id: id++, rating: 2.0));
    }
    for (int i = 0; i < count1Stars; i++) {
      reviews.add(createReview(id: id++, rating: 1.0));
    }

    return reviews;
  }
}

/// Factory for creating RatingStats instances for testing
class RatingStatsFixtures {
  /// Create RatingStats with sensible defaults
  static RatingStats createRatingStats({
    double averageRating = 4.2,
    int totalReviews = 10,
    Map<int, int>? breakdown,
  }) {
    return RatingStats(
      averageRating: averageRating,
      totalReviews: totalReviews,
      breakdown: breakdown ?? {5: 4, 4: 3, 3: 2, 2: 1, 1: 0},
    );
  }

  /// Create empty RatingStats
  static RatingStats createEmptyRatingStats() {
    return const RatingStats(
      averageRating: 0.0,
      totalReviews: 0,
      breakdown: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
    );
  }

  /// Create RatingStats JSON for fromJson testing
  static Map<String, dynamic> createRatingStatsJson({
    double averageRating = 4.2,
    int totalReviews = 10,
    Map<String, int>? breakdown,
  }) {
    return {
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'breakdown': breakdown ?? {'5': 4, '4': 3, '3': 2, '2': 1, '1': 0},
    };
  }
}

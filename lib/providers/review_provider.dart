import 'package:flutter/foundation.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';
import '../services/cache_manager.dart';
import 'service_peovider.dart';

/// Provider for managing review state and operations
class ReviewProvider with ChangeNotifier {
  final CacheManager _cache = CacheManager();
  ServiceProvider? _serviceProvider;

  /// Set the service provider reference for updating ratings
  void setServiceProvider(ServiceProvider provider) {
    _serviceProvider = provider;
  }
  // State
  final Map<int, List<Review>> _serviceReviews = {};
  final Map<int, RatingStats> _serviceStats = {};
  final Map<int, Review?> _userReviews = {};

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Anti-cheating: rate limiting
  DateTime? _lastSubmissionTime;
  static const Duration _rateLimitDuration = Duration(minutes: 1);
  static const int minCommentLength = 10;
  static const int maxCommentLength = 1000;

  // Getters
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  /// Get reviews for a service
  List<Review> getReviews(int serviceId) => _serviceReviews[serviceId] ?? [];

  /// Get rating stats for a service
  RatingStats? getStats(int serviceId) => _serviceStats[serviceId];

  /// Get user's review for a service
  Review? getUserReview(int serviceId) => _userReviews[serviceId];

  /// Check if user has reviewed a service
  bool hasUserReviewed(int serviceId) => _userReviews[serviceId] != null;

  /// Check if can submit now (rate limiting)
  bool canSubmitNow() {
    if (_lastSubmissionTime == null) return true;
    return DateTime.now().difference(_lastSubmissionTime!) > _rateLimitDuration;
  }

  /// Get time until can submit again
  Duration? getTimeUntilCanSubmit() {
    if (_lastSubmissionTime == null) return null;
    final elapsed = DateTime.now().difference(_lastSubmissionTime!);
    if (elapsed > _rateLimitDuration) return null;
    return _rateLimitDuration - elapsed;
  }

  /// Fetch reviews for a service
  Future<void> fetchReviews(int serviceId, {int? userId, String? supabaseUserId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ReviewService.getServiceReviews(
        serviceId,
        currentSupabaseUserId: supabaseUserId,
      );

      _serviceReviews[serviceId] = response.reviews;
      _serviceStats[serviceId] = response.stats ?? RatingStats.fromReviews(response.reviews);

      // Find user's review if supabaseUserId provided
      if (supabaseUserId != null) {
        try {
          _userReviews[serviceId] = response.reviews.firstWhere(
            (r) => r.isOwnedBy(supabaseUserId),
          );
        } catch (e) {
          _userReviews[serviceId] = null;
        }
      }

      // Update the service's rating in ServiceProvider
      final stats = _serviceStats[serviceId];
      if (stats != null && _serviceProvider != null) {
        _serviceProvider!.updateServiceRating(
          serviceId,
          stats.averageRating,
          stats.totalReviews,
        );
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load reviews';
      debugPrint('Error fetching reviews: $e');
      notifyListeners();
    }
  }

  /// Fetch only rating stats (lighter operation)
  Future<void> fetchStats(int serviceId) async {
    try {
      final stats = await ReviewService.getServiceRatingStats(serviceId);
      _serviceStats[serviceId] = stats;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    }
  }

  /// Submit a new review
  Future<bool> submitReview({
    required int serviceId,
    required int userId,
    required double rating,
    required String comment,
    String? supabaseUserId,
  }) async {
    // Validate
    final validationError = validateComment(comment);
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    if (!isValidRating(rating)) {
      _errorMessage = 'invalid_rating';
      notifyListeners();
      return false;
    }

    // Rate limiting
    if (!canSubmitNow()) {
      _errorMessage = 'rate_limit_exceeded';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    // Set rate limit timestamp BEFORE submission to prevent race conditions
    final previousSubmissionTime = _lastSubmissionTime;
    _lastSubmissionTime = DateTime.now();
    notifyListeners();

    try {
      final result = await ReviewService.submitReview(
        serviceId: serviceId,
        userId: userId,
        rating: rating,
        comment: comment,
        supabaseUserId: supabaseUserId,
      );

      _isSubmitting = false;

      if (result['success'] == true) {
        // Refresh reviews
        await fetchReviews(serviceId, userId: userId, supabaseUserId: supabaseUserId);
        // Invalidate services cache so rating updates
        await _cache.delete('services', 'all_services');
        debugPrint('✅ Review submitted, services cache invalidated');
        return true;
      } else {
        // Revert rate limit on failure
        _lastSubmissionTime = previousSubmissionTime;
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Revert rate limit on error
      _lastSubmissionTime = previousSubmissionTime;
      _isSubmitting = false;
      _errorMessage = 'Failed to submit review';
      debugPrint('Error submitting review: $e');
      notifyListeners();
      return false;
    }
  }

  /// Update an existing review
  Future<bool> updateReview({
    required int reviewId,
    required int serviceId,
    required int userId,
    required double rating,
    required String comment,
    String? supabaseUserId,
  }) async {
    // Validate
    final validationError = validateComment(comment);
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    if (!isValidRating(rating)) {
      _errorMessage = 'invalid_rating';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ReviewService.updateReview(
        reviewId: reviewId,
        userId: userId,
        rating: rating,
        comment: comment,
        supabaseUserId: supabaseUserId,
      );

      _isSubmitting = false;

      if (result['success'] == true) {
        // Refresh reviews
        await fetchReviews(serviceId, userId: userId, supabaseUserId: supabaseUserId);
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Failed to update review';
      debugPrint('Error updating review: $e');
      notifyListeners();
      return false;
    }
  }

  /// Delete a review
  Future<bool> deleteReview({
    required int reviewId,
    required int serviceId,
    required int userId,
    String? supabaseUserId,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ReviewService.deleteReview(
        reviewId: reviewId,
        userId: userId,
        supabaseUserId: supabaseUserId,
      );

      _isSubmitting = false;

      if (result['success'] == true) {
        // Remove from local state
        _userReviews[serviceId] = null;
        // Refresh reviews
        await fetchReviews(serviceId, userId: userId, supabaseUserId: supabaseUserId);
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Failed to delete review';
      debugPrint('Error deleting review: $e');
      notifyListeners();
      return false;
    }
  }

  /// Mark a review as helpful
  Future<bool> toggleHelpful({
    required int reviewId,
    required int serviceId,
    required int userId,
    String? supabaseUserId,
  }) async {
    try {
      final result = await ReviewService.toggleHelpful(
        reviewId: reviewId,
        userId: userId,
        supabaseUserId: supabaseUserId,
      );

      if (result['success'] == true) {
        // Update local state
        final reviews = _serviceReviews[serviceId];
        if (reviews != null) {
          final index = reviews.indexWhere((r) => r.id == reviewId);
          if (index != -1) {
            final review = reviews[index];
            final isHelpful = result['isHelpful'] as bool;
            reviews[index] = review.copyWith(
              isHelpfulByMe: isHelpful,
              helpfulCount: review.helpfulCount + (isHelpful ? 1 : -1),
            );
            notifyListeners();
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error toggling helpful: $e');
      return false;
    }
  }

  /// Validate comment
  String? validateComment(String comment) {
    final trimmed = comment.trim();
    if (trimmed.length < minCommentLength) {
      return 'comment_too_short';
    }
    if (trimmed.length > maxCommentLength) {
      return 'comment_too_long';
    }
    return null;
  }

  /// Validate rating
  bool isValidRating(double rating) {
    return rating >= 0.5 && rating <= 5.0;
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear all cached data
  void clearCache() {
    _serviceReviews.clear();
    _serviceStats.clear();
    _userReviews.clear();
    notifyListeners();
  }

  /// Get rating label based on rating value
  static String getRatingLabel(double rating) {
    if (rating >= 4.5) return 'rating_excellent';
    if (rating >= 3.5) return 'rating_very_good';
    if (rating >= 2.5) return 'rating_good';
    if (rating >= 1.5) return 'rating_fair';
    return 'rating_poor';
  }
}

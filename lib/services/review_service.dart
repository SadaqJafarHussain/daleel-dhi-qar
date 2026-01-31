import 'package:flutter/foundation.dart';
import '../models/review_model.dart';
import 'supabase_service.dart';

/// Service for managing reviews (Supabase only)
class ReviewService {
  static final SupabaseService _supabase = SupabaseService();

  /// Get all reviews for a service
  static Future<ReviewsResponse> getServiceReviews(int serviceId, {String? currentSupabaseUserId}) async {
    try {
      // Get reviews with user profiles (including avatar_url)
      final data = await _supabase.client
          .from('reviews')
          .select('*, profiles:user_id(name, avatar_url)')
          .eq('service_id', serviceId)
          .order('created_at', ascending: false);

      // Get helpful votes for current user
      Set<int> helpfulByMe = {};
      if (currentSupabaseUserId != null) {
        final helpfulData = await _supabase.client
            .from('review_helpful_votes')
            .select('review_id')
            .eq('user_id', currentSupabaseUserId);

        helpfulByMe = (helpfulData as List)
            .map((h) => h['review_id'] as int)
            .toSet();
      }

      final reviews = (data as List).map((row) {
        final profileData = row['profiles'];
        final supabaseUserId = row['user_id'] as String;
        return Review(
          id: row['id'] as int,
          serviceId: row['service_id'] as int,
          userId: supabaseUserId.hashCode, // For backward compatibility
          supabaseUserId: supabaseUserId, // Store actual UUID for ownership checks
          userName: profileData?['name'] as String? ?? 'Anonymous',
          userAvatar: profileData?['avatar_url'] as String?,
          rating: (row['rating'] as num).toDouble(),
          comment: row['comment'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
          updatedAt: row['updated_at'] != null
              ? DateTime.parse(row['updated_at'] as String)
              : null,
          helpfulCount: row['helpful_count'] as int? ?? 0,
          isHelpfulByMe: helpfulByMe.contains(row['id'] as int),
        );
      }).toList();

      final stats = RatingStats.fromReviews(reviews);

      debugPrint('ReviewService: Loaded ${reviews.length} reviews for service $serviceId');

      return ReviewsResponse(
        status: 'success',
        message: 'Reviews loaded successfully',
        reviews: reviews,
        stats: stats,
      );
    } catch (e) {
      debugPrint('Error getting reviews: $e');
      return const ReviewsResponse(
        status: 'error',
        message: 'Failed to load reviews',
        reviews: [],
        stats: RatingStats.empty,
      );
    }
  }

  /// Get rating stats for a service
  static Future<RatingStats> getServiceRatingStats(int serviceId) async {
    try {
      final service = await _supabase.client
          .from('services')
          .select('average_rating, total_reviews')
          .eq('id', serviceId)
          .maybeSingle();

      if (service != null) {
        return RatingStats(
          averageRating: (service['average_rating'] as num?)?.toDouble() ?? 0,
          totalReviews: service['total_reviews'] as int? ?? 0,
          breakdown: {},
        );
      }
    } catch (e) {
      debugPrint('Error getting stats: $e');
    }

    // Fallback to calculating from reviews
    final response = await getServiceReviews(serviceId);
    return response.stats ?? RatingStats.empty;
  }

  /// Get user's review for a service
  static Future<Review?> getUserReview(int serviceId, {String? supabaseUserId}) async {
    final response = await getServiceReviews(serviceId, currentSupabaseUserId: supabaseUserId);
    try {
      return response.reviews.firstWhere((r) => r.isOwnedBy(supabaseUserId));
    } catch (e) {
      return null;
    }
  }

  /// Submit a new review
  static Future<Map<String, dynamic>> submitReview({
    required int serviceId,
    required int userId,
    required double rating,
    required String comment,
    String? supabaseUserId,
  }) async {
    // Validate
    if (rating < 0.5 || rating > 5.0) {
      return {'success': false, 'message': 'invalid_rating'};
    }
    if (comment.trim().length < 10) {
      return {'success': false, 'message': 'comment_too_short'};
    }
    if (comment.trim().length > 1000) {
      return {'success': false, 'message': 'comment_too_long'};
    }

    if (supabaseUserId == null) {
      return {'success': false, 'message': 'User not authenticated'};
    }

    try {
      // Check if already reviewed
      final existing = await _supabase.client
          .from('reviews')
          .select('id')
          .eq('service_id', serviceId)
          .eq('user_id', supabaseUserId)
          .maybeSingle();

      if (existing != null) {
        return {'success': false, 'message': 'already_reviewed'};
      }

      // Insert review
      final result = await _supabase.client
          .from('reviews')
          .insert({
            'service_id': serviceId,
            'user_id': supabaseUserId,
            'rating': rating,
            'comment': comment.trim(),
          })
          .select()
          .single();

      debugPrint('ReviewService: Review submitted: ${result['id']}');

      // Rating is automatically updated by database trigger
      return {
        'success': true,
        'message': 'review_submitted',
        'data': {'id': result['id']},
      };
    } catch (e) {
      debugPrint('Error submitting review: $e');
      if (e.toString().contains('duplicate') || e.toString().contains('unique')) {
        return {'success': false, 'message': 'already_reviewed'};
      }
      return {'success': false, 'message': 'Failed to submit review: $e'};
    }
  }

  /// Update an existing review
  static Future<Map<String, dynamic>> updateReview({
    required int reviewId,
    required int userId,
    required double rating,
    required String comment,
    String? supabaseUserId,
  }) async {
    // Validate
    if (rating < 0.5 || rating > 5.0) {
      return {'success': false, 'message': 'invalid_rating'};
    }
    if (comment.trim().length < 10) {
      return {'success': false, 'message': 'comment_too_short'};
    }

    if (supabaseUserId == null) {
      return {'success': false, 'message': 'User not authenticated'};
    }

    try {
      await _supabase.client
          .from('reviews')
          .update({
            'rating': rating,
            'comment': comment.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reviewId)
          .eq('user_id', supabaseUserId);

      debugPrint('ReviewService: Review updated: $reviewId');
      return {'success': true, 'message': 'review_updated'};
    } catch (e) {
      debugPrint('Error updating review: $e');
      return {'success': false, 'message': 'Failed to update review'};
    }
  }

  /// Delete a review
  static Future<Map<String, dynamic>> deleteReview({
    required int reviewId,
    required int userId,
    String? supabaseUserId,
  }) async {
    if (supabaseUserId == null) {
      return {'success': false, 'message': 'User not authenticated'};
    }

    try {
      await _supabase.client
          .from('reviews')
          .delete()
          .eq('id', reviewId)
          .eq('user_id', supabaseUserId);

      debugPrint('ReviewService: Review deleted: $reviewId');
      return {'success': true, 'message': 'review_deleted'};
    } catch (e) {
      debugPrint('Error deleting review: $e');
      return {'success': false, 'message': 'Failed to delete review'};
    }
  }

  /// Mark a review as helpful
  static Future<Map<String, dynamic>> toggleHelpful({
    required int reviewId,
    required int userId,
    String? supabaseUserId,
  }) async {
    if (supabaseUserId == null) {
      return {'success': false, 'message': 'User not authenticated'};
    }

    try {
      // Check if already marked helpful
      final existing = await _supabase.client
          .from('review_helpful_votes')
          .select('id')
          .eq('review_id', reviewId)
          .eq('user_id', supabaseUserId)
          .maybeSingle();

      if (existing != null) {
        // Remove vote
        await _supabase.client
            .from('review_helpful_votes')
            .delete()
            .eq('review_id', reviewId)
            .eq('user_id', supabaseUserId);

        // Decrement count
        await _supabase.client.rpc('decrement_helpful_count', params: {'review_id_param': reviewId});

        return {'success': true, 'message': 'helpful_removed', 'isHelpful': false};
      } else {
        // Add vote
        await _supabase.client.from('review_helpful_votes').insert({
          'review_id': reviewId,
          'user_id': supabaseUserId,
        });

        // Increment count
        await _supabase.client.rpc('increment_helpful_count', params: {'review_id_param': reviewId});

        return {'success': true, 'message': 'helpful_added', 'isHelpful': true};
      }
    } catch (e) {
      debugPrint('Error toggling helpful: $e');
      return {'success': false, 'message': 'Failed to toggle helpful'};
    }
  }

  /// Check if user can submit a review (rate limiting)
  static Future<bool> canSubmitReview(int userId) async {
    return true; // Rate limiting handled in provider
  }

  /// Check if user has already reviewed a service
  static Future<bool> hasUserReviewed(int serviceId, int userId, {String? supabaseUserId}) async {
    if (supabaseUserId == null) return false;

    try {
      final result = await _supabase.client
          .from('reviews')
          .select('id')
          .eq('service_id', serviceId)
          .eq('user_id', supabaseUserId)
          .maybeSingle();
      return result != null;
    } catch (e) {
      return false;
    }
  }
}

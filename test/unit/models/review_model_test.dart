import 'package:flutter_test/flutter_test.dart';
import 'package:tour_guid/models/review_model.dart';

import '../../fixtures/review_fixtures.dart';

void main() {
  group('Review', () {
    group('isEditable', () {
      test('returns true for review created today', () {
        final review = ReviewFixtures.createReviewDaysAgo(0);
        expect(review.isEditable, isTrue);
      });

      test('returns true for review created 7 days ago', () {
        final review = ReviewFixtures.createReviewDaysAgo(7);
        expect(review.isEditable, isTrue);
      });

      test('returns false for review created 8 days ago', () {
        final review = ReviewFixtures.createReviewDaysAgo(8);
        expect(review.isEditable, isFalse);
      });

      test('returns false for review created 30 days ago', () {
        final review = ReviewFixtures.createReviewDaysAgo(30);
        expect(review.isEditable, isFalse);
      });

      test('returns true for review created 6 days ago', () {
        final review = ReviewFixtures.createReviewDaysAgo(6);
        expect(review.isEditable, isTrue);
      });
    });

    group('isOwnedBy', () {
      test('returns true when supabaseUserId matches', () {
        final review = ReviewFixtures.createReview(
          supabaseUserId: 'user-123',
        );
        expect(review.isOwnedBy('user-123'), isTrue);
      });

      test('returns false when supabaseUserId does not match', () {
        final review = ReviewFixtures.createReview(
          supabaseUserId: 'user-123',
        );
        expect(review.isOwnedBy('user-456'), isFalse);
      });

      test('returns false when review supabaseUserId is null', () {
        final review = ReviewFixtures.createReview(
          supabaseUserId: null,
        );
        expect(review.isOwnedBy('user-123'), isFalse);
      });

      test('returns false when parameter is null', () {
        final review = ReviewFixtures.createReview(
          supabaseUserId: 'user-123',
        );
        expect(review.isOwnedBy(null), isFalse);
      });

      test('returns false when both are null', () {
        final review = ReviewFixtures.createReview(
          supabaseUserId: null,
        );
        expect(review.isOwnedBy(null), isFalse);
      });
    });

    group('timeAgo', () {
      test('returns just_now for review created less than 1 minute ago', () {
        final review = ReviewFixtures.createReview(
          createdAt: DateTime.now().subtract(const Duration(seconds: 30)),
        );
        expect(review.timeAgo, equals('just_now'));
      });

      test('returns minute_ago for 1 minute', () {
        final review = ReviewFixtures.createReview(
          createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
        );
        expect(review.timeAgo, equals('minute_ago'));
      });

      test('returns minutes_ago:N for multiple minutes', () {
        final review = ReviewFixtures.createReviewMinutesAgo(5);
        expect(review.timeAgo, equals('minutes_ago:5'));
      });

      test('returns hour_ago for 1 hour', () {
        final review = ReviewFixtures.createReviewHoursAgo(1);
        expect(review.timeAgo, equals('hour_ago'));
      });

      test('returns hours_ago:N for multiple hours', () {
        final review = ReviewFixtures.createReviewHoursAgo(5);
        expect(review.timeAgo, equals('hours_ago:5'));
      });

      test('returns day_ago for 1 day', () {
        final review = ReviewFixtures.createReviewDaysAgo(1);
        expect(review.timeAgo, equals('day_ago'));
      });

      test('returns days_ago:N for multiple days', () {
        final review = ReviewFixtures.createReviewDaysAgo(5);
        expect(review.timeAgo, equals('days_ago:5'));
      });

      test('returns week_ago for 1 week', () {
        final review = ReviewFixtures.createReview(
          createdAt: DateTime.now().subtract(const Duration(days: 8)),
        );
        expect(review.timeAgo, equals('week_ago'));
      });

      test('returns weeks_ago:N for multiple weeks', () {
        final review = ReviewFixtures.createReview(
          createdAt: DateTime.now().subtract(const Duration(days: 21)),
        );
        expect(review.timeAgo, equals('weeks_ago:3'));
      });

      test('returns month_ago for 1 month', () {
        // The logic uses > 30 days for months, so 31-60 days = 1 month
        final review = ReviewFixtures.createReview(
          createdAt: DateTime.now().subtract(const Duration(days: 35)),
        );
        expect(review.timeAgo, equals('month_ago'));
      });

      test('returns months_ago:N for multiple months', () {
        // 90 days / 30 = 3 months
        final review = ReviewFixtures.createReview(
          createdAt: DateTime.now().subtract(const Duration(days: 90)),
        );
        expect(review.timeAgo, equals('months_ago:3'));
      });

      test('returns year_ago for 1 year', () {
        // The logic uses > 365 days for years, so 366-729 days = 1 year
        final review = ReviewFixtures.createReview(
          createdAt: DateTime.now().subtract(const Duration(days: 400)),
        );
        expect(review.timeAgo, equals('year_ago'));
      });

      test('returns years_ago:N for multiple years', () {
        // 3 * 365 = 1095 days, use 1100 to be safe
        final review = ReviewFixtures.createReview(
          createdAt: DateTime.now().subtract(const Duration(days: 1100)),
        );
        expect(review.timeAgo, equals('years_ago:3'));
      });
    });

    group('userInitials', () {
      test('returns first letter for single word name', () {
        final review = ReviewFixtures.createReview(userName: 'John');
        expect(review.userInitials, equals('J'));
      });

      test('returns initials for two word name', () {
        final review = ReviewFixtures.createReview(userName: 'John Doe');
        expect(review.userInitials, equals('JD'));
      });

      test('returns initials for multi-word name (uses first two)', () {
        final review = ReviewFixtures.createReview(userName: 'John Michael Doe');
        expect(review.userInitials, equals('JM'));
      });

      test('returns ? for empty name', () {
        final review = ReviewFixtures.createReview(userName: '');
        expect(review.userInitials, equals('?'));
      });

      test('returns uppercase initials', () {
        final review = ReviewFixtures.createReview(userName: 'john doe');
        expect(review.userInitials, equals('JD'));
      });

      test('handles name with leading/trailing spaces', () {
        final review = ReviewFixtures.createReview(userName: '  John Doe  ');
        expect(review.userInitials, equals('JD'));
      });
    });

    group('fromJson', () {
      test('parses complete JSON correctly', () {
        final json = ReviewFixtures.createReviewJson(
          id: 42,
          serviceId: 100,
          userId: 'uuid-123',
          userName: 'Test User',
          userAvatar: 'https://example.com/avatar.jpg',
          rating: 4.5,
          comment: 'Great service!',
          helpfulCount: 10,
          isHelpfulByMe: true,
        );

        final review = Review.fromJson(json);

        expect(review.id, equals(42));
        expect(review.serviceId, equals(100));
        expect(review.supabaseUserId, equals('uuid-123'));
        expect(review.userName, equals('Test User'));
        expect(review.userAvatar, equals('https://example.com/avatar.jpg'));
        expect(review.rating, equals(4.5));
        expect(review.comment, equals('Great service!'));
        expect(review.helpfulCount, equals(10));
        expect(review.isHelpfulByMe, isTrue);
      });

      test('handles integer user_id', () {
        final json = ReviewFixtures.createReviewJson(
          userId: 123,
          supabaseUserId: 'uuid-456',
        );

        final review = Review.fromJson(json);

        expect(review.userId, equals(123));
        expect(review.supabaseUserId, equals('uuid-456'));
      });

      test('handles string user_id (UUID)', () {
        final json = ReviewFixtures.createReviewJson(
          userId: 'uuid-from-supabase',
        );

        final review = Review.fromJson(json);

        expect(review.supabaseUserId, equals('uuid-from-supabase'));
        expect(review.userId, equals('uuid-from-supabase'.hashCode));
      });

      test('handles missing optional fields', () {
        final json = <String, dynamic>{
          'id': 1,
          'service_id': 1,
          'user_id': 1,
          'rating': 5.0,
        };

        final review = Review.fromJson(json);

        expect(review.id, equals(1));
        expect(review.userName, equals('Anonymous'));
        expect(review.comment, isEmpty);
        expect(review.helpfulCount, equals(0));
        expect(review.isHelpfulByMe, isFalse);
      });

      test('handles alternative field names (camelCase)', () {
        final json = <String, dynamic>{
          'id': 1,
          'service_id': 1,
          'user_id': 1,
          'userName': 'CamelCase User',
          'userAvatar': 'https://example.com/avatar.jpg',
          'rating': 4.0,
          'helpfulCount': 5,
          'isHelpfulByMe': true,
          'created_at': DateTime.now().toIso8601String(),
        };

        final review = Review.fromJson(json);

        expect(review.userName, equals('CamelCase User'));
        expect(review.userAvatar, equals('https://example.com/avatar.jpg'));
        expect(review.helpfulCount, equals(5));
        expect(review.isHelpfulByMe, isTrue);
      });
    });

    group('toJson', () {
      test('produces valid JSON', () {
        final review = ReviewFixtures.createReview(
          id: 1,
          serviceId: 100,
          userId: 50,
          supabaseUserId: 'uuid-123',
          userName: 'Test User',
          rating: 4.5,
          comment: 'Great!',
          helpfulCount: 5,
        );

        final json = review.toJson();

        expect(json['id'], equals(1));
        expect(json['service_id'], equals(100));
        expect(json['user_id'], equals(50));
        expect(json['supabase_user_id'], equals('uuid-123'));
        expect(json['user_name'], equals('Test User'));
        expect(json['rating'], equals(4.5));
        expect(json['comment'], equals('Great!'));
        expect(json['helpful_count'], equals(5));
      });

      test('round-trip serialization preserves data', () {
        final original = ReviewFixtures.createReview(
          id: 42,
          serviceId: 100,
          userName: 'Round Trip',
          rating: 3.5,
          comment: 'Testing round trip',
        );

        final json = original.toJson();
        final restored = Review.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.serviceId, equals(original.serviceId));
        expect(restored.userName, equals(original.userName));
        expect(restored.rating, equals(original.rating));
        expect(restored.comment, equals(original.comment));
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final original = ReviewFixtures.createReview(
          id: 1,
          rating: 4.0,
          comment: 'Original comment',
        );

        final copy = original.copyWith(
          rating: 5.0,
          comment: 'Updated comment',
        );

        expect(copy.id, equals(original.id));
        expect(copy.rating, equals(5.0));
        expect(copy.comment, equals('Updated comment'));
        expect(original.rating, equals(4.0)); // Original unchanged
      });
    });

    group('equality', () {
      test('reviews with same id are equal', () {
        final review1 = ReviewFixtures.createReview(id: 1, rating: 4.0);
        final review2 = ReviewFixtures.createReview(id: 1, rating: 5.0);

        expect(review1, equals(review2));
        expect(review1.hashCode, equals(review2.hashCode));
      });

      test('reviews with different id are not equal', () {
        final review1 = ReviewFixtures.createReview(id: 1);
        final review2 = ReviewFixtures.createReview(id: 2);

        expect(review1, isNot(equals(review2)));
      });
    });
  });
}

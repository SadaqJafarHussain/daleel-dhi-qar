import 'package:flutter_test/flutter_test.dart';
import 'package:tour_guid/models/review_model.dart';

import '../../fixtures/review_fixtures.dart';

void main() {
  group('RatingStats', () {
    group('getPercentage', () {
      test('calculates percentage correctly', () {
        final stats = RatingStatsFixtures.createRatingStats(
          totalReviews: 10,
          breakdown: {5: 5, 4: 3, 3: 1, 2: 1, 1: 0},
        );

        expect(stats.getPercentage(5), equals(50.0));
        expect(stats.getPercentage(4), equals(30.0));
        expect(stats.getPercentage(3), equals(10.0));
        expect(stats.getPercentage(2), equals(10.0));
        expect(stats.getPercentage(1), equals(0.0));
      });

      test('returns 0 when totalReviews is 0', () {
        final stats = RatingStatsFixtures.createEmptyRatingStats();

        expect(stats.getPercentage(5), equals(0.0));
        expect(stats.getPercentage(4), equals(0.0));
        expect(stats.getPercentage(1), equals(0.0));
      });

      test('returns 0 for stars not in breakdown', () {
        final stats = RatingStatsFixtures.createRatingStats(
          totalReviews: 10,
          breakdown: {5: 10},
        );

        expect(stats.getPercentage(4), equals(0.0));
        expect(stats.getPercentage(3), equals(0.0));
      });
    });

    group('getCount', () {
      test('returns breakdown value for star rating', () {
        final stats = RatingStatsFixtures.createRatingStats(
          breakdown: {5: 45, 4: 30, 3: 15, 2: 7, 1: 3},
        );

        expect(stats.getCount(5), equals(45));
        expect(stats.getCount(4), equals(30));
        expect(stats.getCount(3), equals(15));
        expect(stats.getCount(2), equals(7));
        expect(stats.getCount(1), equals(3));
      });

      test('returns 0 for stars not in breakdown', () {
        final stats = RatingStatsFixtures.createRatingStats(
          breakdown: {5: 10},
        );

        expect(stats.getCount(4), equals(0));
        expect(stats.getCount(1), equals(0));
      });
    });

    group('formattedRating', () {
      test('formats rating to one decimal place', () {
        final stats = RatingStatsFixtures.createRatingStats(
          averageRating: 4.567,
          totalReviews: 10,
        );

        expect(stats.formattedRating, equals('4.6'));
      });

      test('preserves single decimal for whole numbers', () {
        final stats = RatingStatsFixtures.createRatingStats(
          averageRating: 4.0,
          totalReviews: 10,
        );

        expect(stats.formattedRating, equals('4.0'));
      });

      test('returns 0.0 when no reviews', () {
        final stats = RatingStatsFixtures.createEmptyRatingStats();

        expect(stats.formattedRating, equals('0.0'));
      });
    });

    group('displayString', () {
      test('formats display string correctly', () {
        final stats = RatingStatsFixtures.createRatingStats(
          averageRating: 4.5,
          totalReviews: 128,
        );

        expect(stats.displayString, equals('4.5 (128)'));
      });
    });

    group('hasReviews', () {
      test('returns true when totalReviews > 0', () {
        final stats = RatingStatsFixtures.createRatingStats(totalReviews: 1);
        expect(stats.hasReviews, isTrue);
      });

      test('returns false when totalReviews is 0', () {
        final stats = RatingStatsFixtures.createEmptyRatingStats();
        expect(stats.hasReviews, isFalse);
      });
    });

    group('fromReviews', () {
      test('aggregates reviews correctly', () {
        final reviews = ReviewFixtures.createReviewsForStats(
          count5Stars: 5,
          count4Stars: 3,
          count3Stars: 2,
          count2Stars: 0,
          count1Stars: 0,
        );

        final stats = RatingStats.fromReviews(reviews);

        expect(stats.totalReviews, equals(10));
        expect(stats.breakdown[5], equals(5));
        expect(stats.breakdown[4], equals(3));
        expect(stats.breakdown[3], equals(2));
        expect(stats.breakdown[2], equals(0));
        expect(stats.breakdown[1], equals(0));

        // Average: (5*5 + 4*3 + 3*2) / 10 = (25 + 12 + 6) / 10 = 4.3
        expect(stats.averageRating, equals(4.3));
      });

      test('handles empty review list', () {
        final stats = RatingStats.fromReviews([]);

        expect(stats.totalReviews, equals(0));
        expect(stats.averageRating, equals(0.0));
        expect(stats.breakdown[5], equals(0));
        expect(stats.breakdown[4], equals(0));
        expect(stats.breakdown[3], equals(0));
        expect(stats.breakdown[2], equals(0));
        expect(stats.breakdown[1], equals(0));
      });

      test('rounds fractional ratings for breakdown', () {
        final reviews = [
          ReviewFixtures.createReview(id: 1, rating: 4.7), // Rounds to 5
          ReviewFixtures.createReview(id: 2, rating: 4.4), // Rounds to 4
          ReviewFixtures.createReview(id: 3, rating: 3.5), // Rounds to 4
          ReviewFixtures.createReview(id: 4, rating: 2.3), // Rounds to 2
        ];

        final stats = RatingStats.fromReviews(reviews);

        expect(stats.breakdown[5], equals(1));
        expect(stats.breakdown[4], equals(2));
        expect(stats.breakdown[3], equals(0));
        expect(stats.breakdown[2], equals(1));
        expect(stats.breakdown[1], equals(0));
      });

      test('clamps ratings to valid range', () {
        final reviews = [
          ReviewFixtures.createReview(id: 1, rating: 5.5), // Clamps to 5
          ReviewFixtures.createReview(id: 2, rating: 0.5), // Clamps to 1
        ];

        final stats = RatingStats.fromReviews(reviews);

        expect(stats.breakdown[5], equals(1)); // 5.5 rounds to 6, clamps to 5
        expect(stats.breakdown[1], equals(1)); // 0.5 rounds to 1
      });
    });

    group('fromJson', () {
      test('parses JSON correctly', () {
        final json = RatingStatsFixtures.createRatingStatsJson(
          averageRating: 4.2,
          totalReviews: 100,
          breakdown: {'5': 45, '4': 30, '3': 15, '2': 7, '1': 3},
        );

        final stats = RatingStats.fromJson(json);

        expect(stats.averageRating, equals(4.2));
        expect(stats.totalReviews, equals(100));
        expect(stats.breakdown[5], equals(45));
        expect(stats.breakdown[4], equals(30));
        expect(stats.breakdown[3], equals(15));
        expect(stats.breakdown[2], equals(7));
        expect(stats.breakdown[1], equals(3));
      });

      test('handles alternative field names', () {
        final json = {
          'averageRating': 3.8,
          'totalReviews': 50,
          'rating_breakdown': {'5': 10, '4': 20, '3': 10, '2': 5, '1': 5},
        };

        final stats = RatingStats.fromJson(json);

        expect(stats.averageRating, equals(3.8));
        expect(stats.totalReviews, equals(50));
        expect(stats.breakdown[5], equals(10));
      });

      test('handles missing breakdown', () {
        final json = {
          'average_rating': 4.0,
          'total_reviews': 10,
        };

        final stats = RatingStats.fromJson(json);

        expect(stats.averageRating, equals(4.0));
        expect(stats.totalReviews, equals(10));
        expect(stats.breakdown, isEmpty);
      });
    });

    group('toJson', () {
      test('produces valid JSON', () {
        final stats = RatingStatsFixtures.createRatingStats(
          averageRating: 4.5,
          totalReviews: 50,
          breakdown: {5: 25, 4: 15, 3: 5, 2: 3, 1: 2},
        );

        final json = stats.toJson();

        expect(json['average_rating'], equals(4.5));
        expect(json['total_reviews'], equals(50));
        expect(json['breakdown']['5'], equals(25));
        expect(json['breakdown']['4'], equals(15));
      });

      test('round-trip serialization preserves data', () {
        final original = RatingStatsFixtures.createRatingStats(
          averageRating: 4.3,
          totalReviews: 75,
          breakdown: {5: 30, 4: 25, 3: 10, 2: 7, 1: 3},
        );

        final json = original.toJson();
        final restored = RatingStats.fromJson(json);

        expect(restored.averageRating, equals(original.averageRating));
        expect(restored.totalReviews, equals(original.totalReviews));
        expect(restored.breakdown[5], equals(original.breakdown[5]));
        expect(restored.breakdown[4], equals(original.breakdown[4]));
        expect(restored.breakdown[3], equals(original.breakdown[3]));
        expect(restored.breakdown[2], equals(original.breakdown[2]));
        expect(restored.breakdown[1], equals(original.breakdown[1]));
      });
    });

    group('empty', () {
      test('has correct default values', () {
        const stats = RatingStats.empty;

        expect(stats.averageRating, equals(0.0));
        expect(stats.totalReviews, equals(0));
        expect(stats.hasReviews, isFalse);
        expect(stats.formattedRating, equals('0.0'));
      });
    });

    group('toString', () {
      test('returns descriptive string', () {
        final stats = RatingStatsFixtures.createRatingStats(
          averageRating: 4.5,
          totalReviews: 100,
        );

        expect(stats.toString(), equals('RatingStats(average: 4.5, total: 100)'));
      });
    });
  });
}

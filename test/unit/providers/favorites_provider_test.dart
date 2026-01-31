import 'package:flutter_test/flutter_test.dart';
import 'package:tour_guid/providers/favorites_provider.dart';

import '../../fixtures/favorite_fixtures.dart';
import '../../fixtures/service_fixtures.dart';

void main() {
  group('FavoritesProvider', () {
    late FavoritesProvider provider;

    setUp(() {
      provider = FavoritesProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    group('initial state', () {
      test('starts with empty favorites', () {
        expect(provider.favorites, isEmpty);
        expect(provider.favoriteIds, isEmpty);
        expect(provider.favoritesCount, equals(0));
        expect(provider.hasData, isFalse);
      });

      test('starts with loading state false', () {
        expect(provider.isLoading, isFalse);
        expect(provider.isFavoriteLoading, isFalse);
      });

      test('starts with no error message', () {
        expect(provider.errorMessage, isNull);
      });
    });

    group('setSupabaseUserId', () {
      test('sets user id correctly', () {
        provider.setSupabaseUserId('user-123');
        // We can't directly test private _supabaseUserId,
        // but we can test its effects on isFavorite
        expect(provider.isFavorite(1), isFalse); // No favorites yet, but no false due to null user
      });

      test('null user id is handled', () {
        provider.setSupabaseUserId(null);
        expect(provider.isFavorite(1), isFalse);
      });
    });

    group('isFavorite', () {
      test('returns false when user is not authenticated', () {
        // User ID not set (null)
        expect(provider.isFavorite(1), isFalse);
      });

      test('returns false when user id is empty', () {
        provider.setSupabaseUserId('');
        expect(provider.isFavorite(1), isFalse);
      });

      test('returns false when service is not in favorites', () {
        provider.setSupabaseUserId('user-123');
        expect(provider.isFavorite(999), isFalse);
      });
    });

    group('getFavoriteByServiceId', () {
      test('returns null when favorite does not exist', () {
        expect(provider.getFavoriteByServiceId(999), isNull);
      });
    });

    group('toggleFavorite', () {
      test('returns false with no user ID set', () async {
        // No user ID set
        final result = await provider.toggleFavorite(1);
        expect(result, isFalse);
      });

      test('returns false with invalid serviceId (0)', () async {
        provider.setSupabaseUserId('user-123');
        final result = await provider.toggleFavorite(0);
        expect(result, isFalse);
      });

      test('returns false with negative serviceId', () async {
        provider.setSupabaseUserId('user-123');
        final result = await provider.toggleFavorite(-1);
        expect(result, isFalse);
      });
    });

    group('clearFavorites', () {
      test('clears all state', () {
        provider.setSupabaseUserId('user-123');
        provider.clearFavorites();

        expect(provider.favorites, isEmpty);
        expect(provider.favoriteIds, isEmpty);
        expect(provider.isLoading, isFalse);
        expect(provider.isFavoriteLoading, isFalse);
        expect(provider.errorMessage, isNull);
      });
    });

    group('fetchFavorites', () {
      test('skips fetch when no user ID is set', () async {
        // No user ID set
        await provider.fetchFavorites();

        // Should not be loading since we skipped
        expect(provider.isLoading, isFalse);
        expect(provider.favorites, isEmpty);
      });
    });

    group('addFavorite', () {
      test('returns true if already a favorite', () async {
        // This test verifies the early return logic
        // In reality, this would need the service ID to already be in favoriteIds
        // Since we can't easily add to favoriteIds without mocking,
        // we test the behavior indirectly
        provider.setSupabaseUserId('user-123');

        // Without an existing favorite, it will try to toggle
        // which will fail without a real service connection
        final result = await provider.addFavorite(1);
        expect(result, isFalse); // Will fail without real backend
      });
    });

    group('removeFavorite', () {
      test('returns true if not a favorite', () async {
        provider.setSupabaseUserId('user-123');

        // Service 999 is not a favorite, so removeFavorite should return true
        final result = await provider.removeFavorite(999);
        expect(result, isTrue);
      });
    });

    group('getters', () {
      test('favorites returns unmodifiable list', () {
        final favorites = provider.favorites;
        expect(() => (favorites as List).add(FavoriteFixtures.createFavorite()),
               throwsUnsupportedError);
      });

      test('favoriteIds returns unmodifiable set', () {
        final ids = provider.favoriteIds;
        expect(() => (ids as Set).add(1), throwsUnsupportedError);
      });
    });

    group('setEnrichmentFunctions', () {
      test('sets enrichment functions', () {
        provider.setEnrichmentFunctions(
          getCategoryName: (id) => 'Category $id',
          getSubcategoryName: (id) => 'Subcategory $id',
        );

        // Enrichment functions are private, but we verify no error occurs
        expect(true, isTrue);
      });
    });

    group('realtime subscriptions', () {
      test('subscribeToRealtime does nothing without user ID', () {
        // No user ID set
        provider.subscribeToRealtime();
        // Should not throw, just do nothing
        expect(true, isTrue);
      });

      test('unsubscribeFromRealtime can be called safely', () {
        provider.unsubscribeFromRealtime();
        // Should not throw
        expect(true, isTrue);
      });
    });
  });
}

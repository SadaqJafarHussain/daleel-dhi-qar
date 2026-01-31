import 'package:flutter/foundation.dart';
import '../models/favorite.dart';
import '../models/service_model.dart';
import '../config/app_config.dart';
import 'supabase_service.dart';
import 'cache_manager.dart';

/// Favorites service using Supabase with caching
class FavoritesService {
  static final SupabaseService _supabase = SupabaseService();
  static final CacheManager _cache = CacheManager();

  /// Get all favorites for a user
  static Future<FavoritesResponse> getAllFavorites(
    String userId, {
    String? Function(int)? getCategoryName,
    String? Function(int)? getSubcategoryName,
  }) async {
    if (kDebugMode) {
      print('FavoritesService: 🔄 Fetching favorites for user: $userId');
    }

    try {
      // Try cache first
      final cacheKey = 'user_$userId';
      final cached = await _cache.getList('favorites', cacheKey);

      if (cached != null) {
        if (kDebugMode) {
          print('FavoritesService: ✅ Cache hit for favorites');
        }
        return _parseFavoritesResponse(
          cached,
          getCategoryName: getCategoryName,
          getSubcategoryName: getSubcategoryName,
        );
      }

      // Fetch from Supabase
      final data = await _supabase.client
          .from('favorites')
          .select('*, services:service_id(*, service_files(*), profiles!fk_services_user(name, is_verified))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (kDebugMode) {
        print('FavoritesService: 📡 Fetched ${data.length} favorites from Supabase');
      }

      // Cache the result
      await _cache.set(
        'favorites',
        cacheKey,
        List<Map<String, dynamic>>.from(data),
        ttl: AppConfig.favoritesCacheDuration,
      );

      return _parseFavoritesResponse(
        List<Map<String, dynamic>>.from(data),
        getCategoryName: getCategoryName,
        getSubcategoryName: getSubcategoryName,
      );
    } catch (e) {
      if (kDebugMode) {
        print('FavoritesService: ❌ Error fetching favorites: $e');
      }

      // Return empty on error
      return FavoritesResponse(
        status: 'error',
        message: e.toString(),
        favorites: [],
      );
    }
  }

  /// Parse favorites response from raw data
  static FavoritesResponse _parseFavoritesResponse(
    List<Map<String, dynamic>> data, {
    String? Function(int)? getCategoryName,
    String? Function(int)? getSubcategoryName,
  }) {
    final favorites = <Favorite>[];

    for (var item in data) {
      try {
        final serviceData = item['services'];
        if (serviceData != null) {
          // If enrichment functions are provided, add category/subcategory names to the data
          final enrichedData = Map<String, dynamic>.from(serviceData);
          if (getCategoryName != null) {
            enrichedData['cat_name'] = getCategoryName(enrichedData['cat_id'] ?? 0) ?? '';
          }
          if (getSubcategoryName != null) {
            enrichedData['subcat_name'] = getSubcategoryName(enrichedData['subcat_id'] ?? 0) ?? '';
          }

          final service = Service.fromJson(enrichedData);

          favorites.add(Favorite(
            id: item['id'],
            serviceId: item['service_id'],
            service: service,
          ));
        }
      } catch (e) {
        if (kDebugMode) {
          print('FavoritesService: ⚠️ Error parsing favorite item: $e');
        }
      }
    }

    return FavoritesResponse(
      status: 'success',
      message: 'Loaded ${favorites.length} favorites',
      favorites: favorites,
    );
  }

  /// Add a service to favorites
  static Future<bool> addFavorite(int serviceId, String userId) async {
    if (kDebugMode) {
      print('FavoritesService: ➕ Adding favorite for service: $serviceId');
    }

    try {
      // Check if already exists
      final existing = await _supabase.client
          .from('favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('service_id', serviceId)
          .maybeSingle();

      if (existing != null) {
        if (kDebugMode) {
          print('FavoritesService: ℹ️ Already a favorite');
        }
        return true;
      }

      // Insert new favorite
      await _supabase.client.from('favorites').insert({
        'user_id': userId,
        'service_id': serviceId,
      });

      // Invalidate cache
      await _cache.delete('favorites', 'user_$userId');

      if (kDebugMode) {
        print('FavoritesService: ✅ Favorite added successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('FavoritesService: ❌ Error adding favorite: $e');
      }
      return false;
    }
  }

  /// Remove a service from favorites
  static Future<bool> removeFavorite(int serviceId, String userId) async {
    if (kDebugMode) {
      print('FavoritesService: ➖ Removing favorite for service: $serviceId');
    }

    try {
      await _supabase.client
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('service_id', serviceId);

      // Invalidate cache
      await _cache.delete('favorites', 'user_$userId');

      if (kDebugMode) {
        print('FavoritesService: ✅ Favorite removed successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('FavoritesService: ❌ Error removing favorite: $e');
      }
      return false;
    }
  }

  /// Toggle favorite (add if not exists, remove if exists)
  static Future<bool> toggleFavorite(int serviceId, String userId) async {
    if (kDebugMode) {
      print('FavoritesService: 🔄 Toggling favorite for service: $serviceId');
    }

    try {
      // Check if exists
      final existing = await _supabase.client
          .from('favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('service_id', serviceId)
          .maybeSingle();

      if (existing != null) {
        // Remove
        return await removeFavorite(serviceId, userId);
      } else {
        // Add
        return await addFavorite(serviceId, userId);
      }
    } catch (e) {
      if (kDebugMode) {
        print('FavoritesService: ❌ Error toggling favorite: $e');
      }
      return false;
    }
  }

  /// Check if a service is favorited
  static Future<bool> isFavorite(int serviceId, String userId) async {
    try {
      final existing = await _supabase.client
          .from('favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('service_id', serviceId)
          .maybeSingle();

      return existing != null;
    } catch (e) {
      if (kDebugMode) {
        print('FavoritesService: ❌ Error checking favorite: $e');
      }
      return false;
    }
  }

  /// Clear favorites cache for a user
  static Future<void> clearCache(String userId) async {
    await _cache.delete('favorites', 'user_$userId');
  }
}

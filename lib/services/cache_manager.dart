import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/app_config.dart';
import '../models/offline_operation.dart';

/// Manages local caching using Hive for offline support
class CacheManager {
  // Singleton instance
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  // Box names
  static const String _categoriesBox = 'categories_cache';
  static const String _subcategoriesBox = 'subcategories_cache';
  static const String _servicesBox = 'services_cache';
  static const String _favoritesBox = 'favorites_cache';
  static const String _reviewsBox = 'reviews_cache';
  static const String _adsBox = 'ads_cache';
  static const String _profileBox = 'profile_cache';
  static const String _offlineQueueBox = 'offline_queue';
  static const String _metadataBox = 'sync_metadata';

  bool _isInitialized = false;

  /// Initialize Hive and open all boxes
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();

      // Open all cache boxes
      await Future.wait([
        Hive.openBox(_categoriesBox),
        Hive.openBox(_subcategoriesBox),
        Hive.openBox(_servicesBox),
        Hive.openBox(_favoritesBox),
        Hive.openBox(_reviewsBox),
        Hive.openBox(_adsBox),
        Hive.openBox(_profileBox),
        Hive.openBox(_offlineQueueBox),
        Hive.openBox(_metadataBox),
      ]);

      _isInitialized = true;
      debugPrint('CacheManager: Initialized successfully');
    } catch (e) {
      debugPrint('CacheManager: Initialization error: $e');
      rethrow;
    }
  }

  /// Get a box by name - maps simple names to actual box names
  /// Returns null if box is not available (safer than throwing)
  Box? _getBoxSafe(String boxName) {
    final actualBoxName = _mapBoxName(boxName);
    if (!Hive.isBoxOpen(actualBoxName)) {
      debugPrint('CacheManager: Box $actualBoxName not open');
      return null;
    }
    return Hive.box(actualBoxName);
  }

  /// Get a box by name - throws if not available (for critical operations)
  Box _getBox(String boxName) {
    final box = _getBoxSafe(boxName);
    if (box == null) {
      final actualBoxName = _mapBoxName(boxName);
      throw StateError('Box $actualBoxName is not open. Call init() first.');
    }
    return box;
  }

  /// Map simple box names to actual box names
  String _mapBoxName(String boxName) {
    switch (boxName) {
      case 'categories':
        return _categoriesBox;
      case 'subcategories':
        return _subcategoriesBox;
      case 'services':
        return _servicesBox;
      case 'favorites':
        return _favoritesBox;
      case 'reviews':
        return _reviewsBox;
      case 'ads':
        return _adsBox;
      case 'profile':
        return _profileBox;
      case 'offline_queue':
        return _offlineQueueBox;
      case 'metadata':
        return _metadataBox;
      default:
        // If already a full name, return as-is
        return boxName;
    }
  }

  // ========================================
  // GENERIC CACHE OPERATIONS
  // ========================================

  /// Get cached data by key
  Future<T?> get<T>(String boxName, String key) async {
    try {
      final box = _getBoxSafe(boxName);
      if (box == null) return null;
      final cached = box.get(key);

      if (cached == null) return null;

      // Check if it's a cache entry with TTL
      if (cached is Map && cached.containsKey('cached_at')) {
        final entry = CacheEntry<T>.fromJson(
          Map<String, dynamic>.from(cached),
          (data) => data as T,
        );
        if (entry.isExpired) {
          await delete(boxName, key);
          return null;
        }
        return entry.data;
      }

      return cached as T;
    } catch (e) {
      debugPrint('CacheManager: Error getting $key from $boxName: $e');
      return null;
    }
  }

  /// Get cached data as Map
  Future<Map<String, dynamic>?> getMap(String boxName, String key) async {
    try {
      final box = _getBoxSafe(boxName);
      if (box == null) return null;
      final cached = box.get(key);

      if (cached == null) return null;

      final map = Map<String, dynamic>.from(cached as Map);

      // Check if it's a cache entry with TTL
      if (map.containsKey('cached_at') && map.containsKey('data')) {
        final cachedAt = DateTime.parse(map['cached_at'] as String);
        final ttlMs = map['ttl_ms'] as int;
        final ttl = Duration(milliseconds: ttlMs);

        if (DateTime.now().isAfter(cachedAt.add(ttl))) {
          await delete(boxName, key);
          return null;
        }

        return Map<String, dynamic>.from(map['data'] as Map);
      }

      return map;
    } catch (e) {
      debugPrint('CacheManager: Error getting map $key from $boxName: $e');
      return null;
    }
  }

  /// Get cached list
  Future<List<Map<String, dynamic>>?> getList(String boxName, String key) async {
    try {
      final box = _getBoxSafe(boxName);
      if (box == null) return null;
      final cached = box.get(key);

      if (cached == null) return null;

      // Check if it's wrapped in cache entry
      if (cached is Map && cached.containsKey('cached_at')) {
        final map = Map<String, dynamic>.from(cached);
        final cachedAt = DateTime.parse(map['cached_at'] as String);
        final ttlMs = map['ttl_ms'] as int;
        final ttl = Duration(milliseconds: ttlMs);

        if (DateTime.now().isAfter(cachedAt.add(ttl))) {
          await delete(boxName, key);
          return null;
        }

        final data = map['data'] as List;
        return data.map((e) => _deepConvertMap(e as Map)).toList();
      }

      if (cached is List) {
        return cached.map((e) => _deepConvertMap(e as Map)).toList();
      }

      return null;
    } catch (e) {
      debugPrint('CacheManager: Error getting list $key from $boxName: $e');
      return null;
    }
  }

  /// Deep convert a Map to Map<String, dynamic>, handling nested maps and lists
  Map<String, dynamic> _deepConvertMap(Map map) {
    return map.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), _deepConvertMap(value));
      } else if (value is List) {
        return MapEntry(key.toString(), _deepConvertList(value));
      } else {
        return MapEntry(key.toString(), value);
      }
    });
  }

  /// Deep convert a List, handling nested maps
  List _deepConvertList(List list) {
    return list.map((item) {
      if (item is Map) {
        return _deepConvertMap(item);
      } else if (item is List) {
        return _deepConvertList(item);
      } else {
        return item;
      }
    }).toList();
  }

  /// Set cached data with optional TTL
  Future<void> set<T>(
    String boxName,
    String key,
    T value, {
    Duration? ttl,
  }) async {
    try {
      final box = _getBoxSafe(boxName);
      if (box == null) return;

      if (ttl != null) {
        // Wrap in cache entry with TTL
        final entry = {
          'data': value,
          'cached_at': DateTime.now().toIso8601String(),
          'ttl_ms': ttl.inMilliseconds,
        };
        await box.put(key, entry);
      } else {
        await box.put(key, value);
      }
    } catch (e) {
      debugPrint('CacheManager: Error setting $key in $boxName: $e');
    }
  }

  /// Delete cached data by key
  Future<void> delete(String boxName, String key) async {
    try {
      final box = _getBoxSafe(boxName);
      if (box == null) return;
      await box.delete(key);
    } catch (e) {
      debugPrint('CacheManager: Error deleting $key from $boxName: $e');
    }
  }

  /// Clear all data in a box
  Future<void> clearBox(String boxName) async {
    try {
      final box = _getBoxSafe(boxName);
      if (box == null) return;
      await box.clear();
      debugPrint('CacheManager: Cleared $boxName');
    } catch (e) {
      debugPrint('CacheManager: Error clearing $boxName: $e');
    }
  }

  /// Clear all caches
  Future<void> clearAll() async {
    try {
      await Future.wait([
        clearBox(_categoriesBox),
        clearBox(_subcategoriesBox),
        clearBox(_servicesBox),
        clearBox(_favoritesBox),
        clearBox(_reviewsBox),
        clearBox(_adsBox),
        clearBox(_profileBox),
        // Don't clear offline queue or metadata
      ]);
      debugPrint('CacheManager: Cleared all caches');
    } catch (e) {
      debugPrint('CacheManager: Error clearing all: $e');
    }
  }

  /// Check if a key exists and is not expired
  Future<bool> hasValidCache(String boxName, String key) async {
    final cached = await get(boxName, key);
    return cached != null;
  }

  // ========================================
  // ENTITY-SPECIFIC CACHE METHODS
  // ========================================

  // Categories
  Future<List<Map<String, dynamic>>?> getCategories() =>
      getList(_categoriesBox, 'all');

  Future<void> setCategories(List<Map<String, dynamic>> categories) =>
      set(_categoriesBox, 'all', categories, ttl: AppConfig.categoryCacheDuration);

  // Subcategories
  Future<List<Map<String, dynamic>>?> getSubcategories() =>
      getList(_subcategoriesBox, 'all');

  Future<void> setSubcategories(List<Map<String, dynamic>> subcategories) =>
      set(_subcategoriesBox, 'all', subcategories, ttl: AppConfig.subcategoryCacheDuration);

  Future<List<Map<String, dynamic>>?> getSubcategoriesByCategory(int catId) =>
      getList(_subcategoriesBox, 'cat_$catId');

  Future<void> setSubcategoriesByCategory(int catId, List<Map<String, dynamic>> subcategories) =>
      set(_subcategoriesBox, 'cat_$catId', subcategories, ttl: AppConfig.subcategoryCacheDuration);

  // Services
  Future<List<Map<String, dynamic>>?> getServices({int? categoryId, int? subcategoryId}) {
    String key = 'all';
    if (categoryId != null) key = 'cat_$categoryId';
    if (subcategoryId != null) key = 'subcat_$subcategoryId';
    return getList(_servicesBox, key);
  }

  Future<void> setServices(
    List<Map<String, dynamic>> services, {
    int? categoryId,
    int? subcategoryId,
  }) {
    String key = 'all';
    if (categoryId != null) key = 'cat_$categoryId';
    if (subcategoryId != null) key = 'subcat_$subcategoryId';
    return set(_servicesBox, key, services, ttl: AppConfig.serviceCacheDuration);
  }

  Future<Map<String, dynamic>?> getService(int id) =>
      getMap(_servicesBox, 'service_$id');

  Future<void> setService(int id, Map<String, dynamic> service) =>
      set(_servicesBox, 'service_$id', service, ttl: AppConfig.serviceCacheDuration);

  Future<List<Map<String, dynamic>>?> getNearbyServices(double lat, double lng) {
    // Round coordinates to create cache key
    final latKey = lat.toStringAsFixed(2);
    final lngKey = lng.toStringAsFixed(2);
    return getList(_servicesBox, 'nearby_${latKey}_$lngKey');
  }

  Future<void> setNearbyServices(double lat, double lng, List<Map<String, dynamic>> services) {
    final latKey = lat.toStringAsFixed(2);
    final lngKey = lng.toStringAsFixed(2);
    return set(_servicesBox, 'nearby_${latKey}_$lngKey', services, ttl: AppConfig.nearbyCacheDuration);
  }

  // Favorites
  Future<List<Map<String, dynamic>>?> getFavorites(String userId) =>
      getList(_favoritesBox, 'user_$userId');

  Future<void> setFavorites(String userId, List<Map<String, dynamic>> favorites) =>
      set(_favoritesBox, 'user_$userId', favorites, ttl: AppConfig.favoritesCacheDuration);

  // Reviews
  Future<List<Map<String, dynamic>>?> getReviews(int serviceId) =>
      getList(_reviewsBox, 'service_$serviceId');

  Future<void> setReviews(int serviceId, List<Map<String, dynamic>> reviews) =>
      set(_reviewsBox, 'service_$serviceId', reviews, ttl: AppConfig.reviewsCacheDuration);

  // Ads
  Future<List<Map<String, dynamic>>?> getAds() =>
      getList(_adsBox, 'all');

  Future<void> setAds(List<Map<String, dynamic>> ads) =>
      set(_adsBox, 'all', ads, ttl: AppConfig.adsCacheDuration);

  // User Profile
  Future<Map<String, dynamic>?> getProfile(String userId) =>
      getMap(_profileBox, userId);

  Future<void> setProfile(String userId, Map<String, dynamic> profile) =>
      set(_profileBox, userId, profile, ttl: AppConfig.profileCacheDuration);

  // ========================================
  // OFFLINE QUEUE OPERATIONS
  // ========================================

  /// Add operation to offline queue
  Future<void> addToOfflineQueue(OfflineOperation operation) async {
    try {
      final box = _getBoxSafe(_offlineQueueBox);
      if (box == null) {
        debugPrint('CacheManager: Cannot add to offline queue - box not available');
        return;
      }
      final queue = await getOfflineQueue();

      // Fix #18: Proper boundary validation - remove oldest items if at capacity
      if (queue.length >= AppConfig.maxOfflineQueueSize) {
        debugPrint('CacheManager: Offline queue full, removing oldest');
        // Remove oldest operations until we're under capacity
        final toRemove = queue.length - AppConfig.maxOfflineQueueSize + 1;
        for (int i = 0; i < toRemove && i < queue.length; i++) {
          await box.delete(queue[i].id);
        }
      }

      await box.put(operation.id, operation.toJson());
      debugPrint('CacheManager: Added to offline queue: ${operation.id}');
    } catch (e) {
      debugPrint('CacheManager: Error adding to offline queue: $e');
    }
  }

  /// Get all pending offline operations
  Future<List<OfflineOperation>> getOfflineQueue() async {
    try {
      final box = _getBoxSafe(_offlineQueueBox);
      if (box == null) return [];
      final operations = <OfflineOperation>[];

      for (final key in box.keys) {
        try {
          final json = box.get(key);
          if (json != null && json is Map) {
            operations.add(OfflineOperation.fromJson(Map<String, dynamic>.from(json)));
          }
        } catch (e) {
          debugPrint('CacheManager: Error parsing offline operation $key: $e');
          // Remove corrupted entry
          await box.delete(key);
        }
      }

      // Sort by creation time
      operations.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return operations;
    } catch (e) {
      debugPrint('CacheManager: Error getting offline queue: $e');
      return [];
    }
  }

  /// Remove operation from offline queue
  Future<void> removeFromOfflineQueue(String operationId) async {
    try {
      final box = _getBoxSafe(_offlineQueueBox);
      if (box == null) return;
      await box.delete(operationId);
      debugPrint('CacheManager: Removed from offline queue: $operationId');
    } catch (e) {
      debugPrint('CacheManager: Error removing from offline queue: $e');
    }
  }

  /// Update offline operation (e.g., increment retry count)
  Future<void> updateOfflineOperation(OfflineOperation operation) async {
    try {
      final box = _getBoxSafe(_offlineQueueBox);
      if (box == null) return;
      await box.put(operation.id, operation.toJson());
    } catch (e) {
      debugPrint('CacheManager: Error updating offline operation: $e');
    }
  }

  /// Clear offline queue
  Future<void> clearOfflineQueue() async {
    await clearBox(_offlineQueueBox);
  }

  /// Get offline queue size
  Future<int> getOfflineQueueSize() async {
    final box = _getBoxSafe(_offlineQueueBox);
    return box?.length ?? 0;
  }

  // ========================================
  // SYNC METADATA OPERATIONS
  // ========================================

  /// Get last sync time for an entity
  Future<DateTime?> getLastSyncTime(String entity) async {
    try {
      final box = _getBox(_metadataBox);
      final json = box.get('sync_$entity');
      if (json == null) return null;

      final metadata = SyncMetadata.fromJson(Map<String, dynamic>.from(json as Map));
      return metadata.lastSyncTime;
    } catch (e) {
      debugPrint('CacheManager: Error getting last sync time: $e');
      return null;
    }
  }

  /// Set last sync time for an entity
  Future<void> setLastSyncTime(String entity, DateTime time) async {
    try {
      final box = _getBox(_metadataBox);
      final metadata = SyncMetadata(
        entity: entity,
        lastSyncTime: time,
        status: SyncStatus.success,
      );
      await box.put('sync_$entity', metadata.toJson());
    } catch (e) {
      debugPrint('CacheManager: Error setting last sync time: $e');
    }
  }

  /// Get sync metadata for an entity
  Future<SyncMetadata?> getSyncMetadata(String entity) async {
    try {
      final box = _getBox(_metadataBox);
      final json = box.get('sync_$entity');
      if (json == null) return null;

      return SyncMetadata.fromJson(Map<String, dynamic>.from(json as Map));
    } catch (e) {
      debugPrint('CacheManager: Error getting sync metadata: $e');
      return null;
    }
  }

  /// Update sync metadata
  Future<void> updateSyncMetadata(SyncMetadata metadata) async {
    try {
      final box = _getBox(_metadataBox);
      await box.put('sync_${metadata.entity}', metadata.toJson());
    } catch (e) {
      debugPrint('CacheManager: Error updating sync metadata: $e');
    }
  }

  // ========================================
  // BOX NAME GETTERS (for external access)
  // ========================================

  static String get categoriesBoxName => _categoriesBox;
  static String get subcategoriesBoxName => _subcategoriesBox;
  static String get servicesBoxName => _servicesBox;
  static String get favoritesBoxName => _favoritesBox;
  static String get reviewsBoxName => _reviewsBox;
  static String get adsBoxName => _adsBox;
  static String get profileBoxName => _profileBox;
}

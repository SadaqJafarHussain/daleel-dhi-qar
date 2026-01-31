import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../models/service_model.dart';
import '../models/review_model.dart';
import '../models/favorite.dart';
import '../models/subcategory_model.dart';
import 'supabase_service.dart';

/// Service for managing real-time subscriptions to Supabase
class RealtimeService {
  // Singleton instance
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  final SupabaseService _supabase = SupabaseService();
  final Map<String, RealtimeChannel> _channels = {};

  /// Check if a channel is active
  bool isChannelActive(String channelName) => _channels.containsKey(channelName);

  // ========================================
  // SERVICES SUBSCRIPTION
  // ========================================

  /// Subscribe to all services changes
  void subscribeToServices({
    int? categoryId,
    required void Function(Service service) onInsert,
    required void Function(Service service) onUpdate,
    required void Function(int id) onDelete,
  }) {
    if (!AppConfig.enableRealtime) return;

    final channelName = categoryId != null
        ? 'services_cat_$categoryId'
        : 'services_all';

    // Unsubscribe if already subscribed
    if (_channels.containsKey(channelName)) {
      _unsubscribe(channelName);
    }

    final filter = categoryId != null
        ? PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'cat_id', value: categoryId)
        : null;

    final channel = _supabase.client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'services',
          filter: filter,
          callback: (payload) {
            debugPrint('RealtimeService: Service inserted: ${payload.newRecord}');
            try {
              final service = Service.fromJson(payload.newRecord);
              onInsert(service);
            } catch (e) {
              debugPrint('RealtimeService: Error parsing inserted service: $e');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'services',
          filter: filter,
          callback: (payload) {
            debugPrint('RealtimeService: Service updated: ${payload.newRecord}');
            try {
              final service = Service.fromJson(payload.newRecord);
              onUpdate(service);
            } catch (e) {
              debugPrint('RealtimeService: Error parsing updated service: $e');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'services',
          filter: filter,
          callback: (payload) {
            debugPrint('RealtimeService: Service deleted: ${payload.oldRecord}');
            final id = payload.oldRecord['id'];
            if (id != null) {
              onDelete(int.tryParse(id.toString()) ?? 0);
            }
          },
        )
        .subscribe();

    _channels[channelName] = channel;
    debugPrint('RealtimeService: Subscribed to services ($channelName)');
  }

  /// Subscribe to a specific service for live updates
  void subscribeToService({
    required int serviceId,
    required void Function(Service service) onUpdate,
    required void Function() onDelete,
  }) {
    if (!AppConfig.enableRealtime) return;

    final channelName = 'service_$serviceId';

    if (_channels.containsKey(channelName)) {
      _unsubscribe(channelName);
    }

    final filter = PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'id',
      value: serviceId,
    );

    final channel = _supabase.client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'services',
          filter: filter,
          callback: (payload) {
            debugPrint('RealtimeService: Service $serviceId updated');
            try {
              final service = Service.fromJson(payload.newRecord);
              onUpdate(service);
            } catch (e) {
              debugPrint('RealtimeService: Error parsing service update: $e');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'services',
          filter: filter,
          callback: (payload) {
            debugPrint('RealtimeService: Service $serviceId deleted');
            onDelete();
          },
        )
        .subscribe();

    _channels[channelName] = channel;
    debugPrint('RealtimeService: Subscribed to service $serviceId');
  }

  // ========================================
  // REVIEWS SUBSCRIPTION
  // ========================================

  /// Subscribe to reviews for a specific service
  void subscribeToReviews({
    required int serviceId,
    required void Function(Review review) onInsert,
    required void Function(Review review) onUpdate,
    required void Function(int id) onDelete,
  }) {
    if (!AppConfig.enableRealtime) return;

    final channelName = 'reviews_service_$serviceId';

    if (_channels.containsKey(channelName)) {
      _unsubscribe(channelName);
    }

    final filter = PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'service_id',
      value: serviceId,
    );

    final channel = _supabase.client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'reviews',
          filter: filter,
          callback: (payload) {
            debugPrint('RealtimeService: Review inserted for service $serviceId');
            try {
              final review = Review.fromJson(payload.newRecord);
              onInsert(review);
            } catch (e) {
              debugPrint('RealtimeService: Error parsing inserted review: $e');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'reviews',
          filter: filter,
          callback: (payload) {
            debugPrint('RealtimeService: Review updated for service $serviceId');
            try {
              final review = Review.fromJson(payload.newRecord);
              onUpdate(review);
            } catch (e) {
              debugPrint('RealtimeService: Error parsing updated review: $e');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'reviews',
          filter: filter,
          callback: (payload) {
            debugPrint('RealtimeService: Review deleted for service $serviceId');
            final id = payload.oldRecord['id'];
            if (id != null) {
              onDelete(int.tryParse(id.toString()) ?? 0);
            }
          },
        )
        .subscribe();

    _channels[channelName] = channel;
    debugPrint('RealtimeService: Subscribed to reviews for service $serviceId');
  }

  // ========================================
  // FAVORITES SUBSCRIPTION
  // ========================================

  /// Subscribe to favorites changes for a user
  void subscribeToFavorites({
    required String odUserId,
    required void Function(Favorite favorite) onInsert,
    required void Function(int favoriteId, int serviceId) onDelete,
  }) {
    if (!AppConfig.enableRealtime) return;

    final channelName = 'favorites_user_$odUserId';

    if (_channels.containsKey(channelName)) {
      _unsubscribe(channelName);
    }

    final filter = PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'user_id',
      value: odUserId,
    );

    final channel = _supabase.client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'favorites',
          filter: filter,
          callback: (payload) {
            debugPrint('RealtimeService: Favorite added');
            try {
              final favorite = Favorite.fromJson(payload.newRecord);
              onInsert(favorite);
            } catch (e) {
              debugPrint('RealtimeService: Error parsing inserted favorite: $e');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'favorites',
          filter: filter,
          callback: (payload) {
            debugPrint('RealtimeService: Favorite removed');
            final id = payload.oldRecord['id'];
            final serviceId = payload.oldRecord['service_id'];
            if (id != null && serviceId != null) {
              onDelete(
                int.tryParse(id.toString()) ?? 0,
                int.tryParse(serviceId.toString()) ?? 0,
              );
            }
          },
        )
        .subscribe();

    _channels[channelName] = channel;
    debugPrint('RealtimeService: Subscribed to favorites for user $odUserId');
  }

  // ========================================
  // SUBCATEGORIES SUBSCRIPTION
  // ========================================

  /// Subscribe to subcategories changes
  void subscribeToSubcategories({
    required void Function(Subcategory subcategory) onInsert,
    required void Function(Subcategory subcategory) onUpdate,
    required void Function(int id) onDelete,
  }) {
    if (!AppConfig.enableRealtime) return;

    const channelName = 'subcategories_all';

    if (_channels.containsKey(channelName)) {
      _unsubscribe(channelName);
    }

    final channel = _supabase.client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'subcategories',
          callback: (payload) {
            debugPrint('RealtimeService: Subcategory inserted: ${payload.newRecord}');
            try {
              final subcategory = Subcategory.fromJson(payload.newRecord);
              onInsert(subcategory);
            } catch (e) {
              debugPrint('RealtimeService: Error parsing inserted subcategory: $e');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'subcategories',
          callback: (payload) {
            debugPrint('RealtimeService: Subcategory updated: ${payload.newRecord}');
            try {
              final subcategory = Subcategory.fromJson(payload.newRecord);
              onUpdate(subcategory);
            } catch (e) {
              debugPrint('RealtimeService: Error parsing updated subcategory: $e');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'subcategories',
          callback: (payload) {
            debugPrint('RealtimeService: Subcategory deleted: ${payload.oldRecord}');
            final id = payload.oldRecord['id'];
            if (id != null) {
              onDelete(int.tryParse(id.toString()) ?? 0);
            }
          },
        )
        .subscribe();

    _channels[channelName] = channel;
    debugPrint('RealtimeService: Subscribed to subcategories');
  }

  /// Unsubscribe from subcategories channel
  void unsubscribeFromSubcategories() {
    _unsubscribe('subcategories_all');
  }

  // ========================================
  // CATEGORIES SUBSCRIPTION
  // ========================================

  /// Subscribe to categories changes (for admin updates)
  void subscribeToCategories({
    required void Function() onAnyChange,
  }) {
    if (!AppConfig.enableRealtime) return;

    const channelName = 'categories_all';

    if (_channels.containsKey(channelName)) {
      _unsubscribe(channelName);
    }

    final channel = _supabase.client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'categories',
          callback: (payload) {
            debugPrint('RealtimeService: Categories changed');
            onAnyChange();
          },
        )
        .subscribe();

    _channels[channelName] = channel;
    debugPrint('RealtimeService: Subscribed to categories');
  }

  // ========================================
  // ADS SUBSCRIPTION
  // ========================================

  /// Subscribe to ads changes
  void subscribeToAds({
    required void Function() onAnyChange,
  }) {
    if (!AppConfig.enableRealtime) return;

    const channelName = 'ads_all';

    if (_channels.containsKey(channelName)) {
      _unsubscribe(channelName);
    }

    final channel = _supabase.client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'ads',
          callback: (payload) {
            debugPrint('RealtimeService: Ads changed');
            onAnyChange();
          },
        )
        .subscribe();

    _channels[channelName] = channel;
    debugPrint('RealtimeService: Subscribed to ads');
  }

  /// Unsubscribe from ads channel
  void unsubscribeFromAds() {
    _unsubscribe('ads_all');
  }

  // ========================================
  // PROFILES SUBSCRIPTION
  // ========================================

  /// Subscribe to profiles changes (for verification status updates)
  void subscribeToProfiles({
    required void Function(String odUserId, bool isVerified) onVerificationChanged,
  }) {
    if (!AppConfig.enableRealtime) return;

    const channelName = 'profiles_verification';

    if (_channels.containsKey(channelName)) {
      _unsubscribe(channelName);
    }

    final channel = _supabase.client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          callback: (payload) {
            debugPrint('RealtimeService: Profile updated: ${payload.newRecord}');
            try {
              final userId = payload.newRecord['id']?.toString();
              final rawVerified = payload.newRecord['is_verified'];
              final isVerified = rawVerified == true ||
                                 rawVerified == 1 ||
                                 rawVerified == '1' ||
                                 rawVerified == 'true';
              debugPrint('RealtimeService: Profile verification - userId: $userId, rawVerified: $rawVerified, isVerified: $isVerified');
              if (userId != null) {
                onVerificationChanged(userId, isVerified);
              }
            } catch (e) {
              debugPrint('RealtimeService: Error parsing profile update: $e');
            }
          },
        )
        .subscribe();

    _channels[channelName] = channel;
    debugPrint('RealtimeService: Subscribed to profiles verification');
  }

  /// Unsubscribe from profiles channel
  void unsubscribeFromProfiles() {
    _unsubscribe('profiles_verification');
  }

  // ========================================
  // SUBSCRIPTION MANAGEMENT
  // ========================================

  /// Unsubscribe from a specific channel
  void unsubscribe(String channelName) {
    _unsubscribe(channelName);
  }

  /// Internal unsubscribe
  void _unsubscribe(String channelName) {
    final channel = _channels.remove(channelName);
    if (channel != null) {
      _supabase.client.removeChannel(channel);
      debugPrint('RealtimeService: Unsubscribed from $channelName');
    }
  }

  /// Unsubscribe from all channels
  void unsubscribeAll() {
    for (final channelName in _channels.keys.toList()) {
      _unsubscribe(channelName);
    }
    debugPrint('RealtimeService: Unsubscribed from all channels');
  }

  /// Unsubscribe from service-related channels
  void unsubscribeFromServices() {
    final serviceChannels = _channels.keys
        .where((name) => name.startsWith('services_') || name.startsWith('service_'))
        .toList();

    for (final channelName in serviceChannels) {
      _unsubscribe(channelName);
    }
  }

  /// Unsubscribe from review-related channels
  void unsubscribeFromReviews() {
    final reviewChannels = _channels.keys
        .where((name) => name.startsWith('reviews_'))
        .toList();

    for (final channelName in reviewChannels) {
      _unsubscribe(channelName);
    }
  }

  /// Unsubscribe from favorite-related channels
  void unsubscribeFromFavorites() {
    final favoriteChannels = _channels.keys
        .where((name) => name.startsWith('favorites_'))
        .toList();

    for (final channelName in favoriteChannels) {
      _unsubscribe(channelName);
    }
  }

  /// Get list of active channel names
  List<String> get activeChannels => _channels.keys.toList();

  /// Get count of active channels
  int get activeChannelCount => _channels.length;
}

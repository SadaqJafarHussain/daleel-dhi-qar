import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../models/offline_operation.dart';
import 'cache_manager.dart';
import 'connectivity_service.dart';

/// Core Supabase service wrapper with caching support
class SupabaseService {
  // Singleton instance
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late final SupabaseClient _client;
  final CacheManager _cache = CacheManager();
  final ConnectivityService _connectivity = ConnectivityService();
  bool _isInitialized = false;

  /// Default timeout for database operations
  static const Duration _defaultTimeout = Duration(seconds: 30);

  /// Get the Supabase client
  SupabaseClient get client => _client;

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Initialize Supabase
  Future<void> init() async {
    if (_isInitialized) return;

    if (!AppConfig.isSupabaseConfigured) {
      debugPrint('SupabaseService: Supabase not configured, skipping init');
      return;
    }

    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          eventsPerSecond: 2,
        ),
      );

      _client = Supabase.instance.client;
      await _cache.init();

      _isInitialized = true;
      debugPrint('SupabaseService: Initialized successfully');
    } catch (e) {
      debugPrint('SupabaseService: Initialization error: $e');
      rethrow;
    }
  }

  // ========================================
  // AUTH SHORTCUTS
  // ========================================

  /// Get current auth user
  User? get currentUser => _client.auth.currentUser;

  /// Get current session
  Session? get currentSession => _client.auth.currentSession;

  /// Auth state changes stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // ========================================
  // DATABASE OPERATIONS WITH CACHING
  // ========================================

  /// Fetch data with cache support
  Future<List<Map<String, dynamic>>> fetchWithCache({
    required String table,
    required String cacheKey,
    required String cacheBox,
    Duration? cacheDuration,
    String? select,
    Map<String, dynamic>? eq,
    Map<String, dynamic>? neq,
    String? orderBy,
    bool ascending = true,
    int? limit,
    bool forceRefresh = false,
  }) async {
    // Check cache first (if not forcing refresh)
    if (!forceRefresh) {
      final cached = await _cache.getList(cacheBox, cacheKey);
      if (cached != null) {
        debugPrint('SupabaseService: Cache hit for $cacheKey');
        return cached;
      }
    }

    // Check connectivity using singleton instance
    final isOnline = _connectivity.isOnline;
    if (!isOnline) {
      // Return cached data if available, even if expired
      final cached = await _cache.getList(cacheBox, cacheKey);
      if (cached != null) {
        debugPrint('SupabaseService: Offline, returning cached $cacheKey');
        return cached;
      }
      throw Exception('OFFLINE_NO_CACHE');
    }

    try {
      // Build query
      PostgrestFilterBuilder query = _client.from(table).select(select ?? '*');

      // Apply filters
      if (eq != null) {
        eq.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      if (neq != null) {
        neq.forEach((key, value) {
          query = query.neq(key, value);
        });
      }

      // Apply ordering and limit - these return PostgrestTransformBuilder
      PostgrestTransformBuilder finalQuery = query;
      if (orderBy != null) {
        finalQuery = finalQuery.order(orderBy, ascending: ascending);
      }
      if (limit != null) {
        finalQuery = finalQuery.limit(limit);
      }

      // Execute with timeout
      final response = await finalQuery.timeout(_defaultTimeout);
      final data = List<Map<String, dynamic>>.from(response);

      // Cache the result
      await _cache.set(
        cacheBox,
        cacheKey,
        data,
        ttl: cacheDuration ?? AppConfig.serviceCacheDuration,
      );

      debugPrint('SupabaseService: Fetched and cached $cacheKey (${data.length} items)');
      return data;
    } catch (e) {
      debugPrint('SupabaseService: Error fetching $cacheKey: $e');

      // Try to return cached data on error
      final cached = await _cache.getList(cacheBox, cacheKey);
      if (cached != null) {
        debugPrint('SupabaseService: Error occurred, returning cached $cacheKey');
        return cached;
      }

      rethrow;
    }
  }

  /// Fetch single item by ID
  Future<Map<String, dynamic>?> fetchById({
    required String table,
    required dynamic id,
    String idColumn = 'id',
    String? select,
    String? cacheBox,
    String? cacheKey,
    Duration? cacheDuration,
  }) async {
    // Check cache
    if (cacheBox != null && cacheKey != null) {
      final cached = await _cache.getMap(cacheBox, cacheKey);
      if (cached != null) return cached;
    }

    try {
      final response = await _client
          .from(table)
          .select(select ?? '*')
          .eq(idColumn, id)
          .maybeSingle();

      if (response != null && cacheBox != null && cacheKey != null) {
        await _cache.set(cacheBox, cacheKey, response, ttl: cacheDuration);
      }

      return response;
    } catch (e) {
      debugPrint('SupabaseService: Error fetching $table by $idColumn=$id: $e');

      // Return cached on error
      if (cacheBox != null && cacheKey != null) {
        return await _cache.getMap(cacheBox, cacheKey);
      }
      rethrow;
    }
  }

  // ========================================
  // CRUD OPERATIONS WITH OFFLINE SUPPORT
  // ========================================

  /// Insert data (with offline queue support)
  Future<Map<String, dynamic>> insert({
    required String table,
    required Map<String, dynamic> data,
    String? select,
  }) async {
    final isOnline = await ConnectivityService().checkConnectivity();

    if (!isOnline) {
      // Queue for later sync
      await _cache.addToOfflineQueue(OfflineOperation(
        type: OperationType.insert,
        table: table,
        data: data,
      ));
      // Return optimistic result with temp ID
      return {...data, 'id': 'temp_${DateTime.now().millisecondsSinceEpoch}'};
    }

    try {
      final response = await _client
          .from(table)
          .insert(data)
          .select(select ?? '*')
          .single();

      return response;
    } catch (e) {
      debugPrint('SupabaseService: Error inserting into $table: $e');

      // Queue for later if network error
      if (e.toString().contains('network') || e.toString().contains('socket')) {
        await _cache.addToOfflineQueue(OfflineOperation(
          type: OperationType.insert,
          table: table,
          data: data,
        ));
        return {...data, 'id': 'temp_${DateTime.now().millisecondsSinceEpoch}'};
      }

      rethrow;
    }
  }

  /// Update data (with offline queue support)
  Future<Map<String, dynamic>> update({
    required String table,
    required dynamic id,
    required Map<String, dynamic> data,
    String idColumn = 'id',
    String? select,
  }) async {
    final isOnline = await ConnectivityService().checkConnectivity();

    if (!isOnline) {
      await _cache.addToOfflineQueue(OfflineOperation(
        type: OperationType.update,
        table: table,
        data: {...data, idColumn: id},
      ));
      return {...data, idColumn: id};
    }

    try {
      final response = await _client
          .from(table)
          .update(data)
          .eq(idColumn, id)
          .select(select ?? '*')
          .single();

      return response;
    } catch (e) {
      debugPrint('SupabaseService: Error updating $table: $e');

      if (e.toString().contains('network') || e.toString().contains('socket')) {
        await _cache.addToOfflineQueue(OfflineOperation(
          type: OperationType.update,
          table: table,
          data: {...data, idColumn: id},
        ));
        return {...data, idColumn: id};
      }

      rethrow;
    }
  }

  /// Upsert data
  Future<Map<String, dynamic>> upsert({
    required String table,
    required Map<String, dynamic> data,
    String? onConflict,
    String? select,
  }) async {
    final isOnline = await ConnectivityService().checkConnectivity();

    if (!isOnline) {
      await _cache.addToOfflineQueue(OfflineOperation(
        type: OperationType.upsert,
        table: table,
        data: data,
      ));
      return data;
    }

    try {
      final response = await _client
          .from(table)
          .upsert(data, onConflict: onConflict)
          .select(select ?? '*')
          .single();

      return response;
    } catch (e) {
      debugPrint('SupabaseService: Error upserting $table: $e');
      rethrow;
    }
  }

  /// Delete data (with offline queue support)
  Future<void> delete({
    required String table,
    required dynamic id,
    String idColumn = 'id',
  }) async {
    final isOnline = await ConnectivityService().checkConnectivity();

    if (!isOnline) {
      await _cache.addToOfflineQueue(OfflineOperation(
        type: OperationType.delete,
        table: table,
        data: {idColumn: id},
      ));
      return;
    }

    try {
      await _client.from(table).delete().eq(idColumn, id);
    } catch (e) {
      debugPrint('SupabaseService: Error deleting from $table: $e');

      if (e.toString().contains('network') || e.toString().contains('socket')) {
        await _cache.addToOfflineQueue(OfflineOperation(
          type: OperationType.delete,
          table: table,
          data: {idColumn: id},
        ));
        return;
      }

      rethrow;
    }
  }

  // ========================================
  // REAL-TIME SUBSCRIPTIONS
  // ========================================

  /// Subscribe to table changes
  RealtimeChannel subscribeToTable({
    required String table,
    required String channelName,
    PostgresChangeEvent? event,
    String? schema,
    PostgresChangeFilter? filter,
    required void Function(PostgresChangePayload payload) callback,
  }) {
    final channel = _client
        .channel(channelName)
        .onPostgresChanges(
          event: event ?? PostgresChangeEvent.all,
          schema: schema ?? 'public',
          table: table,
          filter: filter,
          callback: callback,
        )
        .subscribe();

    debugPrint('SupabaseService: Subscribed to $table changes on channel $channelName');
    return channel;
  }

  /// Unsubscribe from channel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
    debugPrint('SupabaseService: Unsubscribed from channel');
  }

  /// Unsubscribe all channels
  Future<void> unsubscribeAll() async {
    await _client.removeAllChannels();
    debugPrint('SupabaseService: Unsubscribed from all channels');
  }

  // ========================================
  // RPC (Remote Procedure Calls)
  // ========================================

  /// Call a Postgres function
  Future<dynamic> rpc(String functionName, {Map<String, dynamic>? params}) async {
    try {
      final response = await _client.rpc(functionName, params: params);
      return response;
    } catch (e) {
      debugPrint('SupabaseService: Error calling RPC $functionName: $e');
      rethrow;
    }
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  /// Invalidate cache for a specific key
  Future<void> invalidateCache(String box, String key) async {
    await _cache.delete(box, key);
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    await _cache.clearAll();
  }

  /// Get pending offline operations count
  Future<int> getPendingOperationsCount() async {
    return await _cache.getOfflineQueueSize();
  }
}

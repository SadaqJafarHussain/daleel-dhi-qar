import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/offline_operation.dart';
import 'cache_manager.dart';
import 'connectivity_service.dart';
import 'supabase_service.dart';

/// Service for syncing offline operations when back online
class SyncService {
  // Singleton instance
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final CacheManager _cache = CacheManager();
  final SupabaseService _supabase = SupabaseService();
  final ConnectivityService _connectivity = ConnectivityService();

  Timer? _syncTimer;
  bool _isSyncing = false;
  StreamSubscription<bool>? _connectivitySubscription;

  // Stream controller for sync status
  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();

  /// Stream of sync status changes
  Stream<SyncStatus> get onSyncStatusChanged => _statusController.stream;

  /// Current sync status
  SyncStatus _currentStatus = SyncStatus.idle;
  SyncStatus get currentStatus => _currentStatus;

  /// Initialize sync service
  Future<void> init() async {
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (isOnline) {
        if (isOnline) {
          debugPrint('SyncService: Connection restored, starting sync');
          syncOfflineQueue();
        }
      },
    );

    // Start periodic sync timer
    _startSyncTimer();

    // Initial sync if online
    if (_connectivity.isOnline) {
      await syncOfflineQueue();
    }

    debugPrint('SyncService: Initialized');
  }

  /// Start periodic sync timer
  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      AppConfig.syncRetryInterval,
      (_) async {
        if (_connectivity.isOnline && !_isSyncing) {
          await syncOfflineQueue();
        }
      },
    );
  }

  /// Process all pending offline operations
  Future<SyncResult> syncOfflineQueue() async {
    if (_isSyncing) {
      debugPrint('SyncService: Already syncing, skipping');
      return SyncResult(success: 0, failed: 0, pending: 0);
    }

    if (!_connectivity.isOnline) {
      debugPrint('SyncService: Offline, cannot sync');
      return SyncResult(success: 0, failed: 0, pending: await _cache.getOfflineQueueSize());
    }

    _isSyncing = true;
    _updateStatus(SyncStatus.syncing);

    int successCount = 0;
    int failedCount = 0;

    try {
      final queue = await _cache.getOfflineQueue();

      if (queue.isEmpty) {
        debugPrint('SyncService: No pending operations');
        _updateStatus(SyncStatus.success);
        return SyncResult(success: 0, failed: 0, pending: 0);
      }

      debugPrint('SyncService: Processing ${queue.length} offline operations');

      for (final operation in queue) {
        try {
          await _processOperation(operation);
          await _cache.removeFromOfflineQueue(operation.id);
          successCount++;
          debugPrint('SyncService: Processed operation ${operation.id}');
        } catch (e) {
          debugPrint('SyncService: Failed to process ${operation.id}: $e');

          // Increment retry count
          final updatedOp = operation.copyWith(
            retryCount: operation.retryCount + 1,
            errorMessage: e.toString(),
          );

          if (updatedOp.retryCount >= AppConfig.maxRetryAttempts) {
            // Max retries reached, remove from queue
            debugPrint('SyncService: Max retries reached for ${operation.id}, removing');
            await _cache.removeFromOfflineQueue(operation.id);
            failedCount++;
          } else {
            // Update retry count
            await _cache.updateOfflineOperation(updatedOp);
          }
        }
      }

      final pending = await _cache.getOfflineQueueSize();
      _updateStatus(failedCount > 0 ? SyncStatus.error : SyncStatus.success);

      debugPrint('SyncService: Sync complete - success: $successCount, failed: $failedCount, pending: $pending');

      return SyncResult(
        success: successCount,
        failed: failedCount,
        pending: pending,
      );
    } catch (e) {
      debugPrint('SyncService: Sync error: $e');
      _updateStatus(SyncStatus.error);
      return SyncResult(
        success: successCount,
        failed: failedCount,
        pending: await _cache.getOfflineQueueSize(),
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Process a single offline operation
  Future<void> _processOperation(OfflineOperation operation) async {
    switch (operation.type) {
      case OperationType.insert:
        await _supabase.client
            .from(operation.table)
            .insert(operation.data);
        break;

      case OperationType.update:
        final id = operation.data['id'];
        if (id == null) throw Exception('Missing ID for update');

        final data = Map<String, dynamic>.from(operation.data);
        data.remove('id');

        await _supabase.client
            .from(operation.table)
            .update(data)
            .eq('id', id);
        break;

      case OperationType.delete:
        final id = operation.data['id'];
        if (id == null) throw Exception('Missing ID for delete');

        await _supabase.client
            .from(operation.table)
            .delete()
            .eq('id', id);
        break;

      case OperationType.upsert:
        await _supabase.client
            .from(operation.table)
            .upsert(operation.data);
        break;
    }
  }

  /// Update sync status
  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  /// Sync a specific entity (full refresh from server)
  Future<void> syncEntity(String entity) async {
    if (!_connectivity.isOnline) {
      debugPrint('SyncService: Cannot sync $entity while offline');
      return;
    }

    // Use internal method if already syncing (called from syncAll)
    await _syncEntityInternal(entity);
  }

  /// Internal sync entity method (doesn't check _isSyncing)
  Future<void> _syncEntityInternal(String entity) async {
    try {
      _updateStatus(SyncStatus.syncing);

      final lastSync = await _cache.getLastSyncTime(entity);
      debugPrint('SyncService: Syncing $entity (last: $lastSync)');

      // Fetch and cache based on entity type
      switch (entity) {
        case 'categories':
          final data = await _supabase.client
              .from('categories')
              .select()
              .eq('active', true)
              .order('id');
          await _cache.setCategories(List<Map<String, dynamic>>.from(data));
          break;

        case 'subcategories':
          final data = await _supabase.client
              .from('subcategories')
              .select()
              .eq('active', true)
              .order('id');
          await _cache.setSubcategories(List<Map<String, dynamic>>.from(data));
          break;

        case 'services':
          final data = await _supabase.client
              .from('services')
              .select('*, service_files(*), profiles!fk_services_user(name, is_verified)')
              .eq('active', true)
              .order('created_at', ascending: false);
          await _cache.setServices(List<Map<String, dynamic>>.from(data));
          break;

        case 'ads':
          final data = await _supabase.client
              .from('ads')
              .select()
              .eq('active', true);
          await _cache.setAds(List<Map<String, dynamic>>.from(data));
          break;
      }

      await _cache.setLastSyncTime(entity, DateTime.now());
      _updateStatus(SyncStatus.success);
      debugPrint('SyncService: $entity synced successfully');
    } catch (e) {
      debugPrint('SyncService: Error syncing $entity: $e');
      _updateStatus(SyncStatus.error);
    }
  }

  /// Sync all entities
  Future<void> syncAll() async {
    if (!_connectivity.isOnline) return;

    if (_isSyncing) {
      debugPrint('SyncService: Already syncing, skipping full sync');
      return;
    }

    _isSyncing = true;
    debugPrint('SyncService: Starting full sync');

    try {
      // Sync entities sequentially to avoid race conditions
      await _syncEntityInternal('categories');
      await _syncEntityInternal('subcategories');
      await _syncEntityInternal('services');
      await _syncEntityInternal('ads');

      await syncOfflineQueue();

      debugPrint('SyncService: Full sync complete');
    } finally {
      _isSyncing = false;
    }
  }

  /// Get pending operations count
  Future<int> getPendingCount() async {
    return await _cache.getOfflineQueueSize();
  }

  /// Clear all pending operations
  Future<void> clearPendingOperations() async {
    await _cache.clearOfflineQueue();
    debugPrint('SyncService: Cleared pending operations');
  }

  /// Dispose the service
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _statusController.close();
    debugPrint('SyncService: Disposed');
  }
}

/// Result of a sync operation
class SyncResult {
  final int success;
  final int failed;
  final int pending;

  SyncResult({
    required this.success,
    required this.failed,
    required this.pending,
  });

  bool get hasErrors => failed > 0;
  bool get hasPending => pending > 0;
  bool get isComplete => pending == 0 && failed == 0;

  @override
  String toString() =>
      'SyncResult(success: $success, failed: $failed, pending: $pending)';
}

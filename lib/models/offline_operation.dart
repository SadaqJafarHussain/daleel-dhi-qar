import 'package:uuid/uuid.dart';

/// Represents an operation queued for sync when offline
class OfflineOperation {
  final String id;
  final OperationType type;
  final String table;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  int retryCount;
  String? errorMessage;

  OfflineOperation({
    String? id,
    required this.type,
    required this.table,
    required this.data,
    DateTime? createdAt,
    this.retryCount = 0,
    this.errorMessage,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Create from JSON (Hive storage)
  factory OfflineOperation.fromJson(Map<String, dynamic> json) {
    return OfflineOperation(
      id: json['id'] as String,
      type: OperationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => OperationType.insert,
      ),
      table: json['table'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
      createdAt: DateTime.parse(json['created_at'] as String),
      retryCount: json['retry_count'] as int? ?? 0,
      errorMessage: json['error_message'] as String?,
    );
  }

  /// Convert to JSON (Hive storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'table': table,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
      'error_message': errorMessage,
    };
  }

  /// Create a copy with updated fields
  OfflineOperation copyWith({
    String? id,
    OperationType? type,
    String? table,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? retryCount,
    String? errorMessage,
  }) {
    return OfflineOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      table: table ?? this.table,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return 'OfflineOperation(id: $id, type: ${type.name}, table: $table, retries: $retryCount)';
  }
}

/// Type of offline operation
enum OperationType {
  /// Insert a new record
  insert,

  /// Update an existing record
  update,

  /// Delete a record
  delete,

  /// Upsert (insert or update)
  upsert,
}

/// Cache entry with TTL support
class CacheEntry<T> {
  final T data;
  final DateTime cachedAt;
  final Duration ttl;

  CacheEntry({
    required this.data,
    required this.ttl,
    DateTime? cachedAt,
  }) : cachedAt = cachedAt ?? DateTime.now();

  /// Check if cache entry has expired
  bool get isExpired => DateTime.now().isAfter(cachedAt.add(ttl));

  /// Get remaining time before expiry
  Duration get remainingTtl {
    final expiryTime = cachedAt.add(ttl);
    final now = DateTime.now();
    if (now.isAfter(expiryTime)) return Duration.zero;
    return expiryTime.difference(now);
  }

  /// Create from JSON
  factory CacheEntry.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromData,
  ) {
    return CacheEntry(
      data: fromData(json['data']),
      cachedAt: DateTime.parse(json['cached_at'] as String),
      ttl: Duration(milliseconds: json['ttl_ms'] as int),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson(dynamic Function(T) toData) {
    return {
      'data': toData(data),
      'cached_at': cachedAt.toIso8601String(),
      'ttl_ms': ttl.inMilliseconds,
    };
  }
}

/// Metadata for tracking sync status
class SyncMetadata {
  final String entity;
  final DateTime? lastSyncTime;
  final SyncStatus status;
  final String? errorMessage;

  SyncMetadata({
    required this.entity,
    this.lastSyncTime,
    this.status = SyncStatus.idle,
    this.errorMessage,
  });

  factory SyncMetadata.fromJson(Map<String, dynamic> json) {
    return SyncMetadata(
      entity: json['entity'] as String,
      lastSyncTime: json['last_sync_time'] != null
          ? DateTime.parse(json['last_sync_time'] as String)
          : null,
      status: SyncStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SyncStatus.idle,
      ),
      errorMessage: json['error_message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entity': entity,
      'last_sync_time': lastSyncTime?.toIso8601String(),
      'status': status.name,
      'error_message': errorMessage,
    };
  }

  SyncMetadata copyWith({
    String? entity,
    DateTime? lastSyncTime,
    SyncStatus? status,
    String? errorMessage,
  }) {
    return SyncMetadata(
      entity: entity ?? this.entity,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Sync status enumeration
enum SyncStatus {
  /// No sync in progress
  idle,

  /// Currently syncing
  syncing,

  /// Sync completed successfully
  success,

  /// Sync failed
  error,

  /// Waiting for network
  pendingNetwork,
}

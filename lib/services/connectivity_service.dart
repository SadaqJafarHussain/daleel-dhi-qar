import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service for monitoring network connectivity
class ConnectivityService {
  // Singleton instance
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _statusController = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool _isInitialized = false;

  /// Stream of connectivity status changes
  Stream<bool> get onConnectivityChanged => _statusController.stream;

  /// Current connectivity status
  bool get isOnline => _isOnline;

  /// Initialize connectivity monitoring
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Check initial connectivity
      _isOnline = await checkConnectivity();

      // Listen to connectivity changes
      _subscription = _connectivity.onConnectivityChanged.listen(
        _handleConnectivityChange,
        onError: (e) {
          debugPrint('ConnectivityService: Error in stream: $e');
        },
      );

      _isInitialized = true;
      debugPrint('ConnectivityService: Initialized (online: $_isOnline)');
    } catch (e) {
      debugPrint('ConnectivityService: Initialization error: $e');
      // Default to online if we can't determine
      _isOnline = true;
    }
  }

  /// Handle connectivity change events
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;

    // Check if any connectivity is available
    _isOnline = results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none);

    if (wasOnline != _isOnline) {
      debugPrint('ConnectivityService: Connectivity changed to ${_isOnline ? "online" : "offline"}');
      _statusController.add(_isOnline);

      if (_isOnline && !wasOnline) {
        _onConnectionRestored();
      }
    }
  }

  /// Called when connection is restored
  void _onConnectionRestored() {
    debugPrint('ConnectivityService: Connection restored, triggering sync');
    // SyncService will be called from providers that listen to this
  }

  /// Check current connectivity (performs actual network check)
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();

      _isOnline = results.isNotEmpty &&
          !results.every((r) => r == ConnectivityResult.none);

      return _isOnline;
    } catch (e) {
      debugPrint('ConnectivityService: Error checking connectivity: $e');
      return _isOnline; // Return last known status
    }
  }

  /// Get connectivity type
  Future<ConnectivityType> getConnectivityType() async {
    try {
      final results = await _connectivity.checkConnectivity();

      if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
        return ConnectivityType.none;
      }

      if (results.contains(ConnectivityResult.wifi)) {
        return ConnectivityType.wifi;
      }

      if (results.contains(ConnectivityResult.mobile)) {
        return ConnectivityType.mobile;
      }

      if (results.contains(ConnectivityResult.ethernet)) {
        return ConnectivityType.ethernet;
      }

      return ConnectivityType.other;
    } catch (e) {
      debugPrint('ConnectivityService: Error getting connectivity type: $e');
      return ConnectivityType.unknown;
    }
  }

  /// Wait for connection (useful for sync operations)
  Future<bool> waitForConnection({Duration timeout = const Duration(seconds: 30)}) async {
    if (_isOnline) return true;

    try {
      await for (final isOnline in _statusController.stream.timeout(timeout)) {
        if (isOnline) return true;
      }
    } catch (e) {
      debugPrint('ConnectivityService: Timeout waiting for connection');
    }

    return false;
  }

  /// Dispose the service
  void dispose() {
    _subscription?.cancel();
    _statusController.close();
    _isInitialized = false;
    debugPrint('ConnectivityService: Disposed');
  }
}

/// Connectivity type enumeration
enum ConnectivityType {
  /// No connectivity
  none,

  /// Connected via WiFi
  wifi,

  /// Connected via mobile data
  mobile,

  /// Connected via ethernet
  ethernet,

  /// Connected via other means
  other,

  /// Unknown connectivity
  unknown,
}

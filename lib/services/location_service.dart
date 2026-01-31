import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../config/app_config.dart';

/// Professional location service with permission handling
class LocationService {
  static LocationService? _instance;

  // Singleton pattern
  factory LocationService() {
    _instance ??= LocationService._internal();
    return _instance!;
  }

  LocationService._internal();

  Position? _lastKnownPosition;
  LocationPermission? _lastPermissionStatus;
  bool _isDisposed = false;

  /// Get current location with full permission handling
  Future<LocationResult> getCurrentLocation() async {
    if (_isDisposed) {
      return LocationResult.error('LocationService is disposed');
    }

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          print('LocationService: Location services are disabled');
        }
        return LocationResult.serviceDisabled();
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      _lastPermissionStatus = permission;

      if (kDebugMode) {
        print('LocationService: Permission status: $permission');
      }

      // Handle denied permissions
      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();
        _lastPermissionStatus = permission;

        if (permission == LocationPermission.denied) {
          if (kDebugMode) {
            print('LocationService: Permission denied by user');
          }
          return LocationResult.permissionDenied();
        }
      }

      // Handle permanently denied permissions
      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          print('LocationService: Permission permanently denied');
        }
        return LocationResult.permissionDeniedForever();
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _lastKnownPosition = position;

      if (kDebugMode) {
        print('LocationService: ✅ Got position: ${position.latitude}, ${position.longitude}');
      }

      return LocationResult.success(position);
    } catch (e) {
      if (kDebugMode) {
        print('LocationService: Error getting location: $e');
      }

      // Return last known position if available
      if (_lastKnownPosition != null) {
        if (kDebugMode) {
          print('LocationService: Using last known position');
        }
        return LocationResult.success(_lastKnownPosition!);
      }

      return LocationResult.error(e.toString());
    }
  }

  /// Get last known position (cached)
  Position? get lastKnownPosition => _lastKnownPosition;

  /// Check if we have cached position
  bool get hasLastKnownPosition => _lastKnownPosition != null;

  /// Get permission status
  Future<LocationPermission> getPermissionStatus() async {
    _lastPermissionStatus = await Geolocator.checkPermission();
    return _lastPermissionStatus ?? LocationPermission.denied;
  }

  /// Open app settings (for permanently denied permission)
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Open location settings (for disabled service)
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Clear cached position
  void clearCache() {
    _lastKnownPosition = null;
    _lastPermissionStatus = null;
  }

  /// Dispose the service (for cleanup)
  void dispose() {
    _isDisposed = true;
    clearCache();
    if (kDebugMode) {
      print('LocationService: Disposed');
    }
  }

  /// Reset singleton (for testing or re-initialization)
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }

  /// Get default/fallback location (Dhi Qar / Nasiriyah city center)
  static Position getDefaultLocation() {
    return Position(
      latitude: AppConfig.defaultLatitude,
      longitude: AppConfig.defaultLongitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }
}

/// Result wrapper for location operations
class LocationResult {
  final bool success;
  final Position? position;
  final LocationErrorType? errorType;
  final String? errorMessage;

  LocationResult._({
    required this.success,
    this.position,
    this.errorType,
    this.errorMessage,
  });

  factory LocationResult.success(Position position) {
    return LocationResult._(
      success: true,
      position: position,
    );
  }

  factory LocationResult.serviceDisabled() {
    return LocationResult._(
      success: false,
      errorType: LocationErrorType.serviceDisabled,
      errorMessage: 'Location services are disabled. Please enable location services.',
    );
  }

  factory LocationResult.permissionDenied() {
    return LocationResult._(
      success: false,
      errorType: LocationErrorType.permissionDenied,
      errorMessage: 'Location permission denied. Please grant permission to see nearby services.',
    );
  }

  factory LocationResult.permissionDeniedForever() {
    return LocationResult._(
      success: false,
      errorType: LocationErrorType.permissionDeniedForever,
      errorMessage: 'Location permission permanently denied. Please enable it in app settings.',
    );
  }

  factory LocationResult.error(String message) {
    return LocationResult._(
      success: false,
      errorType: LocationErrorType.unknown,
      errorMessage: message,
    );
  }

  bool get isServiceDisabled => errorType == LocationErrorType.serviceDisabled;
  bool get isPermissionDenied => errorType == LocationErrorType.permissionDenied;
  bool get isPermissionDeniedForever => errorType == LocationErrorType.permissionDeniedForever;
}

/// Location error types
enum LocationErrorType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}
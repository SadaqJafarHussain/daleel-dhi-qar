import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/service_model.dart';
import '../services/location_service.dart';
import '../config/app_config.dart';
import '../services/supabase_service.dart';
import '../services/cache_manager.dart';
import '../services/storage_service.dart';
import '../services/realtime_service.dart';

class ServiceProvider with ChangeNotifier {
  // State
  List<Service> _allServices = [];  // Master list - never filtered
  List<Service> _services = [];     // Current view (filtered or all)
  List<Service> _nearbyServices = [];
  bool _isLoading = false;
  bool _isLoadingNearby = false;
  bool _isAdding = false;
  bool _isUpdating = false;
  bool _isUploadingFiles = false;
  String? _error;
  String? _nearbyError;

  // Location
  Position? _userLocation;
  LocationResult? _lastLocationResult;

  // Cache by category and subcategory
  final Map<String, List<Service>> _categoryCache = {};
  final Map<String, List<Service>> _subcategoryCache = {};
  final Map<String, DateTime> _cacheTimes = {};
  static const Duration _cacheDuration = Duration(minutes: 15);

  // Nearby services cache
  DateTime? _nearbyLastFetchTime;
  static const Duration _nearbyCacheDuration = Duration(minutes: 5);

  // Current filter
  int? _currentCategoryId;
  int? _currentSubcategoryId;

  // Getters
  List<Service> get services => _services;
  List<Service> get allServices => _allServices;
  List<Service> get nearbyServices => _nearbyServices;

  /// Get top rated services (4.0+ stars, sorted by rating) - from ALL services
  List<Service> get topRatedServices {
    return _allServices
        .where((s) => (s.averageRating ?? 0) >= 4.0 && (s.totalReviews ?? 0) > 0)
        .toList()
      ..sort((a, b) => (b.averageRating ?? 0).compareTo(a.averageRating ?? 0));
  }

  /// Get recently added services (last 30 days, sorted by date) - from ALL services
  List<Service> get recentlyAddedServices {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return _allServices.where((s) {
      if (s.createdAt.isEmpty) return false;
      try {
        final createdDate = DateTime.parse(s.createdAt);
        return createdDate.isAfter(thirtyDaysAgo);
      } catch (e) {
        return false;
      }
    }).toList()
      ..sort((a, b) {
        try {
          final dateA = DateTime.parse(a.createdAt);
          final dateB = DateTime.parse(b.createdAt);
          return dateB.compareTo(dateA); // Newest first
        } catch (e) {
          return 0;
        }
      });
  }

  /// Get currently open services - from ALL services
  List<Service> get openNowServices {
    return _allServices.where((s) => s.isCurrentlyOpen).toList();
  }

  /// Get verified owner services - from ALL services
  List<Service> get verifiedServices {
    return _allServices.where((s) => s.isOwnerVerified).toList();
  }
  bool get isLoading => _isLoading;
  bool get isLoadingNearby => _isLoadingNearby;
  bool get isAdding => _isAdding;
  bool get isUpdating => _isUpdating;
  bool get isUploadingFiles => _isUploadingFiles;
  bool get isSaving => _isAdding || _isUpdating || _isUploadingFiles;
  String? get error => _error;
  String? get nearbyError => _nearbyError;
  bool get hasData => _allServices.isNotEmpty;
  bool get hasNearbyData => _nearbyServices.isNotEmpty;
  int? get currentCategoryId => _currentCategoryId;
  int? get currentSubcategoryId => _currentSubcategoryId;
  Position? get userLocation => _userLocation;
  LocationResult? get lastLocationResult => _lastLocationResult;

  // Services
  final LocationService _locationService = LocationService();
  final SupabaseService _supabase = SupabaseService();
  final CacheManager _cache = CacheManager();
  final StorageService _storage = StorageService();
  final RealtimeService _realtime = RealtimeService();

  // ========================================
  // ADD SERVICE (Supabase)
  // ========================================

  Future<Map<String, dynamic>> addService({
    required int catId,
    required int subcatId,
    required String name,
    required String phone,
    required String address,
    required String description,
    required double lat,
    required double lng,
    String? facebook,
    String? instagram,
    String? whatsapp,
    String? telegram,
    List<String>? attachmentPaths,
    String? openTime,
    String? closeTime,
    String? workDays,
    bool? isOpen24Hours,
    bool? isManualOverride,
  }) async {
    _isAdding = true;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('ServiceProvider: 📤 Adding new service via Supabase...');
        print('ServiceProvider: Category: $catId, Subcategory: $subcatId');
        print('ServiceProvider: Name: $name');
      }

      // Get current user ID
      final userId = _supabase.currentUser?.id;
      if (userId == null) {
        _isAdding = false;
        notifyListeners();
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      // Insert service into Supabase
      final serviceData = {
        'user_id': userId,
        'cat_id': catId,
        'subcat_id': subcatId,
        'title': name,
        'phone': phone,
        'address': address,
        'description': description,
        'lat': lat,
        'lng': lng,
        'facebook': facebook,
        'instagram': instagram,
        'whatsapp': whatsapp,
        'telegram': telegram,
        'open_time': openTime,
        'close_time': closeTime,
        'work_days': workDays != null
            ? workDays.split(',').map((d) => int.tryParse(d.trim()) ?? 0).toList()
            : null,
        'is_open_24_hours': isOpen24Hours ?? false,
        'is_manual_override': isManualOverride ?? false,
        'active': true,
      };

      final response = await _supabase.client
          .from('services')
          .insert(serviceData)
          .select('*, service_files(*), profiles!fk_services_user(name, is_verified)')
          .single();

      final newService = Service.fromJson(response);

      if (kDebugMode) {
        print('ServiceProvider: ✅ Service created with ID: ${newService.id}');
      }

      // Upload files if any
      if (attachmentPaths != null && attachmentPaths.isNotEmpty) {
        _isUploadingFiles = true;
        notifyListeners();

        for (int i = 0; i < attachmentPaths.length; i++) {
          final filePath = attachmentPaths[i];
          try {
            if (await File(filePath).exists()) {
              final file = File(filePath);
              final fileName = '${newService.id}_${DateTime.now().millisecondsSinceEpoch}_$i.${filePath.split('.').last}';

              // Upload to Supabase Storage
              final uploadPath = await _storage.uploadServiceImage(
                file: file,
                serviceId: newService.id,
                fileName: fileName,
              );

              if (uploadPath != null) {
                // Insert file record - uploadPath is the full URL from storage
                await _supabase.client.from('service_files').insert({
                  'service_id': newService.id,
                  'file_path': fileName,
                  'url': uploadPath,
                });

                if (kDebugMode) {
                  print('ServiceProvider: ✅ Uploaded file $i: $fileName');
                }
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('ServiceProvider: ⚠️ Error uploading file $filePath: $e');
            }
          }
        }

        _isUploadingFiles = false;
      }

      // Re-fetch the service with files included to get complete data
      final completeServiceResponse = await _supabase.client
          .from('services')
          .select('*, service_files(*), profiles!fk_services_user(name, is_verified)')
          .eq('id', newService.id)
          .single();

      final completeService = Service.fromJson(completeServiceResponse);

      // Add to master list (_allServices)
      final allExistingIndex = _allServices.indexWhere((s) => s.id == completeService.id);
      if (allExistingIndex >= 0) {
        _allServices[allExistingIndex] = completeService;
      } else {
        _allServices.insert(0, completeService);
      }

      // Add to current view list (_services)
      final existingIndex = _services.indexWhere((s) => s.id == completeService.id);
      if (existingIndex >= 0) {
        _services[existingIndex] = completeService;
      } else {
        _services.insert(0, completeService);
      }

      // Add to nearby services if within range
      if (_userLocation != null && completeService.lat != 0 && completeService.lng != 0) {
        final distance = _calculateDistance(
          _userLocation!.latitude,
          _userLocation!.longitude,
          completeService.lat,
          completeService.lng,
        );

        if (distance <= 10.0) {
          completeService.distance = distance;
          final nearbyIndex = _nearbyServices.indexWhere((s) => s.id == completeService.id);
          if (nearbyIndex >= 0) {
            _nearbyServices[nearbyIndex] = completeService;
          } else {
            _nearbyServices.insert(0, completeService);
          }
          _nearbyServices.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));
        }
      }

      // Invalidate caches
      _invalidateCaches(catId, subcatId);

      _isAdding = false;
      notifyListeners();

      if (kDebugMode) {
        print('ServiceProvider: ✅ Service added successfully: ${completeService.title}');
        print('ServiceProvider: 📷 Service has ${completeService.files.length} files');
      }

      return {
        'success': true,
        'message': 'Service added successfully',
        'service': completeService,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ServiceProvider: ❌ Exception in addService: $e');
      }

      _isAdding = false;
      _isUploadingFiles = false;
      notifyListeners();

      return {
        'success': false,
        'message': 'Failed to add service: ${e.toString()}',
      };
    }
  }

  // ========================================
  // UPDATE SERVICE (Supabase)
  // ========================================

  Future<Map<String, dynamic>> updateService({
    required int serviceId,
    required int catId,
    required int subcatId,
    required String name,
    required String phone,
    required String address,
    required String description,
    required double lat,
    required double lng,
    String? facebook,
    String? instagram,
    String? whatsapp,
    String? telegram,
    List<String>? attachmentPaths,
    String? openTime,
    String? closeTime,
    String? workDays,
    bool? isOpen24Hours,
    bool? isManualOverride,
    bool? active,
  }) async {
    _isUpdating = true;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('ServiceProvider: 📝 Updating service ID: $serviceId via Supabase');
      }

      // Update service in Supabase
      final serviceData = {
        'cat_id': catId,
        'subcat_id': subcatId,
        'title': name,
        'phone': phone,
        'address': address,
        'description': description,
        'lat': lat,
        'lng': lng,
        'facebook': facebook,
        'instagram': instagram,
        'whatsapp': whatsapp,
        'telegram': telegram,
        'open_time': openTime,
        'close_time': closeTime,
        'work_days': workDays != null
            ? workDays.split(',').map((d) => int.tryParse(d.trim()) ?? 0).toList()
            : null,
        'is_open_24_hours': isOpen24Hours ?? false,
        'is_manual_override': isManualOverride ?? false,
        if (active != null) 'active': active,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase.client
          .from('services')
          .update(serviceData)
          .eq('id', serviceId)
          .select('*, service_files(*), profiles!fk_services_user(name, is_verified)')
          .single();

      // Parse updated service (response used for validation)
      Service.fromJson(response);

      // Upload new files if any
      if (attachmentPaths != null && attachmentPaths.isNotEmpty) {
        _isUploadingFiles = true;
        notifyListeners();

        for (int i = 0; i < attachmentPaths.length; i++) {
          final filePath = attachmentPaths[i];
          // Skip URLs (existing files)
          if (filePath.startsWith('http')) continue;

          try {
            if (await File(filePath).exists()) {
              final file = File(filePath);
              final fileName = '${serviceId}_${DateTime.now().millisecondsSinceEpoch}_$i.${filePath.split('.').last}';

              final uploadPath = await _storage.uploadServiceImage(
                file: file,
                serviceId: serviceId,
                fileName: fileName,
              );

              if (uploadPath != null) {
                // Insert file record - uploadPath is the full URL from storage
                await _supabase.client.from('service_files').insert({
                  'service_id': serviceId,
                  'file_path': fileName,
                  'url': uploadPath,
                });

                if (kDebugMode) {
                  print('ServiceProvider: ✅ Uploaded file $i: $fileName');
                }
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('ServiceProvider: ⚠️ Error uploading file $filePath: $e');
            }
          }
        }

        _isUploadingFiles = false;
      }

      // Re-fetch the service with files included to get complete data (including new files)
      final completeServiceResponse = await _supabase.client
          .from('services')
          .select('*, service_files(*), profiles!fk_services_user(name, is_verified)')
          .eq('id', serviceId)
          .single();

      final completeService = Service.fromJson(completeServiceResponse);

      // Update in main list
      _updateServiceInList(serviceId, completeService);

      // Update in nearby services
      _updateServiceInNearby(serviceId, completeService);

      // Invalidate caches
      _invalidateCaches(catId, subcatId);

      _isUpdating = false;
      notifyListeners();

      if (kDebugMode) {
        print('ServiceProvider: ✅ Service updated successfully');
        print('ServiceProvider: 📷 Service has ${completeService.files.length} files');
      }

      return {
        'success': true,
        'message': 'Service updated successfully',
        'service': completeService,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ServiceProvider: ❌ Exception in updateService: $e');
      }

      _isUpdating = false;
      _isUploadingFiles = false;
      notifyListeners();

      return {
        'success': false,
        'message': 'Failed to update service: ${e.toString()}',
      };
    }
  }

  // ========================================
  // DELETE SERVICE (Supabase)
  // ========================================

  Future<Map<String, dynamic>> deleteService({
    required int serviceId,
  }) async {
    try {
      if (kDebugMode) {
        print('ServiceProvider: 🗑️ Deleting service ID: $serviceId via Supabase');
      }

      _isUpdating = true;
      notifyListeners();

      // Delete from Supabase (cascade will handle service_files)
      await _supabase.client
          .from('services')
          .delete()
          .eq('id', serviceId);

      // Remove from local lists
      _allServices.removeWhere((s) => s.id == serviceId);
      _services.removeWhere((s) => s.id == serviceId);
      _nearbyServices.removeWhere((s) => s.id == serviceId);
      _categoryCache.forEach((key, list) => list.removeWhere((s) => s.id == serviceId));
      _subcategoryCache.forEach((key, list) => list.removeWhere((s) => s.id == serviceId));

      _isUpdating = false;
      notifyListeners();

      if (kDebugMode) {
        print('ServiceProvider: ✅ Service deleted successfully');
      }

      return {
        'success': true,
        'message': 'Service deleted successfully',
      };
    } catch (e) {
      if (kDebugMode) {
        print('ServiceProvider: ❌ Exception in deleteService: $e');
      }

      _isUpdating = false;
      notifyListeners();

      return {
        'success': false,
        'message': 'Failed to delete service: ${e.toString()}',
      };
    }
  }

  // ========================================
  // DELETE SERVICE FILE (Supabase)
  // ========================================

  Future<Map<String, dynamic>> deleteServiceFile({
    required int fileId,
  }) async {
    try {
      if (kDebugMode) {
        print('ServiceProvider: 🗑️ Deleting file ID: $fileId via Supabase');
      }

      // Get file path first
      final fileRecord = await _supabase.client
          .from('service_files')
          .select('file_path')
          .eq('id', fileId)
          .maybeSingle();

      if (fileRecord != null && fileRecord['file_path'] != null) {
        // Delete from storage
        await _storage.deleteFile(fileRecord['file_path']);
      }

      // Delete from database
      await _supabase.client
          .from('service_files')
          .delete()
          .eq('id', fileId);

      if (kDebugMode) {
        print('ServiceProvider: ✅ File deleted successfully');
      }

      return {
        'success': true,
        'message': 'File deleted successfully',
      };
    } catch (e) {
      if (kDebugMode) {
        print('ServiceProvider: ❌ Exception in deleteServiceFile: $e');
      }

      return {
        'success': false,
        'message': 'Failed to delete file: ${e.toString()}',
      };
    }
  }

  // ========================================
  // HELPER METHODS
  // ========================================

  void _invalidateCaches(int catId, int subcatId) {
    _cacheTimes.remove('all_services');
    _cacheTimes.remove('category_$catId');
    _cacheTimes.remove('subcategory_$subcatId');
    // Also invalidate Supabase cache
    _cache.delete('services', 'all_services');
    _cache.delete('services', 'category_$catId');
    _cache.delete('services', 'subcategory_$subcatId');
  }

  void _updateServiceInList(int serviceId, Service updatedService) {
    // Update in master list (_allServices)
    final allServiceIndex = _allServices.indexWhere((s) => s.id == serviceId);
    if (allServiceIndex != -1) {
      _allServices[allServiceIndex] = updatedService;
    }
    // Update in current view list (_services)
    final serviceIndex = _services.indexWhere((s) => s.id == serviceId);
    if (serviceIndex != -1) {
      _services[serviceIndex] = updatedService;
    }
  }

  void _updateServiceInNearby(int serviceId, Service updatedService) {
    final nearbyIndex = _nearbyServices.indexWhere((s) => s.id == serviceId);

    if (nearbyIndex != -1) {
      if (_userLocation != null && updatedService.lat != 0 && updatedService.lng != 0) {
        final distance = _calculateDistance(
          _userLocation!.latitude,
          _userLocation!.longitude,
          updatedService.lat,
          updatedService.lng,
        );
        updatedService.distance = distance;

        if (distance <= 10.0) {
          _nearbyServices[nearbyIndex] = updatedService;
          _nearbyServices.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));
        } else {
          _nearbyServices.removeAt(nearbyIndex);
        }
      } else {
        _nearbyServices[nearbyIndex] = updatedService;
      }
    }
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371;
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * pi / 180;

  // ========================================
  // FETCH METHODS (Supabase)
  // ========================================

  Service? getById(int id) {
    try {
      return _services.firstWhere((service) => service.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Service> getByCategory(int categoryId) {
    return _services.where((service) => service.catId == categoryId).toList();
  }

  List<Service> getBySubcategory(int subcategoryId) {
    return _services.where((service) => service.subcatId == subcategoryId).toList();
  }

  List<Service> getByUser(int userId) {
    return _services.where((service) => service.userId == userId).toList();
  }

  /// Get a service by ID - first checks local cache, then fetches from server
  Future<Service?> getServiceById(int serviceId) async {
    // First check if we have it in cache
    final cached = _services.firstWhere(
      (s) => s.id == serviceId,
      orElse: () => Service.empty(),
    );
    if (cached.id != 0) {
      return cached;
    }

    // Not in cache, fetch from server
    try {
      final data = await SupabaseService().client
          .from('services')
          .select('*, profiles:user_id(name, avatar_url, is_verified), service_files(*)')
          .eq('id', serviceId)
          .maybeSingle();

      if (data != null) {
        final service = Service.fromJson(data);
        // Add to cache
        _services.add(service);
        return service;
      }
    } catch (e) {
      debugPrint('Error fetching service by ID: $e');
    }
    return null;
  }

  bool _isCacheValid(String key) {
    final cacheTime = _cacheTimes[key];
    if (cacheTime == null) return false;
    return DateTime.now().difference(cacheTime) < _cacheDuration;
  }

  bool get _isNearbyCacheValid {
    if (_nearbyLastFetchTime == null) return false;
    return DateTime.now().difference(_nearbyLastFetchTime!) < _nearbyCacheDuration;
  }

  Future<void> fetchNearbyServices({
    double maxDistanceKm = 10.0,
    bool forceRefresh = false,
    bool useDefaultLocationIfFailed = true,
  }) async {
    if (!forceRefresh && _isNearbyCacheValid && _nearbyServices.isNotEmpty) {
      return;
    }

    _isLoadingNearby = true;
    _nearbyError = null;
    notifyListeners();

    try {
      final locationResult = await _locationService.getCurrentLocation();
      _lastLocationResult = locationResult;

      Position? position;

      if (locationResult.success) {
        position = locationResult.position!;
        _userLocation = position;
      } else {
        if (useDefaultLocationIfFailed) {
          position = _locationService.lastKnownPosition ?? LocationService.getDefaultLocation();
          _userLocation = position;

          if (locationResult.isPermissionDenied) {
            _nearbyError = 'location_permission_denied';
          } else if (locationResult.isPermissionDeniedForever) {
            _nearbyError = 'location_permission_denied_forever';
          } else if (locationResult.isServiceDisabled) {
            _nearbyError = 'location_service_disabled';
          } else {
            _nearbyError = 'location_error_using_default';
          }
        } else {
          _nearbyError = locationResult.errorMessage;
          _nearbyServices = [];
          _isLoadingNearby = false;
          notifyListeners();
          return;
        }
      }

      await _fetchAllServicesIfNeeded();

      if (_services.isEmpty) {
        _nearbyError = _error ?? 'no_services_from_api';
        _nearbyServices = [];
        _isLoadingNearby = false;
        notifyListeners();
        return;
      }

      final nearby = <Service>[];
      for (var service in _services) {
        if (service.lat != 0 && service.lng != 0) {
          final distance = _calculateDistance(
            position.latitude,
            position.longitude,
            service.lat,
            service.lng,
          );

          if (distance <= maxDistanceKm) {
            service.distance = distance;
            nearby.add(service);
          }
        }
      }

      nearby.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));

      _nearbyServices = nearby;
      _nearbyLastFetchTime = DateTime.now();
    } catch (e) {
      _nearbyError = 'Failed to load nearby services: ${e.toString()}';
      _nearbyServices = [];
    } finally {
      _isLoadingNearby = false;
      notifyListeners();
    }
  }

  Future<void> refreshNearbyServices({double maxDistanceKm = 10.0}) async {
    _nearbyLastFetchTime = null;
    _locationService.clearCache();
    await fetchNearbyServices(maxDistanceKm: maxDistanceKm, forceRefresh: true);
  }

  Future<LocationResult> requestLocationPermission() async {
    return await _locationService.getCurrentLocation();
  }

  Future<bool> openLocationSettings() async {
    return await _locationService.openAppSettings();
  }

  void clearNearbyServices() {
    _nearbyServices = [];
    _nearbyError = null;
    _nearbyLastFetchTime = null;
    notifyListeners();
  }

  Future<void> _fetchAllServicesIfNeeded() async {
    if (_allServices.isNotEmpty) return;
    await fetchAllServices();
  }

  Future<void> fetchAllServices({bool forceRefresh = false}) async {
    const cacheKey = 'all_services';

    if (!forceRefresh && _isCacheValid(cacheKey) && _allServices.isNotEmpty) {
      _services = List.from(_allServices);
      _currentCategoryId = null;
      _currentSubcategoryId = null;
      _error = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _currentCategoryId = null;
    _currentSubcategoryId = null;
    Future.microtask(() => notifyListeners());

    try {
      final data = await _supabase.fetchWithCache(
        table: 'services',
        cacheKey: 'all_services',
        cacheBox: 'services',
        cacheDuration: AppConfig.serviceCacheDuration,
        eq: {'active': true},
        orderBy: 'created_at',
        ascending: false,
        select: '*, service_files(*), profiles!fk_services_user(name, is_verified)',
      );

      final servicesList = data.map((json) => Service.fromJson(json)).toList();
      _allServices = servicesList;  // Update master list
      _services = List.from(servicesList);  // Update current view
      _categoryCache[cacheKey] = servicesList;
      _cacheTimes[cacheKey] = DateTime.now();
      _error = null;

      if (kDebugMode) {
        print('✅ [SUPABASE] Loaded ${_services.length} services');
      }

      // Fetch ratings for all services in the background
      _fetchAllServiceRatings();
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      // Don't clear _allServices on error - keep existing data
      if (_allServices.isEmpty) {
        _services = [];
      }
      if (kDebugMode) {
        print('ServiceProvider Exception: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch ratings for all services from reviews table
  Future<void> _fetchAllServiceRatings() async {
    try {
      // Get all reviews grouped by service_id with rating stats
      final reviewsData = await _supabase.client
          .from('reviews')
          .select('service_id, rating');

      if ((reviewsData as List).isEmpty) {
        if (kDebugMode) {
          print('ServiceProvider: No reviews found');
        }
        return;
      }

      // Calculate ratings per service
      final Map<int, List<double>> serviceRatings = {};
      for (var review in reviewsData) {
        final serviceId = review['service_id'] as int;
        final rating = (review['rating'] as num).toDouble();
        serviceRatings.putIfAbsent(serviceId, () => []).add(rating);
      }

      // Update services with calculated ratings
      bool hasUpdates = false;
      for (var entry in serviceRatings.entries) {
        final serviceId = entry.key;
        final ratings = entry.value;
        final avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
        final totalReviews = ratings.length;

        // Update in master services list
        final allIndex = _allServices.indexWhere((s) => s.id == serviceId);
        if (allIndex != -1) {
          _allServices[allIndex] = _allServices[allIndex].copyWith(
            averageRating: avgRating,
            totalReviews: totalReviews,
          );
          hasUpdates = true;
        }

        // Update in current view services list
        final index = _services.indexWhere((s) => s.id == serviceId);
        if (index != -1) {
          _services[index] = _services[index].copyWith(
            averageRating: avgRating,
            totalReviews: totalReviews,
          );
        }

        // Update in nearby services list
        final nearbyIndex = _nearbyServices.indexWhere((s) => s.id == serviceId);
        if (nearbyIndex != -1) {
          _nearbyServices[nearbyIndex] = _nearbyServices[nearbyIndex].copyWith(
            averageRating: avgRating,
            totalReviews: totalReviews,
          );
        }
      }

      if (hasUpdates) {
        if (kDebugMode) {
          print('ServiceProvider: Updated ratings for ${serviceRatings.length} services');
        }
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('ServiceProvider: Error fetching ratings: $e');
      }
    }
  }

  Future<void> fetchServicesByCategory(int categoryId, {bool forceRefresh = false}) async {
    final cacheKey = 'category_$categoryId';

    if (!forceRefresh && _isCacheValid(cacheKey)) {
      _services = _categoryCache[cacheKey] ?? [];
      _currentCategoryId = categoryId;
      _currentSubcategoryId = null;
      _error = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _currentCategoryId = categoryId;
    _currentSubcategoryId = null;
    Future.microtask(() => notifyListeners());

    try {
      final data = await _supabase.fetchWithCache(
        table: 'services',
        cacheKey: cacheKey,
        cacheBox: 'services',
        cacheDuration: AppConfig.serviceCacheDuration,
        eq: {'active': true, 'cat_id': categoryId},
        orderBy: 'created_at',
        ascending: false,
        select: '*, service_files(*), profiles!fk_services_user(name, is_verified)',
      );

      _services = data.map((json) => Service.fromJson(json)).toList();
      _categoryCache[cacheKey] = _services;
      _cacheTimes[cacheKey] = DateTime.now();
      _error = null;

      if (kDebugMode) {
        print('✅ [SUPABASE] Loaded ${_services.length} services for category $categoryId');
      }

      // Fetch ratings for all services in the background
      _fetchAllServiceRatings();
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _services = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchServicesBySubcategory(int subcategoryId, {bool forceRefresh = false}) async {
    final cacheKey = 'subcategory_$subcategoryId';

    if (!forceRefresh && _isCacheValid(cacheKey)) {
      _services = _subcategoryCache[cacheKey] ?? [];
      _currentSubcategoryId = subcategoryId;
      _error = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _currentSubcategoryId = subcategoryId;
    Future.microtask(() => notifyListeners());

    try {
      final data = await _supabase.fetchWithCache(
        table: 'services',
        cacheKey: cacheKey,
        cacheBox: 'services',
        cacheDuration: AppConfig.serviceCacheDuration,
        eq: {'active': true, 'subcat_id': subcategoryId},
        orderBy: 'created_at',
        ascending: false,
        select: '*, service_files(*), profiles!fk_services_user(name, is_verified)',
      );

      _services = data.map((json) => Service.fromJson(json)).toList();
      _subcategoryCache[cacheKey] = _services;
      _cacheTimes[cacheKey] = DateTime.now();
      _error = null;

      if (kDebugMode) {
        print('✅ [SUPABASE] Loaded ${_services.length} services for subcategory $subcategoryId');
      }

      // Fetch ratings for all services in the background
      _fetchAllServiceRatings();
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _services = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCurrentServices() async {
    if (_currentSubcategoryId != null) {
      await fetchServicesBySubcategory(_currentSubcategoryId!, forceRefresh: true);
    } else if (_currentCategoryId != null) {
      await fetchServicesByCategory(_currentCategoryId!, forceRefresh: true);
    }
  }

  void clear() {
    _allServices = [];
    _services = [];
    _nearbyServices = [];
    _error = null;
    _nearbyError = null;
    _currentCategoryId = null;
    _currentSubcategoryId = null;
    _userLocation = null;
    _isAdding = false;
    _isUpdating = false;
    _isUploadingFiles = false;
    notifyListeners();
  }

  void clearAllCache() {
    _categoryCache.clear();
    _subcategoryCache.clear();
    _cacheTimes.clear();
    _nearbyLastFetchTime = null;
  }

  Map<String, dynamic> getCacheStats() {
    return {
      'categoryCacheSize': _categoryCache.length,
      'subcategoryCacheSize': _subcategoryCache.length,
      'nearbyCacheValid': _isNearbyCacheValid,
      'nearbyServicesCount': _nearbyServices.length,
      'hasUserLocation': _userLocation != null,
      'userLocation': _userLocation != null ? '${_userLocation!.latitude}, ${_userLocation!.longitude}' : null,
    };
  }

  /// Update a service's rating (called when a review is submitted/updated/deleted)
  void updateServiceRating(int serviceId, double averageRating, int totalReviews) {
    if (kDebugMode) {
      print('ServiceProvider: Updating service $serviceId rating to $averageRating ($totalReviews reviews)');
    }

    // Update in master list (_allServices)
    final allIndex = _allServices.indexWhere((s) => s.id == serviceId);
    if (allIndex != -1) {
      _allServices[allIndex] = _allServices[allIndex].copyWith(
        averageRating: averageRating,
        totalReviews: totalReviews,
      );
    }

    // Update in current view services list
    final index = _services.indexWhere((s) => s.id == serviceId);
    if (index != -1) {
      _services[index] = _services[index].copyWith(
        averageRating: averageRating,
        totalReviews: totalReviews,
      );
    }

    // Update in nearby services list
    final nearbyIndex = _nearbyServices.indexWhere((s) => s.id == serviceId);
    if (nearbyIndex != -1) {
      _nearbyServices[nearbyIndex] = _nearbyServices[nearbyIndex].copyWith(
        averageRating: averageRating,
        totalReviews: totalReviews,
      );
    }

    // Update in category caches
    for (final cacheKey in _categoryCache.keys) {
      final cachedList = _categoryCache[cacheKey];
      if (cachedList != null) {
        final cacheIndex = cachedList.indexWhere((s) => s.id == serviceId);
        if (cacheIndex != -1) {
          cachedList[cacheIndex] = cachedList[cacheIndex].copyWith(
            averageRating: averageRating,
            totalReviews: totalReviews,
          );
        }
      }
    }

    // Update in subcategory caches
    for (final cacheKey in _subcategoryCache.keys) {
      final cachedList = _subcategoryCache[cacheKey];
      if (cachedList != null) {
        final cacheIndex = cachedList.indexWhere((s) => s.id == serviceId);
        if (cacheIndex != -1) {
          cachedList[cacheIndex] = cachedList[cacheIndex].copyWith(
            averageRating: averageRating,
            totalReviews: totalReviews,
          );
        }
      }
    }

    notifyListeners();
  }

  // ========================================
  // REALTIME SUBSCRIPTIONS
  // ========================================

  /// Subscribe to real-time service updates
  void subscribeToRealtime() {
    _realtime.subscribeToServices(
      onInsert: (service) {
        if (kDebugMode) {
          print('RealtimeService: New service added: ${service.title}');
        }
        // Update master list (_allServices)
        final allExistingIndex = _allServices.indexWhere((s) => s.id == service.id);
        if (allExistingIndex >= 0) {
          _allServices[allExistingIndex] = service;
        } else {
          _allServices.insert(0, service);
        }

        // Update current view list (_services)
        final existingIndex = _services.indexWhere((s) => s.id == service.id);
        if (existingIndex >= 0) {
          _services[existingIndex] = service;
          if (kDebugMode) {
            print('RealtimeService: Service ${service.id} already exists, updating instead');
          }
        } else {
          _services.insert(0, service);
        }

        // Add to nearby if within range
        if (_userLocation != null && service.lat != 0 && service.lng != 0) {
          final distance = _calculateDistance(
            _userLocation!.latitude,
            _userLocation!.longitude,
            service.lat,
            service.lng,
          );
          if (distance <= 10.0) {
            service.distance = distance;
            final nearbyIndex = _nearbyServices.indexWhere((s) => s.id == service.id);
            if (nearbyIndex >= 0) {
              _nearbyServices[nearbyIndex] = service;
            } else {
              _nearbyServices.add(service);
            }
            _nearbyServices.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));
          }
        }
        // Invalidate caches
        clearAllCache();
        notifyListeners();
      },
      onUpdate: (service) {
        if (kDebugMode) {
          print('RealtimeService: Service updated: ${service.title}');
          print('RealtimeService: New rating: ${service.averageRating}, reviews: ${service.totalReviews}');
        }
        // Update in master list (_allServices)
        final allIndex = _allServices.indexWhere((s) => s.id == service.id);
        if (allIndex != -1) {
          final existingAll = _allServices[allIndex];
          final updatedAll = service.copyWith(
            files: service.files.isEmpty ? existingAll.files : service.files,
            distance: existingAll.distance,
          );
          _allServices[allIndex] = updatedAll;
        }

        // Update in current view list (_services)
        final index = _services.indexWhere((s) => s.id == service.id);
        if (index != -1) {
          final existingService = _services[index];
          final updatedService = service.copyWith(
            files: service.files.isEmpty ? existingService.files : service.files,
            distance: existingService.distance,
          );
          _services[index] = updatedService;
        }

        // Update in nearby list
        final nearbyIndex = _nearbyServices.indexWhere((s) => s.id == service.id);
        if (nearbyIndex != -1) {
          final existingNearby = _nearbyServices[nearbyIndex];
          double? distance = existingNearby.distance;
          if (_userLocation != null && service.lat != 0 && service.lng != 0) {
            distance = _calculateDistance(
              _userLocation!.latitude,
              _userLocation!.longitude,
              service.lat,
              service.lng,
            );
          }
          final updatedNearby = service.copyWith(
            files: service.files.isEmpty ? existingNearby.files : service.files,
            distance: distance,
          );
          _nearbyServices[nearbyIndex] = updatedNearby;
        }
        // Invalidate caches
        clearAllCache();
        notifyListeners();
      },
      onDelete: (id) {
        if (kDebugMode) {
          print('RealtimeService: Service deleted: $id');
        }
        // Remove from all lists
        _allServices.removeWhere((s) => s.id == id);
        _services.removeWhere((s) => s.id == id);
        _nearbyServices.removeWhere((s) => s.id == id);
        // Invalidate caches
        clearAllCache();
        notifyListeners();
      },
    );
    // Subscribe to profile verification changes
    _realtime.subscribeToProfiles(
      onVerificationChanged: (userId, isVerified) {
        if (kDebugMode) {
          print('ServiceProvider: Profile verification changed for user $userId: $isVerified');
          print('ServiceProvider: Total services to check: ${_allServices.length}');
          // Debug: Show sample service userIds for comparison
          final sampleIds = _allServices.take(3).map((s) => s.supabaseUserId).toList();
          print('ServiceProvider: Sample service userIds: $sampleIds');
        }
        // Update all services owned by this user
        // Use safe iteration by working on copies to prevent concurrent modification
        int updatedCount = 0;

        // Update in master list (_allServices) - create new list with updated items
        final updatedAllServices = _allServices.map((service) {
          if (service.supabaseUserId == userId) {
            updatedCount++;
            if (kDebugMode) {
              print('ServiceProvider: Updating service ${service.id} (${service.title}) - isOwnerVerified: $isVerified');
            }
            return service.copyWith(isOwnerVerified: isVerified);
          }
          return service;
        }).toList();
        _allServices = updatedAllServices;

        // Update in current view list (_services)
        final updatedServices = _services.map((service) {
          if (service.supabaseUserId == userId) {
            return service.copyWith(isOwnerVerified: isVerified);
          }
          return service;
        }).toList();
        _services = updatedServices;

        // Update in nearby list
        final updatedNearby = _nearbyServices.map((service) {
          if (service.supabaseUserId == userId) {
            return service.copyWith(isOwnerVerified: isVerified);
          }
          return service;
        }).toList();
        _nearbyServices = updatedNearby;

        if (kDebugMode) {
          print('ServiceProvider: Updated $updatedCount services for user $userId');
        }

        if (updatedCount > 0) {
          clearAllCache();
          notifyListeners();
          if (kDebugMode) {
            print('ServiceProvider: Cache cleared and listeners notified');
          }
        }
      },
    );

    if (kDebugMode) {
      print('ServiceProvider: Subscribed to real-time updates');
    }
  }

  /// Unsubscribe from real-time updates
  void unsubscribeFromRealtime() {
    _realtime.unsubscribeFromServices();
    _realtime.unsubscribeFromProfiles();
    if (kDebugMode) {
      print('ServiceProvider: Unsubscribed from real-time updates');
    }
  }

  @override
  void dispose() {
    unsubscribeFromRealtime();
    clear();
    clearAllCache();
    super.dispose();
  }
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/service_model.dart';

class SearchProvider with ChangeNotifier {
  // All services (source of truth)
  List<Service> _allServices = [];

  // Filtered results
  List<Service> _filteredServices = [];

  // Search state
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  // Filter state
  int? _selectedCategoryId;
  int? _selectedSubcategoryId;
  bool _useDistanceFilter = false;
  double _searchRadius = 10.0;
  Position? _userLocation;

  // Getters
  List<Service> get filteredServices => _filteredServices;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasResults => _filteredServices.isNotEmpty;
  int get resultsCount => _filteredServices.length;
  int? get selectedCategoryId => _selectedCategoryId;
  int? get selectedSubcategoryId => _selectedSubcategoryId;
  bool get useDistanceFilter => _useDistanceFilter;
  double get searchRadius => _searchRadius;

  // ✅ Initialize with all services
  void initializeServices(List<Service> services, Position? userLocation) {
    _allServices = services;
    _userLocation = userLocation;
    _filteredServices = services;
    debugPrint('SearchProvider: Initialized with ${services.length} services');
    notifyListeners();
  }

  // ✅ Update search query - REAL-TIME FILTERING
  void updateSearchQuery(String query) {
    _searchQuery = query.trim();
    debugPrint('SearchProvider: Search query: "$_searchQuery"');
    _applyFilters();
  }

  // ✅ Update category filter
  void updateCategoryFilter(int? categoryId) {
    _selectedCategoryId = categoryId;
    _selectedSubcategoryId = null; // Reset subcategory when category changes
    debugPrint('SearchProvider: Category filter: $categoryId');
    _applyFilters();
  }

  // ✅ Update subcategory filter
  void updateSubcategoryFilter(int? subcategoryId) {
    _selectedSubcategoryId = subcategoryId;
    debugPrint('SearchProvider: Subcategory filter: $subcategoryId');
    _applyFilters();
  }

  // ✅ Toggle distance filter
  void toggleDistanceFilter(bool value) {
    _useDistanceFilter = value;
    debugPrint('SearchProvider: Distance filter: $value');
    _applyFilters();
  }

  // ✅ Update search radius
  void updateSearchRadius(double radius) {
    _searchRadius = radius;
    debugPrint('SearchProvider: Search radius: $radius km');
    _applyFilters();
  }

  // ✅ MAIN FILTERING LOGIC - Applies all filters at once
  void _applyFilters() {
    List<Service> results = List.from(_allServices);

    // 1. Apply text search (ALWAYS - most important)
    if (_searchQuery.isNotEmpty) {
      results = results.where((service) {
        final query = _searchQuery.toLowerCase();
        return service.title.toLowerCase().contains(query) ||
            service.description.toLowerCase().contains(query) ||
            service.address.toLowerCase().contains(query) ||
            service.catName.toLowerCase().contains(query) ||
            service.subcatName.toLowerCase().contains(query) ||
            service.phone.contains(query);
      }).toList();

      debugPrint('SearchProvider: After text search: ${results.length} results');
    }

    // 2. Apply category filter (optional)
    if (_selectedCategoryId != null) {
      results = results.where((service) =>
      service.catId == _selectedCategoryId
      ).toList();

      debugPrint('SearchProvider: After category filter: ${results.length} results');
    }

    // 3. Apply subcategory filter (optional)
    if (_selectedSubcategoryId != null) {
      results = results.where((service) =>
      service.subcatId == _selectedSubcategoryId
      ).toList();

      debugPrint('SearchProvider: After subcategory filter: ${results.length} results');
    }

    // 4. Apply distance filter (optional)
    if (_useDistanceFilter && _userLocation != null) {
      results = results.where((service) {
        // Validate coordinates - check for zero and valid bounds
        if (service.lat == 0 || service.lng == 0) return false;
        if (!_isValidCoordinate(service.lat, service.lng)) return false;

        final distance = _calculateDistance(
          _userLocation!.latitude,
          _userLocation!.longitude,
          service.lat,
          service.lng,
        );

        return distance <= _searchRadius;
      }).toList();
      results.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));

      debugPrint('SearchProvider: After distance filter: ${results.length} results');
    }

    _filteredServices = results;
    debugPrint('SearchProvider: Final results: ${results.length}');
    notifyListeners();
  }

  // ✅ Reset all filters
  void resetFilters() {
    _selectedCategoryId = null;
    _selectedSubcategoryId = null;
    _useDistanceFilter = false;
    _searchRadius = 10.0;
    debugPrint('SearchProvider: Filters reset');
    _applyFilters();
  }

  // ✅ Clear search
  void clearSearch() {
    _searchQuery = '';
    debugPrint('SearchProvider: Search cleared');
    _applyFilters();
  }

  // ✅ Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // ✅ Set error
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // ✅ Calculate distance between two points
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371; // Earth’s radius in km
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
            sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (3.14159265359 / 180);

  // ✅ Validate coordinates are within valid bounds
  bool _isValidCoordinate(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  // ✅ Refresh with new services
  void refreshServices(List<Service> services) {
    _allServices = services;
    _applyFilters();
  }

  // ✅ Clear all
  void clear() {
    _allServices = [];
    _filteredServices = [];
    _searchQuery = '';
    _selectedCategoryId = null;
    _selectedSubcategoryId = null;
    _useDistanceFilter = false;
    _searchRadius = 10.0;
    _userLocation = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}
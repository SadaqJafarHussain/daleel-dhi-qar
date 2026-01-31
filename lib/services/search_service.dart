import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/service_model.dart';
import 'supabase_service.dart';
import 'cache_manager.dart';

/// Search service using Supabase with caching
class SearchService {
  static final SupabaseService _supabase = SupabaseService();
  static final CacheManager _cache = CacheManager();

  /// 🔍 Search for services with location and filters using Supabase
  static Future<SearchResponse> searchServices({
    required double lat,
    required double lng,
    required double radius,
    String? query,
    int? categoryId,
    int? subcategoryId,
  }) async {
    debugPrint('🔍 ===== SEARCH REQUEST (Supabase) =====');
    debugPrint('Location: ($lat, $lng)');
    debugPrint('Radius: $radius km');
    debugPrint('Query: $query');
    debugPrint('Category ID: $categoryId');
    debugPrint('Subcategory ID: $subcategoryId');

    try {
      // Build cache key
      final cacheKey = 'search_${lat.toStringAsFixed(2)}_${lng.toStringAsFixed(2)}_${radius}_${query ?? ''}_${categoryId ?? ''}_${subcategoryId ?? ''}';

      // Try cache first (short TTL for search)
      final cached = await _cache.getList('services', cacheKey);
      if (cached != null) {
        debugPrint('🔍 Search cache hit');
        final services = cached.map((json) => Service.fromJson(json)).toList();
        return SearchResponse(
          status: 'success',
          message: 'Cache hit',
          services: services,
        );
      }

      // Build Supabase query
      var queryBuilder = _supabase.client
          .from('services')
          .select('*, service_files(*), profiles!fk_services_user(name, is_verified)')
          .eq('active', true);

      // Apply category filter
      if (categoryId != null) {
        queryBuilder = queryBuilder.eq('cat_id', categoryId);
      }

      // Apply subcategory filter
      if (subcategoryId != null) {
        queryBuilder = queryBuilder.eq('subcat_id', subcategoryId);
      }

      // Apply text search filter with sanitization
      if (query != null && query.isNotEmpty) {
        // Sanitize query to prevent injection - escape special chars
        final sanitizedQuery = _sanitizeSearchQuery(query);
        if (sanitizedQuery.isNotEmpty) {
          queryBuilder = queryBuilder.or('title.ilike.%$sanitizedQuery%,description.ilike.%$sanitizedQuery%,address.ilike.%$sanitizedQuery%');
        }
      }

      final response = await queryBuilder.order('created_at', ascending: false);

      debugPrint('🔍 Raw results: ${response.length}');

      // Filter by distance with coordinate validation
      final List<Service> filteredServices = [];
      for (var item in response) {
        final service = Service.fromJson(Map<String, dynamic>.from(item));

        // Validate coordinates before calculating distance
        if (service.lat != 0 && service.lng != 0 &&
            _isValidCoordinate(service.lat, service.lng)) {
          final distance = _calculateDistance(lat, lng, service.lat, service.lng);

          if (distance <= radius) {
            service.distance = distance;
            filteredServices.add(service);
          }
        }
      }

      // Sort by distance
      filteredServices.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));

      debugPrint('✅ Search completed - Found ${filteredServices.length} services within $radius km');

      // Cache the result (short TTL)
      await _cache.set(
        'services',
        cacheKey,
        filteredServices.map((s) => s.toJson()).toList(),
        ttl: const Duration(minutes: 5),
      );

      return SearchResponse(
        status: 'success',
        message: 'Found ${filteredServices.length} services',
        services: filteredServices,
      );
    } catch (e) {
      debugPrint('❌ Search Error: $e');
      return SearchResponse(
        status: 'error',
        message: e.toString(),
        services: [],
      );
    }
  }

  /// Sanitize search query to prevent injection
  static String _sanitizeSearchQuery(String query) {
    // Remove special characters that could be dangerous for SQL/PostgREST
    var result = query;
    // Remove SQL wildcards, brackets, quotes, backslashes, and semicolons
    result = result.replaceAll(RegExp(r'[%_;\[\]{}()\\]'), '');
    result = result.replaceAll("'", '');
    result = result.replaceAll('"', '');
    // Remove PostgREST operators preceded by dot
    result = result.replaceAll(
      RegExp(r'\.(ilike|eq|neq|gt|lt|gte|lte|like|is|in|cs|cd|sl|sr|nxl|nxr|adj|ov|fts|plfts|phfts|wfts)'),
      '',
    );
    return result.trim();
  }

  /// Validate coordinates are within valid bounds
  static bool _isValidCoordinate(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  /// Calculate distance between two coordinates in km (Haversine formula)
  static double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371; // Earth radius in km
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _deg2rad(double deg) => deg * pi / 180;
}

/// Search Response Model
class SearchResponse {
  final String status;
  final String message;
  final List<Service> services;

  SearchResponse({
    required this.status,
    required this.message,
    required this.services,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    List<Service> servicesList = [];

    if (json['data'] != null) {
      if (json['data'] is List) {
        servicesList = (json['data'] as List)
            .map((item) => Service.fromJson(item))
            .toList();
      }
    }

    debugPrint('✅ Parsed ${servicesList.length} services');
    return SearchResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      services: servicesList,
    );
  }
}

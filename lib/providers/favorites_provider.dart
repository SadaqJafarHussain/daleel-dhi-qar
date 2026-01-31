import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/favorite.dart';
import '../services/favorites_service.dart';
import '../services/realtime_service.dart';

class FavoritesProvider with ChangeNotifier {
  // List of full favorite objects
  final List<Favorite> _favorites = [];

  // Set of favorite service IDs for quick lookup
  final Set<int> _favoriteIds = {};

  // Loading state
  bool _isLoading = false;
  bool _isFavoriteLoading = false;

  // Error state
  String? _errorMessage;

  // Services
  final RealtimeService _realtime = RealtimeService();

  // Current user ID (Supabase UUID)
  String? _supabaseUserId;

  // Debounce for toggle operations - prevents rapid clicks
  final Set<int> _pendingToggles = {};

  // Store enrichment functions
  String? Function(int)? _getCategoryName;
  String? Function(int)? _getSubcategoryName;

  // Set Supabase user ID
  void setSupabaseUserId(String? userId) {
    _supabaseUserId = userId;
    debugPrint('FavoritesProvider: Set Supabase user ID: $userId');
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get isFavoriteLoading => _isFavoriteLoading;
  String? get errorMessage => _errorMessage;
  List<Favorite> get favorites => List.unmodifiable(_favorites);
  Set<int> get favoriteIds => Set.unmodifiable(_favoriteIds);
  int get favoritesCount => _favoriteIds.length;
  bool get hasData => _favorites.isNotEmpty;

  // Set enrichment functions (call this during app initialization)
  void setEnrichmentFunctions({
    required String? Function(int) getCategoryName,
    required String? Function(int) getSubcategoryName,
  }) {
    _getCategoryName = getCategoryName;
    _getSubcategoryName = getSubcategoryName;
  }

  // Check if a service is favorite
  // Returns false if user is not authenticated (visitor mode)
  bool isFavorite(int serviceId) {
    // Visitors cannot have favorites
    if (_supabaseUserId == null || _supabaseUserId!.isEmpty) {
      return false;
    }
    final result = _favoriteIds.contains(serviceId);
    debugPrint('FavoritesProvider: isFavorite($serviceId): $result');
    return result;
  }

  // Get favorite by service ID
  Favorite? getFavoriteByServiceId(int serviceId) {
    try {
      return _favorites.firstWhere((fav) => fav.serviceId == serviceId);
    } catch (e) {
      return null;
    }
  }

  // Initialize favorites from storage
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString('favorites');

      if (favoritesJson != null) {
        final Map<String, dynamic> jsonData = json.decode(favoritesJson);
        final response = FavoritesResponse.fromJson(
          jsonData,
          getCategoryName: _getCategoryName,
          getSubcategoryName: _getSubcategoryName,
        );

        _favorites.clear();
        _favoriteIds.clear();

        _favorites.addAll(response.favorites);
        _favoriteIds.addAll(response.favorites.map((f) => f.serviceId));

        debugPrint('FavoritesProvider: Loaded ${_favorites.length} favorites from cache');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('FavoritesProvider: Error loading favorites from storage: $e');
    }
  }

  // Save favorites to storage
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final response = FavoritesResponse(
        status: 'success',
        message: 'Cached favorites',
        favorites: _favorites,
      );
      final favoritesJson = json.encode(response.toJson());
      await prefs.setString('favorites', favoritesJson);
      debugPrint('FavoritesProvider: Saved ${_favorites.length} favorites to cache');
    } catch (e) {
      debugPrint('FavoritesProvider: Error saving favorites to storage: $e');
    }
  }

  // Fetch favorites from Supabase
  Future<void> fetchFavorites() async {
    if (_supabaseUserId == null) {
      debugPrint('FavoritesProvider: No user ID set, skipping fetch');
      return;
    }

    debugPrint('FavoritesProvider: fetchFavorites called');

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await FavoritesService.getAllFavorites(
        _supabaseUserId!,
        getCategoryName: _getCategoryName,
        getSubcategoryName: _getSubcategoryName,
      );

      _favorites.clear();
      _favoriteIds.clear();

      _favorites.addAll(response.favorites);
      _favoriteIds.addAll(response.favorites.map((f) => f.serviceId));

      debugPrint('FavoritesProvider: Fetched ${_favorites.length} favorites');

      await _saveFavorites();

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('FavoritesProvider: Error fetching favorites: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle favorite with optimistic update and debounce
  Future<bool> toggleFavorite(int serviceId) async {
    if (_supabaseUserId == null) {
      debugPrint('FavoritesProvider: No user ID set, cannot toggle');
      return false;
    }

    // Validate serviceId
    if (serviceId <= 0) {
      debugPrint('FavoritesProvider: Invalid serviceId: $serviceId');
      return false;
    }

    // Prevent rapid clicks - debounce per service
    if (_pendingToggles.contains(serviceId)) {
      debugPrint('FavoritesProvider: Toggle already pending for $serviceId');
      return false;
    }
    _pendingToggles.add(serviceId);

    debugPrint('FavoritesProvider: toggleFavorite($serviceId) called');

    _isFavoriteLoading = true;
    notifyListeners();

    // Check current state
    final wasLiked = _favoriteIds.contains(serviceId);

    // Optimistic update - save state for potential rollback
    Favorite? removedFavorite;
    if (wasLiked) {
      // Find and remove favorite
      final index = _favorites.indexWhere((fav) => fav.serviceId == serviceId);
      if (index != -1) {
        removedFavorite = _favorites[index];
        _favorites.removeAt(index);
      }
      _favoriteIds.remove(serviceId);
    } else {
      _favoriteIds.add(serviceId);
    }

    notifyListeners();

    try {
      // Make Supabase call
      final success = await FavoritesService.toggleFavorite(
        serviceId,
        _supabaseUserId!,
      );

      if (!success) {
        // Revert optimistic update
        _revertOptimisticUpdate(wasLiked, serviceId, removedFavorite);
        _isFavoriteLoading = false;
        notifyListeners();
        return false;
      }

      // Fetch fresh data after successful toggle
      try {
        await fetchFavorites();
      } catch (fetchError) {
        // Fetch failed but toggle succeeded - keep optimistic state
        debugPrint('FavoritesProvider: Fetch after toggle failed: $fetchError');
      }

      _isFavoriteLoading = false;
      _pendingToggles.remove(serviceId);
      return true;
    } catch (e) {
      debugPrint('FavoritesProvider: Exception during toggle: $e');

      // Revert optimistic update on error
      _revertOptimisticUpdate(wasLiked, serviceId, removedFavorite);

      _isFavoriteLoading = false;
      _pendingToggles.remove(serviceId);
      notifyListeners();
      return false;
    }
  }

  /// Helper to revert optimistic update
  void _revertOptimisticUpdate(bool wasLiked, int serviceId, Favorite? removedFavorite) {
    if (wasLiked) {
      // Was liked before, we removed it, now restore
      if (removedFavorite != null) {
        _favorites.add(removedFavorite);
      }
      _favoriteIds.add(serviceId);
    } else {
      // Was not liked before, we added it, now remove
      _favoriteIds.remove(serviceId);
      // Don't need to remove from _favorites as we didn't add the full object
    }
  }

  // Add to favorites
  Future<bool> addFavorite(int serviceId) async {
    if (_favoriteIds.contains(serviceId)) {
      return true;
    }
    return await toggleFavorite(serviceId);
  }

  // Remove from favorites
  Future<bool> removeFavorite(int serviceId) async {
    if (!_favoriteIds.contains(serviceId)) {
      return true;
    }
    return await toggleFavorite(serviceId);
  }

  // Clear all favorites (logout)
  void clearFavorites() {
    _favorites.clear();
    _favoriteIds.clear();
    _isLoading = false;
    _isFavoriteLoading = false;
    _errorMessage = null;
    _supabaseUserId = null;
    notifyListeners();
  }

  // Refresh favorites
  Future<void> refreshFavorites() async {
    if (_supabaseUserId != null) {
      await FavoritesService.clearCache(_supabaseUserId!);
    }
    await fetchFavorites();
  }

  // Subscribe to real-time updates
  void subscribeToRealtime() {
    if (_supabaseUserId == null) return;

    _realtime.subscribeToFavorites(
      odUserId: _supabaseUserId!,
      onInsert: (favorite) {
        if (!_favoriteIds.contains(favorite.serviceId)) {
          _favorites.add(favorite);
          _favoriteIds.add(favorite.serviceId);
          notifyListeners();
        }
      },
      onDelete: (favoriteId, serviceId) {
        _favorites.removeWhere((f) => f.id == favoriteId);
        _favoriteIds.remove(serviceId);
        notifyListeners();
      },
    );
  }

  // Unsubscribe from real-time updates
  void unsubscribeFromRealtime() {
    _realtime.unsubscribeFromFavorites();
  }

  @override
  void dispose() {
    unsubscribeFromRealtime();
    _favorites.clear();
    _favoriteIds.clear();
    super.dispose();
  }
}

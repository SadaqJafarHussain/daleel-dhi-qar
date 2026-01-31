import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart' as cat_model;
import '../services/supabase_service.dart';
import '../services/realtime_service.dart';
import '../config/app_config.dart';

typedef Category = cat_model.Category;

class CategoryProvider with ChangeNotifier {
  static const String cacheKey = 'cached_categories';
  final SupabaseService _supabase = SupabaseService();
  final RealtimeService _realtime = RealtimeService();
  BuildContext? _context;

  bool _isLoading = false;
  bool _isFetching = false; // Prevents concurrent fetches
  bool get isLoading => _isLoading;

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  /// Use context to access AuthProvider token
  Future<void> init(BuildContext context) async {
    _context = context;
    await _loadFromCache();
    await fetchCategories(context);
  }

  Future<void> fetchCategories(BuildContext context) async {
    // Prevent concurrent fetch attempts
    if (_isFetching) {
      debugPrint('CategoryProvider: Fetch already in progress, skipping');
      return;
    }

    _isFetching = true;
    _isLoading = true;
    notifyListeners();

    try {
      if (_supabase.isInitialized) {
        // Force refresh if cache returned empty (likely stale/invalid cache)
        var data = await _supabase.fetchWithCache(
          table: 'categories',
          cacheKey: 'all_categories',
          cacheBox: 'categories',
          cacheDuration: AppConfig.categoryCacheDuration,
          eq: {'active': true},
          orderBy: 'id',
        );

        // If cache returned empty, try ONE refresh from server (no retry loop)
        if (data.isEmpty) {
          debugPrint('CategoryProvider: Cache empty, forcing single refresh...');
          data = await _supabase.fetchWithCache(
            table: 'categories',
            cacheKey: 'all_categories',
            cacheBox: 'categories',
            cacheDuration: AppConfig.categoryCacheDuration,
            eq: {'active': true},
            orderBy: 'id',
            forceRefresh: true,
          );
        }

        _categories = data.map<Category>((e) => Category.fromJson(e)).toList();
        await _saveToCache();
        debugPrint('CategoryProvider: Loaded ${_categories.length} categories');
      } else {
        debugPrint('CategoryProvider: Supabase not initialized');
      }
    } catch (e) {
      debugPrint("CategoryProvider: fetch failed: $e");
      // Don't clear existing categories on error - keep stale data
    }

    _isLoading = false;
    _isFetching = false;
    notifyListeners();
  }

  /// Get category name by ID
  String? getCategoryNameById(int id) {
    try {
      final category = _categories.firstWhere((cat) => cat.id == id);
      return category.name;
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      final List decoded = json.decode(cached);
      _categories = decoded.map<Category>((e) => Category.fromJson(e)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveToCache() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(_categories.map((e) => e.toJson()).toList());
    await prefs.setString(cacheKey, encoded);
  }

  /// Subscribe to real-time category updates
  void subscribeToRealtime() {
    _realtime.subscribeToCategories(
      onAnyChange: () {
        debugPrint('CategoryProvider: Real-time category change detected');
        // Refresh categories when any change is detected
        if (_context != null) {
          fetchCategories(_context!);
        }
      },
    );
    debugPrint('CategoryProvider: Subscribed to real-time updates');
  }

  /// Unsubscribe from real-time updates
  void unsubscribeFromRealtime() {
    _realtime.unsubscribe('categories_all');
    debugPrint('CategoryProvider: Unsubscribed from real-time updates');
  }
}

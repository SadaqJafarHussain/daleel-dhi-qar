import 'package:flutter/foundation.dart';

import '../models/subcategory_model.dart';
import '../services/supabase_service.dart';
import '../services/realtime_service.dart';

/// Subcategory provider - No caching, real-time only
class SubcategoryProvider with ChangeNotifier {
  // State
  List<Subcategory> _subcategories = [];
  bool _isLoading = false;
  String? _error;
  bool _isSubscribed = false;

  // Services
  final SupabaseService _supabase = SupabaseService();
  final RealtimeService _realtime = RealtimeService();

  // Getters
  List<Subcategory> get subcategories => _subcategories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _subcategories.isNotEmpty;

  // Get subcategories by category ID
  List<Subcategory> getByCategory(int categoryId) {
    return _subcategories.where((subcat) => subcat.catId == categoryId).toList();
  }

  /// Get subcategory by ID
  Subcategory? getById(int id) {
    try {
      return _subcategories.firstWhere((subcat) => subcat.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get subcategory name by ID
  String? getSubcategoryNameById(int id) {
    return getById(id)?.name;
  }

  // Check if category has subcategories
  bool hasSubcategories(int categoryId) {
    return _subcategories.any((subcat) => subcat.catId == categoryId);
  }

  // Get subcategories count by category
  int getCountByCategory(int categoryId) {
    return getByCategory(categoryId).length;
  }

  /// Fetch all subcategories directly from database (no cache)
  Future<void> fetchSubcategories(String token, {bool forceRefresh = false}) async {
    // If already have data and not forcing refresh, skip
    if (!forceRefresh && _subcategories.isNotEmpty && !_isLoading) {
      debugPrint('SubcategoryProvider: Using existing data (${_subcategories.length} items)');
      return;
    }

    _isLoading = true;
    _error = null;
    Future.microtask(() => notifyListeners());

    try {
      if (_supabase.isInitialized) {
        // Direct fetch from Supabase - no caching
        final response = await _supabase.client
            .from('subcategories')
            .select('*')
            .eq('active', true)
            .order('id', ascending: true);

        final data = List<Map<String, dynamic>>.from(response);
        _subcategories = data.map((json) => Subcategory.fromJson(json)).toList();
        _error = null;

        debugPrint('SubcategoryProvider: Loaded ${_subcategories.length} subcategories');
      } else {
        _error = 'Supabase not initialized';
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      debugPrint('SubcategoryProvider Exception: $e');
      // Don't clear existing data on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh subcategories
  Future<void> refreshSubcategories(String token) async {
    _subcategories = []; // Clear to force reload
    return await fetchSubcategories(token, forceRefresh: true);
  }

  /// Subscribe to real-time subcategory updates
  void subscribeToRealtime() {
    if (_isSubscribed) return;

    _realtime.subscribeToSubcategories(
      onInsert: (Subcategory subcategory) {
        debugPrint('SubcategoryProvider: Real-time insert: ${subcategory.name}');
        // Check if already exists (prevent duplicates)
        final exists = _subcategories.any((s) => s.id == subcategory.id);
        if (!exists) {
          _subcategories.add(subcategory);
          _subcategories.sort((a, b) => a.id.compareTo(b.id));
          notifyListeners();
        }
      },
      onUpdate: (Subcategory subcategory) {
        debugPrint('SubcategoryProvider: Real-time update: ${subcategory.name}');
        final index = _subcategories.indexWhere((s) => s.id == subcategory.id);
        if (index != -1) {
          _subcategories[index] = subcategory;
          notifyListeners();
        }
      },
      onDelete: (int id) {
        debugPrint('SubcategoryProvider: Real-time delete: $id');
        _subcategories.removeWhere((s) => s.id == id);
        notifyListeners();
      },
    );

    _isSubscribed = true;
    debugPrint('SubcategoryProvider: Subscribed to real-time updates');
  }

  /// Unsubscribe from real-time updates
  void unsubscribeFromRealtime() {
    if (!_isSubscribed) return;
    _realtime.unsubscribe('subcategories_all');
    _isSubscribed = false;
    debugPrint('SubcategoryProvider: Unsubscribed from real-time updates');
  }

  // Clear all data
  void clear() {
    _subcategories = [];
    _error = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    unsubscribeFromRealtime();
    clear();
    super.dispose();
  }
}

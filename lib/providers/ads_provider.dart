import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../models/adds_model.dart';
import '../services/supabase_service.dart';
import '../services/realtime_service.dart';
import '../services/cache_manager.dart';
import 'auth_provider.dart';

class AdvProvider extends ChangeNotifier {
  List<AdvModel> _allAds = []; // All ads (unfiltered)
  List<AdvModel> ads = [];      // Filtered ads for current user
  bool isLoading = false;
  final SupabaseService _supabase = SupabaseService();
  final RealtimeService _realtime = RealtimeService();
  final CacheManager _cache = CacheManager();
  BuildContext? _context;

  /// Fetch ads and filter based on user profile
  Future<void> fetchAds(BuildContext context, {bool forceRefresh = false}) async {
    _context = context;

    if (isLoading || (_allAds.isNotEmpty && !forceRefresh)) {
      // If ads are already loaded, just re-filter for current user
      if (_allAds.isNotEmpty) {
        _filterAdsForUser(context);
      }
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      if (_supabase.isInitialized) {
        var data = await _supabase.fetchWithCache(
          table: 'ads',
          cacheKey: 'all_ads',
          cacheBox: 'ads',
          cacheDuration: AppConfig.adsCacheDuration,
          eq: {'active': true},
          orderBy: 'created_at',
          ascending: false,
        );

        // If cache returned empty, force refresh from server
        if (data.isEmpty) {
          debugPrint('AdvProvider: Cache empty, forcing refresh...');
          data = await _supabase.fetchWithCache(
            table: 'ads',
            cacheKey: 'all_ads',
            cacheBox: 'ads',
            cacheDuration: AppConfig.adsCacheDuration,
            eq: {'active': true},
            orderBy: 'created_at',
            ascending: false,
            forceRefresh: true,
          );
        }

        _allAds = data.map((json) => AdvModel.fromJson(json)).toList();
        _filterAdsForUser(context);
        debugPrint('AdvProvider: Loaded ${_allAds.length} ads, showing ${ads.length} after targeting');
      } else {
        // Use fallback ads if Supabase not initialized
        _allAds = _getFallbackAds();
        _filterAdsForUser(context);
      }
    } catch (e) {
      debugPrint("AdvProvider Exception: $e");
      // Fallback to mock ads if API fails
      _allAds = _getFallbackAds();
      _filterAdsForUser(context);
    }

    isLoading = false;
    notifyListeners();
  }

  /// Filter ads based on current user's profile
  void _filterAdsForUser(BuildContext context) {
    // Safely get AuthProvider with null check
    AuthProvider? authProvider;
    try {
      authProvider = Provider.of<AuthProvider>(context, listen: false);
    } catch (e) {
      debugPrint('AdvProvider: AuthProvider not available: $e');
    }

    final user = authProvider?.user;

    if (user == null) {
      // Guest user - show only non-targeted ads
      ads = _allAds.where((ad) => !ad.targeting.hasTargeting).toList();
      debugPrint('AdvProvider: Guest user: showing ${ads.length} non-targeted ads');
    } else {
      // Logged in user - filter based on targeting
      ads = _allAds.where((ad) => ad.shouldShowToUser(user)).toList();
      debugPrint('AdvProvider: User ${user.name}: showing ${ads.length}/${_allAds.length} targeted ads');
    }

    // If no ads match, show at least the non-targeted ones
    if (ads.isEmpty && _allAds.isNotEmpty) {
      ads = _allAds.where((ad) => !ad.targeting.hasTargeting).toList();
      debugPrint('AdvProvider: No targeted ads match, showing ${ads.length} general ads');
    }
  }

  /// Refresh ads for a new user (call after login/logout)
  void refreshAdsForUser(BuildContext context) {
    if (_allAds.isNotEmpty) {
      _filterAdsForUser(context);
      notifyListeners();
    }
  }

  /// Clear all ads (call on logout)
  void clearAds() {
    _allAds.clear();
    ads.clear();
    notifyListeners();
  }

  /// Force refresh ads - clears cache and reloads from server
  Future<void> forceRefreshAds(BuildContext context) async {
    debugPrint('AdvProvider: Force refreshing ads...');
    _allAds.clear();
    ads.clear();
    await _cache.delete('ads', 'all_ads');
    isLoading = false; // Reset loading state
    await fetchAds(context, forceRefresh: true);
  }

  /// Get fallback mock ads for testing
  List<AdvModel> _getFallbackAds() {
    return [
      AdvModel(
        id: 1,
        title: 'اكتشف معالم ذي قار التاريخية',
        content: 'زوروا أور الأثرية ومعبد زقورة أور الشهير - رحلة عبر التاريخ',
        image: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/Ziggurat_of_ur.jpg/1280px-Ziggurat_of_ur.jpg',
        link: 'https://en.wikipedia.org/wiki/Ziggurat_of_Ur',
        adType: AdType.externalLink,
        isSponsored: true,
      ),
      AdvModel(
        id: 2,
        title: 'أفضل المطاعم في الناصرية',
        content: 'تذوق أشهى المأكولات العراقية الأصيلة',
        image: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800',
        link: '',
        serviceId: 1,
        adType: AdType.servicePromotion,
        isSponsored: true,
      ),
      AdvModel(
        id: 3,
        title: 'فنادق مميزة بأسعار منافسة',
        content: 'احجز إقامتك الآن واستمتع بخصم 20%',
        image: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800',
        link: 'https://booking.com',
        adType: AdType.externalLink,
        isSponsored: false,
      ),
    ];
  }

  /// Subscribe to real-time ads updates
  void subscribeToRealtime() {
    _realtime.subscribeToAds(
      onAnyChange: () {
        debugPrint('AdvProvider: Real-time ads change detected');
        // Clear cache and reload ads
        _allAds.clear();
        _cache.delete('ads', 'all_ads');
        if (_context != null) {
          fetchAds(_context!, forceRefresh: true);
        }
      },
    );
    debugPrint('AdvProvider: Subscribed to real-time updates');
  }

  /// Unsubscribe from real-time updates
  void unsubscribeFromRealtime() {
    _realtime.unsubscribeFromAds();
    debugPrint('AdvProvider: Unsubscribed from real-time updates');
  }

  @override
  void dispose() {
    unsubscribeFromRealtime();
    _allAds.clear();
    ads.clear();
    _context = null;
    super.dispose();
  }
}

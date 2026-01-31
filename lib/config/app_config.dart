/// Application configuration for Supabase backend
class AppConfig {
  // ========================================
  // SUPABASE CONFIGURATION
  // ========================================
  /// Your Supabase project URL
  static const String supabaseUrl = 'https://exnbjsehnyqjgllgmjxt.supabase.co';

  /// Your Supabase anonymous/public key
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV4bmJqc2VobnlxamdsbGdtanh0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyMTc0NzgsImV4cCI6MjA4MDc5MzQ3OH0.LqJxMKL2KBanDNmnDhaLyAQiv9xTQBByORSO8NN-Zmk';

  // ========================================
  // CACHE CONFIGURATION
  // ========================================
  /// How long to cache categories (long-lived, rarely change)
  static const Duration categoryCacheDuration = Duration(hours: 24);

  /// How long to cache subcategories
  static const Duration subcategoryCacheDuration = Duration(hours: 24);

  /// How long to cache services list
  static const Duration serviceCacheDuration = Duration(minutes: 30);

  /// How long to cache nearby services (location-based, shorter TTL)
  static const Duration nearbyCacheDuration = Duration(minutes: 5);

  /// How long to cache user profile
  static const Duration profileCacheDuration = Duration(hours: 12);

  /// How long to cache favorites
  static const Duration favoritesCacheDuration = Duration(hours: 1);

  /// How long to cache reviews
  static const Duration reviewsCacheDuration = Duration(minutes: 15);

  /// How long to cache ads
  static const Duration adsCacheDuration = Duration(hours: 6);

  // ========================================
  // OFFLINE SYNC CONFIGURATION
  // ========================================
  /// Maximum number of operations to queue when offline
  static const int maxOfflineQueueSize = 100;

  /// How often to retry syncing offline operations
  static const Duration syncRetryInterval = Duration(minutes: 5);

  /// Maximum retry attempts for a single operation
  static const int maxRetryAttempts = 3;

  // ========================================
  // LOCATION DEFAULTS
  // ========================================
  /// Default location (Nasiriyah, Iraq) when GPS is unavailable
  static const double defaultLatitude = 31.0439;
  static const double defaultLongitude = 46.2576;

  /// Maximum distance for nearby services (km)
  static const double maxNearbyDistanceKm = 50.0;

  // ========================================
  // STORAGE CONFIGURATION
  // ========================================
  /// Supabase storage bucket for service images
  static const String serviceImagesBucket = 'service-images';

  /// Supabase storage bucket for user avatars
  static const String avatarsBucket = 'avatars';

  /// Maximum image size in bytes (5MB)
  static const int maxImageSize = 5 * 1024 * 1024;

  // ========================================
  // REAL-TIME CONFIGURATION
  // ========================================
  /// Enable real-time subscriptions
  static const bool enableRealtime = true;

  /// Tables to subscribe to for real-time updates
  static const List<String> realtimeTables = [
    'services',
    'reviews',
    'favorites',
  ];

  // ========================================
  // HELPER METHODS
  // ========================================

  /// Always use Supabase
  static bool get useSupabase => true;

  /// Check if Supabase is properly configured
  static bool get isSupabaseConfigured =>
      supabaseUrl != 'YOUR_SUPABASE_URL' &&
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY' &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty;
}

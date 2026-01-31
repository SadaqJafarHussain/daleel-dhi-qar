import 'package:mocktail/mocktail.dart';
import 'package:tour_guid/services/supabase_service.dart';
import 'package:tour_guid/services/cache_manager.dart';
import 'package:tour_guid/services/connectivity_service.dart';
import 'package:tour_guid/services/realtime_service.dart';
import 'package:tour_guid/services/favorites_service.dart';
import 'package:tour_guid/models/favorite.dart';

/// Mock for SupabaseService
class MockSupabaseService extends Mock implements SupabaseService {}

/// Mock for CacheManager
class MockCacheManager extends Mock implements CacheManager {}

/// Mock for ConnectivityService
class MockConnectivityService extends Mock implements ConnectivityService {}

/// Mock for RealtimeService
class MockRealtimeService extends Mock implements RealtimeService {}

/// Register fallback values for mocktail
void registerFallbackValues() {
  registerFallbackValue(const Duration(seconds: 1));
  registerFallbackValue(<String, dynamic>{});
  registerFallbackValue(<Map<String, dynamic>>[]);
}

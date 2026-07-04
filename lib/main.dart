import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:tour_guid/providers/ads_provider.dart';
import 'package:tour_guid/providers/auth_provider.dart';
import 'package:tour_guid/providers/category_provider.dart';
import 'package:tour_guid/providers/favorites_provider.dart';
import 'package:tour_guid/providers/language_provider.dart';
import 'package:tour_guid/providers/search_provider.dart';
import 'package:tour_guid/providers/service_peovider.dart';
import 'package:tour_guid/providers/subcategory_provider.dart';
import 'package:tour_guid/providers/theme_provider.dart';
import 'package:tour_guid/providers/review_provider.dart';
import 'package:tour_guid/providers/notification_provider.dart';
import 'package:tour_guid/providers/app_settings_provider.dart';
import 'package:tour_guid/providers/home_sections_provider.dart';
import 'package:tour_guid/providers/home_sections_config_provider.dart';
import 'package:tour_guid/providers/app_config_provider.dart';
import 'package:tour_guid/screens/splash_screen.dart';
import 'package:tour_guid/utils/app_localization.dart';
import 'package:tour_guid/utils/app_theme.dart';
import 'package:tour_guid/config/app_config.dart';
import 'package:tour_guid/services/supabase_service.dart';
import 'package:tour_guid/services/cache_manager.dart';
import 'package:tour_guid/services/connectivity_service.dart';
import 'package:tour_guid/services/sync_service.dart';
import 'package:tour_guid/services/navigation_service.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM Background Message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core services before running the app
  await _initializeServices();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()..init()),
        ChangeNotifierProvider(create: (_) => AdvProvider()),
        ChangeNotifierProvider(create: (context) => CategoryProvider()..init(context)),
        ChangeNotifierProvider(create: (_) => SubcategoryProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
        ChangeNotifierProvider(create: (_) => HomeSectionsProvider()),
        ChangeNotifierProvider(create: (_) => HomeSectionsConfigProvider()..fetchConfigs()),
        ChangeNotifierProvider(create: (_) => AppConfigProvider()..fetchConfig()),
      ],
      child: const DaleelAwrApp(),
    ),
  );
}

/// Initialize core services (Firebase, Supabase, Cache, Connectivity)
Future<void> _initializeServices() async {
  try {
    // Initialize Firebase (non-blocking - continue if it fails)
    try {
      await Firebase.initializeApp();
      debugPrint('Main: Firebase initialized');

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      debugPrint('Main: Firebase background message handler set');
    } catch (e) {
      debugPrint('Main: Firebase init failed (app will continue): $e');
    }

    // Initialize cache manager (Hive)
    await CacheManager().init();
    debugPrint('Main: CacheManager initialized');

    // Clear caches on startup to ensure fresh data
    await CacheManager().delete('services', 'all_services');
    await CacheManager().delete('subcategories', 'all_subcategories');
    debugPrint('Main: Caches cleared for fresh data');

    // Initialize connectivity service
    await ConnectivityService().init();
    debugPrint('Main: ConnectivityService initialized');

    // Initialize Supabase if configured
    if (AppConfig.useSupabase && AppConfig.isSupabaseConfigured) {
      await SupabaseService().init();
      debugPrint('Main: SupabaseService initialized');

      // Initialize sync service
      await SyncService().init();
      debugPrint('Main: SyncService initialized');

      // Sync offline queue if online
      if (ConnectivityService().isOnline) {
        final syncResult = await SyncService().syncOfflineQueue();
        debugPrint('Main: Initial sync result: $syncResult');
      }
    }
  } catch (e) {
    debugPrint('Main: Error initializing services: $e');
  }
}

class DaleelAwrApp extends StatefulWidget {
  const DaleelAwrApp({Key? key}) : super(key: key);

  @override
  State<DaleelAwrApp> createState() => _DaleelAwrAppState();
}

class _DaleelAwrAppState extends State<DaleelAwrApp> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  /// Initialize all providers in the correct order
  Future<void> _initializeProviders() async {
    if (_isInitialized) return;

    // Capture all providers synchronously before any await
    final categoryProvider     = Provider.of<CategoryProvider>(context, listen: false);
    final subcategoryProvider  = Provider.of<SubcategoryProvider>(context, listen: false);
    final favoritesProvider    = Provider.of<FavoritesProvider>(context, listen: false);
    final authProvider         = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    final serviceProvider      = Provider.of<ServiceProvider>(context, listen: false);
    final reviewProvider       = Provider.of<ReviewProvider>(context, listen: false);
    final adsProvider          = Provider.of<AdvProvider>(context, listen: false);

    try {
      // Wait for categories to load
      if (categoryProvider.categories.isEmpty && !categoryProvider.isLoading) {
        await categoryProvider.fetchCategories(context);
      }

      // Initialize subcategories (for both authenticated users and visitors)
      if (subcategoryProvider.subcategories.isEmpty) {
        // Pass empty string for visitors - subcategory fetch doesn't actually need auth token
        await subcategoryProvider.fetchSubcategories(authProvider.token ?? '');
      }

      // Set up enrichment functions for favorites
      favoritesProvider.setEnrichmentFunctions(
        getCategoryName: categoryProvider.getCategoryNameById,
        getSubcategoryName: subcategoryProvider.getSubcategoryNameById,
      );

      // Set Supabase user ID for favorites
      if (authProvider.supabaseUserId != null) {
        favoritesProvider.setSupabaseUserId(authProvider.supabaseUserId);
      }

      // Initialize favorites (will load from cache with enrichment)
      await favoritesProvider.init();

      // Fetch favorites from Supabase if user is authenticated
      if (authProvider.supabaseUserId != null) {
        await favoritesProvider.fetchFavorites();
        // Subscribe to real-time favorites updates
        favoritesProvider.subscribeToRealtime();

        // Initialize notifications for the user
        await notificationProvider.setUser(authProvider.supabaseUserId!);
      }

      // Fetch all services and subscribe to real-time updates
      await serviceProvider.fetchAllServices();
      serviceProvider.subscribeToRealtime();

      // Connect ReviewProvider to ServiceProvider for rating updates
      reviewProvider.setServiceProvider(serviceProvider);

      // Subscribe to real-time category updates
      categoryProvider.subscribeToRealtime();

      // Subscribe to real-time subcategory updates
      subcategoryProvider.subscribeToRealtime();

      // Subscribe to real-time ads updates
      adsProvider.subscribeToRealtime();

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing providers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ThemeProvider, LanguageProvider, AppConfigProvider>(
      builder: (context, themeProvider, languageProvider, appConfig, child) {
        final primary   = appConfig.primaryColor;
        final secondary = appConfig.secondaryColor;
        return MaterialApp(
          title: 'Daleel Dhi Qar',
          debugShowCheckedModeBanner: false,
          navigatorKey: NavigationService().navigatorKey,

          // Localization Configuration
          locale: languageProvider.locale,
          supportedLocales: const [
            Locale('ar', 'SA'), // Arabic
            Locale('en', 'US'), // English
          ],

          // Localization delegates
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // RTL/LTR + Global font scale from admin
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(appConfig.fontScale),
              ),
              child: Directionality(
                textDirection: languageProvider.textDirection,
                child: child!,
              ),
            );
          },

          // Theme Configuration (dynamic colors from admin)
          theme: AppThemes.buildLightTheme(primary, secondary),
          darkTheme: AppThemes.buildDarkTheme(primary, secondary),
          themeMode: themeProvider.themeMode,

          home: const SplashScreen(),
        );
      },
    );
  }
}

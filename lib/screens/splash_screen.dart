// ============================================
// main.dart - Session & Onboarding Flow
// Location: lib/main.dart
// ============================================
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tour_guid/screens/main_screen.dart';

import '../providers/auth_provider.dart';
import '../providers/app_config_provider.dart';
import '../providers/language_provider.dart';
import '../utils/app_localization.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'complete_profile_screen.dart';
import 'force_update_screen.dart';


// ============================================
// Splash Screen - Determines Initial Route
// ============================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }

  Future<void> _checkInitialRoute() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final configProvider = Provider.of<AppConfigProvider>(context, listen: false);

    // Initialize auth + fetch config in parallel
    await Future.wait([
      authProvider.init(),
      configProvider.fetchConfig(),
    ]);

    // Check for forced update
    if (mounted && await _checkForceUpdate(configProvider)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ForceUpdateScreen()),
      );
      return;
    }

    // Check if onboarding has been completed
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    // Wait a bit for splash effect (optional)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Navigation Logic:
    // 1. First time user → Show Onboarding
    // 2. Returning user, not logged in → Show Login
    // 3. Returning user, logged in but profile incomplete → Show Complete Profile
    // 4. Returning user, logged in with complete profile → Show Home

    if (!hasSeenOnboarding) {
      // First time user - show onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    } else if (!authProvider.isAuthenticated) {
      // User has seen onboarding but not logged in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else if (authProvider.needsProfileCompletion) {
      // User is logged in but hasn't completed profile
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CompleteProfileScreen()),
      );
    } else {
      // User is logged in with complete profile
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  Future<bool> _checkForceUpdate(AppConfigProvider cfg) async {
    if (cfg.get('force_update_enabled') != 'true') return false;
    final minVersion = cfg.get('min_version');
    if (minVersion.isEmpty) return false;
    try {
      final info = await PackageInfo.fromPlatform();
      return _versionLessThan(info.version, minVersion);
    } catch (_) {
      return false;
    }
  }

  /// Returns true if [current] is strictly less than [minimum].
  bool _versionLessThan(String current, String minimum) {
    final c = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final m = minimum.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final cv = i < c.length ? c[i] : 0;
      final mv = i < m.length ? m[i] : 0;
      if (cv < mv) return true;
      if (cv > mv) return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfigProvider>();
    final isAr = context.watch<LanguageProvider>().isArabic;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/splash_logo.png",
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            Text(
              appConfig.appName(isAr),
              style: TextStyle(
                color: Theme.of(context).textTheme.labelLarge!.color,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              appConfig.appTagline(isAr),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium!.color,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

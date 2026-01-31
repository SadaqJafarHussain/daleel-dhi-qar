// ============================================
// main.dart - Session & Onboarding Flow
// Location: lib/main.dart
// ============================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tour_guid/screens/main_screen.dart';

import '../providers/auth_provider.dart';
import '../utils/app_localization.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'complete_profile_screen.dart';


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

    // Initialize auth provider (restores session if exists)
    await authProvider.init();

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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your app logo here
            Image.asset(
              "assets/images/splash_logo.png",
              width: 200,  // or any size you want
              height: 200, // keep it square to match launcher icon
              fit: BoxFit.contain,
            ),
             Text(loc.t('app_name'),style: TextStyle(color: Theme.of(context).textTheme.labelLarge!.color,fontWeight: FontWeight.w800,fontSize: 22),),
            const SizedBox(height: 20),
             CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

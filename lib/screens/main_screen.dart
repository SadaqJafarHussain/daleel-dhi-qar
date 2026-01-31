import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tour_guid/providers/auth_provider.dart';
import 'package:tour_guid/screens/profile_screen/profile_screen.dart';
import 'package:tour_guid/screens/settings_screen.dart';
import 'package:tour_guid/utils/app_localization.dart';
import 'favorites_screen.dart';
import 'home screen/home_screen.dart';
import 'widgets/add_service_sheet.dart';
import 'widgets/login_prompt_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2; // Start with Home (index 2)

  // Build screens dynamically with keys based on auth state to force rebuild
  List<Widget> _buildScreens(bool isAuthenticated) {
    // Using a key based on auth state ensures screens rebuild when auth changes
    final authKey = isAuthenticated ? 'auth' : 'visitor';
    return [
      ProfileScreen(key: ValueKey('profile_$authKey')),
      FavoritesScreen(key: ValueKey('favorites_$authKey')),
      const HomeScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final w = MediaQuery.of(context).size.width;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screens = _buildScreens(authProvider.isAuthenticated);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackNavigation();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
        bottomNavigationBar: _buildBottomNavBar(w, isDarkMode),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            // Check if user is authenticated
            if (authProvider.user == null) {
              showLoginPromptDialog(context, feature: 'add_service');
              return;
            }
            await openAddServiceSheet(context);
            // UI will automatically update because provider calls notifyListeners()
          },
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 6,
          child: Icon(Icons.add, color: Colors.white, size: w * 0.07),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  /// Handle back navigation - go to home or show exit dialog
  Future<void> _handleBackNavigation() async {
    // If not on home screen, navigate to home
    if (_currentIndex != 2) {
      setState(() {
        _currentIndex = 2;
      });
      return;
    }

    // If on home screen, show exit confirmation dialog
    final shouldExit = await _showExitConfirmationDialog();
    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  /// Show exit confirmation dialog
  Future<bool?> _showExitConfirmationDialog() {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.exit_to_app,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                loc.t('exit_app'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          loc.t('exit_app_confirm'),
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              loc.t('cancel'),
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(loc.t('exit')),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(double w, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
        selectedFontSize: w * 0.03,
        unselectedFontSize: w * 0.028,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: [
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Icon(Icons.person_outline, size: w * 0.065),
            ),
            activeIcon: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Icon(Icons.person, size: w * 0.065),
            ),
            label: AppLocalizations.of(context).t("nav_profile"),
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Icon(Icons.favorite_outline, size: w * 0.065),
            ),
            activeIcon: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Icon(Icons.favorite, size: w * 0.065),
            ),
            label: AppLocalizations.of(context).t("nav_favorites"),
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Icon(Icons.home_outlined, size: w * 0.065),
            ),
            activeIcon: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Icon(Icons.home, size: w * 0.065),
            ),
            label:  AppLocalizations.of(context).t("nav_home"),
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Icon(Icons.settings_outlined, size: w * 0.065),
            ),
            activeIcon: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Icon(Icons.settings, size: w * 0.065),
            ),
            label: AppLocalizations.of(context).t("nav_settings"),
          ),
        ],
      ),
    );
  }
}
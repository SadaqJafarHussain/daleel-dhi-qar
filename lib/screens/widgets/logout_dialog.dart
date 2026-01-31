import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guid/providers/auth_provider.dart';
import 'package:tour_guid/providers/favorites_provider.dart';
import 'package:tour_guid/providers/service_peovider.dart';
import 'package:tour_guid/providers/search_provider.dart';
import 'package:tour_guid/providers/review_provider.dart';
import 'package:tour_guid/providers/notification_provider.dart';
import '../../utils/app_localization.dart';
import '../login_screen.dart';

void showLogoutDialog(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  final h = MediaQuery.of(context).size.height;
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final locale = AppLocalizations.of(context);

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.all(w * 0.06),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.logout_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 60,
            ),
            SizedBox(height: h * 0.02),
            Text(
              locale.t('logout'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: h * 0.01),
            Text(
              locale.t('logout_confirm'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: h * 0.03),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    child: Text(
                      locale.t('cancel'),
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                    onPressed: () async {
                      Navigator.pop(dialogContext);

                      // Clear ALL provider data before logout to prevent data leaks
                      try {
                        Provider.of<FavoritesProvider>(context, listen: false).clearFavorites();
                        Provider.of<ServiceProvider>(context, listen: false).clear();
                        Provider.of<SearchProvider>(context, listen: false).clear();
                        Provider.of<ReviewProvider>(context, listen: false).clearCache();
                        await Provider.of<NotificationProvider>(context, listen: false).clearUser();
                      } catch (e) {
                        debugPrint('Logout cleanup error: $e');
                      }

                      await Provider.of<AuthProvider>(context, listen: false).logout();

                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                      );
                    },
                    child: Text(
                      locale.t('confirm'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
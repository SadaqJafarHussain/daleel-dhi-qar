import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tour_guid/utils/app_localization.dart';

import 'app_texts_style.dart';

/// Professional map launcher with clean design and accurate location handling
class MapLauncher {
  /// Opens map selection or launches map directly
  static Future<void> openMaps({
    required BuildContext context,
    required double latitude,
    required double longitude,
    required String placeName,
  }) async {
    final availableApps = await _getAvailableMapApps(
      latitude: latitude,
      longitude: longitude,
      placeName: placeName,
    );

    if (availableApps.isEmpty) {
      // Fallback to web Google Maps
      _launchWebGoogleMaps(latitude, longitude, placeName);
      return;
    }

    if (availableApps.length == 1) {
      // Launch directly if only one app
      await _launchMapApp(availableApps.first);
      return;
    }

    // Show professional bottom sheet
    if (context.mounted) {
      _showMapSelector(
        context: context,
        apps: availableApps,
        placeName: placeName,
      );
    }
  }

  /// Get available map applications
  static Future<List<MapApp>> _getAvailableMapApps({
    required double latitude,
    required double longitude,
    required String placeName,
  }) async {
    final List<MapApp> availableApps = [];
    final encodedName = Uri.encodeComponent(placeName);
    // Google Maps - Proper URL with place name and exact location
    final googleMaps = MapApp(
      name: 'Google Maps',
      url: Uri.parse(
        "https://www.google.com/maps?q=$latitude,$longitude($encodedName)",
      ),
      webFallback: Uri.parse(
        'https://www.google.com/maps?q=$latitude,$longitude($encodedName)',
      ),
      icon: Icons.map,
      color: const Color(0xFF1A73E8),
    );

    // Apple Maps - With place name
    final appleMaps = MapApp(
      name: 'Apple Maps',
      url: Uri.parse(
        'http://maps.apple.com/?q=$encodedName&ll=$latitude,$longitude&z=16',
      ),
      webFallback: Uri.parse(
        'https://maps.apple.com/?q=$encodedName&ll=$latitude,$longitude',
      ),
      icon: Icons.map_outlined,
      color: const Color(0xFF007AFF),
    );

    // Waze - With place name
    final waze = MapApp(
      name: 'Waze',
      url: Uri.parse(
        'https://waze.com/ul?q=$encodedName&ll=$latitude,$longitude&navigate=yes',
      ),
      webFallback: Uri.parse(
        'https://waze.com/ul?ll=$latitude,$longitude',
      ),
      icon: Icons.navigation,
      color: const Color(0xFF33CCFF),
    );

    // Yandex Maps - Popular in Iraq
    final yandexMaps = MapApp(
      name: 'Yandex Maps',
      url: Uri.parse(
        'yandexmaps://build_route_on_map?lat_to=$latitude&lon_to=$longitude',
      ),
      webFallback: Uri.parse(
        'https://yandex.com/maps/?text=$encodedName&ll=$longitude,$latitude&z=16',
      ),
      icon: Icons.explore,
      color: const Color(0xFFFF0000),
    );

    // Check availability
    final allApps = [googleMaps, appleMaps, waze, yandexMaps];

    for (final app in allApps) {
      try {
        if (await canLaunchUrl(app.url)) {
          availableApps.add(app);
        }
      } catch (e) {
        continue;
      }
    }

    return availableApps;
  }

  /// Show professional, clean map selector
  static void _showMapSelector({
    required BuildContext context,
    required List<MapApp> apps,
    required String placeName,
  }) {
    final t = AppLocalizations.of(context).t;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('open_in_maps'),
                      style: TextStyle(
                        fontSize: AppTextSizes.h3,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      placeName,
                      style: TextStyle(
                        fontSize: AppTextSizes.bodySmall,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const Divider(height: 24),

              // Map apps list
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: apps.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final app = apps[index];
                  return _buildMapTile(context, app);
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Build clean, professional map tile
  static Widget _buildMapTile(BuildContext context, MapApp app) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _launchMapApp(app);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: app.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  app.icon,
                  color: app.color,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Name
              Expanded(
                child: Text(
                  app.name,
                  style: TextStyle(
                    fontSize: AppTextSizes.bodyLarge,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Launch map app
  static Future<void> _launchMapApp(MapApp app) async {
    try {
      final launched = await launchUrl(
        app.url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await launchUrl(
          app.webFallback,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      try {
        await launchUrl(
          app.webFallback,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        debugPrint('Failed to launch map: $e');
      }
    }
  }

  /// Fallback to web Google Maps
  static Future<void> _launchWebGoogleMaps(
      double latitude,
      double longitude,
      String placeName,
      ) async {
    final encodedName = Uri.encodeComponent(placeName);
    final url = Uri.parse(
      'https://www.google.com/maps?q=$latitude,$longitude($encodedName)',
    );

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Failed to launch Google Maps: $e');
    }
  }
}

/// Map application model
class MapApp {
  final String name;
  final Uri url;
  final Uri webFallback;
  final IconData icon;
  final Color color;

  const MapApp({
    required this.name,
    required this.url,
    required this.webFallback,
    required this.icon,
    required this.color,
  });
}
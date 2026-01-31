import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../utils/app_localization.dart';
import '../utils/app_texts_style.dart';
import '../utils/app_icons.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isTogglingPush = false;

  @override
  void initState() {
    super.initState();
    // Load preferences
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<NotificationProvider>(context, listen: false);
      provider.loadPreferences();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AppBackButton.light(),
        ),
        title: Text(
          loc.t('notification_settings'),
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: AppTextSizes.h2,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          final prefs = provider.preferences;

          if (prefs == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: EdgeInsets.all(w * 0.04),
            children: [
              // Header Icon
              Center(
                child: Container(
                  width: w * 0.2,
                  height: w * 0.2,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    size: w * 0.1,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
              ),
              SizedBox(height: h * 0.01),
              Center(
                child: Text(
                  loc.t('manage_notifications'),
                  style: TextStyle(
                    fontSize: AppTextSizes.bodySmall,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ),
              SizedBox(height: h * 0.03),

              // Master Toggle
              _buildMasterToggle(
                context: context,
                title: loc.t('push_notifications'),
                subtitle: loc.t('enable_all_notifications'),
                value: prefs.pushEnabled,
                isLoading: _isTogglingPush,
                onChanged: (value) async {
                  setState(() => _isTogglingPush = true);
                  try {
                    // Update preference in database
                    await provider.togglePreference('push_enabled', value);
                    // Actually enable/disable push notifications (FCM token)
                    final success = await provider.togglePushNotifications(value);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? (value ? loc.t('push_enabled_success') : loc.t('push_disabled_success'))
                                : loc.t('push_toggle_failed'),
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isTogglingPush = false);
                    }
                  }
                },
              ),
              SizedBox(height: h * 0.02),

              // Notification Types Section
              if (prefs.pushEnabled) ...[
                _buildSectionHeader(
                  context: context,
                  title: loc.t('notification_types'),
                  icon: Icons.tune,
                ),
                SizedBox(height: h * 0.01),

                // Review Notifications
                _buildNotificationTile(
                  context: context,
                  icon: Icons.star_rounded,
                  iconColor: const Color(0xFFFBBF24),
                  title: loc.t('review_notifications'),
                  subtitle: loc.t('review_notifications_desc'),
                  value: prefs.reviewNotifications,
                  onChanged: (value) {
                    provider.togglePreference('review_notifications', value);
                  },
                ),

                // Favorite Notifications
                _buildNotificationTile(
                  context: context,
                  icon: Icons.favorite_rounded,
                  iconColor: const Color(0xFFEF4444),
                  title: loc.t('favorite_notifications'),
                  subtitle: loc.t('favorite_notifications_desc'),
                  value: prefs.favoriteNotifications,
                  onChanged: (value) {
                    provider.togglePreference('favorite_notifications', value);
                  },
                ),

                // Service Update Notifications
                _buildNotificationTile(
                  context: context,
                  icon: Icons.update_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: loc.t('service_update_notifications'),
                  subtitle: loc.t('service_update_notifications_desc'),
                  value: prefs.serviceUpdateNotifications,
                  onChanged: (value) {
                    provider.togglePreference('service_update_notifications', value);
                  },
                ),

                // Promotion Notifications
                _buildNotificationTile(
                  context: context,
                  icon: Icons.local_offer_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  title: loc.t('promotion_notifications'),
                  subtitle: loc.t('promotion_notifications_desc'),
                  value: prefs.promotionNotifications,
                  onChanged: (value) {
                    provider.togglePreference('promotion_notifications', value);
                  },
                ),

                // Ads Notifications
                _buildNotificationTile(
                  context: context,
                  icon: Icons.campaign_rounded,
                  iconColor: const Color(0xFFEC4899),
                  title: loc.t('ads_notifications'),
                  subtitle: loc.t('ads_notifications_desc'),
                  value: prefs.adsNotifications,
                  onChanged: (value) {
                    provider.togglePreference('ads_notifications', value);
                  },
                ),

                // System Notifications
                _buildNotificationTile(
                  context: context,
                  icon: Icons.info_rounded,
                  iconColor: const Color(0xFF6B7280),
                  title: loc.t('system_notifications'),
                  subtitle: loc.t('system_notifications_desc'),
                  value: prefs.systemNotifications,
                  onChanged: (value) {
                    provider.togglePreference('system_notifications', value);
                  },
                ),

                // Verification Notifications
                _buildNotificationTile(
                  context: context,
                  icon: Icons.verified_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  title: loc.t('verification_notifications'),
                  subtitle: loc.t('verification_notifications_desc'),
                  value: prefs.verificationNotifications,
                  onChanged: (value) {
                    provider.togglePreference('verification_notifications', value);
                  },
                ),
              ],

              SizedBox(height: h * 0.04),

              // Info Card
              Container(
                padding: EdgeInsets.all(w * 0.04),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 24,
                    ),
                    SizedBox(width: w * 0.03),
                    Expanded(
                      child: Text(
                        loc.t('notification_settings_info'),
                        style: TextStyle(
                          fontSize: AppTextSizes.bodySmall,
                          color: Colors.blue.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMasterToggle({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    bool isLoading = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: value
                  ? const Color(0xFF10B981).withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    value ? Icons.notifications_active : Icons.notifications_off,
                    color: value ? const Color(0xFF10B981) : Colors.grey,
                    size: 28,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTextSizes.bodyLarge,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: AppTextSizes.bodySmall,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: isLoading ? null : onChanged,
            activeColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: AppTextSizes.bodyMedium,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: AppTextSizes.bodyMedium,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: AppTextSizes.bodySmall,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: iconColor,
        ),
      ),
    );
  }
}

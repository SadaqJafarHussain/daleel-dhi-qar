import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tour_guid/providers/auth_provider.dart';
import 'package:tour_guid/providers/theme_provider.dart';
import 'package:tour_guid/providers/notification_provider.dart';
import 'package:tour_guid/screens/widgets/language_selector.dart';
import 'package:tour_guid/screens/widgets/logout_button.dart';
import 'package:tour_guid/screens/widgets/logout_dialog.dart';
import 'package:tour_guid/screens/widgets/profile_menu_item.dart';
import 'package:tour_guid/screens/widgets/profile_section_header.dart';
import '../utils/app_localization.dart';
import '../utils/app_texts_style.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isTogglingNotifications = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final authProvider = Provider.of<AuthProvider>(context);
    final loc = AppLocalizations.of(context);  // NEW: Get translations
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.settings, color: Theme.of(context).iconTheme.color),
            const SizedBox(width: 10),
            Text(
              loc.t('settings'),
              style: TextStyle(
                color: Theme.of(context).textTheme.displayMedium!.color,
                fontWeight: FontWeight.bold,
                fontSize: AppTextSizes.h2,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: h * 0.01),
              // Notifications (only show if logged in)
              if (authProvider.user != null)
                Consumer<NotificationProvider>(
                  builder: (context, notificationProvider, _) {
                    return _buildNotificationToggle(
                      context,
                      notificationProvider,
                      loc,
                      w,
                      h,
                    );
                  },
                ),

              // Language Selector (NEW)
              LanguageSelector(width: w, height: h),

              // Dark Mode Toggle
              ProfileMenuItem(
                icon: isDarkMode ? Icons.dark_mode : Icons.light_mode,
                title: loc.t('dark_mode'),  // TRANSLATED
                iconColor: const Color(0xFF64748B),
                trailing: Switch(
                  value: isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                ),
                onTap: () {
                  themeProvider.toggleTheme();
                },
                width: w,
                height: h,
              ),

              // Help & Support Section
              ProfileSectionHeader(
                title: loc.t('help_support'),  // TRANSLATED
                icon: Icons.help_outline_outlined,
              ),

              ProfileMenuItem(
                icon: Icons.headset_mic_outlined,
                title: loc.t('contact_us'),
                iconColor: const Color(0xFF22C55E),
                onTap: () => _showContactUsSheet(context, loc),
                width: w,
                height: h,
              ),

              ProfileMenuItem(
                icon: Icons.description_outlined,
                title: loc.t('terms_conditions'),
                iconColor: const Color(0xFF3B82F6),
                onTap: () => _showTermsConditions(context, loc),
                width: w,
                height: h,
              ),

              ProfileMenuItem(
                icon: Icons.privacy_tip_outlined,
                title: loc.t('privacy_policy'),
                iconColor: const Color(0xFFF59E0B),
                onTap: () => _showPrivacyPolicy(context, loc),
                width: w,
                height: h,
              ),

              ProfileMenuItem(
                icon: Icons.info_outline,
                title: loc.t('about_app'),
                iconColor: const Color(0xFF8B5CF6),
                onTap: () => _showAboutDialog(context, loc),
                width: w,
                height: h,
              ),

              SizedBox(height: h * 0.02),

              // Logout Button (only show if logged in)
              authProvider.user == null
                  ? const SizedBox()
                  : LogoutButton(
                width: w,
                height: h,
                onTap: () => showLogoutDialog(context),
              ),

              SizedBox(height: h * 0.05),
            ],
          ),
        ),
      ),
    );
  }

  /// Build professional notification toggle with loading state
  Widget _buildNotificationToggle(
    BuildContext context,
    NotificationProvider notificationProvider,
    AppLocalizations loc,
    double w,
    double h,
  ) {
    final isPushEnabled = notificationProvider.isPushEnabled;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.005),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.005),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isPushEnabled ? Icons.notifications_active : Icons.notifications_off_outlined,
            color: const Color(0xFF3B82F6),
            size: 24,
          ),
        ),
        title: Text(
          loc.t('push_notifications'),
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: AppTextSizes.bodyMedium,
          ),
        ),
        subtitle: Text(
          isPushEnabled ? loc.t('notifications_enabled') : loc.t('notifications_disabled'),
          style: TextStyle(
            fontSize: AppTextSizes.bodySmall,
            color: isPushEnabled ? Colors.green : Colors.grey,
          ),
        ),
        trailing: _isTogglingNotifications
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Switch(
                value: isPushEnabled,
                onChanged: (value) => _toggleNotifications(context, notificationProvider, value, loc),
              ),
        onTap: _isTogglingNotifications
            ? null
            : () => _toggleNotifications(context, notificationProvider, !isPushEnabled, loc),
      ),
    );
  }

  /// Toggle push notifications with feedback
  Future<void> _toggleNotifications(
    BuildContext context,
    NotificationProvider notificationProvider,
    bool enable,
    AppLocalizations loc,
  ) async {
    // Haptic feedback
    HapticFeedback.selectionClick();

    setState(() => _isTogglingNotifications = true);

    try {
      final success = await notificationProvider.togglePushNotifications(enable);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    enable ? Icons.notifications_active : Icons.notifications_off,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    enable ? loc.t('notifications_turned_on') : loc.t('notifications_turned_off'),
                  ),
                ],
              ),
              backgroundColor: enable ? Colors.green : Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Text(loc.t('notification_toggle_failed')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isTogglingNotifications = false);
      }
    }
  }

  /// Show Contact Us bottom sheet with multiple contact options
  void _showContactUsSheet(BuildContext context, AppLocalizations loc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      loc.t('contact_us'),
                      style: TextStyle(
                        fontSize: AppTextSizes.h3,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.t('contact_us_desc'),
                      style: TextStyle(
                        fontSize: AppTextSizes.bodySmall,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // WhatsApp
                    _buildContactOption(
                      context: context,
                      icon: Icons.chat,
                      title: 'WhatsApp',
                      subtitle: '+964 783 156 3335',
                      color: const Color(0xFF25D366),
                      onTap: () => _launchUrl('https://wa.me/9647831563335'),
                    ),
                    const SizedBox(height: 12),
                    // Email
                    _buildContactOption(
                      context: context,
                      icon: Icons.email_outlined,
                      title: loc.t('email'),
                      subtitle: 'support@daleeldhiqar.com',
                      color: const Color(0xFF3B82F6),
                      onTap: () => _launchUrl('mailto:support@daleeldhiqar.com'),
                    ),
                    const SizedBox(height: 12),
                    // Phone
                    _buildContactOption(
                      context: context,
                      icon: Icons.phone_outlined,
                      title: loc.t('phone'),
                      subtitle: '+964 783 156 3335',
                      color: const Color(0xFF22C55E),
                      onTap: () => _launchUrl('tel:+9647831563335'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: AppTextSizes.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppTextSizes.bodySmall,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  /// Show Terms & Conditions page
  void _showTermsConditions(BuildContext context, AppLocalizations loc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _LegalPageScreen(
          title: loc.t('terms_conditions'),
          content: loc.t('terms_conditions_content'),
        ),
      ),
    );
  }

  /// Show Privacy Policy page
  void _showPrivacyPolicy(BuildContext context, AppLocalizations loc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _LegalPageScreen(
          title: loc.t('privacy_policy'),
          content: loc.t('privacy_policy_content'),
        ),
      ),
    );
  }

  /// Show About App dialog
  Future<void> _showAboutDialog(BuildContext context, AppLocalizations loc) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            // App Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFB91C4C).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.explore,
                size: 48,
                color: Color(0xFFB91C4C),
              ),
            ),
            const SizedBox(height: 16),
            // App Name
            Text(
              loc.t('app_name'),
              style: TextStyle(
                fontSize: AppTextSizes.h2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Version
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${loc.t('version')} ${packageInfo.version} (${packageInfo.buildNumber})',
                style: TextStyle(
                  fontSize: AppTextSizes.bodySmall,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Description
            Text(
              loc.t('app_description'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTextSizes.bodySmall,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            // Divider
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 12),
            // Developer info
            Text(
              loc.t('developed_by'),
              style: TextStyle(
                fontSize: AppTextSizes.bodySmall,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'GI Tech',
              style: TextStyle(
                fontSize: AppTextSizes.bodyMedium,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFB91C4C),
              ),
            ),
            const SizedBox(height: 16),
            // Copyright
            Text(
              '© ${DateTime.now().year} ${loc.t('all_rights_reserved')}',
              style: TextStyle(
                fontSize: AppTextSizes.labelSmall,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.t('close')),
          ),
        ],
      ),
    );
  }

  /// Launch URL helper
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Legal page screen for Terms & Privacy Policy
class _LegalPageScreen extends StatelessWidget {
  final String title;
  final String content;

  const _LegalPageScreen({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last updated
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${AppLocalizations.of(context).t('last_updated')}: ${DateTime.now().year}-01-01',
                style: TextStyle(
                  fontSize: AppTextSizes.labelSmall,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Content
            Text(
              content,
              style: TextStyle(
                fontSize: AppTextSizes.bodyMedium,
                height: 1.8,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
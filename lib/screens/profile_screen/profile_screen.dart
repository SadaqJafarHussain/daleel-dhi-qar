import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guid/providers/auth_provider.dart';
import 'package:tour_guid/providers/favorites_provider.dart';
import 'package:tour_guid/providers/language_provider.dart';
import 'package:tour_guid/providers/service_peovider.dart';
import 'package:tour_guid/screens/favorites_screen.dart';
import 'package:tour_guid/screens/my_services_screen.dart';
import 'package:tour_guid/screens/edit_profile_screen.dart';
import 'package:tour_guid/screens/change_password_screen.dart';
import 'package:tour_guid/models/user_model.dart';
import '../../utils/app_localization.dart';
import '../../utils/app_texts_style.dart';
import '../login_screen.dart';
import '../widgets/logout_button.dart';
import '../widgets/logout_dialog.dart';
import '../widgets/profile_app_bar.dart';
import '../widgets/profile_menu_item.dart';
import '../widgets/profile_section_header.dart';
import '../widgets/profile_stat_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t; // ✅ shortcut for translations
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;
    final favProvider = Provider.of<FavoritesProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final serviceProvider = Provider.of<ServiceProvider>(context);
    final userData = authProvider.user;
    final isAuthenticated = authProvider.isAuthenticated;

    // If user not logged in → visitor screen
    if (!isAuthenticated) {
      return _buildVisitorScreen(context, w, h, t);
    }

    // Filter services by supabaseUserId (UUID) not int userId
    final mySupabaseId = authProvider.supabaseUserId;
    debugPrint('ProfileScreen: My Supabase ID = $mySupabaseId');
    debugPrint('ProfileScreen: Total services = ${serviceProvider.services.length}');
    for (var s in serviceProvider.services) {
      debugPrint('ProfileScreen: Service "${s.title}" has supabaseUserId = ${s.supabaseUserId}');
    }

    final myServices = serviceProvider.services
        .where((s) => s.supabaseUserId != null &&
                      s.supabaseUserId == mySupabaseId)
        .toList();
    debugPrint('ProfileScreen: My services count = ${myServices.length}');

    // Calculate average rating from user's services
    double averageRating = 0.0;
    if (myServices.isNotEmpty) {
      final servicesWithRating = myServices.where((s) => s.averageRating != null && s.averageRating! > 0);
      if (servicesWithRating.isNotEmpty) {
        averageRating = servicesWithRating.map((s) => s.averageRating!).reduce((a, b) => a + b) / servicesWithRating.length;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          ProfileAppBar(width: w, height: h, user: userData),
          SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(height: h * 0.02),

                // ✅ Stats
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.045),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap:(){
                            Navigator.push(context, MaterialPageRoute(builder: (_)=>FavoritesScreen()));
                          },
                          child: ProfileStatCard(
                            icon: Icons.favorite,
                            iconColor: const Color(0xFFEF4444),
                            title: favProvider.favorites.length.toString(),
                            subtitle: t('favorites'),
                            width: w,
                            height: h,
                          ),
                        ),
                      ),
                      SizedBox(width: w * 0.03),
                      Expanded(
                        child: InkWell(
                          onTap: (){
                            Navigator.push(context, MaterialPageRoute(builder: (_)=>MyServicesScreen()));
                          },
                          child: ProfileStatCard(
                            icon: Icons.cleaning_services,
                            iconColor: const Color(0xFF3B82F6),
                            title: myServices.length.toString(),
                            subtitle: t('my_services'),
                            width: w,
                            height: h,
                          ),
                        ),
                      ),
                      SizedBox(width: w * 0.03),
                      Expanded(
                        child: ProfileStatCard(
                          icon: Icons.star,
                          iconColor: const Color(0xFFFBBF24),
                          title: averageRating > 0 ? averageRating.toStringAsFixed(1) : '-',
                          subtitle: t('rating'),
                          width: w,
                          height: h,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: h * 0.025),

                // ✅ Profile Info Section
                if (userData != null) ...[
                  ProfileSectionHeader(title: t('profile_info'), icon: Icons.info_outline),
                  _buildProfileInfoCard(context, userData, w, h, t),
                  SizedBox(height: h * 0.02),
                ],

                // ✅ Account Section
                ProfileSectionHeader(title: t('my_account'), icon: Icons.person_outline),
                ProfileMenuItem(
                  icon: Icons.edit_outlined,
                  title: t('edit_profile'),
                  iconColor: const Color(0xFF3B82F6),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    );
                  },
                  width: w,
                  height: h,
                ),
                ProfileMenuItem(
                  icon: Icons.lock_outline,
                  title: t('change_password'),
                  iconColor: const Color(0xFFF59E0B),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                    );
                  },
                  width: w,
                  height: h,
                ),
                SizedBox(height: h * 0.02),

                // ✅ Logout
                LogoutButton(
                  width: w,
                  height: h,
                  onTap: () => showLogoutDialog(context),
                ),

                SizedBox(height: h * 0.04),
                Text(
                  t('made_with_love'),
                  style: TextStyle(
                    fontSize: AppTextSizes.bodySmall,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                SizedBox(height: h * 0.06),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Visitor screen for non-authenticated users
  Widget _buildVisitorScreen(BuildContext context, double w, double h, String Function(String) t) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    return Directionality(
      textDirection: languageProvider.textDirection,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: w * 0.06),
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: h),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    SizedBox(height: h * 0.05),

                    // Icon
                    Container(
                      width: w * 0.2,
                      height: w * 0.2,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.person_outline_rounded,
                          size: w * 0.14,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),

                    SizedBox(height: h * 0.02),
                    Text(
                      t('welcome'),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: AppTextSizes.h1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: h * 0.005),
                    Text(
                      t('login_message'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: AppTextSizes.bodyMedium,
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: h * 0.03),

                    _buildFeatureItem(context, Icons.favorite_rounded, t('save_favorites'),
                        const Color(0xFFEF4444), w),
                    SizedBox(height: h * 0.01),
                    _buildFeatureItem(context, Icons.history_rounded, t('track_orders'),
                        const Color(0xFF3B82F6), w),
                    SizedBox(height: h * 0.01),
                    _buildFeatureItem(context, Icons.star_rounded, t('rate_share'),
                        const Color(0xFF8B5CF6), w),

                    SizedBox(height: h * 0.02),

                    SizedBox(
                      width: double.infinity,
                      height: h * 0.065,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        child: Text(
                          t('login'),
                          style: TextStyle(
                            fontSize: AppTextSizes.button,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: h * 0.01),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
      BuildContext context,
      IconData icon,
      String title,
      Color iconColor,
      double w,
      ) {
    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(w * 0.025),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: iconColor, size: w * 0.06),
          ),
          SizedBox(width: w * 0.04),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: AppTextSizes.bodyMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.check_circle, color: iconColor, size: w * 0.05),
        ],
      ),
    );
  }

  /// Translate value if it's a localization key, otherwise return as-is
  String _translateValue(String value, String Function(String) t) {
    // Try to translate the value as a key
    final translated = t(value);
    // If translation returns something different, use it
    if (translated != value) {
      return translated;
    }
    // Return original value (might be legacy Arabic data)
    return value;
  }

  Widget _buildProfileInfoCard(
    BuildContext context,
    UserModel user,
    double w,
    double h,
    String Function(String) t,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: w * 0.045),
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          // Gender
          if (user.gender != null)
            _buildInfoRow(
              context,
              Icons.person_outline,
              t('gender'),
              user.gender == Gender.male ? t('male') : t('female'),
              const Color(0xFF3B82F6),
              w,
            ),

          // Birth Date / Age
          if (user.birthDate != null) ...[
            if (user.gender != null) _buildDivider(isDark),
            _buildInfoRow(
              context,
              Icons.cake_outlined,
              t('birth_date'),
              '${user.birthDate!.day}/${user.birthDate!.month}/${user.birthDate!.year}${user.age != null ? ' (${user.age} ${t("years")})' : ''}',
              const Color(0xFFEC4899),
              w,
            ),
          ],

          // City
          if (user.city != null && user.city!.isNotEmpty) ...[
            if (user.gender != null || user.birthDate != null) _buildDivider(isDark),
            _buildInfoRow(
              context,
              Icons.location_city_outlined,
              t('city'),
              _translateValue(user.city!, t),
              const Color(0xFF10B981),
              w,
            ),
          ],

          // Occupation
          if (user.occupation != null && user.occupation!.isNotEmpty) ...[
            if (user.gender != null || user.birthDate != null || user.city != null) _buildDivider(isDark),
            _buildInfoRow(
              context,
              Icons.work_outline,
              t('occupation'),
              _translateValue(user.occupation!, t),
              const Color(0xFFF59E0B),
              w,
            ),
          ],

          // Interests
          if (user.interests != null && user.interests!.isNotEmpty) ...[
            _buildDivider(isDark),
            Padding(
              padding: EdgeInsets.symmetric(vertical: h * 0.01),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.interests_outlined,
                      color: Color(0xFF8B5CF6),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: w * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('interests'),
                          style: TextStyle(
                            fontSize: AppTextSizes.bodySmall,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: user.interests!.map((interest) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _translateValue(interest, t),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8B5CF6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Show message if no info
          if (user.gender == null &&
              user.birthDate == null &&
              (user.city == null || user.city!.isEmpty) &&
              (user.occupation == null || user.occupation!.isEmpty) &&
              (user.interests == null || user.interests!.isEmpty))
            Padding(
              padding: EdgeInsets.symmetric(vertical: h * 0.02),
              child: Column(
                children: [
                  Icon(
                    Icons.person_add_outlined,
                    size: 40,
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                  SizedBox(height: h * 0.01),
                  Text(
                    t('complete_profile_hint'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                      fontSize: AppTextSizes.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
    double w,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTextSizes.bodySmall,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: AppTextSizes.bodyMedium,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      height: 1,
    );
  }
}
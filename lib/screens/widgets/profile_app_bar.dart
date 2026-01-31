import 'package:flutter/material.dart';
import 'package:tour_guid/utils/app_texts_style.dart';
import 'package:tour_guid/utils/app_localization.dart';
import '../../models/user_model.dart';

class ProfileAppBar extends StatelessWidget {
  final double width;
  final double height;
  final UserModel? user;

  const ProfileAppBar({
    super.key,
    required this.width,
    required this.height,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final w = width;
    final h = height;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: h * 0.3,
      pinned: true,
      backgroundColor: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFB91C4C),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: isDarkMode
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [const Color(0xFFB91C4C), const Color(0xFF831843)],
                ),
              ),
            ),
            Positioned(
              top: -50,
              right: -50,
              child: CircleAvatar(
                radius: 100,
                backgroundColor: Colors.white.withOpacity(0.1),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: CircleAvatar(
                radius: 75,
                backgroundColor: Colors.white.withOpacity(0.05),
              ),
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Avatar with image or initials fallback
                  CircleAvatar(
                    radius: w * 0.14,
                    backgroundColor: Colors.white,
                    child: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                        ? CircleAvatar(
                            radius: w * 0.13,
                            backgroundImage: NetworkImage(user!.avatarUrl!),
                            onBackgroundImageError: (_, __) {},
                            child: null,
                          )
                        : CircleAvatar(
                            radius: w * 0.13,
                            backgroundColor: const Color(0xFF16A34A),
                            child: Text(
                              _getInitials(user?.name ?? AppLocalizations.of(context).t('guest')),
                              style: TextStyle(
                                fontSize: w * 0.1,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                  SizedBox(height: h * 0.01),
                  Text(
                    user?.name ?? AppLocalizations.of(context).t('guest'),
                    style: TextStyle(
                      fontSize:AppTextSizes.h3,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: h * 0.005),
                  Text(
                    user?.phone ?? '',
                    style: TextStyle(
                      fontSize: AppTextSizes.cardSubtitle,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  if (user?.city != null && user!.city!.isNotEmpty) ...[
                    SizedBox(height: h * 0.005),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _translateCity(context, user!.city!),
                          style: TextStyle(
                            fontSize: AppTextSizes.bodySmall,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: h * 0.015),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.substring(0, name.length > 2 ? 2 : name.length).toUpperCase();
  }

  String _translateCity(BuildContext context, String city) {
    final loc = AppLocalizations.of(context);
    final translated = loc.t(city);
    // If translation returns same value, it's not a key - return as-is
    return translated != city ? translated : city;
  }
}
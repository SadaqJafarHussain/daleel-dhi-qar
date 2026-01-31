import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tour_guid/providers/auth_provider.dart';
import 'package:tour_guid/providers/notification_provider.dart';
import 'package:tour_guid/screens/notifications_screen.dart';
import 'package:tour_guid/utils/app_localization.dart';
import 'package:tour_guid/utils/page_transitions.dart';

class HomeAppBar extends StatelessWidget {
  final double width;
  final double height;

  const HomeAppBar({super.key, required this.width, required this.height});

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.substring(0, name.length > 2 ? 2 : name.length).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final loc = AppLocalizations.of(context);
    final w = width;
    final h = height;

    return Container(
      color: Theme.of(context).cardColor,
      padding: EdgeInsets.symmetric(horizontal: w * 0.045, vertical: h * 0.012),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Avatar with image or initials fallback
              authProvider.user?.avatarUrl != null && authProvider.user!.avatarUrl!.isNotEmpty
                  ? CircleAvatar(
                      radius: w * 0.055,
                      backgroundImage: NetworkImage(authProvider.user!.avatarUrl!),
                      onBackgroundImageError: (_, __) {},
                    )
                  : CircleAvatar(
                      radius: w * 0.055,
                      backgroundColor: const Color(0xFF22C55E),
                      child: Text(
                        _getInitials(authProvider.user?.name ?? loc.t('guest')),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: w * 0.04,
                        ),
                      ),
                    ),
              SizedBox(width: w * 0.025),
              Text(
                authProvider.user?.name ?? loc.t('guest'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: w * 0.04,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          _NotificationBell(width: w),
        ],
      ),
    );
  }
}

/// Notification bell with badge
class _NotificationBell extends StatelessWidget {
  final double width;

  const _NotificationBell({required this.width});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final unreadCount = provider.unreadCount;
        final hasUnread = unreadCount > 0;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              PageTransitions.slideRight(
                page: const NotificationsScreen(),
              ),
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasUnread
                      ? const Color(0xFF3B82F6).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasUnread
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_outlined,
                  color: hasUnread
                      ? const Color(0xFF3B82F6)
                      : Theme.of(context).iconTheme.color,
                  size: width * 0.065,
                ),
              ),
              if (hasUnread)
                Positioned(
                  right: 4,
                  top: 4,
                  child: _AnimatedBadge(count: unreadCount, width: width),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Animated badge for notification count
class _AnimatedBadge extends StatelessWidget {
  final int count;
  final double width;

  const _AnimatedBadge({required this.count, required this.width});

  @override
  Widget build(BuildContext context) {
    final displayCount = count > 99 ? '99+' : count.toString();
    final badgeWidth = displayCount.length > 2
        ? width * 0.055
        : (displayCount.length > 1 ? width * 0.045 : width * 0.04);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: displayCount.length > 1 ? 4 : 0,
        ),
        constraints: BoxConstraints(
          minWidth: badgeWidth,
          minHeight: badgeWidth,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).cardColor,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          displayCount,
          style: TextStyle(
            color: Colors.white,
            fontSize: width * 0.025,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

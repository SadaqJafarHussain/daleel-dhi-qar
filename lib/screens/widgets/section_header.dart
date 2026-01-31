import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tour_guid/utils/app_localization.dart';

/// Unified section header widget for all home screen sections
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Color>? iconGradientColors;
  final VoidCallback? onViewAll;
  final int? itemCount;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconGradientColors,
    VoidCallback? onViewAll,
    this.itemCount,
    VoidCallback? onTap, // Alias for onViewAll for backward compatibility
  }) : onViewAll = onViewAll ?? onTap;

  /// Factory for nearby services header
  factory SectionHeader.nearby({
    required String title,
    String? subtitle,
    VoidCallback? onViewAll,
    int? itemCount,
  }) {
    return SectionHeader(
      title: title,
      subtitle: subtitle,
      icon: Icons.near_me_rounded,
      iconGradientColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      onViewAll: onViewAll,
      itemCount: itemCount,
    );
  }

  /// Factory for verified services header
  factory SectionHeader.verified({
    required String title,
    String? subtitle,
    VoidCallback? onViewAll,
    int? itemCount,
  }) {
    return SectionHeader(
      title: title,
      subtitle: subtitle,
      icon: Icons.verified_rounded,
      iconGradientColors: const [Color(0xFF1DA1F2), Color(0xFF0D8ECF)],
      onViewAll: onViewAll,
      itemCount: itemCount,
    );
  }

  /// Factory for top rated services header
  factory SectionHeader.topRated({
    required String title,
    String? subtitle,
    VoidCallback? onViewAll,
    int? itemCount,
  }) {
    return SectionHeader(
      title: title,
      subtitle: subtitle,
      icon: Icons.star_rounded,
      iconGradientColors: const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
      onViewAll: onViewAll,
      itemCount: itemCount,
    );
  }

  /// Factory for recently added services header
  factory SectionHeader.recentlyAdded({
    required String title,
    String? subtitle,
    VoidCallback? onViewAll,
    int? itemCount,
  }) {
    return SectionHeader(
      title: title,
      subtitle: subtitle,
      icon: Icons.new_releases_rounded,
      iconGradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
      onViewAll: onViewAll,
      itemCount: itemCount,
    );
  }

  /// Factory for open now services header
  factory SectionHeader.openNow({
    required String title,
    String? subtitle,
    VoidCallback? onViewAll,
    int? itemCount,
  }) {
    return SectionHeader(
      title: title,
      subtitle: subtitle,
      icon: Icons.access_time_filled_rounded,
      iconGradientColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      onViewAll: onViewAll,
      itemCount: itemCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasIcon = icon != null && iconGradientColors != null;

    return Row(
      children: [
        // Icon with gradient background
        if (hasIcon) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: iconGradientColors!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: iconGradientColors!.first.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
        ],

        // Title and subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                      ),
                    ),
                    if (itemCount != null && itemCount! > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: hasIcon
                              ? iconGradientColors!.first.withOpacity(0.15)
                              : Theme.of(context).primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$itemCount',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: hasIcon
                                ? iconGradientColors!.first
                                : Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),

        // View all button
        if (onViewAll != null)
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onViewAll!();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    loc.t('view_all'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasIcon
                          ? iconGradientColors!.first
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: hasIcon
                        ? iconGradientColors!.first
                        : Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

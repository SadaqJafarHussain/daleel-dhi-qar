import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tour_guid/providers/auth_provider.dart';
import 'package:tour_guid/screens/service_details_screen.dart';
import 'package:tour_guid/utils/app_localization.dart';
import 'package:tour_guid/utils/app_icons.dart';
import 'package:tour_guid/utils/map_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/service_model.dart';
import 'favorite_button.dart';
import 'login_prompt_dialog.dart';

/// Card style variants for different sections
enum ServiceCardStyle {
  standard,    // Default style
  topRated,    // Gold accent for top rated
  recentlyAdded, // Green accent for new
  openNow,     // Blue accent for open now
  nearby,      // Location-focused style
}

/// Style configuration for card variants
class _CardStyleConfig {
  final Color accentColor;
  final IconData? badgeIcon;
  final bool showAccentBorder;

  const _CardStyleConfig({
    required this.accentColor,
    this.badgeIcon,
    this.showAccentBorder = false,
  });

  static _CardStyleConfig forStyle(ServiceCardStyle style) {
    switch (style) {
      case ServiceCardStyle.topRated:
        return const _CardStyleConfig(
          accentColor: Color(0xFFFBBF24), // Gold
          badgeIcon: Icons.star_rounded,
          showAccentBorder: true,
        );
      case ServiceCardStyle.recentlyAdded:
        return const _CardStyleConfig(
          accentColor: Color(0xFF10B981), // Green
          badgeIcon: Icons.fiber_new_rounded,
          showAccentBorder: true,
        );
      case ServiceCardStyle.openNow:
        return const _CardStyleConfig(
          accentColor: Color(0xFF3B82F6), // Blue
          badgeIcon: Icons.access_time_filled_rounded,
          showAccentBorder: true,
        );
      case ServiceCardStyle.nearby:
        return const _CardStyleConfig(
          accentColor: Color(0xFF8B5CF6), // Purple
          badgeIcon: Icons.near_me_rounded,
          showAccentBorder: true,
        );
      case ServiceCardStyle.standard:
        return _CardStyleConfig(
          accentColor: Colors.grey.shade600,
        );
    }
  }
}

class ServiceCard extends StatefulWidget {
  final Service service;
  final int index;
  final String fromWhere;
  final double? width;
  final double? height;
  final bool showDistance;
  final bool compact;
  final ServiceCardStyle cardStyle;

  const ServiceCard({
    Key? key,
    required this.service,
    required this.index,
    required this.fromWhere,
    this.width,
    this.height,
    this.showDistance = true,
    this.compact = false,
    this.cardStyle = ServiceCardStyle.standard,
  }) : super(key: key);

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    final cardWidth = widget.width ?? 280.0;
    final cardHeight = widget.height ?? 220.0;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  ServiceDetailsScreen(service: widget.service),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _isPressed
                    ? Colors.transparent
                    : (isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.08)),
                blurRadius: _isPressed ? 0 : 20,
                offset: const Offset(0, 8),
                spreadRadius: _isPressed ? 0 : -2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                _buildImageSection(context, isDark, cardWidth, cardHeight, loc),

                // Content Section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title with verified badge and open/close status
                        Row(
                          children: [
                            if (widget.service.isOwnerVerified) ...[
                              const Icon(
                                Icons.verified,
                                size: 18,
                                color: Color(0xFF1DA1F2),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                widget.service.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Open/Closed badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: widget.service.isCurrentlyOpen
                                    ? Colors.green.withOpacity(0.15)
                                    : Colors.red.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: widget.service.isCurrentlyOpen
                                          ? Colors.green
                                          : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.service.isCurrentlyOpen
                                        ? loc.t('open_now')
                                        : loc.t('closed'),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: widget.service.isCurrentlyOpen
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 3),

                        // Rating row
                        if (widget.service.averageRating != null && widget.service.averageRating! > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: Color(0xFFFBBF24),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  widget.service.averageRating!.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.grey.shade800,
                                  ),
                                ),
                                if (widget.service.totalReviews != null && widget.service.totalReviews! > 0) ...[
                                  Text(
                                    ' (${widget.service.totalReviews})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                        // Working hours display (below rating)
                        if (widget.service.workingHoursDisplay.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 12,
                                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.service.workingHoursDisplay,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Category with icon
                        if (widget.service.catName.isNotEmpty)
                          Row(
                            children: [
                              AppIcon.small(
                                Icons.category_outlined,
                                color: Theme.of(context).primaryColor.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.service.catName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                        const Spacer(),

                        // Footer: Distance + Actions
                        Row(
                          children: [
                            if (widget.showDistance &&
                                widget.service.distance != null) ...[
                              AppDistanceIcon(
                                distance: widget.service.distance!,
                                unit: loc.t('km'),
                              ),
                            ],
                            const Spacer(),
                            _buildQuickActions(context, isDark),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(
      BuildContext context, bool isDark, double cardWidth, double cardHeight, AppLocalizations loc) {
    final imageHeight = cardHeight * 0.48;
    final styleConfig = _CardStyleConfig.forStyle(widget.cardStyle);

    return Stack(
      children: [
        // Image
        Hero(
          tag: 'service_image_${widget.service.id}${widget.fromWhere}',
          child: SizedBox(
            width: double.infinity,
            height: imageHeight,
            child: widget.service.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.service.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildImagePlaceholder(isDark),
                    errorWidget: (context, url, error) =>
                        _buildImagePlaceholder(isDark),
                  )
                : _buildImagePlaceholder(isDark),
          ),
        ),

        // Gradient overlay for better text readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Style accent ribbon (only for top rated)
        if (widget.cardStyle == ServiceCardStyle.topRated)
          Positioned(
            top: 0,
            left: 0,
            child: ClipPath(
              clipper: _AccentRibbonClipper(),
              child: Container(
                width: 32,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      styleConfig.accentColor,
                      styleConfig.accentColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Icon(
                    styleConfig.badgeIcon,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
          ),

        // Favorite button
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withOpacity(0.4)
                  : Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: FavoriteButton(
              serviceId: widget.service.id,
              size: FavoriteButtonSize.small,
              style: FavoriteButtonStyle.minimal,
            ),
          ),
        ),

      ],
    );
  }

  Widget _buildImagePlaceholder(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF5F5F5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon.large(
              Icons.image_outlined,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).t('no_image'),
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Check if user is authenticated, show login prompt if not
  bool _checkAuth(String feature) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      showLoginPromptDialog(context, feature: feature);
      return false;
    }
    return true;
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.service.phone.isNotEmpty)
          AppActionButton.call(
            onTap: () {
              HapticFeedback.lightImpact();
              if (!_checkAuth('call_service')) return;
              _showCallDialog(context);
            },
          ),
        if (widget.service.phone.isNotEmpty &&
            widget.service.lat != 0 &&
            widget.service.lng != 0)
          const SizedBox(width: 8),
        if (widget.service.lat != 0 && widget.service.lng != 0)
          AppActionButton.directions(
            onTap: () {
              HapticFeedback.lightImpact();
              if (!_checkAuth('view_location')) return;
              MapLauncher.openMaps(
                context: context,
                latitude: widget.service.lat,
                longitude: widget.service.lng,
                placeName: widget.service.title,
              );
            },
          ),
      ],
    );
  }

  void _showCallDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            AppIcon.circle(
              icon: Icons.phone_rounded,
              color: Theme.of(context).primaryColor,
              size: AppIconSize.xl,
              containerSize: AppIconContainerSize.xl,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).t('call_to'),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.service.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              widget.service.phone,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).primaryColor,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context).t('cancel'),
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _makePhoneCall(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppIcon.small(Icons.phone_rounded, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context).t('call_now'),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _makePhoneCall(BuildContext context) async {
    final phoneUri = Uri(scheme: 'tel', path: widget.service.phone);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (context.mounted) {
          _showErrorSnackBar(context, AppLocalizations.of(context).t('cannot_make_call'));
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, AppLocalizations.of(context).t('error_making_call'));
      }
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            AppIcon.small(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

/// Custom clipper for accent ribbon with V-cut at bottom
class _AccentRibbonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - 8);
    path.lineTo(size.width / 2, size.height - 12);
    path.lineTo(0, size.height - 8);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

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

/// Premium card design for verified services - Enhanced version
class VerifiedServiceCard extends StatefulWidget {
  final Service service;
  final int index;
  final String fromWhere;

  const VerifiedServiceCard({
    Key? key,
    required this.service,
    required this.index,
    required this.fromWhere,
  }) : super(key: key);

  @override
  State<VerifiedServiceCard> createState() => _VerifiedServiceCardState();
}

class _VerifiedServiceCardState extends State<VerifiedServiceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  // Premium verified colors
  static const Color verifiedBlue = Color(0xFF1DA1F2);
  static const Color verifiedBlueDark = Color(0xFF0D8ECF);
  static const Color goldAccent = Color(0xFFFFD700);
  static const Color premiumGold = Color(0xFFF4C430);

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
    _glowAnimation = Tween<double>(begin: 0.2, end: 0.4).animate(
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
    const cardWidth = 320.0;
    const cardHeight = 270.0;

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
        child: Container(
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
                      // Image Section with premium overlay
                      _buildImageSection(context, isDark, cardWidth, loc),

                      // Content Section
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title with verified badge and open/close status
                              Row(
                                children: [
                                  const Icon(
                                    Icons.verified,
                                    size: 18,
                                    color: verifiedBlue,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      widget.service.title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1A1A2E),
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Open/Closed badge facing title
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
                              // Owner name
                              if (widget.service.userName.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  widget.service.userName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],

                              const SizedBox(height: 10),

                              // Rating, reviews count and category in a premium row
                              Row(
                                children: [
                                  // Premium rating badge
                                  if (widget.service.averageRating != null &&
                                      widget.service.averageRating! > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            premiumGold.withOpacity(0.2),
                                            goldAccent.withOpacity(0.1),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: premiumGold.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            size: 14,
                                            color: premiumGold,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            widget.service.averageRating!
                                                .toStringAsFixed(1),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.grey.shade800,
                                            ),
                                          ),
                                          if (widget.service.totalReviews != null &&
                                              widget.service.totalReviews! > 0) ...[
                                            Text(
                                              ' (${widget.service.totalReviews})',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isDark
                                                    ? Colors.grey.shade400
                                                    : Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  // Category badge
                                  if (widget.service.catName.isNotEmpty)
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.05)
                                              : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
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
                                    ),
                                ],
                              ),

                              const Spacer(),

                              // Footer: Distance + Premium Actions
                              Row(
                                children: [
                                  // Distance with premium styling
                                  if (widget.service.distance != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            verifiedBlue.withOpacity(0.15),
                                            verifiedBlueDark.withOpacity(0.1),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: verifiedBlue.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.near_me_rounded,
                                            size: 14,
                                            color: verifiedBlue,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${widget.service.distance!.toStringAsFixed(1)} ${loc.t('km')}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: verifiedBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const Spacer(),
                                  _buildPremiumActions(context, isDark),
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
    BuildContext context,
    bool isDark,
    double cardWidth,
    AppLocalizations loc,
  ) {
    const imageHeight = 130.0;

    return Stack(
      children: [
        // Image with rounded corners
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: Hero(
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
        ),

        // Gradient overlay for text visibility
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
        ),

        // Small decorative ribbon hanging from top-left
        Positioned(
          top: 0,
          left: 12,
          child: _buildCornerRibbon(loc),
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

        // Working hours badge if available
        if (widget.service.workingHoursDisplay.isNotEmpty)
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withOpacity(0.6)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 12,
                    color: verifiedBlue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.service.workingHoursDisplay,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Builds a small decorative ribbon with scissor-cut end
  Widget _buildCornerRibbon(AppLocalizations loc) {
    return ClipPath(
      clipper: _RibbonClipper(),
      child: Container(
        width: 24,
        height: 36,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [verifiedBlue, verifiedBlueDark],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2A3A4D), const Color(0xFF1A2A3D)]
              : [const Color(0xFFF0F4F8), const Color(0xFFE8EEF4)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: verifiedBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_rounded,
                size: 32,
                color: verifiedBlue.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).t('no_image'),
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
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

  Widget _buildPremiumActions(BuildContext context, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.service.phone.isNotEmpty)
          _buildPremiumActionButton(
            icon: Icons.phone_rounded,
            color: Colors.green.shade500,
            onTap: () {
              HapticFeedback.lightImpact();
              if (!_checkAuth('call_service')) return;
              _makePhoneCall(context);
            },
          ),
        if (widget.service.phone.isNotEmpty &&
            widget.service.lat != 0 &&
            widget.service.lng != 0)
          const SizedBox(width: 10),
        if (widget.service.lat != 0 && widget.service.lng != 0)
          _buildPremiumActionButton(
            icon: Icons.directions_rounded,
            color: verifiedBlue,
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

  Widget _buildPremiumActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: color,
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
          _showErrorSnackBar(
              context, AppLocalizations.of(context).t('cannot_make_call'));
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(
            context, AppLocalizations.of(context).t('error_making_call'));
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

/// Custom clipper for ribbon with V-cut at bottom
class _RibbonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - 8);
    // V-cut at bottom
    path.lineTo(size.width / 2, size.height - 14);
    path.lineTo(0, size.height - 8);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

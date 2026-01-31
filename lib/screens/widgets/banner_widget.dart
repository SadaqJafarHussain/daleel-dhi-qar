import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/adds_model.dart';
import '../../models/service_model.dart';
import '../../providers/ads_provider.dart';
import '../../providers/service_peovider.dart';
import '../../utils/app_localization.dart';
import '../service_details_screen.dart';
import 'shimmer_loading.dart';

class AdsBannerSlider extends StatefulWidget {
  final double height;

  const AdsBannerSlider({super.key, required this.height});

  @override
  State<AdsBannerSlider> createState() => _AdsBannerSliderState();
}

class _AdsBannerSliderState extends State<AdsBannerSlider> {
  final PageController _controller = PageController(viewportFraction: 1.0);
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<AdvProvider>(context, listen: false).fetchAds(context);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoPlay(int count) {
    if (count <= 1) return;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      int next = (_currentIndex + 1) % count;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _stopAutoPlay() => _timer?.cancel();
  void _resumeAutoPlay(int count) => _startAutoPlay(count);

  Future<void> _handleAdTap(AdvModel ad) async {
    HapticFeedback.lightImpact();

    switch (ad.adType) {
      case AdType.servicePromotion:
        if (ad.serviceId != null) {
          await _navigateToService(ad.serviceId!);
        } else if (ad.link.isNotEmpty) {
          await _launchLink(ad.link);
        }
        break;
      case AdType.externalLink:
        if (ad.link.isNotEmpty) {
          await _launchLink(ad.link);
        }
        break;
      case AdType.appPromotion:
        // Handle in-app navigation based on link
        if (ad.link.isNotEmpty) {
          await _launchLink(ad.link);
        }
        break;
      case AdType.announcement:
        // No action for announcements
        break;
    }
  }

  Future<void> _navigateToService(int serviceId) async {
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);

    // Try to find the service in existing data
    Service? service;
    try {
      service = serviceProvider.services.firstWhere((s) => s.id == serviceId);
    } catch (e) {
      // Service not found in current list, try to fetch it
      try {
        await serviceProvider.fetchAllServices();
        service = serviceProvider.services.firstWhere((s) => s.id == serviceId);
      } catch (e) {
        if (mounted) {
          final locale = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(locale.t('service_not_found')),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        return;
      }
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServiceDetailsScreen(service: service!),
        ),
      );
    }
  }

  Future<void> _launchLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        final locale = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locale.t('cannot_open_url')),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdvProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (provider.isLoading) return _buildShimmerPlaceholder(isDark);
    final ads = provider.ads;
    if (ads.isEmpty) return const SizedBox.shrink();

    _startAutoPlay(ads.length);

    return Column(
      children: [
        // Main Banner
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: ads.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              return _buildAdCard(ads[index], isDark);
            },
          ),
        ),

        // Page Indicators
        if (ads.length > 1) ...[
          const SizedBox(height: 12),
          _buildPageIndicators(ads.length, isDark),
        ],
      ],
    );
  }

  Widget _buildAdCard(AdvModel ad, bool isDark) {
    return GestureDetector(
      onTapDown: (_) => _stopAutoPlay(),
      onTapUp: (_) => _resumeAutoPlay(Provider.of<AdvProvider>(context, listen: false).ads.length),
      onTapCancel: () => _resumeAutoPlay(Provider.of<AdvProvider>(context, listen: false).ads.length),
      onTap: ad.hasAction ? () => _handleAdTap(ad) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.4)
                  : Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              _buildBackgroundImage(ad, isDark),

              // Gradient Overlay
              _buildGradientOverlay(ad),

              // Content
              _buildContent(ad, isDark),

              // Badges
              _buildBadges(ad, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundImage(AdvModel ad, bool isDark) {
    if (ad.image.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: ad.image,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
          ),
        ),
        child: const Icon(Icons.image_not_supported, color: Colors.white54, size: 40),
      ),
    );
  }

  Widget _buildGradientOverlay(AdvModel ad) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.2),
            Colors.black.withOpacity(0.7),
            Colors.black.withOpacity(0.85),
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        ),
      ),
    );
  }

  Widget _buildContent(AdvModel ad, bool isDark) {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          if (ad.title.isNotEmpty)
            Text(
              ad.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.2,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

          if (ad.content.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              ad.content,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Action Button
          if (ad.hasAction) ...[
            const SizedBox(height: 14),
            _buildActionButton(ad),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(AdvModel ad) {
    final locale = AppLocalizations.of(context);
    final buttonText = ad.getButtonText(
      locale.t('discover_more'),
      serviceText: locale.t('view_service'),
      externalText: locale.t('discover_more'),
      appText: locale.t('try_now'),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            buttonText,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            _getActionIcon(ad.adType),
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(AdType type) {
    switch (type) {
      case AdType.servicePromotion:
        return Icons.storefront_rounded;
      case AdType.externalLink:
        return Icons.open_in_new_rounded;
      case AdType.appPromotion:
        return Icons.touch_app_rounded;
      case AdType.announcement:
        return Icons.campaign_rounded;
    }
  }

  Widget _buildBadges(AdvModel ad, bool isDark) {
    final locale = AppLocalizations.of(context);
    return Positioned(
      top: 14,
      right: 14,
      child: Row(
        children: [
          // Sponsored badge
          if (ad.isSponsored)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.campaign_rounded,
                    size: 12,
                    color: Colors.amber.shade300,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    locale.t('sponsored'),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Ad type indicator
          if (ad.adType == AdType.servicePromotion) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    locale.t('featured_service'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPageIndicators(int count, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = _currentIndex == index;
        return GestureDetector(
          onTap: () {
            _controller.animateToPage(
              index,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).primaryColor
                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildShimmerPlaceholder(bool isDark) {
    return ShimmerLoading(
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

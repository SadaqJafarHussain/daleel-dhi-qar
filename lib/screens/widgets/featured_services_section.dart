import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tour_guid/screens/widgets/section_header.dart';
import 'package:tour_guid/screens/widgets/service_card.dart';
import 'package:tour_guid/screens/widgets/verified_service_card.dart';
import 'package:tour_guid/screens/widgets/shimmer_loading.dart';
import '../../models/service_model.dart';
import '../../providers/service_peovider.dart';
import '../../utils/app_localization.dart';
import '../../utils/page_transitions.dart';
import '../services_screen.dart';

/// Featured section types
enum FeaturedSectionType {
  topRated,
  recentlyAdded,
  openNow,
  verified,
}

/// Configuration for featured section appearance
class FeaturedSectionConfig {
  final IconData icon;
  final List<Color> gradientColors;
  final String titleKey;
  final String subtitleKey;
  final String emptyTitleKey;
  final String emptySubtitleKey;

  const FeaturedSectionConfig({
    required this.icon,
    required this.gradientColors,
    required this.titleKey,
    required this.subtitleKey,
    required this.emptyTitleKey,
    required this.emptySubtitleKey,
  });

  static FeaturedSectionConfig forType(FeaturedSectionType type) {
    switch (type) {
      case FeaturedSectionType.topRated:
        return const FeaturedSectionConfig(
          icon: Icons.star_rounded,
          gradientColors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
          titleKey: 'top_rated',
          subtitleKey: 'top_rated_subtitle',
          emptyTitleKey: 'no_top_rated',
          emptySubtitleKey: 'no_top_rated_subtitle',
        );
      case FeaturedSectionType.recentlyAdded:
        return const FeaturedSectionConfig(
          icon: Icons.new_releases_rounded,
          gradientColors: [Color(0xFF10B981), Color(0xFF059669)],
          titleKey: 'recently_added',
          subtitleKey: 'recently_added_subtitle',
          emptyTitleKey: 'no_recently_added',
          emptySubtitleKey: 'no_recently_added_subtitle',
        );
      case FeaturedSectionType.openNow:
        return const FeaturedSectionConfig(
          icon: Icons.access_time_filled_rounded,
          gradientColors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          titleKey: 'open_now_services',
          subtitleKey: 'open_now_subtitle',
          emptyTitleKey: 'no_open_now',
          emptySubtitleKey: 'no_open_now_subtitle',
        );
      case FeaturedSectionType.verified:
        return const FeaturedSectionConfig(
          icon: Icons.verified_rounded,
          gradientColors: [Color(0xFF1DA1F2), Color(0xFF0D8ECF)],
          titleKey: 'verified_services',
          subtitleKey: 'verified_services_subtitle',
          emptyTitleKey: 'no_verified_services',
          emptySubtitleKey: 'no_verified_services_subtitle',
        );
    }
  }
}

/// A professional featured services section widget
class FeaturedServicesSection extends StatelessWidget {
  final double width;
  final double height;
  final FeaturedSectionType type;
  final int maxItems;

  const FeaturedServicesSection({
    Key? key,
    required this.width,
    required this.height,
    required this.type,
    this.maxItems = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = FeaturedSectionConfig.forType(type);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    return Consumer<ServiceProvider>(
      builder: (context, serviceProvider, _) {
        final services = _getServices(serviceProvider);
        final isLoading = serviceProvider.isLoading;

        // Don't show section if no services and not loading
        if (services.isEmpty && !isLoading) {
          return const SizedBox.shrink();
        }

        if (isLoading && services.isEmpty) {
          return _buildLoadingState(width, height, isDark, loc, config);
        }

        return _buildServicesSection(
          context,
          width,
          height,
          isDark,
          loc,
          config,
          services.take(maxItems).toList(),
        );
      },
    );
  }

  List<Service> _getServices(ServiceProvider provider) {
    switch (type) {
      case FeaturedSectionType.topRated:
        return provider.topRatedServices;
      case FeaturedSectionType.recentlyAdded:
        return provider.recentlyAddedServices;
      case FeaturedSectionType.openNow:
        return provider.openNowServices;
      case FeaturedSectionType.verified:
        return provider.verifiedServices;
    }
  }

  Widget _buildLoadingState(
    double w,
    double h,
    bool isDark,
    AppLocalizations loc,
    FeaturedSectionConfig config,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.045, vertical: h * 0.01),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeaderWidget(loc, config, null, null),
          const SizedBox(height: 16),
          HorizontalSkeletonList(
            itemCount: 3,
            itemWidth: 280,
            itemHeight: 220,
            spacing: 12,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection(
    BuildContext context,
    double w,
    double h,
    bool isDark,
    AppLocalizations loc,
    FeaturedSectionConfig config,
    List<Service> services,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with badge
        Padding(
          padding: EdgeInsets.fromLTRB(w * 0.045, h * 0.015, w * 0.045, 0),
          child: _buildSectionHeaderWidget(
            loc,
            config,
            services.length,
            () => _navigateToAllServices(context, services, loc, config),
          ),
        ),

        const SizedBox(height: 14),

        // Services horizontal list
        SizedBox(
          height: type == FeaturedSectionType.verified ? 280 : 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: w * 0.045),
            itemCount: services.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return AnimatedListItem(
                index: index,
                delay: const Duration(milliseconds: 50),
                child: type == FeaturedSectionType.verified
                    ? VerifiedServiceCard(
                        service: services[index],
                        index: index,
                        fromWhere: type.name,
                      )
                    : ServiceCard(
                        service: services[index],
                        index: index,
                        fromWhere: type.name,
                        height: 220,
                        cardStyle: _getCardStyleForType(type),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build section header widget based on type
  Widget _buildSectionHeaderWidget(
    AppLocalizations loc,
    FeaturedSectionConfig config,
    int? itemCount,
    VoidCallback? onViewAll,
  ) {
    switch (type) {
      case FeaturedSectionType.topRated:
        return SectionHeader.topRated(
          title: loc.t(config.titleKey),
          subtitle: loc.t(config.subtitleKey),
          itemCount: itemCount,
          onViewAll: onViewAll,
        );
      case FeaturedSectionType.recentlyAdded:
        return SectionHeader.recentlyAdded(
          title: loc.t(config.titleKey),
          subtitle: loc.t(config.subtitleKey),
          itemCount: itemCount,
          onViewAll: onViewAll,
        );
      case FeaturedSectionType.openNow:
        return SectionHeader.openNow(
          title: loc.t(config.titleKey),
          subtitle: loc.t(config.subtitleKey),
          itemCount: itemCount,
          onViewAll: onViewAll,
        );
      case FeaturedSectionType.verified:
        return SectionHeader.verified(
          title: loc.t(config.titleKey),
          subtitle: loc.t(config.subtitleKey),
          itemCount: itemCount,
          onViewAll: onViewAll,
        );
    }
  }

  void _navigateToAllServices(
    BuildContext context,
    List<Service> services,
    AppLocalizations loc,
    FeaturedSectionConfig config,
  ) {
    Navigator.push(
      context,
      PageTransitions.slideRight(
        page: ServicesScreen.fromFeaturedServices(
          services: services,
          title: loc.t(config.titleKey),
        ),
      ),
    );
  }

  /// Maps FeaturedSectionType to ServiceCardStyle
  ServiceCardStyle _getCardStyleForType(FeaturedSectionType type) {
    switch (type) {
      case FeaturedSectionType.topRated:
        return ServiceCardStyle.topRated;
      case FeaturedSectionType.recentlyAdded:
        return ServiceCardStyle.recentlyAdded;
      case FeaturedSectionType.openNow:
        return ServiceCardStyle.openNow;
      case FeaturedSectionType.verified:
        return ServiceCardStyle.standard; // Verified uses VerifiedServiceCard
    }
  }
}

/// Animated list item wrapper for staggered animations
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;

  const AnimatedListItem({
    Key? key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 100),
  }) : super(key: key);

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(
      Duration(milliseconds: widget.index * widget.delay.inMilliseconds),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tour_guid/providers/ads_provider.dart';
import 'package:tour_guid/providers/category_provider.dart';
import 'package:tour_guid/providers/service_peovider.dart';
import 'package:tour_guid/screens/widgets/banner_widget.dart';
import 'package:tour_guid/screens/widgets/categories_section.dart';
import 'package:tour_guid/screens/widgets/home_app_bar.dart';
import 'package:tour_guid/screens/widgets/nearby_services_section.dart';
import 'package:tour_guid/screens/widgets/search_section.dart';
import 'package:tour_guid/screens/widgets/service_list_section.dart';
import 'package:tour_guid/screens/widgets/featured_services_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    HapticFeedback.mediumImpact();

    // Refresh all providers
    if (mounted) {
      final adsProvider = Provider.of<AdvProvider>(context, listen: false);
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);

      // Force refresh all data from server
      await Future.wait([
        adsProvider.forceRefreshAds(context),
        categoryProvider.fetchCategories(context),
        serviceProvider.fetchAllServices(forceRefresh: true),
      ]);
    }

    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: Theme.of(context).primaryColor,
          backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          displacement: 60,
          strokeWidth: 2.5,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // App Bar
              SliverToBoxAdapter(
                child: HomeAppBar(width: w, height: h),
              ),

              // Search Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.045),
                  child: SearchSection(width: w, height: h),
                ),
              ),

              // Banner Slider
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(w * 0.045, 0, w * 0.045, h * 0.01),
                  child: AdsBannerSlider(height: h * 0.2),
                ),
              ),

              // Categories Section
              SliverToBoxAdapter(
                child: CategoriesSection(width: w, height: h),
              ),

              // Verified Services Section (Premium) - First priority
              SliverToBoxAdapter(
                child: FeaturedServicesSection(
                  width: w,
                  height: h,
                  type: FeaturedSectionType.verified,
                ),
              ),

              // Spacer
              SliverToBoxAdapter(child: SizedBox(height: h * 0.025)),

              // Nearby Services Section
              SliverToBoxAdapter(
                child: NearbyServicesSection(width: w, height: h),
              ),

              // Spacer
              SliverToBoxAdapter(child: SizedBox(height: h * 0.025)),

              // Top Rated Services Section
              SliverToBoxAdapter(
                child: FeaturedServicesSection(
                  width: w,
                  height: h,
                  type: FeaturedSectionType.topRated,
                ),
              ),

              // Spacer
              SliverToBoxAdapter(child: SizedBox(height: h * 0.025)),

              // Recently Added Services Section
              SliverToBoxAdapter(
                child: FeaturedServicesSection(
                  width: w,
                  height: h,
                  type: FeaturedSectionType.recentlyAdded,
                ),
              ),

              // Spacer
              SliverToBoxAdapter(child: SizedBox(height: h * 0.025)),

              // Open Now Services Section
              SliverToBoxAdapter(
                child: FeaturedServicesSection(
                  width: w,
                  height: h,
                  type: FeaturedSectionType.openNow,
                ),
              ),

              // Divider
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.045,
                    vertical: h * 0.01,
                  ),
                  child: Divider(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    thickness: 1,
                  ),
                ),
              ),

              // All Services Section
              SliverToBoxAdapter(
                child: ServicesListSection(width: w, height: h),
              ),

              // Bottom Spacing
              SliverToBoxAdapter(
                child: SizedBox(height: h * 0.12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

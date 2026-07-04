import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tour_guid/providers/ads_provider.dart';
import 'package:tour_guid/providers/app_settings_provider.dart';
import 'package:tour_guid/providers/category_provider.dart';
import 'package:tour_guid/providers/app_config_provider.dart';
import 'package:tour_guid/providers/home_sections_provider.dart';
import 'package:tour_guid/providers/home_sections_config_provider.dart';
import 'package:tour_guid/models/home_section_config_model.dart';
import 'package:tour_guid/providers/language_provider.dart';
import 'package:tour_guid/providers/service_peovider.dart';
import 'package:tour_guid/screens/widgets/banner_widget.dart';
import 'package:tour_guid/screens/widgets/categories_section.dart';
import 'package:tour_guid/screens/widgets/dynamic_home_section_widget.dart';
import 'package:tour_guid/screens/widgets/home_app_bar.dart';
import 'package:tour_guid/screens/widgets/nearby_services_section.dart';
import 'package:tour_guid/screens/widgets/search_section.dart';
import 'package:tour_guid/screens/widgets/featured_services_section.dart';
import 'package:tour_guid/utils/app_localization.dart';

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
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<AppSettingsProvider>(context, listen: false).fetchSettings();
      Provider.of<HomeSectionsProvider>(context, listen: false).fetchSections();
      Provider.of<HomeSectionsConfigProvider>(context, listen: false).fetchConfigs();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    HapticFeedback.mediumImpact();

    if (mounted) {
      final adsProvider = Provider.of<AdvProvider>(context, listen: false);
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
      final layoutCfgProvider = Provider.of<HomeSectionsConfigProvider>(context, listen: false);

      await Future.wait([
        adsProvider.forceRefreshAds(context),
        categoryProvider.fetchCategories(context),
        serviceProvider.fetchAllServices(forceRefresh: true),
        layoutCfgProvider.forceReload(),
      ]);
    }

    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cfg = context.watch<AppConfigProvider>();
    final layoutCfg = context.watch<HomeSectionsConfigProvider>();
    final isAr = context.watch<LanguageProvider>().isArabic;

    // Build ordered visible section widgets
    final dynamicSections = _buildDynamicSections(
      w: w, h: h,
      cfg: cfg,
      layoutCfg: layoutCfg,
      isAr: isAr,
    );

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
              // App Bar (always fixed at top)
              SliverToBoxAdapter(child: HomeAppBar(width: w, height: h)),

              // ── Dynamic sections (ordered + toggled by admin) ──────────
              ...dynamicSections,

              // Bottom spacing
              SliverToBoxAdapter(child: SizedBox(height: h * 0.1)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDynamicSections({
    required double w,
    required double h,
    required AppConfigProvider cfg,
    required HomeSectionsConfigProvider layoutCfg,
    required bool isAr,
  }) {
    // If config not loaded yet, fall back to default order so screen isn't blank
    final configs = layoutCfg.visibleConfigs.isNotEmpty
        ? layoutCfg.visibleConfigs
        : _defaultConfigs;

    final slivers = <Widget>[];

    for (final section in configs) {
      final title = section.localizedTitle(isAr).isNotEmpty
          ? section.localizedTitle(isAr)
          : null;

      Widget? widget = _widgetForKey(
        key: section.key,
        w: w, h: h,
        cfg: cfg,
        customTitle: title,
      );

      if (widget == null) continue;

      slivers.add(SliverToBoxAdapter(child: widget));
      slivers.add(SliverToBoxAdapter(child: SizedBox(height: h * 0.012)));
    }

    return slivers;
  }

  Widget? _widgetForKey({
    required String key,
    required double w,
    required double h,
    required AppConfigProvider cfg,
    String? customTitle,
  }) {
    switch (key) {
      case 'header':
        return Padding(
          padding: EdgeInsets.fromLTRB(w * 0.045, h * 0.012, w * 0.045, h * 0.004),
          child: _HomeHeaderText(width: w, height: h),
        );
      case 'search':
        return Padding(
          padding: EdgeInsets.fromLTRB(w * 0.045, 0, w * 0.045, 0),
          child: SearchSection(width: w),
        );
      case 'ads':
        return Padding(
          padding: EdgeInsets.fromLTRB(w * 0.045, 0, w * 0.045, 0),
          child: AdsBannerSlider(height: h * 0.28),
        );
      case 'categories':
        return CategoriesSection(width: w, height: h, customTitle: customTitle);
      case 'featured':
        return FeaturedServicesSection(
          width: w, height: h,
          type: FeaturedSectionType.featured,
          customTitle: customTitle,
        );
      case 'verified':
        return FeaturedServicesSection(
          width: w, height: h,
          type: FeaturedSectionType.verified,
          customTitle: customTitle,
        );
      case 'top_rated':
        return FeaturedServicesSection(
          width: w, height: h,
          type: FeaturedSectionType.topRated,
          customTitle: customTitle,
        );
      case 'recently_added':
        return FeaturedServicesSection(
          width: w, height: h,
          type: FeaturedSectionType.recentlyAdded,
          customTitle: customTitle,
        );
      case 'open_now':
        return FeaturedServicesSection(
          width: w, height: h,
          type: FeaturedSectionType.openNow,
          customTitle: customTitle,
        );
      case 'nearby':
        if (!cfg.featureNearby) return null;
        return NearbyServicesSection(width: w, height: h);
      case 'custom_sections':
        return HomeSectionsWidget(width: w, height: h);
      default:
        return null;
    }
  }

  /// Default config shown when DB not yet loaded (prevents empty screen on first frame)
  static final List<HomeSectionConfig> _defaultConfigs = [
    const HomeSectionConfig(key: 'header',         titleAr: '', titleEn: '', visible: true, sortOrder: 1),
    const HomeSectionConfig(key: 'search',         titleAr: '', titleEn: '', visible: true, sortOrder: 2),
    const HomeSectionConfig(key: 'ads',            titleAr: '', titleEn: '', visible: true, sortOrder: 3),
    const HomeSectionConfig(key: 'categories',     titleAr: '', titleEn: '', visible: true, sortOrder: 4),
    const HomeSectionConfig(key: 'featured',       titleAr: '', titleEn: '', visible: true, sortOrder: 5),
    const HomeSectionConfig(key: 'verified',       titleAr: '', titleEn: '', visible: true, sortOrder: 6),
    const HomeSectionConfig(key: 'nearby',         titleAr: '', titleEn: '', visible: true, sortOrder: 7),
    const HomeSectionConfig(key: 'top_rated',      titleAr: '', titleEn: '', visible: true, sortOrder: 8),
    const HomeSectionConfig(key: 'recently_added', titleAr: '', titleEn: '', visible: true, sortOrder: 9),
    const HomeSectionConfig(key: 'open_now',       titleAr: '', titleEn: '', visible: true, sortOrder: 10),
    const HomeSectionConfig(key: 'custom_sections',titleAr: '', titleEn: '', visible: true, sortOrder: 11),
  ];
}

// ─── Title + Subtitle above banner ───────────────────────────────────────────

class _HomeHeaderText extends StatelessWidget {
  final double width;
  final double height;

  const _HomeHeaderText({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final isAr = context.watch<LanguageProvider>().isArabic;
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = settings.getLabel('home_title', isAr: isAr) ?? loc.t('home_greeting');
    final subtitle = settings.getLabel('home_subtitle', isAr: isAr) ?? loc.t('discover_services');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

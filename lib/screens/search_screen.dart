import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:tour_guid/utils/app_icons.dart';
import '../providers/app_config_provider.dart';
import '../providers/category_provider.dart';
import '../providers/language_provider.dart';
import '../providers/service_peovider.dart';
import '../providers/subcategory_provider.dart';
import '../providers/search_provider.dart';
import '../providers/favorites_provider.dart';
import '../utils/app_localization.dart';
import 'widgets/service_card.dart';
import 'dart:async';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  bool _showFilters = false;
  bool _gridView = false;
  // Sort options: index → provider sort key
  static const _sortKeys = ['rating', 'newest', 'nearest'];
  int _activeSortIndex = 0;

  @override
  void initState() {
    super.initState();

    _filterAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
      context.read<AppConfigProvider>().addListener(_onConfigChanged);
      // Set active sort pill to match config default
      final cfgSort = context.read<AppConfigProvider>().searchDefaultSort;
      final idx = _sortKeys.indexOf(cfgSort);
      if (idx >= 0 && idx != _activeSortIndex) {
        setState(() => _activeSortIndex = idx);
      }
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _searchFocusNode.requestFocus();
      });
    });
  }

  void _onConfigChanged() {
    if (!mounted) return;
    final cfg = context.read<AppConfigProvider>();
    context.read<SearchProvider>().updateSearchConfig(
      defaultSort:  cfg.searchDefaultSort,
      resultsLimit: cfg.searchResultsLimit,
    );
  }

  Future<void> _initializeData() async {
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);

    searchProvider.setLoading(true);

    try {
      // ✅ 1. Ensure favorites provider has enrichment functions
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final subcategoryProvider = Provider.of<SubcategoryProvider>(context, listen: false);

      favoritesProvider.setEnrichmentFunctions(
        getCategoryName: (catId) => categoryProvider.getCategoryNameById(catId),
        getSubcategoryName: (subcatId) => subcategoryProvider.getSubcategoryNameById(subcatId),
      );

      // ✅ 2. Fetch ALL services for search (simple and fast)
      await serviceProvider.fetchAllServices();

      // ✅ 3. Try to get user location for distance filter
      // Use the existing user location if available, don't fetch nearby services
      // This prevents affecting the main screen's nearby services
      Position? userLocation = serviceProvider.userLocation;

      // If no location available, try to get it directly without affecting nearbyServices
      if (userLocation == null) {
        try {
          final permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse) {
            userLocation = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 5),
            );
          }
        } catch (e) {
          debugPrint('Could not get location for search: $e');
          // Continue without location - search will still work!
        }
      }

      // ✅ 4. Initialize search with all services + config
      final cfg = Provider.of<AppConfigProvider>(context, listen: false);
      searchProvider.initializeServices(
        serviceProvider.services,
        userLocation,
        defaultSort:  cfg.searchDefaultSort,
        initialRadius: cfg.nearbyRadiusKm,
        resultsLimit:  cfg.searchResultsLimit,
      );

      searchProvider.setError(null);
    } catch (e) {
      searchProvider.setError('${AppLocalizations.of(context).t('failed_to_load_services')}: ${e.toString()}');
    } finally {
      searchProvider.setLoading(false);
    }
  }

  void _onSearchChanged(String query) {
    // Update UI immediately for clear button visibility
    setState(() {});

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final minLen = context.read<AppConfigProvider>().searchMinLength;
      // Always process empty query (clears results), but require minLength for actual search
      if (query.isEmpty || query.length >= minLen) {
        Provider.of<SearchProvider>(context, listen: false).updateSearchQuery(query);
      }
    });
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });

    if (_showFilters) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  @override
  void dispose() {
    context.read<AppConfigProvider>().removeListener(_onConfigChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    _filterAnimationController.dispose();
    super.dispose();
  }

  /// Dismiss keyboard when tapping outside search field
  void _dismissKeyboard() {
    _searchFocusNode.unfocus();
  }

  Widget _buildFiltersSection(BuildContext context, Size size, bool isDark) {
    final searchProvider = Provider.of<SearchProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final subcategoryProvider = Provider.of<SubcategoryProvider>(context);
    final loc = AppLocalizations.of(context);
    final isAr = context.read<LanguageProvider>().isArabic;
    final cfg = context.read<AppConfigProvider>();

    return SizeTransition(
      sizeFactor: _filterAnimation,
      axisAlignment: -1.0,
      child: Container(
        margin: EdgeInsets.fromLTRB(
          size.width * 0.04,
          0,
          size.width * 0.04,
          size.height * 0.02,
        ),
        padding: EdgeInsets.all(size.width * 0.04),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Reset Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    AppIcon.gradient(
                      icon: Icons.tune_rounded,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.7),
                      ],
                      size: AppIconSize.md,
                      containerSize: 40,
                      borderRadius: 12,
                    ),
                    SizedBox(width: size.width * 0.03),
                    Text(
                      loc.t('filters'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                if (searchProvider.selectedCategoryId != null ||
                    searchProvider.selectedSubcategoryId != null ||
                    searchProvider.useDistanceFilter)
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton.icon(
                      onPressed: () {
                        searchProvider.resetFilters();
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        loc.t('reset'),
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: size.height * 0.02),
            Divider(color: Colors.grey.shade300, height: 1),
            SizedBox(height: size.height * 0.02),

            // Category Filter
            Row(
              children: [
                AppIcon.small(
                  Icons.category_rounded,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(width: size.width * 0.02),
                Text(
                  loc.t('category'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: size.height * 0.015),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildModernFilterChip(
                    context: context,
                    label: loc.t('all'),
                    icon: Icons.grid_view_rounded,
                    isSelected: searchProvider.selectedCategoryId == null,
                    onTap: () {
                      searchProvider.updateCategoryFilter(null);
                    },
                    size: size,
                  ),
                  ...categoryProvider.categories.map((category) {
                    return _buildModernFilterChip(
                      context: context,
                      label: category.localizedName(isAr),
                      icon: Icons.folder_rounded,
                      isSelected:
                      searchProvider.selectedCategoryId == category.id,
                      onTap: () {
                        searchProvider.updateCategoryFilter(category.id);
                      },
                      size: size,
                    );
                  }).toList(),
                ],
              ),
            ),

            // Subcategory Filter
            if (searchProvider.selectedCategoryId != null) ...[
              SizedBox(height: size.height * 0.025),
              Row(
                children: [
                  AppIcon.small(
                    Icons.label_rounded,
                    color: Theme.of(context).primaryColor,
                  ),
                  SizedBox(width: size.width * 0.02),
                  Text(
                    loc.t('subcategory'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              SizedBox(height: size.height * 0.015),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildModernFilterChip(
                      context: context,
                      label: loc.t('all'),
                      icon: Icons.grid_view_rounded,
                      isSelected: searchProvider.selectedSubcategoryId == null,
                      onTap: () {
                        searchProvider.updateSubcategoryFilter(null);
                      },
                      size: size,
                    ),
                    ...subcategoryProvider
                        .getByCategory(searchProvider.selectedCategoryId!)
                        .map((subcategory) {
                      return _buildModernFilterChip(
                        context: context,
                        label: subcategory.localizedName(isAr),
                        icon: Icons.label_outline_rounded,
                        isSelected: searchProvider.selectedSubcategoryId ==
                            subcategory.id,
                        onTap: () {
                          searchProvider.updateSubcategoryFilter(subcategory.id);
                        },
                        size: size,
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],

            // Distance Filter Toggle (hidden if admin disabled it)
            if (cfg.searchShowDistanceFilter) ...[
            SizedBox(height: size.height * 0.025),
            Container(
              padding: EdgeInsets.all(size.width * 0.04),
              decoration: BoxDecoration(
                color: searchProvider.useDistanceFilter
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: searchProvider.useDistanceFilter
                      ? Theme.of(context).primaryColor.withOpacity(0.3)
                      : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      AppIcon.rounded(
                        icon: Icons.location_on_rounded,
                        color: searchProvider.useDistanceFilter
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade400,
                        size: AppIconSize.md,
                        containerSize: 36,
                        borderRadius: 10,
                        filled: true,
                      ),
                      SizedBox(width: size.width * 0.03),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.t('search_range'),
                            style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            searchProvider.useDistanceFilter
                                ? loc.t('enabled')
                                : loc.t('disabled'),
                            style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: searchProvider.useDistanceFilter
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Switch(
                    value: searchProvider.useDistanceFilter,
                    onChanged: (value) {
                      searchProvider.toggleDistanceFilter(value);
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),

            // Radius Slider (Only enabled when distance filter is on)
            if (searchProvider.useDistanceFilter) ...[
              SizedBox(height: size.height * 0.02),
              AnimatedOpacity(
                opacity: searchProvider.useDistanceFilter ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: EdgeInsets.all(size.width * 0.04),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.15),
                        Theme.of(context).primaryColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '1 ${loc.t('km')}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.05,
                              vertical: size.height * 0.01,
                            ),
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
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '${searchProvider.searchRadius.toStringAsFixed(0)} ${loc.t('km')}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Text(
                            '100 ${loc.t('km')}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: size.height * 0.01),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 5,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 12,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 24,
                          ),
                          activeTrackColor: Theme.of(context).primaryColor,
                          inactiveTrackColor: Colors.grey.shade300,
                          thumbColor: Theme.of(context).primaryColor,
                          overlayColor:
                          Theme.of(context).primaryColor.withOpacity(0.2),
                        ),
                        child: Slider(
                          value: searchProvider.searchRadius,
                          min: 1,
                          max: 100,
                          divisions: 99,
                          onChanged: (value) {
                            searchProvider.updateSearchRadius(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            ], // closes if (cfg.searchShowDistanceFilter)
          ],
        ),
      ),
    );
  }

  Widget _buildModernFilterChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Size size,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: size.width * 0.02),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.045,
              vertical: size.height * 0.012,
            ),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              )
                  : null,
              color: isSelected ? null : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(25),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon.small(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
                SizedBox(width: size.width * 0.02),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    context.watch<AppConfigProvider>(); // rebuild when config changes (e.g. distance filter toggle)

    return GestureDetector(
      onTap: _dismissKeyboard,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        resizeToAvoidBottomInset: true,
        body: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            // App Bar with Search and Filter Button
            _buildSliverAppBar(context, size, isDark),

            // Collapsible Filters Section
            if (_showFilters)
              SliverToBoxAdapter(
                child: _buildFiltersSection(context, size, isDark),
              ),

            // Sort + View toggle row
            SliverToBoxAdapter(
              child: _buildSortRow(context, size),
            ),

            // Results Count
            SliverToBoxAdapter(
              child: _buildResultsHeader(context, size),
            ),

            // Search Results
            _buildSearchResults(context, size),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Size size, bool isDark) {
    final searchProvider = Provider.of<SearchProvider>(context);
    final loc = AppLocalizations.of(context);

    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      toolbarHeight: 70,
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            // Back Button
            AppBackButton.light(),
            const SizedBox(width: 8),

            // Search Bar
            Expanded(
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  autofocus: false,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _dismissKeyboard(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: loc.t('search_hint'),
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 22,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              searchProvider.clearSearch();
                              setState(() {});
                            },
                          )
                        : (searchProvider.isLoading
                            ? Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                              )
                            : null),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Filter Toggle Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleFilters,
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: _showFilters
                        ? LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withOpacity(0.7),
                            ],
                          )
                        : null,
                    color: _showFilters
                        ? null
                        : (isDark ? Colors.grey.shade800 : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _showFilters
                            ? Theme.of(context).primaryColor.withOpacity(0.3)
                            : Colors.black.withOpacity(0.08),
                        blurRadius: _showFilters ? 8 : 10,
                        offset: Offset(0, _showFilters ? 2 : 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        color: _showFilters
                            ? Colors.white
                            : Theme.of(context).primaryColor,
                        size: 22,
                      ),
                      // Active filter indicator
                      if (searchProvider.selectedCategoryId != null ||
                          searchProvider.selectedSubcategoryId != null ||
                          searchProvider.useDistanceFilter)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _showFilters ? Colors.white : Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
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
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildSortRow(BuildContext context, Size size) {
    final searchProvider = Provider.of<SearchProvider>(context);
    final loc = AppLocalizations.of(context);
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sortLabels = [
      loc.t('top_rated'),
      loc.t('newest'),
      loc.t('nearest'),
    ];
    final sortIcons = [
      Icons.star_rounded,
      Icons.schedule_rounded,
      Icons.location_on_rounded,
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(size.width * 0.04, 0, size.width * 0.04, size.height * 0.012),
      child: Row(
        children: [
          // Sort pills
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_sortKeys.length, (i) {
                  final isSelected = _activeSortIndex == i;
                  return Padding(
                    padding: EdgeInsets.only(right: size.width * 0.02),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _activeSortIndex = i);
                        searchProvider.updateSearchConfig(defaultSort: _sortKeys[i]);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? primary : (isDark ? Colors.grey.shade800 : Colors.white),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? primary : Colors.grey.shade300,
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: primary.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2))]
                              : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(sortIcons[i],
                                size: 14,
                                color: isSelected ? Colors.white : Colors.grey.shade600),
                            const SizedBox(width: 5),
                            Text(
                              sortLabels[i],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          // Grid/List toggle
          GestureDetector(
            onTap: () => setState(() => _gridView = !_gridView),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _gridView ? primary : (isDark ? Colors.grey.shade800 : Colors.white),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _gridView ? primary : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Icon(
                _gridView ? Icons.grid_view_rounded : Icons.view_list_rounded,
                size: 18,
                color: _gridView ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader(BuildContext context, Size size) {
    final searchProvider = Provider.of<SearchProvider>(context);
    final loc = AppLocalizations.of(context);

    if (!searchProvider.hasResults && searchProvider.searchQuery.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.04,
          vertical: size.height * 0.02,
        ),
        child: Container(
          padding: EdgeInsets.all(size.width * 0.04),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.1),
                Theme.of(context).primaryColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              AppIcon.small(
                Icons.info_outline_rounded,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(width: size.width * 0.03),
              Expanded(
                child: Text(
                  loc.t('start_typing'),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!searchProvider.hasResults || searchProvider.isLoading) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.height * 0.015,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.035,
              vertical: size.height * 0.01,
            ),
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
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                SizedBox(width: size.width * 0.02),
                Text(
                  loc.t('found_services').replaceAll('{count}', searchProvider.resultsCount.toString()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, Size size) {
    final searchProvider = Provider.of<SearchProvider>(context);
    final loc = AppLocalizations.of(context);

    if (searchProvider.isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.2),
                      Theme.of(context).primaryColor.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.03),
              Text(
                loc.t('loading_text'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: size.height * 0.01),
              Text(
                loc.t('please_wait'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (searchProvider.errorMessage != null) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(size.width * 0.06),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon.circle(
                icon: Icons.error_outline_rounded,
                color: Colors.red.shade400,
                size: AppIconSize.xxl,
                containerSize: 96,
              ),
                SizedBox(height: size.height * 0.03),
                Text(
                  loc.t('error_occurred'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: size.height * 0.015),
                Text(
                  searchProvider.errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: size.height * 0.04),
                ElevatedButton.icon(
                  onPressed: _initializeData,
                  icon: const Icon(Icons.refresh_rounded, size: 22),
                  label: Text(
                    loc.t('try_again'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.08,
                      vertical: size.height * 0.018,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!searchProvider.hasResults) {
      return SliverFillRemaining(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon.circle(
                  icon: searchProvider.searchQuery.isEmpty
                      ? Icons.search_rounded
                      : Icons.search_off_rounded,
                  color: Theme.of(context).primaryColor.withOpacity(0.6),
                  size: AppIconSize.xl,
                  containerSize: AppIconContainerSize.xl,
                ),
                SizedBox(height: size.height * 0.02),
                Text(
                  searchProvider.searchQuery.isEmpty
                      ? loc.t('start_search')
                      : loc.t('no_results_found'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: size.height * 0.01),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
                  child: Text(
                    searchProvider.searchQuery.isEmpty
                        ? loc.t('type_to_search')
                        : loc.t('try_different_keywords'),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final services = searchProvider.filteredServices;
    final hPad = size.width * 0.04;

    if (_gridView) {
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(hPad, 0, hPad, size.height * 0.02),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.75,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 250 + (index * 40)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.scale(scale: 0.9 + 0.1 * value, child: child),
                ),
                child: ServiceCard(
                  service: services[index],
                  index: index,
                  fromWhere: 'searchScreen',
                ),
              );
            },
            childCount: services.length,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.only(
        left: hPad,
        right: hPad,
        bottom: size.height * 0.02,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final service = services[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * 50)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  height: 240,
                  child: ServiceCard(
                    service: service,
                    index: index,
                    fromWhere: 'searchScreen',
                  ),
                ),
              ),
            );
          },
          childCount: services.length,
        ),
      ),
    );
  }
}
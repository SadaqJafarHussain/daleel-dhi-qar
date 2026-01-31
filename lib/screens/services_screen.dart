import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tour_guid/providers/auth_provider.dart';
import 'package:tour_guid/providers/category_provider.dart';
import 'package:tour_guid/screens/widgets/favorite_button.dart';
import 'package:tour_guid/screens/service_details_screen.dart';
import 'package:tour_guid/utils/app_icons.dart';
import 'dart:ui';
import '../models/service_model.dart';
import '../providers/service_peovider.dart';
import '../providers/subcategory_provider.dart';
import '../utils/app_localization.dart';

/// Navigation source to determine filtering behavior
enum ServicesNavigationSource {
  category,
  subcategory,
  nearbyServices,
  allServices,
  featuredServices,
}

/// Error types for better UX
enum ServiceErrorType {
  network,
  authentication,
  server,
  notFound,
  timeout,
  unknown,
}

class ServicesScreen extends StatefulWidget {
  final int? categoryId;
  final String? categoryName;
  final int? subcategoryId;
  final String? subcategoryName;
  final ServicesNavigationSource source;
  final List<Service>? _nearbyServices;
  final List<Service>? _featuredServices;
  final String? customTitle;

  const ServicesScreen({
    Key? key,
    this.categoryId,
    this.categoryName,
    this.subcategoryId,
    this.subcategoryName,
    this.source = ServicesNavigationSource.allServices,
    List<Service>? nearbyServices,
    List<Service>? featuredServices,
    this.customTitle,
  }) : _nearbyServices = nearbyServices,
       _featuredServices = featuredServices,
        super(key: key);

  factory ServicesScreen.fromCategory({
    required int categoryId,
    required String categoryName,
  }) {
    return ServicesScreen(
      categoryId: categoryId,
      categoryName: categoryName,
      source: ServicesNavigationSource.category,
    );
  }

  factory ServicesScreen.fromSubcategory({
    required int subcategoryId,
    required String subcategoryName,
    int? parentCategoryId,
  }) {
    return ServicesScreen(
      subcategoryId: subcategoryId,
      subcategoryName: subcategoryName,
      categoryId: parentCategoryId,
      source: ServicesNavigationSource.subcategory,
    );
  }

  factory ServicesScreen.fromNearbyServices({
    required List<Service> nearbyServices,
  }) {
    return ServicesScreen(
      source: ServicesNavigationSource.nearbyServices,
      nearbyServices: nearbyServices,
    );
  }

  factory ServicesScreen.fromService({
    required Service service,
  }) {
    return ServicesScreen(
      categoryId: service.catId,
      categoryName: service.catName,
      subcategoryId: service.subcatId,
      subcategoryName: service.subcatName,
      source: ServicesNavigationSource.subcategory,
    );
  }

  factory ServicesScreen.allServices() {
    return const ServicesScreen(
      source: ServicesNavigationSource.allServices,
    );
  }

  factory ServicesScreen.fromFeaturedServices({
    required List<Service> services,
    required String title,
  }) {
    return ServicesScreen(
      source: ServicesNavigationSource.featuredServices,
      featuredServices: services,
      customTitle: title,
    );
  }

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  int? _selectedFilterId;
  bool _showingAll = false;
  List<Service> _displayServices = [];

  @override
  void initState() {
    super.initState();
    _initializeFilter();

    if (widget._nearbyServices != null && widget._nearbyServices!.isNotEmpty) {
      _displayServices = List.from(widget._nearbyServices!);
    } else if (widget._featuredServices != null && widget._featuredServices!.isNotEmpty) {
      _displayServices = List.from(widget._featuredServices!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _initializeFilter() {
    if (widget.source == ServicesNavigationSource.subcategory) {
      _selectedFilterId = widget.subcategoryId;
      _showingAll = false;
    } else if (widget.source == ServicesNavigationSource.category) {
      _selectedFilterId = widget.categoryId;
      _showingAll = false;
    } else if (widget.source == ServicesNavigationSource.featuredServices) {
      _selectedFilterId = null;
      _showingAll = true;
    } else {
      _selectedFilterId = null;
      _showingAll = true;
    }
  }

  ServiceErrorType _getErrorType(String error) {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('network') ||
        errorLower.contains('connection') ||
        errorLower.contains('socket')) {
      return ServiceErrorType.network;
    } else if (errorLower.contains('timeout')) {
      return ServiceErrorType.timeout;
    } else if (errorLower.contains('401') ||
        errorLower.contains('authentication') ||
        errorLower.contains('unauthorized')) {
      return ServiceErrorType.authentication;
    } else if (errorLower.contains('404') ||
        errorLower.contains('not found')) {
      return ServiceErrorType.notFound;
    } else if (errorLower.contains('500') ||
        errorLower.contains('502') ||
        errorLower.contains('503') ||
        errorLower.contains('server')) {
      return ServiceErrorType.server;
    } else {
      return ServiceErrorType.unknown;
    }
  }

  Map<String, dynamic> _getErrorInfo(ServiceErrorType errorType, AppLocalizations loc) {
    switch (errorType) {
      case ServiceErrorType.network:
        return {
          'icon': Icons.wifi_off_outlined,
          'title': loc.t('network_error'),
          'description': loc.t('network_error_desc'),
          'color': Colors.orange,
          'action': loc.t('retry'),
        };
      case ServiceErrorType.timeout:
        return {
          'icon': Icons.hourglass_empty_outlined,
          'title': loc.t('timeout_error'),
          'description': loc.t('timeout_error_desc'),
          'color': Colors.orange,
          'action': loc.t('retry'),
        };
      case ServiceErrorType.authentication:
        return {
          'icon': Icons.lock_outline,
          'title': loc.t('authentication_failed'),
          'description': loc.t('session_expired_desc'),
          'color': Colors.red,
          'action': loc.t('login'),
        };
      case ServiceErrorType.server:
        return {
          'icon': Icons.cloud_off_outlined,
          'title': loc.t('server_error'),
          'description': loc.t('server_error_desc'),
          'color': Colors.red,
          'action': loc.t('retry'),
        };
      case ServiceErrorType.notFound:
        return {
          'icon': Icons.search_off_outlined,
          'title': loc.t('not_found'),
          'description': loc.t('services_not_found_desc'),
          'color': Colors.grey,
          'action': loc.t('go_back'),
        };
      case ServiceErrorType.unknown:
      default:
        return {
          'icon': Icons.error_outline,
          'title': loc.t('something_went_wrong'),
          'description': loc.t('unexpected_error_desc'),
          'color': Colors.red,
          'action': loc.t('retry'),
        };
    }
  }

  void _handleErrorAction(ServiceErrorType errorType) {
    switch (errorType) {
      case ServiceErrorType.authentication:
        Navigator.pushReplacementNamed(context, '/login');
        break;
      case ServiceErrorType.notFound:
        Navigator.pop(context);
        break;
      default:
        _loadInitialData();
        break;
    }
  }

  Future<void> _loadInitialData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token!;

    if (widget._nearbyServices != null && widget._nearbyServices!.isNotEmpty) {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      await categoryProvider.fetchCategories(context);
      return;
    }

    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    final subcategoryProvider = Provider.of<SubcategoryProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    switch (widget.source) {
      case ServicesNavigationSource.category:
        try {
          await subcategoryProvider.fetchSubcategories(token);
        } catch (e) {
          if (mounted) debugPrint('Could not load subcategories: $e');
        }
        await serviceProvider.fetchServicesByCategory(widget.categoryId!);
        break;

      case ServicesNavigationSource.subcategory:
        if (widget.categoryId != null) {
          try {
            await subcategoryProvider.fetchSubcategories(token);
          } catch (e) {
            if (mounted) debugPrint('Could not load subcategories: $e');
          }
        }
        await serviceProvider.fetchServicesBySubcategory(widget.subcategoryId!);
        break;

      case ServicesNavigationSource.nearbyServices:
        break;

      case ServicesNavigationSource.featuredServices:
        // Featured services are already passed in, no need to load
        break;

      case ServicesNavigationSource.allServices:
        await categoryProvider.fetchCategories(context);
        await _loadAllServicesWithFallback(token, serviceProvider, categoryProvider);
        break;
    }
  }

  Future<void> _loadAllServicesWithFallback(
      String token,
      ServiceProvider serviceProvider,
      CategoryProvider categoryProvider,
      ) async {
    await serviceProvider.fetchAllServices();

    if (serviceProvider.services.isEmpty && serviceProvider.error != null) {
      if (mounted) {
        debugPrint('Fetching all services failed, aggregating from categories...');
      }

      await categoryProvider.fetchCategories(context);

      final allServices = <Service>[];
      for (var category in categoryProvider.categories) {
        await serviceProvider.fetchServicesByCategory(category.id);
        allServices.addAll(serviceProvider.services);
      }

      final uniqueServices = <int, Service>{};
      for (var service in allServices) {
        uniqueServices[service.id] = service;
      }

      if (mounted) {
        debugPrint('Aggregated ${uniqueServices.length} unique services from categories');
      }
    }
  }

  void _onFilterSelected(int? filterId) async {
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);

    setState(() {
      _selectedFilterId = filterId;
      _showingAll = filterId == null;
    });

    if (widget._nearbyServices != null && widget._nearbyServices!.isNotEmpty) {
      setState(() {
        _displayServices = filterId == null
            ? List.from(widget._nearbyServices!)
            : widget._nearbyServices!
            .where((s) => s.catId == filterId || s.subcatId == filterId)
            .toList();
      });
      return;
    }

    if (widget._featuredServices != null && widget._featuredServices!.isNotEmpty) {
      setState(() {
        _displayServices = filterId == null
            ? List.from(widget._featuredServices!)
            : widget._featuredServices!
            .where((s) => s.catId == filterId || s.subcatId == filterId)
            .toList();
      });
      return;
    }

    switch (widget.source) {
      case ServicesNavigationSource.category:
        if (filterId == null) {
          // "View All" should show all services in THIS category, not all services in the app
          await serviceProvider.fetchServicesByCategory(widget.categoryId!, forceRefresh: true);
        } else {
          await serviceProvider.fetchServicesBySubcategory(filterId, forceRefresh: true);
        }
        break;
      case ServicesNavigationSource.subcategory:
        if (filterId == null) {
          // "View All" should show all services in the parent category
          if (widget.categoryId != null) {
            await serviceProvider.fetchServicesByCategory(widget.categoryId!, forceRefresh: true);
          } else {
            await serviceProvider.fetchServicesBySubcategory(widget.subcategoryId!, forceRefresh: true);
          }
        } else {
          await serviceProvider.fetchServicesBySubcategory(filterId, forceRefresh: true);
        }
        break;
      case ServicesNavigationSource.allServices:
        if (filterId == null) {
          await serviceProvider.fetchAllServices(forceRefresh: true);
        } else {
          await serviceProvider.fetchServicesByCategory(filterId, forceRefresh: true);
        }
        break;
      case ServicesNavigationSource.nearbyServices:
        // Don't fetch nearby services again - just filter locally
        if (filterId == null) {
          _displayServices = List.from(widget._nearbyServices ?? []);
        } else {
          _displayServices = (widget._nearbyServices ?? [])
              .where((s) => s.catId == filterId || s.subcatId == filterId)
              .toList();
        }
        break;
      case ServicesNavigationSource.featuredServices:
        // Don't fetch featured services again - just filter locally
        if (filterId == null) {
          _displayServices = List.from(widget._featuredServices ?? []);
        } else {
          _displayServices = (widget._featuredServices ?? [])
              .where((s) => s.catId == filterId || s.subcatId == filterId)
              .toList();
        }
        break;
    }

    setState(() {
      _displayServices = serviceProvider.services;
    });
  }

  Future<void> _onRefresh() async {
    if (widget._nearbyServices != null && widget._nearbyServices!.isNotEmpty) {
      setState(() {
        _selectedFilterId = null;
        _showingAll = true;
        _displayServices = List.from(widget._nearbyServices!);
      });
      return;
    }

    if (widget._featuredServices != null && widget._featuredServices!.isNotEmpty) {
      setState(() {
        _selectedFilterId = null;
        _showingAll = true;
        _displayServices = List.from(widget._featuredServices!);
      });
      return;
    }

    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    await serviceProvider.refreshCurrentServices();
  }

  bool _isShowingCategories() {
    return widget.source == ServicesNavigationSource.nearbyServices ||
        widget.source == ServicesNavigationSource.allServices ||
        widget.source == ServicesNavigationSource.featuredServices;
  }

  List<Service> _getDisplayServices(ServiceProvider serviceProvider) {
    if (widget._nearbyServices != null && widget._nearbyServices!.isNotEmpty) {
      return _displayServices;
    }
    if (widget._featuredServices != null && widget._featuredServices!.isNotEmpty) {
      return _displayServices;
    }
    return serviceProvider.services;
  }

  bool _isLoading(ServiceProvider serviceProvider) {
    if (widget._nearbyServices != null && widget._nearbyServices!.isNotEmpty) {
      return false;
    }
    if (widget._featuredServices != null && widget._featuredServices!.isNotEmpty) {
      return false;
    }
    return serviceProvider.isLoading;
  }

  String? _getError(ServiceProvider serviceProvider) {
    if (widget._nearbyServices != null && widget._nearbyServices!.isNotEmpty) {
      return null;
    }
    if (widget._featuredServices != null && widget._featuredServices!.isNotEmpty) {
      return null;
    }
    return serviceProvider.error;
  }

  String _getTitle() {
    final loc = AppLocalizations.of(context);

    if (widget.source == ServicesNavigationSource.nearbyServices) {
      return loc.t('nearby_services');
    }

    if (widget.source == ServicesNavigationSource.featuredServices) {
      return widget.customTitle ?? loc.t('view_all');
    }

    if (_showingAll) {
      if (widget.categoryName != null) {
        return widget.categoryName!;
      }
      return loc.t('view_all');
    }

    if (widget.subcategoryName != null) {
      return widget.subcategoryName!;
    }

    if (widget.categoryName != null) {
      return widget.categoryName!;
    }

    return loc.t('additional_services');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final loc = AppLocalizations.of(context);
    final w = size.width;
    final h = size.height;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: AppBackButton.light(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _getTitle(),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.1),
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            _buildFilterChips(w, h, isDarkMode, loc),
            _buildServicesGrid(w, h, isDarkMode, loc),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesGrid(double w, double h, bool isDarkMode, AppLocalizations loc) {
    return Consumer<ServiceProvider>(
      builder: (context, serviceProvider, _) {
        final services = _getDisplayServices(serviceProvider);
        final isLoading = _isLoading(serviceProvider);
        final error = _getError(serviceProvider);

        if (isLoading && services.isEmpty) {
          return _buildLoadingState(w, h, isDarkMode, loc);
        }

        if (error != null) {
          final errorType = _getErrorType(error);
          final errorInfo = _getErrorInfo(errorType, loc);
          return _buildEnhancedErrorState(
            w, h, isDarkMode, loc,
            errorType, errorInfo, error,
          );
        }

        if (services.isEmpty) {
          return _buildEmptyState(w, h, isDarkMode, loc);
        }

        return _buildSuccessState(services, w, h, isDarkMode, loc, isLoading);
      },
    );
  }

  Widget _buildLoadingState(double w, double h, bool isDarkMode, AppLocalizations loc) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
              strokeWidth: 3,
            ),
            SizedBox(height: h * 0.025),
            Text(
              loc.t('loading_services'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: h * 0.01),
            Text(
              loc.t('please_wait'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDarkMode ? Colors.white54 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedErrorState(
      double w,
      double h,
      bool isDarkMode,
      AppLocalizations loc,
      ServiceErrorType errorType,
      Map<String, dynamic> errorInfo,
      String rawError,
      ) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(w * 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(w * 0.08),
                decoration: BoxDecoration(
                  color: (errorInfo['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  errorInfo['icon'] as IconData,
                  size: 80,
                  color: errorInfo['color'] as Color,
                ),
              ),
              SizedBox(height: h * 0.04),

              Text(
                errorInfo['title'] as String,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: h * 0.015),

              Text(
                errorInfo['description'] as String,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              if (kDebugMode) ...[
                SizedBox(height: h * 0.02),
                Container(
                  padding: EdgeInsets.all(w * 0.03),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Debug: $rawError',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              SizedBox(height: h * 0.04),

              SizedBox(
                width: w * 0.6,
                child: ElevatedButton.icon(
                  onPressed: () => _handleErrorAction(errorType),
                  icon: Icon(
                    _getActionIcon(errorType),
                    size: 20,
                  ),
                  label: Text(
                    errorInfo['action'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: errorInfo['color'] as Color,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: h * 0.02,
                      horizontal: w * 0.08,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                ),
              ),

              if (errorType == ServiceErrorType.authentication) ...[
                SizedBox(height: h * 0.015),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    loc.t('go_back'),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getActionIcon(ServiceErrorType errorType) {
    switch (errorType) {
      case ServiceErrorType.authentication:
        return Icons.login;
      case ServiceErrorType.notFound:
        return Icons.arrow_back;
      default:
        return Icons.refresh;
    }
  }

  Widget _buildEmptyState(double w, double h, bool isDarkMode, AppLocalizations loc) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(w * 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 120,
                color: Colors.grey.withOpacity(0.4),
              ),
              SizedBox(height: h * 0.03),
              Text(
                loc.t('no_services_found'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: h * 0.015),
              Text(
                loc.t('try_another_filter'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: h * 0.03),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedFilterId = null;
                    _showingAll = true;
                  });
                  _onFilterSelected(null);
                },
                icon: const Icon(Icons.refresh, size: 20),
                label: Text(loc.t('show_all')),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.08,
                    vertical: h * 0.015,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState(
      List<Service> services,
      double w,
      double h,
      bool isDarkMode,
      AppLocalizations loc,
      bool isLoading,
      ) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.02, w * 0.04, h * 0.015),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${services.length} ${loc.t('services')}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.03),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: w > 600 ? 3 : 2,
            mainAxisSpacing: w * 0.03,
            crossAxisSpacing: w * 0.03,
            childCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return _buildServiceCard(service, w, h, isDarkMode);
            },
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: h * 0.03),
        ),
      ],
    );
  }

  // ✅ FIXED: Filter subcategories by category ID
  Widget _buildFilterChips(double w, double h, bool isDarkMode, AppLocalizations loc) {
    if (_isShowingCategories()) {
      return Consumer<CategoryProvider>(
        builder: (context, categoryProvider, _) {
          final categories = categoryProvider.categories;
          if (categories.isEmpty) {
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }

          return SliverToBoxAdapter(
            child: Container(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.04,
                vertical: h * 0.015,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: loc.t("view_all"),
                      isSelected: _showingAll,
                      onTap: () => _onFilterSelected(null),
                    ),
                    SizedBox(width: w * 0.02),
                    ...categories.map((category) {
                      return Padding(
                        padding: EdgeInsets.only(right: w * 0.02),
                        child: _buildFilterChip(
                          label: category.name,
                          isSelected: _selectedFilterId == category.id,
                          onTap: () => _onFilterSelected(category.id),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else {
      return Consumer<SubcategoryProvider>(
        builder: (context, subcategoryProvider, _) {
          // ✅ Filter subcategories by category ID if coming from a category
          final allSubcategories = subcategoryProvider.subcategories;
          final subcategories = widget.categoryId != null
              ? allSubcategories.where((sub) => sub.catId == widget.categoryId).toList()
              : allSubcategories;

          if (subcategories.isEmpty) {
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }

          return SliverToBoxAdapter(
            child: Container(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.04,
                vertical: h * 0.015,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: loc.t("view_all"),
                      isSelected: _showingAll,
                      onTap: () => _onFilterSelected(null),
                    ),
                    SizedBox(width: w * 0.02),
                    ...subcategories.map((subcategory) {
                      return Padding(
                        padding: EdgeInsets.only(right: w * 0.02),
                        child: _buildFilterChip(
                          label: subcategory.name,
                          isSelected: _selectedFilterId == subcategory.id,
                          onTap: () => _onFilterSelected(subcategory.id),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : (isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDarkMode ? Colors.white70 : Colors.black87),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(Service service, double w, double h, bool isDarkMode) {
    final randomHeights = [200.0, 240.0, 280.0, 220.0, 260.0, 200.0];
    final cardHeight = randomHeights[service.id % randomHeights.length];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailsScreen(service: service),
          ),
        );
      },
      child: Hero(
        tag: 'service_${service.id}',
        child: Container(
          height: cardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                service.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: service.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.3),
                          Theme.of(context).primaryColor.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 50,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                )
                    : Container(
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
                  child: Icon(
                    Icons.image_outlined,
                    size: 60,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.75),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            service.subcatName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Title with verified badge
                        Row(
                          children: [
                            if (service.isOwnerVerified) ...[
                              const Icon(
                                Icons.verified,
                                size: 18,
                                color: Color(0xFF1DA1F2),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                service.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black38,
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Rating row
                        if (service.averageRating != null && service.averageRating! > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFBBF24),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  service.averageRating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (service.totalReviews != null && service.totalReviews! > 0)
                                  Text(
                                    ' (${service.totalReviews})',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        // Working hours row (below rating)
                        if (service.workingHoursDisplay.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  service.workingHoursDisplay,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                service.address,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                service.userName,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Availability badge (top left)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: service.isCurrentlyOpen
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      service.isCurrentlyOpen
                          ? AppLocalizations.of(context).t('open_now')
                          : AppLocalizations.of(context).t('closed'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: FavoriteButton(serviceId: service.id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
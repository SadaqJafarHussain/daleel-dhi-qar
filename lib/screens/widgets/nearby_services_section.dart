import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tour_guid/screens/login_screen.dart';
import 'package:tour_guid/screens/widgets/section_header.dart';
import 'package:tour_guid/screens/widgets/service_card.dart';
import 'package:tour_guid/screens/widgets/shimmer_loading.dart';
import 'package:tour_guid/utils/app_icons.dart';
import '../../models/service_model.dart';
import '../../providers/service_peovider.dart';
import '../../utils/app_localization.dart';
import '../../utils/page_transitions.dart';
import '../services_screen.dart';

class NearbyServicesSection extends StatefulWidget {
  final double width;
  final double height;

  const NearbyServicesSection({
    Key? key,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  State<NearbyServicesSection> createState() => _NearbyServicesSectionState();
}

class _NearbyServicesSectionState extends State<NearbyServicesSection> {
  double _currentDistance = 1.0;
  bool _isSearching = false;
  bool _searchCompleted = false;
  bool _isInitialAutoExpand = true;
  int _currentServicesCount = 0;

  static const List<double> _autoExpandDistances = [1, 5, 10, 25, 50, 100];
  static const double _maxAutoExpandDistance = 100.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialSearch();
    });
  }

  Future<void> _initialSearch() async {
    _isInitialAutoExpand = true;

    for (final distance in _autoExpandDistances) {
      if (!mounted) return;

      final found = await _searchAtDistanceInternal(distance, isAutoExpand: true);

      if (found > 0) {
        if (mounted) {
          setState(() {
            _currentDistance = distance;
            _currentServicesCount = found;
            _isSearching = false;
            _searchCompleted = true;
            _isInitialAutoExpand = false;
          });
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        _currentDistance = _maxAutoExpandDistance;
        _currentServicesCount = 0;
        _isSearching = false;
        _searchCompleted = true;
        _isInitialAutoExpand = false;
      });
    }
  }

  String _formatDistance(double km) {
    if (km >= 1000) {
      return '${(km / 1000).toStringAsFixed(0)}،000';
    } else if (km >= 100) {
      return km.toStringAsFixed(0);
    } else if (km >= 10) {
      return km.toStringAsFixed(0);
    } else {
      return km.toStringAsFixed(1);
    }
  }

  Future<int> _searchAtDistanceInternal(double distance, {bool isAutoExpand = false}) async {
    // Note: Nearby services should work for both authenticated users and visitors
    // No token check needed here - ServiceProvider handles this

    if (mounted) {
      setState(() {
        _isSearching = true;
        _searchCompleted = false;
        _currentDistance = distance;
      });
    }

    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);

    if (kDebugMode) {
      print('📍 ${isAutoExpand ? "[AUTO-EXPAND]" : ""} Searching at $distance km');
    }

    await serviceProvider.fetchNearbyServices(
      maxDistanceKm: distance,
      useDefaultLocationIfFailed: true,
      forceRefresh: true,
    );

    final count = serviceProvider.nearbyServices.length;

    if (kDebugMode) {
      print('✅ Search completed at $distance km - Found $count services');
    }

    return count;
  }

  Future<void> _searchAtDistance(double distance) async {
    _isInitialAutoExpand = false;
    HapticFeedback.lightImpact();

    final count = await _searchAtDistanceInternal(distance, isAutoExpand: false);

    if (mounted) {
      setState(() {
        _currentDistance = distance;
        _currentServicesCount = count;
        _isSearching = false;
        _searchCompleted = true;
      });
    }
  }

  void _increaseDistance() {
    if (_isSearching) return;

    double newDistance = _currentDistance * 2;
    if (newDistance > 20000) newDistance = 20000;

    _searchAtDistance(newDistance);
  }

  void _decreaseDistance() {
    if (_isSearching) return;

    double newDistance = _currentDistance / 2;
    if (newDistance < 1) newDistance = 1;

    _searchAtDistance(newDistance);
  }

  Future<void> _handleLocationPermissionRequest() async {
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    final result = await serviceProvider.requestLocationPermission();

    if (result.success) {
      _searchAtDistance(1.0);
    } else if (result.isPermissionDeniedForever) {
      _showOpenSettingsDialog();
    }
  }

  void _showOpenSettingsDialog() {
    final loc = AppLocalizations.of(context);
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
              icon: Icons.location_off_rounded,
              color: Colors.orange,
              size: AppIconSize.xl,
              containerSize: AppIconContainerSize.xl,
            ),
            const SizedBox(height: 16),
            Text(
              loc.t('location_permission_required'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                loc.t('location_permission_settings_message'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
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
                      ),
                      child: Text(loc.t('cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final serviceProvider =
                            Provider.of<ServiceProvider>(context, listen: false);
                        await serviceProvider.openLocationSettings();
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
                      child: Text(loc.t('open_settings')),
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

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final h = widget.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<ServiceProvider>(
      builder: (context, serviceProvider, _) {
        if (_isSearching) {
          return _buildLoadingState(w, h, isDark);
        }

        if (_searchCompleted && serviceProvider.nearbyError != null) {
          return _buildErrorState(w, h, isDark, serviceProvider.nearbyError!, serviceProvider);
        }

        if (_searchCompleted && serviceProvider.nearbyServices.isEmpty && !_isSearching) {
          return _buildEmptyState(w, h, isDark);
        }

        if (serviceProvider.nearbyServices.isNotEmpty) {
          return _buildServicesSection(w, h, isDark, serviceProvider.nearbyServices);
        }

        return _buildLoadingState(w, h, isDark);
      },
    );
  }

  Widget _buildLoadingState(double w, double h, bool isDark) {
    final loc = AppLocalizations.of(context);

    final searchMessage = _isInitialAutoExpand
        ? '${loc.t('searching_nearby_services')} (${_formatDistance(_currentDistance)} ${loc.t('km')})'
        : '${loc.t('searching_in_range')} ${_formatDistance(_currentDistance)} ${loc.t('km')}...';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.045, vertical: h * 0.015),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(loc, isDark),
          const SizedBox(height: 12),
          // Search status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Theme.of(context).primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  searchMessage,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Skeleton loading
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

  Widget _buildSectionTitle(AppLocalizations loc, bool isDark) {
    return Row(
      children: [
        AppIcon.gradient(
          icon: Icons.near_me_rounded,
          colors: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
          size: AppIconSize.sm,
          containerSize: 34,
          borderRadius: 10,
        ),
        const SizedBox(width: 12),
        Text(
          loc.t('nearby_services'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(double w, double h, bool isDark, String error, ServiceProvider serviceProvider) {
    final loc = AppLocalizations.of(context);

    IconData icon;
    Color iconColor;
    String title;
    String message;
    String actionText;
    VoidCallback? onAction;

    if (error == 'location_permission_denied') {
      icon = Icons.location_off_rounded;
      iconColor = Colors.orange;
      title = loc.t('location_permission_required');
      message = loc.t('grant_location_access_message');
      actionText = loc.t('grant_permission');
      onAction = _handleLocationPermissionRequest;
    } else if (error == 'location_permission_denied_forever') {
      icon = Icons.location_disabled_rounded;
      iconColor = Colors.red;
      title = loc.t('location_access_disabled');
      message = loc.t('enable_location_settings_message');
      actionText = loc.t('open_settings');
      onAction = _showOpenSettingsDialog;
    } else if (error == 'location_service_disabled') {
      icon = Icons.gps_off_rounded;
      iconColor = Colors.orange;
      title = loc.t('location_service_disabled');
      message = loc.t('enable_location_service_message');
      actionText = loc.t('enable_service');
      onAction = () async {
        await serviceProvider.openLocationSettings();
      };
    } else if (error.contains('Authentication failed') || error.contains('401')) {
      icon = Icons.lock_outline_rounded;
      iconColor = Colors.red;
      title = loc.t('authentication_failed');
      message = loc.t('please_login_again');
      actionText = loc.t('login');
      onAction = () {
        Navigator.pushReplacement(
          context,
          PageTransitions.fade(page: LoginScreen()),
        );
      };
    } else {
      icon = Icons.error_outline_rounded;
      iconColor = Colors.red;
      title = loc.t('could_not_load_services');
      message = error;
      actionText = loc.t('retry');
      onAction = () => _searchAtDistance(1.0);
    }

    return Padding(
      padding: EdgeInsets.all(w * 0.045),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(loc, isDark),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                AppIcon.circle(
                  icon: icon,
                  color: iconColor,
                  size: AppIconSize.xl,
                  containerSize: AppIconContainerSize.xl,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (onAction != null) ...[
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      actionText,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double w, double h, bool isDark) {
    final loc = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.all(w * 0.045),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(loc, isDark),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                AppIcon.circle(
                  icon: Icons.search_off_rounded,
                  color: Colors.grey.shade400,
                  size: AppIconSize.xl,
                  containerSize: AppIconContainerSize.xl,
                ),
                const SizedBox(height: 16),
                Text(
                  loc.t('no_nearby_services'),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${loc.t('no_services_in_range')} ${_formatDistance(_currentDistance)} ${loc.t('km')}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _buildDistanceControls(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection(double w, double h, bool isDark, List<Service> services) {
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.045),
          child: SectionHeader.nearby(
            title: loc.t("nearby_services"),
            subtitle: loc.t("nearby_services_subtitle"),
            itemCount: services.length,
            onViewAll: () {
              Navigator.push(
                context,
                PageTransitions.slideRight(
                  page: ServicesScreen.fromNearbyServices(nearbyServices: services),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Distance Info & Controls
        Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.045),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                AppIcon.rounded(
                icon: Icons.location_on_rounded,
                color: const Color(0xFF3B82F6),
                size: AppIconSize.xs,
                containerSize: 28,
                borderRadius: 8,
              ),
                const SizedBox(width: 10),
                Text(
                  '${_formatDistance(_currentDistance)} ${loc.t('km')}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  '$_currentServicesCount ${loc.t('service')}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                _buildDistanceControls(isDark),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Services List with staggered animation
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: w * 0.045),
            itemCount: services.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return AnimatedListItem(
                index: index,
                delay: const Duration(milliseconds: 60),
                child: ServiceCard(
                  service: services[index],
                  index: index,
                  fromWhere: 'nearby',
                  height: 220,
                  cardStyle: ServiceCardStyle.nearby,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceControls(bool isDark) {
    final canDecrease = _currentDistance > 1 && !_isSearching;
    final canIncrease = _currentDistance < 20000 && !_isSearching;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A3E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canDecrease ? _decreaseDistance : null,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: AppIcon.small(
                  Icons.remove_rounded,
                  color: canDecrease
                      ? (isDark ? Colors.white : Colors.black87)
                      : Colors.grey.shade400,
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 20,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          // Increase button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canIncrease ? _increaseDistance : null,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: AppIcon.small(
                  Icons.add_rounded,
                  color: canIncrease
                      ? (isDark ? Colors.white : Colors.black87)
                      : Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

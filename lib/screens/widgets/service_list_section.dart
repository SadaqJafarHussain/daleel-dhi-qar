import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guid/providers/auth_provider.dart';
import 'package:tour_guid/screens/widgets/service_image_widget.dart';
import '../../models/subcategory_model.dart';
import '../../utils/app_localization.dart';
import '../../providers/subcategory_provider.dart';
import '../../utils/app_texts_style.dart';
import '../services_screen.dart';
import 'profile_section_header.dart';

class ServicesListSection extends StatefulWidget {
  final double width;
  final double height;

  const ServicesListSection({
    Key? key,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  State<ServicesListSection> createState() => _ServicesListSectionState();
}

class _ServicesListSectionState extends State<ServicesListSection> {
  @override
  void initState() {
    super.initState();
    _loadSubcategories();
  }

  /// Load subcategories from API
  Future<void> _loadSubcategories() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final subcategoryProvider =
      Provider.of<SubcategoryProvider>(context, listen: false);

      if (authProvider.token != null && authProvider.token!.isNotEmpty) {
        subcategoryProvider.fetchSubcategories(authProvider.token!);
      }
    });
  }

  /// Retry loading subcategories
  Future<void> _retryLoading() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final subcategoryProvider =
    Provider.of<SubcategoryProvider>(context, listen: false);

    if (authProvider.token != null && authProvider.token!.isNotEmpty) {
      await subcategoryProvider.fetchSubcategories(authProvider.token!);
    }
  }

  /// Determine error type from error message
  ErrorType _getErrorType(String error) {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('network') ||
        errorLower.contains('connection') ||
        errorLower.contains('timeout')) {
      return ErrorType.network;
    } else if (errorLower.contains('401') ||
        errorLower.contains('authentication') ||
        errorLower.contains('unauthorized')) {
      return ErrorType.authentication;
    } else if (errorLower.contains('404')) {
      return ErrorType.notFound;
    } else if (errorLower.contains('500') ||
        errorLower.contains('502') ||
        errorLower.contains('503')) {
      return ErrorType.server;
    } else {
      return ErrorType.unknown;
    }
  }

  Color _getColorForIndex(int index) {
    final colors = [
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFF10B981), // Green
      const Color(0xFFEC4899), // Pink
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF14B8A6), // Teal
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final w = widget.width;
    final h = widget.height;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Consumer<SubcategoryProvider>(
      builder: (context, subcategoryProvider, _) {
        // ========================================
        // LOADING STATE
        // ========================================
        if (subcategoryProvider.isLoading && !subcategoryProvider.hasData) {
          return _buildLoadingState(w, h, isDarkMode, loc);
        }

        // ========================================
        // ERROR STATE
        // ========================================
        if (subcategoryProvider.error != null && !subcategoryProvider.hasData) {
          final errorType = _getErrorType(subcategoryProvider.error!);
          return _buildErrorState(
              w, h, isDarkMode, loc, errorType, subcategoryProvider.error!);
        }

        // ========================================
        // EMPTY STATE
        // ========================================
        final subcategories = subcategoryProvider.subcategories.take(6).toList();
        if (subcategories.isEmpty) {
          return _buildEmptyState(w, h, isDarkMode, loc);
        }

        // ========================================
        // SUCCESS STATE - SHOW SUBCATEGORIES
        // ========================================
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.045),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: h * 0.025),

              // Section Header
              ProfileSectionHeader(
                title: loc.t('additional_services'),
                icon: Icons.workspace_premium_outlined,
              ),

              SizedBox(height: h * 0.015),

              // Subcategories List
              ...subcategories.asMap().entries.map((entry) {
                final index = entry.key;
                final subcategory = entry.value;
                return _buildServiceCard(
                  context,
                  subcategory,
                  index,
                  w,
                  h,
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // ========================================
  // UI STATE BUILDERS
  // ========================================

  /// Loading state
  Widget _buildLoadingState(
      double w, double h, bool isDarkMode, AppLocalizations loc) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.045, vertical: h * 0.03),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileSectionHeader(
            title: loc.t('additional_services'),
            icon: Icons.workspace_premium_outlined,
          ),
          SizedBox(height: h * 0.02),

          // Shimmer loading cards
          ...List.generate(3, (index) {
            return Container(
              margin: EdgeInsets.only(bottom: h * 0.015),
              padding: EdgeInsets.all(w * 0.04),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.grey.shade800.withOpacity(0.3)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Icon placeholder
                  Container(
                    width: w * 0.15,
                    height: w * 0.15,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  SizedBox(width: w * 0.03),

                  // Text placeholders
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16,
                          width: w * 0.4,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(height: h * 0.01),
                        Container(
                          height: 12,
                          width: w * 0.6,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Error state with retry
  Widget _buildErrorState(
      double w,
      double h,
      bool isDarkMode,
      AppLocalizations loc,
      ErrorType errorType,
      String errorMessage,
      ) {
    IconData errorIcon;
    String errorTitle;
    String errorDescription;
    Color errorColor;

    switch (errorType) {
      case ErrorType.network:
        errorIcon = Icons.wifi_off_outlined;
        errorTitle = loc.t('network_error');
        errorDescription = loc.t('network_error_desc');
        errorColor = Colors.orange;
        break;
      case ErrorType.authentication:
        errorIcon = Icons.lock_outline;
        errorTitle = loc.t('authentication_failed');
        errorDescription = loc.t('please_login_again');
        errorColor = Colors.red;
        break;
      case ErrorType.server:
        errorIcon = Icons.cloud_off_outlined;
        errorTitle = loc.t('server_error');
        errorDescription = loc.t('server_error_desc');
        errorColor = Colors.red;
        break;
      case ErrorType.notFound:
        errorIcon = Icons.search_off_outlined;
        errorTitle = loc.t('not_found');
        errorDescription = loc.t('not_found_desc');
        errorColor = Colors.grey;
        break;
      case ErrorType.unknown:
      default:
        errorIcon = Icons.error_outline;
        errorTitle = loc.t('something_went_wrong');
        errorDescription = errorMessage;
        errorColor = Colors.red;
        break;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.045, vertical: h * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileSectionHeader(
            title: loc.t('additional_services'),
            icon: Icons.workspace_premium_outlined,
          ),
          SizedBox(height: h * 0.02),

          Container(
            width: double.infinity,
            padding: EdgeInsets.all(w * 0.05),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF1E1E1E)
                  : errorColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: errorColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Error Icon
                Container(
                  padding: EdgeInsets.all(w * 0.04),
                  decoration: BoxDecoration(
                    color: errorColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    errorIcon,
                    size: 40,
                    color: errorColor,
                  ),
                ),
                SizedBox(height: h * 0.02),

                // Error Title
                Text(
                  errorTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: h * 0.01),

                // Error Description
                Text(
                  errorDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: h * 0.025),

                // Retry Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _retryLoading,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: Text(
                      loc.t('retry'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: h * 0.015),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state
  Widget _buildEmptyState(
      double w, double h, bool isDarkMode, AppLocalizations loc) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.045, vertical: h * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileSectionHeader(
            title: loc.t('additional_services'),
            icon: Icons.workspace_premium_outlined,
          ),
          SizedBox(height: h * 0.02),

          Container(
            width: double.infinity,
            padding: EdgeInsets.all(w * 0.06),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 60,
                  color: Colors.grey.withOpacity(0.5),
                ),
                SizedBox(height: h * 0.015),
                Text(
                  loc.t('no_services_available'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: h * 0.008),
                Text(
                  loc.t('check_back_later'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Service card widget
  Widget _buildServiceCard(
      BuildContext context,
      Subcategory subcategory,
      int index,
      double w,
      double h,
      ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final color = _getColorForIndex(index);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServicesScreen.fromSubcategory(
              subcategoryId: subcategory.id,
              subcategoryName: subcategory.name,
              parentCategoryId: subcategory.catId,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: h * 0.015),
        padding: EdgeInsets.all(w * 0.04),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Service Image
            Container(
              width: w * 0.15,
              height: w * 0.15,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ServiceImageWidget(
                  imageUrl: subcategory.image,
                  fit: BoxFit.cover,
                  showLoadingIndicator: false,
                ),
              ),
            ),
            SizedBox(width: w * 0.03),

            // Service Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subcategory.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: AppTextSizes.cardTitle,
                    ),
                  ),

                ],
              ),
            ),
            SizedBox(width: w * 0.03),

            // Arrow Icon
            Icon(
              Icons.arrow_forward_ios,
              size: w * 0.05,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// ERROR TYPE ENUM
// ========================================
enum ErrorType {
  network,
  authentication,
  server,
  notFound,
  unknown,
}
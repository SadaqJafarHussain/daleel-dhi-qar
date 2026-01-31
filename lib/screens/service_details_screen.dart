import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../models/service_model.dart';
import '../providers/auth_provider.dart';
import '../providers/review_provider.dart';
import '../providers/service_peovider.dart';
import '../utils/app_localization.dart';
import '../utils/map_launcher.dart';
import '../utils/retry_helper.dart';
import 'widgets/add_service_sheet.dart' show openEditServiceSheet;
import 'widgets/favorite_button.dart';
import 'widgets/rating/reviews_section.dart';
import 'widgets/login_prompt_dialog.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final Service? service;
  final int? serviceId;

  const ServiceDetailsScreen({
    Key? key,
    this.service,
    this.serviceId,
  }) : assert(service != null || serviceId != null, 'Either service or serviceId must be provided'),
       super(key: key);

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  late PageController _pageController;
  Service? _service;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentImageIndex = 0;
  Timer? _autoPlayTimer;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    if (widget.service != null) {
      _service = widget.service!;
      _isLoading = false;
      _startAutoPlay();
    } else if (widget.serviceId != null) {
      _loadService();
    }
  }

  Future<void> _loadService({bool isRetry = false}) async {
    if (!isRetry && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);

      // Use retry helper for network resilience
      final service = await RetryHelper.retry(
        () => serviceProvider.getServiceById(widget.serviceId!),
        maxRetries: 3,
        initialDelay: const Duration(seconds: 1),
      );

      if (mounted) {
        setState(() {
          _service = service;
          _isLoading = false;
          if (service != null) {
            _startAutoPlay();
          } else {
            _errorMessage = 'service_not_found';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'failed_to_load_service';
        });
      }
    }
  }

  void _startAutoPlay() {
    if (_service == null) return;
    final images = _service!.files.where((f) => f.url.isNotEmpty).toList();
    if (images.length > 1) {
      _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (_pageController.hasClients) {
          int nextPage = (_currentImageIndex + 1) % images.length;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    // Show loading state
    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show error state
    if (_errorMessage != null || _service == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? loc.t('service_not_found'),
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _loadService(isRetry: true),
                    icon: const Icon(Icons.refresh),
                    label: Text(loc.t('retry')),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(loc.t('go_back')),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            // App Bar with Image
            _buildSliverAppBar(context, isDark, loc),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // User/Owner Info Card
                  _buildUserInfoCard(context, isDark, loc),
                  const SizedBox(height: 16),

                  // Title and Status
                  _buildTitleSection(context, isDark, loc),
                  const SizedBox(height: 16),

                  // Owner Actions (Edit, Toggle, Delete)
                  _buildOwnerActions(context, isDark, loc),

                  // Description
                  if (_service!.description.isNotEmpty) ...[
                    _buildDescriptionSection(context, isDark, loc),
                    const SizedBox(height: 16),
                  ],

                  // Working Hours
                  if (_service!.openTime != null || _service!.isOpen24Hours == true) ...[
                    _buildWorkingHoursSection(context, isDark, loc),
                    const SizedBox(height: 16),
                  ],

                  // Location (with address)
                  _buildLocationSection(context, isDark, loc),
                  const SizedBox(height: 16),

                  // Social Media (including WhatsApp)
                  if (_hasSocialMedia()) ...[
                    _buildSocialMediaSection(context, isDark, loc),
                    const SizedBox(height: 16),
                  ],

                  // Reviews
                  _buildReviewsSection(context, isDark, loc),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
      // Bottom Action Bar
      bottomNavigationBar: _buildBottomBar(context, isDark, loc),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDark, AppLocalizations loc) {
    final images = _service!.files.where((f) => f.url.isNotEmpty).toList();
    final hasImages = images.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      foregroundColor: hasImages ? Colors.white : (isDark ? Colors.white : Colors.black),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: FavoriteButton(
              serviceId: _service!.id,
              style: FavoriteButtonStyle.minimal,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: hasImages
            ? _buildImageGallery(images, isDark)
            : _buildNoImagePlaceholder(isDark),
      ),
    );
  }

  Widget _buildImageGallery(List<ServiceFile> images, bool isDark) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentImageIndex = index),
          itemCount: images.length,
          itemBuilder: (context, index) {
            return CachedNetworkImage(
              imageUrl: images[index].url,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                child: const Icon(Icons.broken_image, size: 48),
              ),
            );
          },
        ),
        // Gradient overlay
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),
        ),
        // Image indicators
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (index) {
                return Container(
                  width: index == _currentImageIndex ? 20 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: index == _currentImageIndex
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                );
              }),
            ),
          ),
        // Image counter
        if (images.length > 1)
          Positioned(
            top: MediaQuery.of(context).padding.top + 50,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${images.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNoImagePlaceholder(bool isDark) {
    return Container(
      color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.store_rounded,
          size: 80,
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
        ),
      ),
    );
  }

  /// Beautiful User/Owner Info Card
  Widget _buildUserInfoCard(BuildContext context, bool isDark, AppLocalizations loc) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Check if current user is the owner - if so, use their name
        final isOwner = (authProvider.supabaseUserId != null &&
                _service!.supabaseUserId != null &&
                authProvider.supabaseUserId == _service!.supabaseUserId);

        String userName;
        if (_service!.userName.isNotEmpty) {
          userName = _service!.userName;
        } else if (isOwner && authProvider.user?.name != null && authProvider.user!.name.isNotEmpty) {
          userName = authProvider.user!.name;
        } else {
          userName = loc.t('unknown_user');
        }

        final initials = userName.isNotEmpty && userName != loc.t('unknown_user')
            ? userName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
            : '?';

        return _buildUserInfoCardContent(context, isDark, loc, userName, initials, isOwner);
      },
    );
  }

  Widget _buildUserInfoCardContent(BuildContext context, bool isDark, AppLocalizations loc, String userName, String initials, bool isOwner) {
    // Get avatar URL - check service owner's avatar or current user's avatar if owner
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String? avatarUrl = _service!.userAvatarUrl;
    if (avatarUrl == null && isOwner && authProvider.user?.avatarUrl != null) {
      avatarUrl = authProvider.user!.avatarUrl;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1E1E), const Color(0xFF2A2A2A)]
              : [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with image or initials fallback
          avatarUrl != null && avatarUrl.isNotEmpty
              ? Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(avatarUrl),
                    onBackgroundImageError: (_, __) {},
                  ),
                )
              : Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
          const SizedBox(width: 16),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.t('posted_by'),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Verified Badge (only show if owner is verified)
          if (_service!.isOwnerVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified,
                    size: 16,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    loc.t('verified'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context, bool isDark, AppLocalizations loc) {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, _) {
        final stats = reviewProvider.getStats(_service!.id);
        final rating = stats?.averageRating ?? _service!.averageRating ?? 0;
        final reviewCount = stats?.totalReviews ?? _service!.totalReviews ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category & Status Row
            Row(
              children: [
                // Category badge
                if (_service!.catName.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _service!.catName,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                // Open/Closed status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _service!.isCurrentlyOpen
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _service!.isCurrentlyOpen ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _service!.isCurrentlyOpen ? loc.t('open_now') : loc.t('closed'),
                        style: TextStyle(
                          color: _service!.isCurrentlyOpen ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Title
            Text(
              _service!.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            if (_service!.subcatName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _service!.subcatName,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Rating and Distance
            Row(
              children: [
                if (rating > 0) ...[
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    ' ($reviewCount ${loc.t('reviews')})',
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (_service!.distance != null) ...[
                  Icon(
                    Icons.location_on,
                    size: 18,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_service!.distance!.toStringAsFixed(1)} ${loc.t('km')}',
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                // Favorites count
                if (_service!.favoritesCount > 0) ...[
                  Icon(
                    Icons.favorite,
                    size: 18,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_service!.favoritesCount}',
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildOwnerActions(BuildContext context, bool isDark, AppLocalizations loc) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Check ownership using Supabase UUID or legacy int ID
        final isOwner = (authProvider.supabaseUserId != null &&
                _service!.supabaseUserId != null &&
                authProvider.supabaseUserId == _service!.supabaseUserId) ||
            (authProvider.user?.id != null &&
                authProvider.user!.id == _service!.userId);

        debugPrint('Owner check: authUserId=${authProvider.supabaseUserId}, serviceUserId=${_service!.supabaseUserId}, isOwner=$isOwner');

        if (!isOwner) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    loc.t('manage_service'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Edit Button
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.edit,
                      label: loc.t('edit'),
                      color: Colors.blue,
                      onTap: () => _openEditSheet(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Toggle Status Button
                  Expanded(
                    child: _buildActionButton(
                      icon: _service!.isCurrentlyOpen ? Icons.lock : Icons.lock_open,
                      label: _service!.isCurrentlyOpen ? loc.t('mark_closed') : loc.t('mark_open'),
                      color: _service!.isCurrentlyOpen ? Colors.orange : Colors.green,
                      onTap: () => _toggleServiceStatus(context, loc),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete Button
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.delete,
                      label: loc.t('delete'),
                      color: Colors.red,
                      onTap: () => _deleteService(context, loc),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection(BuildContext context, bool isDark, AppLocalizations loc) {
    final description = _service!.description;
    final isLong = description.length > 150;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.t('description'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isDescriptionExpanded || !isLong
                ? description
                : '${description.substring(0, 150)}...',
            style: TextStyle(
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              height: 1.6,
            ),
          ),
          if (isLong)
            TextButton(
              onPressed: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
              child: Text(
                _isDescriptionExpanded ? loc.t('show_less') : loc.t('show_more'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWorkingHoursSection(BuildContext context, bool isDark, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.t('working_hours'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                _service!.isOpen24Hours == true
                    ? Icons.all_inclusive
                    : Icons.access_time,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _service!.isOpen24Hours == true
                    ? loc.t('open_24_hours')
                    : '${_service!.openTime ?? ''} - ${_service!.closeTime ?? ''}',
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Location section with address combined
  Widget _buildLocationSection(BuildContext context, bool isDark, AppLocalizations loc) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.t('location'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                // Address row
                InkWell(
                  onTap: () {
                    if (!_checkAuthForContact('view_location')) return;
                    MapLauncher.openMaps(
                      context: context,
                      latitude: _service!.lat,
                      longitude: _service!.lng,
                      placeName: _service!.title,
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.location_on, color: Colors.red, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _service!.address,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                loc.t('tap_for_directions'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Map preview
          GestureDetector(
            onTap: () {
              if (!_checkAuthForContact('view_location')) return;
              MapLauncher.openMaps(
                context: context,
                latitude: _service!.lat,
                longitude: _service!.lng,
                placeName: _service!.title,
              );
            },
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      'https://maps.googleapis.com/maps/api/staticmap?'
                      'center=${_service!.lat},${_service!.lng}'
                      '&zoom=15&size=600x300&maptype=roadmap'
                      '&markers=color:red%7C${_service!.lat},${_service!.lng}'
                      '&key=AIzaSyD0w9EnRWj8cxiu2E_QvUO4LvXjsSSllSw',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(
                          Icons.map,
                          size: 48,
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.directions, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              loc.t('directions'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
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
            ),
          ),
        ],
      ),
    );
  }

  bool _hasSocialMedia() {
    return (_service!.facebook?.isNotEmpty ?? false) ||
        (_service!.instagram?.isNotEmpty ?? false) ||
        (_service!.telegram?.isNotEmpty ?? false) ||
        (_service!.whatsapp?.isNotEmpty ?? false);
  }

  /// Social media section including WhatsApp
  Widget _buildSocialMediaSection(BuildContext context, bool isDark, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.t('social_media'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // WhatsApp
              if (_service!.whatsapp?.isNotEmpty ?? false)
                _buildSocialButton(
                  icon: Icons.chat,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () => _launchWhatsApp(_service!.whatsapp!),
                ),
              // Facebook
              if (_service!.facebook?.isNotEmpty ?? false)
                _buildSocialButton(
                  icon: Icons.facebook,
                  label: 'Facebook',
                  color: const Color(0xFF1877F2),
                  onTap: () => _launchUrl(_service!.facebook!),
                ),
              // Instagram
              if (_service!.instagram?.isNotEmpty ?? false)
                _buildSocialButton(
                  icon: Icons.camera_alt,
                  label: 'Instagram',
                  color: const Color(0xFFE4405F),
                  onTap: () => _launchUrl(_service!.instagram!),
                ),
              // Telegram
              if (_service!.telegram?.isNotEmpty ?? false)
                _buildSocialButton(
                  icon: Icons.send,
                  label: 'Telegram',
                  color: const Color(0xFF0088CC),
                  onTap: () => _launchUrl(_service!.telegram!),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection(BuildContext context, bool isDark, AppLocalizations loc) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ReviewsSection(
            service: _service!,
            currentUserId: authProvider.user?.id,
            isLoggedIn: authProvider.isAuthenticated,
            onLoginRequired: () {
              showLoginPromptDialog(context, feature: 'write_review');
            },
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isDark, AppLocalizations loc) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Call Button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _makePhoneCall(_service!.phone),
              icon: const Icon(Icons.phone),
              label: Text(loc.t('call')),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.green.shade400),
                foregroundColor: Colors.green,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Directions Button
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                if (!_checkAuthForContact('view_location')) return;
                MapLauncher.openMaps(
                  context: context,
                  latitude: _service!.lat,
                  longitude: _service!.lng,
                  placeName: _service!.title,
                );
              },
              icon: const Icon(Icons.directions),
              label: Text(loc.t('directions')),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // ACTIONS
  // ============================================

  Future<void> _openEditSheet(BuildContext context) async {
    final result = await openEditServiceSheet(context, _service!);

    if (result != null && result['success'] == true && result['service'] != null) {
      setState(() {
        _service = result['service'] as Service;
      });
    }
  }

  Future<void> _toggleServiceStatus(BuildContext context, AppLocalizations loc) async {
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    final newStatus = !_service!.isCurrentlyOpen;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await serviceProvider.updateService(
        serviceId: _service!.id,
        catId: _service!.catId,
        subcatId: _service!.subcatId,
        name: _service!.title,
        phone: _service!.phone,
        address: _service!.address,
        description: _service!.description,
        lat: _service!.lat,
        lng: _service!.lng,
        isManualOverride: true,
        active: newStatus,
      );

      if (mounted) Navigator.pop(context);

      if (result['success'] == true) {
        setState(() {
          _service = _service!.copyWith(
            active: newStatus ? '1' : '0',
            isManualOverride: true,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus ? loc.t('service_marked_open') : loc.t('service_marked_closed'),
            ),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.t('failed_to_update_service'))),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('error_occurred'))),
      );
    }
  }

  Future<void> _deleteService(BuildContext context, AppLocalizations loc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade400),
            const SizedBox(width: 12),
            Text(loc.t('delete_service')),
          ],
        ),
        content: Text(loc.t('are_you_sure_delete_service')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(loc.t('delete')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await serviceProvider.deleteService(serviceId: _service!.id);

      if (mounted) Navigator.pop(context);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.t('service_deleted_successfully')),
            backgroundColor: Colors.green,
          ),
        );
        if (mounted) Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.t('failed_to_delete_service'))),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('error_deleting_service'))),
      );
    }
  }

  /// Check if user is authenticated, show login prompt if not
  bool _checkAuthForContact(String feature) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      showLoginPromptDialog(context, feature: feature);
      return false;
    }
    return true;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (!_checkAuthForContact('call_service')) return;

    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp(String number) async {
    if (!_checkAuthForContact('view_contact')) return;

    String cleanNumber = number.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$cleanNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!_checkAuthForContact('view_contact')) return;

    String finalUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      finalUrl = 'https://$url';
    }
    final uri = Uri.parse(finalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

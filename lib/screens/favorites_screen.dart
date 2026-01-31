import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guid/providers/auth_provider.dart';
import 'package:tour_guid/providers/favorites_provider.dart';
import 'package:tour_guid/screens/login_screen.dart';
import 'package:tour_guid/screens/widgets/favorite_button.dart';
import 'package:tour_guid/screens/service_details_screen.dart';
import 'package:tour_guid/screens/widgets/service_image_widget.dart';
import '../models/favorite.dart';
import '../utils/app_localization.dart';
import '../utils/app_texts_style.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Fixed duration
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final favoritesProvider =
    Provider.of<FavoritesProvider>(context, listen: false);

    // Set Supabase user ID if not already set
    if (authProvider.supabaseUserId != null) {
      favoritesProvider.setSupabaseUserId(authProvider.supabaseUserId);
    } else {
      return;
    }

    try {
      await favoritesProvider.fetchFavorites();
      _animationController.forward(from: 0);
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          AppLocalizations.of(context).t('failed_to_load_favorites'),
          const Color(0xFFEF4444),
          Icons.error_outline,
        );
      }
    }
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: AppTextSizes.bodyMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        margin: const EdgeInsets.all(AppSpacing.lg),
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(loc),
          _buildBody(loc),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(AppLocalizations loc) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(right: AppSpacing.lg, bottom: AppSpacing.lg),
        title: Text(
          loc.t('favorites'),
          style: TextStyle(
            color: Theme.of(context).textTheme.labelLarge!.color,
            fontSize: AppTextSizes.h1,
            fontWeight: FontWeight.bold,
          ),
        ),
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
      actions: [
        Consumer<FavoritesProvider>(
          builder: (context, favoritesProvider, child) {
            if (favoritesProvider.isLoading) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              );
            }

            return Container(
              margin: EdgeInsets.only(
                  left: AppSpacing.md, top: AppSpacing.sm, bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: _loadFavorites,
                tooltip: loc.t('refresh'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody(AppLocalizations loc) {
    return Consumer2<FavoritesProvider, AuthProvider>(
      builder: (context, favoritesProvider, authProvider, child) {
        if (authProvider.user == null) {
          return SliverToBoxAdapter(child: _buildNotLoggedInState(loc));
        }

        if (favoritesProvider.isLoading && !favoritesProvider.hasData) {
          return SliverToBoxAdapter(child: _buildLoadingState(loc));
        }

        if (favoritesProvider.errorMessage != null &&
            !favoritesProvider.hasData) {
          return SliverToBoxAdapter(
            child: _buildErrorState(loc, favoritesProvider.errorMessage!),
          );
        }

        if (favoritesProvider.favorites.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyState(loc));
        }

        return _buildFavoritesList(favoritesProvider.favorites);
      },
    );
  }

  Widget _buildLoadingState(AppLocalizations loc) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Theme.of(context).primaryColor.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
              strokeWidth: 3.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            loc.t('loading_text'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: AppTextSizes.h3,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            loc.t('please_wait'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
              fontSize: AppTextSizes.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations loc, String error) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            loc.t('error_occurred_title'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: AppTextSizes.h1,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
              height: 1.5,
              fontSize: AppTextSizes.bodyMedium,
            ),
          ),
          const SizedBox(height: 40),
          _buildModernButton(
            onPressed: _loadFavorites,
            icon: Icons.refresh_rounded,
            label: loc.t('try_again'),
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedInState(AppLocalizations loc) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.2),
                  Theme.of(context).primaryColor.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.login_rounded,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            loc.t('not_logged_in'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: AppTextSizes.h1,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            loc.t('please_login_to_view_favorites'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
              height: 1.5,
              fontSize: AppTextSizes.bodyMedium,
            ),
          ),
          const SizedBox(height: 40),
          _buildModernButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            icon: Icons.login_rounded,
            label: loc.t('login'),
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations loc) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.15),
                  Theme.of(context).primaryColor.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_border_rounded,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            loc.t('no_favorites_yet'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: AppTextSizes.h1,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              loc.t('start_adding_favorites'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
                height: 1.6,
                fontSize: AppTextSizes.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    bool isPrimary = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: isPrimary
            ? [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ]
            : null,
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: AppTextSizes.button,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? Theme.of(context).primaryColor
              : Colors.grey.shade200,
          foregroundColor: isPrimary ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesList(List<Favorite> favorites) {
    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: TweenAnimationBuilder<double>(
                key: ValueKey(favorites[index].serviceId),
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 80)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(30 * (1 - value), 0),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: _FavoriteListItem(
                  favorite: favorites[index],
                  onRemoved: () {
                    // Item will automatically disappear when provider updates
                  },
                ),
              ),
            );
          },
          childCount: favorites.length,
        ),
      ),
    );
  }
}

// Separate widget for each list item with its own animation
class _FavoriteListItem extends StatefulWidget {
  final Favorite favorite;
  final VoidCallback onRemoved;

  const _FavoriteListItem({
    Key? key,
    required this.favorite,
    required this.onRemoved,
  }) : super(key: key);

  @override
  State<_FavoriteListItem> createState() => _FavoriteListItemState();
}

class _FavoriteListItemState extends State<_FavoriteListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _removeController;
  bool _isRemoving = false;
  bool _wasFavorite = true;

  @override
  void initState() {
    super.initState();
    _removeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _removeController.dispose();
    super.dispose();
  }

  void _handleRemoval() {
    if (!_isRemoving) {
      setState(() => _isRemoving = true);
      _removeController.forward().then((_) {
        if (mounted) {
          widget.onRemoved();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.favorite.service;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    // Check if this item should be removed with better logic
    return Consumer<FavoritesProvider>(
      builder: (context, favProvider, _) {
        final isFavorite = favProvider.isFavorite(service.id);

        // Detect removal: was favorite before but not anymore
        if (_wasFavorite && !isFavorite && !_isRemoving) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleRemoval();
          });
        }
        _wasFavorite = isFavorite;

        return AnimatedBuilder(
          animation: _removeController,
          builder: (context, child) {
            final slideValue = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(1.2, 0.0),
            ).animate(CurvedAnimation(
              parent: _removeController,
              curve: Curves.easeInBack,
            ));

            final fadeValue = Tween<double>(
              begin: 1.0,
              end: 0.0,
            ).animate(CurvedAnimation(
              parent: _removeController,
              curve: Curves.easeOut,
            ));

            final sizeValue = Tween<double>(
              begin: 1.0,
              end: 0.0,
            ).animate(CurvedAnimation(
              parent: _removeController,
              curve: Curves.easeInOut,
            ));

            return SizeTransition(
              sizeFactor: sizeValue,
              axisAlignment: -1.0,
              child: FadeTransition(
                opacity: fadeValue,
                child: SlideTransition(
                  position: slideValue,
                  child: child,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceDetailsScreen(service: service),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Image Section
                    Hero(
                      tag: 'service_image_${service.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(AppRadius.lg),
                        ),
                        child: ServiceImageWidget(
                          imageUrl: service.imageUrl,
                          height: 110,
                          width: 110,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // Content Section
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              service.title,
                              style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: AppTextSizes.cardTitle,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.xs),

                            // Category Badge
                            if (service.subcatName.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  service.subcatName,
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: AppTextSizes.cardCaption,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            const SizedBox(height: AppSpacing.sm),

                            // Description
                            if (service.description.isNotEmpty)
                              Text(
                                service.description,
                                style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDarkMode
                                      ? Colors.white.withOpacity(0.6)
                                      : Colors.black.withOpacity(0.5),
                                  fontSize: AppTextSizes.cardSubtitle,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Action Section
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Favorite Button
                          FavoriteButton(
                            serviceId: service.id,
                            style: FavoriteButtonStyle.minimal,
                            size: FavoriteButtonSize.medium,
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // View Details Icon
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: Theme.of(context).primaryColor,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ServiceDetailsScreen(service: service),
                                  ),
                                );
                              },
                              tooltip: loc.t('details'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
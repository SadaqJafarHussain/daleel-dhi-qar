import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guid/providers/auth_provider.dart';
import 'package:tour_guid/providers/favorites_provider.dart';
import 'package:tour_guid/providers/language_provider.dart';
import 'package:tour_guid/providers/subcategory_provider.dart';
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
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFavorites());
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
    if (authProvider.supabaseUserId != null) {
      favoritesProvider.setSupabaseUserId(authProvider.supabaseUserId);
    } else {
      return;
    }
    try {
      await favoritesProvider.fetchFavorites();
      _animationController.forward(from: 0);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(AppLocalizations.of(context).t('failed_to_load_favorites')),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer2<FavoritesProvider, AuthProvider>(
        builder: (context, favProvider, authProvider, _) {
          final count = favProvider.favorites.length;

          return CustomScrollView(
            slivers: [
              // ── App bar ─────────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                title: Row(
                  children: [
                    Text(
                      loc.t('favorites'),
                      style: TextStyle(
                        fontSize: AppTextSizes.h2,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF111827),
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 2),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: primary,
                            fontSize: AppTextSizes.label,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  if (favProvider.isLoading)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primary,
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(Icons.refresh_rounded, color: primary),
                      onPressed: _loadFavorites,
                      tooltip: loc.t('refresh'),
                    ),
                ],
              ),

              // ── Body ─────────────────────────────────────────────────────
              if (authProvider.user == null)
                SliverFillRemaining(
                  child: _buildCenteredState(
                    context,
                    icon: Icons.favorite_border_rounded,
                    iconColor: primary,
                    title: loc.t('not_logged_in'),
                    subtitle: loc.t('please_login_to_view_favorites'),
                    buttonLabel: loc.t('login'),
                    buttonIcon: Icons.login_rounded,
                    onButton: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const LoginScreen())),
                  ),
                )
              else if (favProvider.isLoading && !favProvider.hasData)
                SliverFillRemaining(child: _buildLoadingState(primary))
              else if (favProvider.errorMessage != null && !favProvider.hasData)
                SliverFillRemaining(
                  child: _buildCenteredState(
                    context,
                    icon: Icons.error_outline_rounded,
                    iconColor: const Color(0xFFEF4444),
                    title: loc.t('error_occurred_title'),
                    subtitle: favProvider.errorMessage!,
                    buttonLabel: loc.t('try_again'),
                    buttonIcon: Icons.refresh_rounded,
                    onButton: _loadFavorites,
                  ),
                )
              else if (favProvider.favorites.isEmpty)
                SliverFillRemaining(
                  child: _buildCenteredState(
                    context,
                    icon: Icons.favorite_border_rounded,
                    iconColor: primary,
                    title: loc.t('no_favorites_yet'),
                    subtitle: loc.t('start_adding_favorites'),
                  ),
                )
              else
                _buildGrid(favProvider.favorites),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(Color primary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 3, color: primary),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context).t('loading_text'),
            style: TextStyle(
              fontSize: AppTextSizes.bodyMedium,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenteredState(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? buttonLabel,
    IconData? buttonIcon,
    VoidCallback? onButton,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: iconColor.withOpacity(0.7)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTextSizes.h3,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTextSizes.bodySmall,
                color: Colors.grey.shade500,
                height: 1.6,
              ),
            ),
            if (buttonLabel != null && onButton != null) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onButton,
                  icon: Icon(buttonIcon, size: 18),
                  label: Text(buttonLabel,
                      style: const TextStyle(
                          fontSize: AppTextSizes.button,
                          fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<Favorite> favorites) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.70,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: TweenAnimationBuilder<double>(
                key: ValueKey(favorites[index].serviceId),
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 250 + (index * 60)),
                curve: Curves.easeOutCubic,
                builder: (context, v, child) => Transform.translate(
                  offset: Offset(0, 20 * (1 - v)),
                  child: Opacity(opacity: v, child: child),
                ),
                child: _FavoriteGridCard(favorite: favorites[index]),
              ),
            );
          },
          childCount: favorites.length,
        ),
      ),
    );
  }
}

// ── Grid card ───────────────────────────────────────────────────────────────

class _FavoriteGridCard extends StatefulWidget {
  final Favorite favorite;

  const _FavoriteGridCard({required this.favorite});

  @override
  State<_FavoriteGridCard> createState() => _FavoriteGridCardState();
}

class _FavoriteGridCardState extends State<_FavoriteGridCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _removeController;
  bool _isRemoving = false;
  bool _wasFavorite = true;

  @override
  void initState() {
    super.initState();
    _removeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
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
      _removeController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.favorite.service;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    final isAr = context.read<LanguageProvider>().isArabic;
    final subcatProvider = context.read<SubcategoryProvider>();
    final subcatName = subcatProvider
            .getLocalizedSubcategoryNameById(service.subcatId, isAr) ??
        service.subcatName;

    return Consumer<FavoritesProvider>(
      builder: (context, favProvider, _) {
        final isFavorite = favProvider.isFavorite(service.id);

        if (_wasFavorite && !isFavorite && !_isRemoving) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _handleRemoval());
        }
        _wasFavorite = isFavorite;

        return AnimatedBuilder(
          animation: _removeController,
          builder: (context, child) => FadeTransition(
            opacity: Tween(begin: 1.0, end: 0.0).animate(
              CurvedAnimation(
                  parent: _removeController, curve: Curves.easeOut),
            ),
            child: ScaleTransition(
              scale: Tween(begin: 1.0, end: 0.85).animate(
                CurvedAnimation(
                    parent: _removeController, curve: Curves.easeInBack),
              ),
              child: child,
            ),
          ),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ServiceDetailsScreen(service: service)),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.25)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Image ───────────────────────────────────────────────
                  Expanded(
                    flex: 5,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          child: ServiceImageWidget(
                            imageUrl: service.imageUrl,
                            height: double.infinity,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Favourite toggle overlay
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withOpacity(0.55)
                                  : Colors.white.withOpacity(0.92),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 6,
                                )
                              ],
                            ),
                            child: FavoriteButton(
                              serviceId: service.id,
                              style: FavoriteButtonStyle.minimal,
                              size: FavoriteButtonSize.small,
                            ),
                          ),
                        ),
                        // Rating badge (bottom left of image)
                        if (service.averageRating != null &&
                            service.averageRating! > 0)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded,
                                      size: 11, color: Color(0xFFFBBF24)),
                                  const SizedBox(width: 3),
                                  Text(
                                    service.averageRating!.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Content ─────────────────────────────────────────────
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.title,
                            style: TextStyle(
                              fontSize: AppTextSizes.cardTitle,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (subcatName.isNotEmpty)
                            Text(
                              subcatName,
                              style: TextStyle(
                                fontSize: AppTextSizes.cardCaption,
                                color: primary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

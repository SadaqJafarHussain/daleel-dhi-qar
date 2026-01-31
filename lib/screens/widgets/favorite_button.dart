import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tour_guid/providers/auth_provider.dart';
import 'package:tour_guid/providers/favorites_provider.dart';
import 'package:tour_guid/utils/app_localization.dart';
import 'package:tour_guid/screens/widgets/login_prompt_dialog.dart';
import 'dart:math' as math;

class FavoriteButton extends StatefulWidget {
  /// Service ID
  final int serviceId;

  /// Visual style of the button
  final FavoriteButtonStyle style;

  /// Size of the button
  final FavoriteButtonSize size;

  /// Color when favorited
  final Color? activeColor;

  /// Color when not favorited
  final Color? inactiveColor;

  /// Show particle effects on favorite
  final bool showParticles;

  /// Enable haptic feedback
  final bool enableHaptic;

  /// Show tooltip
  final bool showTooltip;

  /// Callback on success
  final VoidCallback? onSuccess;

  /// Callback on error
  final VoidCallback? onError;

  const FavoriteButton({
    Key? key,
    required this.serviceId,
    this.style = FavoriteButtonStyle.minimal,
    this.size = FavoriteButtonSize.medium,
    this.activeColor,
    this.inactiveColor,
    this.showParticles = true,
    this.enableHaptic = true,
    this.showTooltip = true,
    this.onSuccess,
    this.onError,
  }) : super(key: key);

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  bool _isProcessing = false;
  List<ParticleData> _particles = [];

  @override
  void initState() {
    super.initState();

    // Scale animation for press effect
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Rotation animation for favorite action
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.elasticOut),
    );

    // Particle animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _particleController.addListener(() {
      if (mounted) {
        setState(() {
          for (var particle in _particles) {
            particle.update();
          }
          _particles.removeWhere((p) => p.isDead);
        });
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (_isProcessing) return;

    // Haptic feedback
    if (widget.enableHaptic) {
      HapticFeedback.mediumImpact();
    }

    // Scale animation
    await _scaleController.forward();
    _scaleController.reverse();

    setState(() => _isProcessing = true);

    // Get providers
    final favoritesProvider =
    Provider.of<FavoritesProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check if user is authenticated
    if (authProvider.supabaseUserId == null) {
      setState(() => _isProcessing = false);
      // Show login prompt dialog
      showLoginPromptDialog(context, feature: 'add_favorites');
      if (widget.onError != null) widget.onError!();
      return;
    }

    // Set Supabase user ID if not already set
    favoritesProvider.setSupabaseUserId(authProvider.supabaseUserId);

    // Check current state before toggle
    final wasLiked = favoritesProvider.isFavorite(widget.serviceId);

    // Toggle favorite
    final success = await favoritesProvider.toggleFavorite(
      widget.serviceId,
    );

    if (!mounted) return;

    setState(() => _isProcessing = false);

    if (success) {
      final isNowLiked = favoritesProvider.isFavorite(widget.serviceId);

      if (isNowLiked && !wasLiked) {
        // Added to favorites
        _onFavorited();
        _showMessage(
          AppLocalizations.of(context).t('added_to_favorites'),
          isError: false,
        );
      } else if (!isNowLiked && wasLiked) {
        // Removed from favorites
        _showMessage(
          AppLocalizations.of(context).t('removed_from_favorites'),
          isError: false,
        );
      }

      if (widget.onSuccess != null) widget.onSuccess!();
    } else {
      _showMessage(
        AppLocalizations.of(context).t('operation_failed'),
        isError: true,
      );
      if (widget.onError != null) widget.onError!();
    }
  }

  void _onFavorited() {
    // Rotation animation
    _rotationController.forward(from: 0);

    // Haptic feedback
    if (widget.enableHaptic) {
      HapticFeedback.heavyImpact();
    }

    // Create particles
    if (widget.showParticles) {
      _createParticles();
      _particleController.forward(from: 0);
    }
  }

  void _createParticles() {
    final random = math.Random();
    _particles.clear();

    for (int i = 0; i < 8; i++) {
      final angle = (i * 2 * math.pi / 8) + random.nextDouble() * 0.5;
      _particles.add(ParticleData(
        angle: angle,
        velocity: 2.0 + random.nextDouble() * 2.0,
        color: widget.activeColor ??
            Theme.of(context).primaryColor,
      ));
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
        isError ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        elevation: 6,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        final isFavorite = favoritesProvider.isFavorite(widget.serviceId);
        final isLoading = favoritesProvider.isFavoriteLoading && _isProcessing;

        Widget button = _buildButton(isFavorite, isLoading);

        // Add particles overlay
        if (widget.showParticles && _particles.isNotEmpty) {
          button = Stack(
            clipBehavior: Clip.none,
            children: [
              button,
              ..._particles.map((particle) => _buildParticle(particle)).toList(),
            ],
          );
        }

        // Add tooltip
        if (widget.showTooltip) {
          button = Tooltip(
            message: isFavorite ? AppLocalizations.of(context).t('remove_from_favorites') : AppLocalizations.of(context).t('add_to_favorites'),
            child: button,
          );
        }

        return button;
      },
    );
  }

  Widget _buildButton(bool isFavorite, bool isLoading) {
    final activeColor = widget.activeColor ?? Theme.of(context).primaryColor;
    final inactiveColor = widget.inactiveColor ?? Colors.grey.shade400;

    // Get size values
    final sizeData = _getSizeData(widget.size);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: isLoading ? null : _handlePress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: sizeData.containerSize,
          height: sizeData.containerSize,
          decoration: _getDecoration(isFavorite, activeColor, inactiveColor),
          child: Center(
            child: isLoading
                ? SizedBox(
              width: sizeData.iconSize,
              height: sizeData.iconSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isFavorite ? activeColor : inactiveColor,
                ),
              ),
            )
                : RotationTransition(
              turns: _rotationAnimation,
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                size: sizeData.iconSize,
                color:
                _getIconColor(isFavorite, activeColor, inactiveColor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _getDecoration(
      bool isFavorite, Color activeColor, Color inactiveColor) {
    switch (widget.style) {
      case FavoriteButtonStyle.minimal:
        return const BoxDecoration();

      case FavoriteButtonStyle.outlined:
        return BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isFavorite ? activeColor : inactiveColor.withOpacity(0.3),
            width: 2,
          ),
        );

      case FavoriteButtonStyle.filled:
        return BoxDecoration(
          color: isFavorite ? activeColor : Colors.grey.shade100,
          shape: BoxShape.circle,
          boxShadow: isFavorite
              ? [
            BoxShadow(
              color: activeColor.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        );

      case FavoriteButtonStyle.soft:
        return BoxDecoration(
          color: isFavorite
              ? activeColor.withOpacity(0.15)
              : Colors.grey.shade50,
          shape: BoxShape.circle,
          border: Border.all(
            color: isFavorite
                ? activeColor.withOpacity(0.3)
                : Colors.grey.shade200,
            width: 1,
          ),
        );
    }
  }

  Color _getIconColor(bool isFavorite, Color activeColor, Color inactiveColor) {
    if (widget.style == FavoriteButtonStyle.filled && isFavorite) {
      return Colors.white;
    }
    return isFavorite ? activeColor : inactiveColor;
  }

  Widget _buildParticle(ParticleData particle) {
    return Positioned(
      left: particle.x,
      top: particle.y,
      child: Opacity(
        opacity: particle.opacity,
        child: Container(
          width: particle.size,
          height: particle.size,
          decoration: BoxDecoration(
            color: particle.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  _SizeData _getSizeData(FavoriteButtonSize size) {
    switch (size) {
      case FavoriteButtonSize.small:
        return _SizeData(containerSize: 36, iconSize: 18);
      case FavoriteButtonSize.medium:
        return _SizeData(containerSize: 44, iconSize: 22);
      case FavoriteButtonSize.large:
        return _SizeData(containerSize: 56, iconSize: 28);
    }
  }
}

// ==================== ENUMS ====================

/// Button visual styles
enum FavoriteButtonStyle {
  /// Transparent background, just the icon
  minimal,

  /// Border outline
  outlined,

  /// Solid background with white icon when active
  filled,

  /// Soft colored background with light border
  soft,
}

/// Button sizes
enum FavoriteButtonSize {
  small,
  medium,
  large,
}

// ==================== HELPER CLASSES ====================

/// Size data for button dimensions
class _SizeData {
  final double containerSize;
  final double iconSize;

  _SizeData({required this.containerSize, required this.iconSize});
}

/// Particle effect data
class ParticleData {
  double x = 0;
  double y = 0;
  final double angle;
  final double velocity;
  final Color color;
  double opacity = 1.0;
  double size = 4;
  bool isDead = false;

  ParticleData({
    required this.angle,
    required this.velocity,
    required this.color,
  });

  void update() {
    x += math.cos(angle) * velocity;
    y += math.sin(angle) * velocity;
    opacity -= 0.02;
    size -= 0.05;

    if (opacity <= 0 || size <= 0) {
      isDead = true;
    }
  }
}

// ==================== BONUS WIDGETS ====================

/// Badge showing favorite status
class FavoriteBadge extends StatelessWidget {
  final int serviceId;

  const FavoriteBadge({
    Key? key,
    required this.serviceId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        final isFavorite = favoritesProvider.isFavorite(serviceId);

        if (!isFavorite) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite,
                size: 14,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(context).t('favorite'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
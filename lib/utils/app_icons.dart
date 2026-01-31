import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

/// Standardized icon sizes used throughout the app
class AppIconSize {
  static const double xs = 14.0;
  static const double sm = 18.0;
  static const double md = 22.0;
  static const double lg = 28.0;
  static const double xl = 36.0;
  static const double xxl = 48.0;
}

/// Standardized icon container sizes
class AppIconContainerSize {
  static const double xs = 28.0;
  static const double sm = 36.0;
  static const double md = 44.0;
  static const double lg = 56.0;
  static const double xl = 72.0;
}

/// App icon widget with consistent styling
class AppIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final bool withBackground;
  final Color? backgroundColor;
  final double? containerSize;
  final double? borderRadius;
  final BoxShape shape;
  final List<BoxShadow>? shadow;
  final Gradient? gradient;
  final Border? border;

  const AppIcon({
    Key? key,
    required this.icon,
    this.size,
    this.color,
    this.withBackground = false,
    this.backgroundColor,
    this.containerSize,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.shadow,
    this.gradient,
    this.border,
  }) : super(key: key);

  /// Small icon without background
  factory AppIcon.small(IconData icon, {Color? color}) {
    return AppIcon(
      icon: icon,
      size: AppIconSize.sm,
      color: color,
    );
  }

  /// Medium icon without background
  factory AppIcon.medium(IconData icon, {Color? color}) {
    return AppIcon(
      icon: icon,
      size: AppIconSize.md,
      color: color,
    );
  }

  /// Large icon without background
  factory AppIcon.large(IconData icon, {Color? color}) {
    return AppIcon(
      icon: icon,
      size: AppIconSize.lg,
      color: color,
    );
  }

  /// Icon with circular colored background
  factory AppIcon.circle({
    required IconData icon,
    required Color color,
    double size = AppIconSize.md,
    double containerSize = AppIconContainerSize.md,
    bool filled = false,
    List<BoxShadow>? shadow,
  }) {
    return AppIcon(
      icon: icon,
      size: size,
      color: filled ? Colors.white : color,
      withBackground: true,
      backgroundColor: filled ? color : color.withOpacity(0.12),
      containerSize: containerSize,
      shape: BoxShape.circle,
      shadow: shadow,
    );
  }

  /// Icon with rounded square background
  factory AppIcon.rounded({
    required IconData icon,
    required Color color,
    double size = AppIconSize.md,
    double containerSize = AppIconContainerSize.md,
    double borderRadius = 12.0,
    bool filled = false,
    List<BoxShadow>? shadow,
  }) {
    return AppIcon(
      icon: icon,
      size: size,
      color: filled ? Colors.white : color,
      withBackground: true,
      backgroundColor: filled ? color : color.withOpacity(0.12),
      containerSize: containerSize,
      borderRadius: borderRadius,
      shadow: shadow,
    );
  }

  /// Icon with gradient background
  factory AppIcon.gradient({
    required IconData icon,
    required List<Color> colors,
    double size = AppIconSize.md,
    double containerSize = AppIconContainerSize.md,
    double borderRadius = 12.0,
    BoxShape shape = BoxShape.rectangle,
    List<BoxShadow>? shadow,
  }) {
    return AppIcon(
      icon: icon,
      size: size,
      color: Colors.white,
      withBackground: true,
      containerSize: containerSize,
      borderRadius: borderRadius,
      shape: shape,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
      shadow: shadow ?? [
        BoxShadow(
          color: colors.first.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Icon with outline/border
  factory AppIcon.outlined({
    required IconData icon,
    required Color color,
    double size = AppIconSize.md,
    double containerSize = AppIconContainerSize.md,
    double borderRadius = 12.0,
    double borderWidth = 1.5,
  }) {
    return AppIcon(
      icon: icon,
      size: size,
      color: color,
      withBackground: true,
      backgroundColor: Colors.transparent,
      containerSize: containerSize,
      borderRadius: borderRadius,
      border: Border.all(color: color.withOpacity(0.3), width: borderWidth),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? Colors.white : Colors.grey.shade700;
    final iconColor = color ?? defaultColor;
    final iconSize = size ?? AppIconSize.md;

    if (!withBackground) {
      return Icon(icon, size: iconSize, color: iconColor);
    }

    final container = containerSize ?? AppIconContainerSize.md;

    return Container(
      width: container,
      height: container,
      decoration: BoxDecoration(
        color: gradient == null ? backgroundColor : null,
        gradient: gradient,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(borderRadius ?? 12)
            : null,
        border: border,
        boxShadow: shadow,
      ),
      child: Center(
        child: Icon(icon, size: iconSize, color: iconColor),
      ),
    );
  }
}

/// Action icon button with consistent styling
class AppIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double containerSize;
  final double borderRadius;
  final bool enabled;
  final String? tooltip;

  const AppIconButton({
    Key? key,
    required this.icon,
    this.onTap,
    this.color,
    this.backgroundColor,
    this.size = AppIconSize.md,
    this.containerSize = AppIconContainerSize.sm,
    this.borderRadius = 10.0,
    this.enabled = true,
    this.tooltip,
  }) : super(key: key);

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? Colors.grey.shade800 : Colors.grey.shade100;
    final defaultColor = isDark ? Colors.white : Colors.grey.shade700;

    final bgColor = widget.enabled
        ? (widget.backgroundColor ?? defaultBg)
        : (isDark ? Colors.grey.shade900 : Colors.grey.shade200);
    final iconColor = widget.enabled
        ? (widget.color ?? defaultColor)
        : Colors.grey.shade400;

    Widget button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Container(
        width: widget.containerSize,
        height: widget.containerSize,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: Center(
          child: Icon(widget.icon, size: widget.size, color: iconColor),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    return GestureDetector(
      onTapDown: widget.enabled ? (_) => _controller.forward() : null,
      onTapUp: widget.enabled ? (_) => _controller.reverse() : null,
      onTapCancel: widget.enabled ? () => _controller.reverse() : null,
      onTap: widget.enabled ? widget.onTap : null,
      child: button,
    );
  }
}

/// Colored action button (for call, directions, etc.)
class AppActionButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final double size;
  final bool filled;
  final String? label;

  const AppActionButton({
    Key? key,
    required this.icon,
    required this.color,
    this.onTap,
    this.size = AppIconSize.sm,
    this.filled = false,
    this.label,
  }) : super(key: key);

  /// Phone call action button
  factory AppActionButton.call({VoidCallback? onTap}) {
    return AppActionButton(
      icon: Icons.phone_rounded,
      color: const Color(0xFF10B981),
      onTap: onTap,
    );
  }

  /// Directions action button
  factory AppActionButton.directions({VoidCallback? onTap}) {
    return AppActionButton(
      icon: Icons.directions_rounded,
      color: const Color(0xFF3B82F6),
      onTap: onTap,
    );
  }

  /// Share action button
  factory AppActionButton.share({VoidCallback? onTap}) {
    return AppActionButton(
      icon: Icons.share_rounded,
      color: const Color(0xFF8B5CF6),
      onTap: onTap,
    );
  }

  /// Edit action button
  factory AppActionButton.edit({VoidCallback? onTap}) {
    return AppActionButton(
      icon: Icons.edit_rounded,
      color: const Color(0xFFF59E0B),
      onTap: onTap,
    );
  }

  /// Delete action button
  factory AppActionButton.delete({VoidCallback? onTap}) {
    return AppActionButton(
      icon: Icons.delete_rounded,
      color: const Color(0xFFEF4444),
      onTap: onTap,
    );
  }

  @override
  State<AppActionButton> createState() => _AppActionButtonState();
}

class _AppActionButtonState extends State<AppActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.label != null ? 12 : 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: widget.filled
                ? widget.color
                : widget.color.withOpacity(isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: widget.size,
                color: widget.filled ? Colors.white : widget.color,
              ),
              if (widget.label != null) ...[
                const SizedBox(width: 6),
                Text(
                  widget.label!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.filled ? Colors.white : widget.color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge icon (for status indicators)
class AppBadgeIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool showDot;

  const AppBadgeIcon({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
    this.showDot = true,
  }) : super(key: key);

  /// Available/Active status badge
  factory AppBadgeIcon.available({required String label}) {
    return AppBadgeIcon(
      icon: Icons.check_circle_rounded,
      label: label,
      color: const Color(0xFF10B981),
    );
  }

  /// Unavailable/Inactive status badge
  factory AppBadgeIcon.unavailable({required String label}) {
    return AppBadgeIcon(
      icon: Icons.cancel_rounded,
      label: label,
      color: Colors.grey,
    );
  }

  /// Sponsored badge
  factory AppBadgeIcon.sponsored({required String label}) {
    return AppBadgeIcon(
      icon: Icons.campaign_rounded,
      label: label,
      color: Colors.amber,
      showDot: false,
    );
  }

  /// Featured badge
  factory AppBadgeIcon.featured({required String label}) {
    return AppBadgeIcon(
      icon: Icons.verified_rounded,
      label: label,
      color: const Color(0xFF3B82F6),
      showDot: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            )
          else
            Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Distance indicator icon
class AppDistanceIcon extends StatelessWidget {
  final double distance;
  final String unit;

  const AppDistanceIcon({
    Key? key,
    required this.distance,
    required this.unit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF3B82F6).withOpacity(0.15)
            : const Color(0xFF3B82F6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.near_me_rounded,
            size: 12,
            color: Color(0xFF3B82F6),
          ),
          const SizedBox(width: 4),
          Text(
            '${distance.toStringAsFixed(1)} $unit',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3B82F6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header icon
class AppSectionIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final Gradient? gradient;

  const AppSectionIcon({
    Key? key,
    required this.icon,
    this.color,
    this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: gradient == null ? primaryColor.withOpacity(0.1) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: gradient != null
            ? [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        size: AppIconSize.sm,
        color: gradient != null ? Colors.white : primaryColor,
      ),
    );
  }
}

/// Consistent back button used throughout the app
/// For RTL (Arabic) apps: Arrow always points RIGHT (→) and button is on the RIGHT side
/// For LTR (English) apps: Arrow always points LEFT (←) and button is on the LEFT side
class AppBackButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final AppBackButtonStyle style;
  final Color? color;
  final Color? backgroundColor;

  const AppBackButton({
    Key? key,
    this.onPressed,
    this.style = AppBackButtonStyle.filled,
    this.color,
    this.backgroundColor,
  }) : super(key: key);

  /// Dark overlay style - for use on images
  factory AppBackButton.overlay({
    VoidCallback? onPressed,
  }) {
    return AppBackButton(
      onPressed: onPressed,
      style: AppBackButtonStyle.overlay,
    );
  }

  /// Light/card style - for use on light backgrounds
  factory AppBackButton.light({
    VoidCallback? onPressed,
  }) {
    return AppBackButton(
      onPressed: onPressed,
      style: AppBackButtonStyle.light,
    );
  }

  /// Minimal style - icon only, no background
  factory AppBackButton.minimal({
    VoidCallback? onPressed,
    Color? color,
  }) {
    return AppBackButton(
      onPressed: onPressed,
      style: AppBackButtonStyle.minimal,
      color: color,
    );
  }

  @override
  State<AppBackButton> createState() => _AppBackButtonState();
}

enum AppBackButtonStyle { filled, overlay, light, minimal }

class _AppBackButtonState extends State<AppBackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use LanguageProvider to determine if Arabic (RTL)
    final languageProvider = context.watch<LanguageProvider>();
    final bool isRTL = languageProvider.isArabic;

    // Style-based colors and decorations
    Color iconColor;
    Color? bgColor;
    List<BoxShadow>? shadows;

    switch (widget.style) {
      case AppBackButtonStyle.overlay:
        iconColor = Colors.white;
        bgColor = Colors.black.withOpacity(0.5);
        shadows = [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
        break;
      case AppBackButtonStyle.light:
        iconColor = isDark ? Colors.white : Colors.black87;
        bgColor = isDark ? Colors.white.withOpacity(0.1) : Colors.white;
        shadows = [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ];
        break;
      case AppBackButtonStyle.filled:
        iconColor = Colors.white;
        bgColor = Theme.of(context).primaryColor;
        shadows = [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
        break;
      case AppBackButtonStyle.minimal:
        iconColor = widget.color ?? (isDark ? Colors.white : Colors.black87);
        bgColor = null;
        shadows = null;
        break;
    }

    // Override with custom colors if provided
    if (widget.color != null && widget.style != AppBackButtonStyle.minimal) {
      iconColor = widget.color!;
    }
    if (widget.backgroundColor != null) {
      bgColor = widget.backgroundColor;
    }

    // Build the icon with correct direction
    // RTL (Arabic): arrow points right (→) - "east" icon
    // LTR (English): arrow points left (←) - "west" icon
    // Using east/west icons because they don't get auto-mirrored by Flutter's RTL system
    debugPrint('🔙 AppBackButton: isRTL=$isRTL, locale=${languageProvider.locale}');
    final Widget iconWidget = Icon(
      isRTL ? Icons.east_rounded : Icons.west_rounded,
      size: 22,
      color: iconColor,
    );

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed ?? () => Navigator.of(context).pop(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: shadows,
          ),
          child: Center(child: iconWidget),
        ),
      ),
    );
  }
}

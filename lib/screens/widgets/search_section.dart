import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tour_guid/utils/app_icons.dart';
import '../../utils/app_localization.dart';
import '../../utils/page_transitions.dart';
import '../search_screen.dart';

class SearchSection extends StatefulWidget {
  final double width;
  final double height;

  const SearchSection({super.key, required this.width, required this.height});

  @override
  State<SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends State<SearchSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final h = widget.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: h * 0.01),
        // Greeting text
        Text(
          loc.t("home_greeting"),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          loc.t('discover_services'),
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: h * 0.018),
        // Search bar
        GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              PageTransitions.slideUp(page: const SearchScreen()),
            );
          },
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isPressed
                      ? Theme.of(context).primaryColor.withOpacity(0.5)
                      : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  width: _isPressed ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isPressed
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : (isDark
                            ? Colors.black.withOpacity(0.2)
                            : Colors.black.withOpacity(0.04)),
                    blurRadius: _isPressed ? 12 : 8,
                    offset: const Offset(0, 4),
                    spreadRadius: _isPressed ? 0 : -2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Search icon with background
                  AppIcon.rounded(
                    icon: Icons.search_rounded,
                    color: Theme.of(context).primaryColor,
                    size: AppIconSize.md,
                    containerSize: 36,
                    borderRadius: 10,
                  ),
                  const SizedBox(width: 12),
                  // Search text
                  Expanded(
                    child: Text(
                      loc.t("search_hint"),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // Filter icon
                  AppIcon.rounded(
                    icon: Icons.tune_rounded,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    size: AppIconSize.sm,
                    containerSize: 36,
                    borderRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: h * 0.02),
      ],
    );
  }
}

import 'package:flutter/material.dart';

/// Star Rating Display Widget with multiple size variants
///
/// Variants:
/// - compact: Small stars with rating text for cards
/// - standard: Medium stars with count for details
/// - large: Big animated stars for headers
class StarRatingDisplay extends StatefulWidget {
  final double rating;
  final int? reviewCount;
  final StarRatingSize size;
  final bool showCount;
  final bool animate;
  final Color? starColor;
  final Color? emptyStarColor;
  final Color? textColor;
  final MainAxisAlignment alignment;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.reviewCount,
    this.size = StarRatingSize.standard,
    this.showCount = true,
    this.animate = false,
    this.starColor,
    this.emptyStarColor,
    this.textColor,
    this.alignment = MainAxisAlignment.start,
  });

  /// Compact variant for ServiceCard
  factory StarRatingDisplay.compact({
    Key? key,
    required double rating,
    int? reviewCount,
    Color? starColor,
    Color? textColor,
  }) {
    return StarRatingDisplay(
      key: key,
      rating: rating,
      reviewCount: reviewCount,
      size: StarRatingSize.compact,
      showCount: true,
      starColor: starColor,
      textColor: textColor,
    );
  }

  /// Standard variant for details sections
  factory StarRatingDisplay.standard({
    Key? key,
    required double rating,
    int? reviewCount,
    bool showCount = true,
    Color? starColor,
    Color? textColor,
  }) {
    return StarRatingDisplay(
      key: key,
      rating: rating,
      reviewCount: reviewCount,
      size: StarRatingSize.standard,
      showCount: showCount,
      starColor: starColor,
      textColor: textColor,
    );
  }

  /// Large variant with animation for headers
  factory StarRatingDisplay.large({
    Key? key,
    required double rating,
    int? reviewCount,
    bool animate = true,
    Color? starColor,
    Color? textColor,
    MainAxisAlignment alignment = MainAxisAlignment.center,
  }) {
    return StarRatingDisplay(
      key: key,
      rating: rating,
      reviewCount: reviewCount,
      size: StarRatingSize.large,
      showCount: true,
      animate: animate,
      starColor: starColor,
      textColor: textColor,
      alignment: alignment,
    );
  }

  @override
  State<StarRatingDisplay> createState() => _StarRatingDisplayState();
}

class _StarRatingDisplayState extends State<StarRatingDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _starAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Create staggered animations for each star
    _starAnimations = List.generate(5, (index) {
      final start = index * 0.15;
      final end = start + 0.4;
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start.clamp(0, 1), end.clamp(0, 1), curve: Curves.easeOutBack),
        ),
      );
    });

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final starColor = widget.starColor ?? const Color(0xFFFBBF24); // Amber
    final emptyStarColor = widget.emptyStarColor ??
        (isDark ? Colors.grey.shade700 : Colors.grey.shade300);
    final textColor = widget.textColor ??
        (isDark ? Colors.grey.shade300 : Colors.grey.shade700);

    final config = _getSizeConfig();

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: widget.alignment,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Stars
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return AnimatedBuilder(
              animation: _starAnimations[index],
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.animate ? _starAnimations[index].value : 1.0,
                  child: _buildStar(
                    index: index,
                    starColor: starColor,
                    emptyStarColor: emptyStarColor,
                    size: config.starSize,
                  ),
                );
              },
            );
          }),
        ),

        // Rating text and count
        if (widget.showCount) ...[
          SizedBox(width: config.spacing),
          _buildRatingText(config, textColor),
        ],
      ],
    );
  }

  Widget _buildStar({
    required int index,
    required Color starColor,
    required Color emptyStarColor,
    required double size,
  }) {
    final fillAmount = (widget.rating - index).clamp(0.0, 1.0);

    if (fillAmount <= 0) {
      // Empty star
      return Icon(
        Icons.star_outline_rounded,
        size: size,
        color: emptyStarColor,
      );
    } else if (fillAmount >= 1) {
      // Full star
      return Icon(
        Icons.star_rounded,
        size: size,
        color: starColor,
      );
    } else {
      // Half star (using stack for partial fill)
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            Icon(
              Icons.star_outline_rounded,
              size: size,
              color: emptyStarColor,
            ),
            ClipRect(
              clipper: _HalfStarClipper(fillAmount),
              child: Icon(
                Icons.star_rounded,
                size: size,
                color: starColor,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildRatingText(_SizeConfig config, Color textColor) {
    final hasReviews = widget.reviewCount != null && widget.reviewCount! > 0;

    if (widget.size == StarRatingSize.compact) {
      // Compact: "4.5 (128)"
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: config.ratingFontSize,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          if (hasReviews) ...[
            const SizedBox(width: 2),
            Text(
              '(${_formatCount(widget.reviewCount!)})',
              style: TextStyle(
                fontSize: config.countFontSize,
                color: textColor.withOpacity(0.7),
              ),
            ),
          ],
        ],
      );
    } else if (widget.size == StarRatingSize.large) {
      // Large: Big rating with label below
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: config.ratingFontSize,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1,
            ),
          ),
          if (hasReviews)
            Text(
              '${_formatCount(widget.reviewCount!)} reviews',
              style: TextStyle(
                fontSize: config.countFontSize,
                color: textColor.withOpacity(0.7),
              ),
            ),
        ],
      );
    } else {
      // Standard: "4.5 (128 reviews)"
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: widget.rating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: config.ratingFontSize,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            if (hasReviews) ...[
              TextSpan(
                text: ' (${_formatCount(widget.reviewCount!)})',
                style: TextStyle(
                  fontSize: config.countFontSize,
                  color: textColor.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      );
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  _SizeConfig _getSizeConfig() {
    switch (widget.size) {
      case StarRatingSize.compact:
        return const _SizeConfig(
          starSize: 14,
          spacing: 4,
          ratingFontSize: 12,
          countFontSize: 11,
        );
      case StarRatingSize.standard:
        return const _SizeConfig(
          starSize: 18,
          spacing: 6,
          ratingFontSize: 14,
          countFontSize: 13,
        );
      case StarRatingSize.large:
        return const _SizeConfig(
          starSize: 28,
          spacing: 12,
          ratingFontSize: 32,
          countFontSize: 14,
        );
    }
  }
}

enum StarRatingSize { compact, standard, large }

class _SizeConfig {
  final double starSize;
  final double spacing;
  final double ratingFontSize;
  final double countFontSize;

  const _SizeConfig({
    required this.starSize,
    required this.spacing,
    required this.ratingFontSize,
    required this.countFontSize,
  });
}

/// Custom clipper for half-star effect
class _HalfStarClipper extends CustomClipper<Rect> {
  final double fillAmount;

  _HalfStarClipper(this.fillAmount);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * fillAmount, size.height);
  }

  @override
  bool shouldReclip(_HalfStarClipper oldClipper) {
    return fillAmount != oldClipper.fillAmount;
  }
}

/// Simple rating display for inline text
class InlineRating extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final double fontSize;
  final Color? color;

  const InlineRating({
    super.key,
    required this.rating,
    this.reviewCount,
    this.fontSize = 12,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = color ?? (isDark ? Colors.grey.shade300 : Colors.grey.shade700);
    final starColor = const Color(0xFFFBBF24);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          size: fontSize + 2,
          color: starColor,
        ),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        if (reviewCount != null) ...[
          Text(
            ' (${reviewCount})',
            style: TextStyle(
              fontSize: fontSize - 1,
              color: textColor.withOpacity(0.7),
            ),
          ),
        ],
      ],
    );
  }
}

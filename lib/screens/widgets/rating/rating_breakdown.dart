import 'package:flutter/material.dart';
import '../../../models/review_model.dart';
import '../../../utils/app_localization.dart';

/// Rating Breakdown Chart with animated bars
class RatingBreakdown extends StatefulWidget {
  final RatingStats stats;
  final bool animate;
  final bool compact;

  const RatingBreakdown({
    super.key,
    required this.stats,
    this.animate = true,
    this.compact = false,
  });

  @override
  State<RatingBreakdown> createState() => _RatingBreakdownState();
}

class _RatingBreakdownState extends State<RatingBreakdown>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _barAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Staggered animations for bars
    _barAnimations = List.generate(5, (index) {
      final start = index * 0.1;
      final end = start + 0.5;
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start.clamp(0, 1), end.clamp(0, 1), curve: Curves.easeOutCubic),
        ),
      );
    });

    if (widget.animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.forward();
      });
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
    final loc = AppLocalizations.of(context);

    if (widget.compact) {
      return _buildCompact(context, isDark, loc);
    }

    return _buildFull(context, isDark, loc);
  }

  Widget _buildFull(BuildContext context, bool isDark, AppLocalizations loc) {
    const starColor = Color(0xFFFBBF24);
    final primaryColor = Theme.of(context).primaryColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side: Average rating display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [Colors.grey.shade800, Colors.grey.shade900]
                  : [Colors.grey.shade50, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Large rating number
              Text(
                widget.stats.formattedRating,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              // Stars
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final fill = (widget.stats.averageRating - index).clamp(0.0, 1.0);
                  return Icon(
                    fill >= 0.5 ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 20,
                    color: fill >= 0.5 ? starColor : Colors.grey.shade400,
                  );
                }),
              ),
              const SizedBox(height: 4),
              // Review count
              Text(
                '${widget.stats.totalReviews} ${loc.t('reviews')}',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Right side: Bar chart
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              final stars = 5 - index;
              final percentage = widget.stats.getPercentage(stars);
              final count = widget.stats.getCount(stars);

              return AnimatedBuilder(
                animation: _barAnimations[index],
                builder: (context, child) {
                  return _buildBarRow(
                    stars: stars,
                    percentage: percentage,
                    count: count,
                    animationValue: _barAnimations[index].value,
                    isDark: isDark,
                    primaryColor: primaryColor,
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildCompact(BuildContext context, bool isDark, AppLocalizations loc) {
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final stars = 5 - index;
        final percentage = widget.stats.getPercentage(stars);

        return AnimatedBuilder(
          animation: _barAnimations[index],
          builder: (context, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  // Star label
                  SizedBox(
                    width: 20,
                    child: Text(
                      '$stars',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: const Color(0xFFFBBF24),
                  ),
                  const SizedBox(width: 8),
                  // Bar
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (percentage / 100) * _barAnimations[index].value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, primaryColor.withOpacity(0.7)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildBarRow({
    required int stars,
    required double percentage,
    required int count,
    required double animationValue,
    required bool isDark,
    required Color primaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Star count label
          SizedBox(
            width: 24,
            child: Row(
              children: [
                Text(
                  '$stars',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: const Color(0xFFFBBF24),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Progress bar
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(5),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth * (percentage / 100) * animationValue;
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: width,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor,
                            primaryColor.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: width > 0
                            ? [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Count
          SizedBox(
            width: 32,
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple rating summary for compact spaces
class RatingSummary extends StatelessWidget {
  final RatingStats stats;
  final bool showBreakdown;

  const RatingSummary({
    super.key,
    required this.stats,
    this.showBreakdown = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    const starColor = Color(0xFFFBBF24);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              stats.formattedRating,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade900,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    final fill = (stats.averageRating - index).clamp(0.0, 1.0);
                    return Icon(
                      fill >= 0.5 ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 16,
                      color: fill >= 0.5 ? starColor : Colors.grey.shade400,
                    );
                  }),
                ),
                Text(
                  '${stats.totalReviews} ${loc.t('reviews')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (showBreakdown) ...[
          const SizedBox(height: 16),
          RatingBreakdown(stats: stats, compact: true),
        ],
      ],
    );
  }
}

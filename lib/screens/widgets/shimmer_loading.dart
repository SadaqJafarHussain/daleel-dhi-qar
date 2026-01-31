import 'package:flutter/material.dart';

/// Modern shimmer effect for loading states
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    Key? key,
    required this.child,
    this.isLoading = true,
    this.baseColor,
    this.highlightColor,
  }) : super(key: key);

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = widget.baseColor ??
        (isDark ? Colors.grey.shade800 : Colors.grey.shade200);
    final highlightColor = widget.highlightColor ??
        (isDark ? Colors.grey.shade700 : Colors.grey.shade100);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                0.0,
                0.5 + _animation.value * 0.25,
                1.0,
              ],
              transform: _SlidingGradientTransform(_animation.value),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

/// Skeleton box for placeholder content
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsets? margin;

  const SkeletonBox({
    Key? key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton for service card
class ServiceCardSkeleton extends StatelessWidget {
  final double width;
  final double height;

  const ServiceCardSkeleton({
    Key? key,
    this.width = 280,
    this.height = 220,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: width,
          height: height,
          color: Theme.of(context).cardColor,
          child: Stack(
            children: [
              // Image placeholder - top 45%
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: height * 0.45,
                child: SkeletonBox(
                  width: double.infinity,
                  height: height * 0.45,
                  borderRadius: 0,
                ),
              ),
              // Content section - use individual positioned elements
              // Title
              Positioned(
                top: height * 0.45 + 10,
                left: 10,
                right: 10,
                child: SkeletonBox(
                  width: width * 0.7,
                  height: 12,
                  borderRadius: 4,
                ),
              ),
              // Subtitle
              Positioned(
                top: height * 0.45 + 30,
                left: 10,
                right: 10,
                child: SkeletonBox(
                  width: width * 0.5,
                  height: 10,
                  borderRadius: 4,
                ),
              ),
              // Bottom row - distance badge
              Positioned(
                bottom: 10,
                left: 10,
                child: SkeletonBox(
                  width: 55,
                  height: 20,
                  borderRadius: 10,
                ),
              ),
              // Bottom row - action button
              Positioned(
                bottom: 10,
                right: 10,
                child: SkeletonBox(
                  width: 24,
                  height: 24,
                  borderRadius: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for category item
class CategorySkeleton extends StatelessWidget {
  final double size;

  const CategorySkeleton({Key? key, this.size = 80}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: [
          SkeletonBox(
            width: size,
            height: size,
            borderRadius: 16,
          ),
          const SizedBox(height: 8),
          SkeletonBox(
            width: size * 0.8,
            height: 12,
            borderRadius: 4,
          ),
        ],
      ),
    );
  }
}

/// Skeleton for list item
class ListItemSkeleton extends StatelessWidget {
  final double height;

  const ListItemSkeleton({Key? key, this.height = 100}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        height: height,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).cardColor,
        ),
        child: Row(
          children: [
            // Image
            SkeletonBox(
              width: height - 24,
              height: height - 24,
              borderRadius: 12,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SkeletonBox(
                    width: double.infinity,
                    height: 16,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 8),
                  SkeletonBox(
                    width: 120,
                    height: 12,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SkeletonBox(
                        width: 60,
                        height: 20,
                        borderRadius: 10,
                      ),
                      const Spacer(),
                      SkeletonBox(
                        width: 80,
                        height: 20,
                        borderRadius: 10,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for banner/ad
class BannerSkeleton extends StatelessWidget {
  final double height;

  const BannerSkeleton({Key? key, this.height = 180}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: SkeletonBox(
        width: double.infinity,
        height: height,
        borderRadius: 16,
      ),
    );
  }
}

/// Horizontal list of skeleton cards
class HorizontalSkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemWidth;
  final double itemHeight;
  final double spacing;
  final EdgeInsets padding;

  const HorizontalSkeletonList({
    Key? key,
    this.itemCount = 3,
    this.itemWidth = 280,
    this.itemHeight = 200,
    this.spacing = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: spacing),
            child: ServiceCardSkeleton(
              width: itemWidth,
              height: itemHeight,
            ),
          );
        },
      ),
    );
  }
}

/// Vertical list of skeleton items
class VerticalSkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double spacing;
  final EdgeInsets padding;

  const VerticalSkeletonList({
    Key? key,
    this.itemCount = 5,
    this.itemHeight = 100,
    this.spacing = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: ListItemSkeleton(height: itemHeight),
        );
      },
    );
  }
}

/// Horizontal category skeleton list
class CategorySkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemSize;
  final double spacing;
  final EdgeInsets padding;

  const CategorySkeletonList({
    Key? key,
    this.itemCount = 5,
    this.itemSize = 80,
    this.spacing = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemSize + 28,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: spacing),
            child: CategorySkeleton(size: itemSize),
          );
        },
      ),
    );
  }
}

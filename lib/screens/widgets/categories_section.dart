import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tour_guid/utils/app_localization.dart';
import 'package:tour_guid/utils/app_icons.dart';
import '../../models/category.dart' as cat_model;
import '../../providers/category_provider.dart';
import '../../utils/page_transitions.dart';
import '../all_categories_screen.dart';
import '../services_screen.dart';
import 'section_header.dart';
import 'shimmer_loading.dart';

class CategoriesSection extends StatefulWidget {
  final double width;
  final double height;

  const CategoriesSection({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  State<CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<CategoriesSection> {
  // Modern gradient color pairs for categories
  List<List<Color>> _getCategoryGradients() {
    return [
      [const Color(0xFF667EEA), const Color(0xFF764BA2)], // Purple-Blue
      [const Color(0xFFF093FB), const Color(0xFFF5576C)], // Pink-Red
      [const Color(0xFF4FACFE), const Color(0xFF00F2FE)], // Blue-Cyan
      [const Color(0xFF43E97B), const Color(0xFF38F9D7)], // Green-Teal
      [const Color(0xFFFA709A), const Color(0xFFFEE140)], // Pink-Yellow
      [const Color(0xFF30CFD0), const Color(0xFF330867)], // Teal-Purple
      [const Color(0xFFF5AF19), const Color(0xFFF12711)], // Orange-Red
      [const Color(0xFF11998E), const Color(0xFF38EF7D)], // Teal-Green
    ];
  }

  IconData _getCategoryIcon(int index) {
    final icons = [
      Icons.restaurant_rounded,
      Icons.hotel_rounded,
      Icons.shopping_bag_rounded,
      Icons.local_hospital_rounded,
      Icons.school_rounded,
      Icons.sports_soccer_rounded,
      Icons.spa_rounded,
      Icons.local_gas_station_rounded,
    ];
    return icons[index % icons.length];
  }

  @override
  void initState() {
    super.initState();
    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      categoryProvider.init(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final w = widget.width;

    // Fixed sizes - vertical layout with icon on top, name below
    const double iconSize = 60.0;
    const double sectionHeight = 115.0; // icon + spacing + 2 lines of text

    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, _) {
        final categories = categoryProvider.categories;

        // Loading state with skeleton
        if (categoryProvider.isLoading && categories.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.045),
                  child: SectionHeader(
                    title: loc.t("categories_title"),
                    onTap: () {},
                  ),
                ),
                const SizedBox(height: 12),
                CategorySkeletonList(
                  itemCount: 5,
                  itemSize: iconSize,
                  padding: EdgeInsets.symmetric(horizontal: w * 0.045),
                ),
              ],
            ),
          );
        }

        if (categories.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.045),
            child: _buildEmptyState(context, loc),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.045),
                child: SectionHeader(
                  title: loc.t("categories_title"),
                  onTap: () {
                    Navigator.push(
                      context,
                      PageTransitions.slideRight(
                        page: const AllCategoriesScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: sectionHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: categories.length,
                  padding: EdgeInsets.symmetric(horizontal: w * 0.045),
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final gradients = _getCategoryGradients();
                    final gradient = gradients[index % gradients.length];
                    return _buildCategoryItem(
                      context,
                      category,
                      gradient,
                      index,
                      iconSize,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          AppIcon.circle(
            icon: Icons.category_outlined,
            color: Colors.grey.shade400,
            size: AppIconSize.xl,
            containerSize: AppIconContainerSize.xl,
          ),
          const SizedBox(height: 12),
          Text(
            loc.t("no_categories_found"),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    cat_model.Category category,
    List<Color> gradient,
    int index,
    double iconSize,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          PageTransitions.scaleUp(
            page: ServicesScreen.fromCategory(
              categoryId: category.id,
              categoryName: category.name,
            ),
          ),
        );
      },
      child: SizedBox(
        width: 80, // Fixed width to accommodate full names
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category icon container
            AppIcon.gradient(
              icon: _getCategoryIcon(index),
              colors: gradient,
              size: iconSize * 0.45,
              containerSize: iconSize,
              borderRadius: 18,
              shadow: [
                BoxShadow(
                  color: gradient[0].withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Category name - full text with wrapping
            SizedBox(
              width: 80,
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF2D3748),
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

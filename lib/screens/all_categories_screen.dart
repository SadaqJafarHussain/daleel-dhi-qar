import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guid/screens/services_screen.dart';
import 'package:tour_guid/utils/app_icons.dart';
import 'package:tour_guid/utils/app_localization.dart';
import '../../models/category.dart' as cat_model;
import '../../providers/category_provider.dart';
import '../../providers/language_provider.dart';

class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({super.key});

  Color _getColorForIndex(int index) {
    final colors = [
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFF10B981), // Green
      const Color(0xFFEC4899), // Pink
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF14B8A6), // Teal
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final categories = categoryProvider.categories;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AppBackButton.light(),
        ),
        title: Text(loc.t("categories_title")),
        centerTitle: true,
      ),
      body: SafeArea(
        child: categoryProvider.isLoading && categories.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : categories.isEmpty
            ? Center(
          child: Text(
            loc.t("no_categories_found"),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        )
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            itemCount: categories.length,
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Two items per row
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final category = categories[index];
              final color = _getColorForIndex(index);
              return _buildCategoryCard(context, category, color);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(String icon, Color color) {
    final isUrl = icon.startsWith('http://') || icon.startsWith('https://');
    if (isUrl) {
      return CachedNetworkImage(
        imageUrl: icon,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: color.withOpacity(0.08)),
        errorWidget: (_, __, ___) => _iconFallback(color),
      );
    } else if (icon.isNotEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: color.withOpacity(0.08),
        child: Center(child: Text(icon, style: const TextStyle(fontSize: 40))),
      );
    } else {
      return _iconFallback(color);
    }
  }

  Widget _iconFallback(Color color) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: color.withOpacity(0.08),
      child: Center(
        child: Icon(Icons.category_rounded, color: color.withOpacity(0.5), size: 36),
      ),
    );
  }

  Widget _buildCategoryCard(
      BuildContext context,
      cat_model.Category category,
      Color color,
      ) {
    final isAr = context.read<LanguageProvider>().isArabic;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServicesScreen.fromCategory(
              categoryId: category.id,
              categoryName: category.localizedName(isAr),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildCategoryIcon(category.icon, color),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Text(
                category.localizedName(isAr),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
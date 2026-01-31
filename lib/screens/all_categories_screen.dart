import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tour_guid/screens/services_screen.dart';
import 'package:tour_guid/screens/widgets/service_image_widget.dart';
import 'package:tour_guid/utils/app_icons.dart';
import 'package:tour_guid/utils/app_localization.dart';
import '../../models/category.dart' as cat_model;
import '../../providers/category_provider.dart';

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

  Widget _buildCategoryCard(
      BuildContext context,
      cat_model.Category category,
      Color color,
      ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServicesScreen.fromCategory(
              categoryId: category.id,
              categoryName: category.name,
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
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: ServiceImageWidget(
                    imageUrl: category.image,
                    fit: BoxFit.fill,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Text(
                category.name,
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
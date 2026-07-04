import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/adds_model.dart';
import '../../models/category.dart' as cat_model;
import '../../models/home_section_model.dart';
import '../../models/service_model.dart';
import '../../models/subcategory_model.dart';
import '../../providers/ads_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/home_sections_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/service_peovider.dart';
import '../../providers/subcategory_provider.dart';
import '../../utils/app_localization.dart';
import '../service_details_screen.dart';
import '../services_screen.dart';

/// Renders all active admin-configured home sections from the DB.
class HomeSectionsWidget extends StatefulWidget {
  final double width;
  final double height;

  const HomeSectionsWidget({super.key, required this.width, required this.height});

  @override
  State<HomeSectionsWidget> createState() => _HomeSectionsWidgetState();
}

class _HomeSectionsWidgetState extends State<HomeSectionsWidget> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        Provider.of<HomeSectionsProvider>(context, listen: false).fetchSections();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeSectionsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.sections.isEmpty) {
          return _buildShimmer();
        }
        if (provider.sections.isEmpty) return const SizedBox.shrink();

        return Column(
          children: provider.sections.map((section) {
            return _DynamicSectionItem(
              section: section,
              width: widget.width,
              height: widget.height,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.width * 0.045, vertical: 12),
      child: Column(
        children: List.generate(3, (_) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 64,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
        )),
      ),
    );
  }
}

// ─── Single section ──────────────────────────────────────────────────────────

class _DynamicSectionItem extends StatelessWidget {
  final HomeSection section;
  final double width;
  final double height;

  const _DynamicSectionItem({
    required this.section,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<LanguageProvider>().isArabic;
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = _resolveItems(context);
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(width * 0.045, 0, width * 0.045, height * 0.015),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          _SectionHeader(section: section, isAr: isAr),
          const SizedBox(height: 12),
          // Items
          ...items.map((item) => _buildItem(context, item, isAr, isDark)),
        ],
      ),
    );
  }

  List<_SectionItem> _resolveItems(BuildContext context) {
    final isAr = context.read<LanguageProvider>().isArabic;
    final ids = section.itemIds;
    final max = section.maxItems;

    switch (section.contentType) {
      case 'categories':
        final cats = context.watch<CategoryProvider>().categories;
        final filtered = ids.isEmpty
            ? cats
            : cats.where((c) => ids.contains(c.id)).toList();
        return filtered.take(max).map((c) => _SectionItem(
          id: c.id,
          name: c.localizedName(isAr),
          imageUrl: c.icon,
          type: 'category',
          data: c,
        )).toList();

      case 'subcategories':
        final subs = context.watch<SubcategoryProvider>().subcategories;
        final filtered = ids.isEmpty
            ? subs
            : subs.where((s) => ids.contains(s.id)).toList();
        return filtered.take(max).map((s) => _SectionItem(
          id: s.id,
          name: s.localizedName(isAr),
          imageUrl: s.image,
          type: 'subcategory',
          data: s,
        )).toList();

      case 'services':
        final svcs = context.watch<ServiceProvider>().services;
        final filtered = ids.isEmpty
            ? svcs
            : svcs.where((s) => ids.contains(s.id)).toList();
        return filtered.take(max).map((s) => _SectionItem(
          id: s.id,
          name: s.title,
          imageUrl: s.imageUrl.isNotEmpty ? s.imageUrl : null,
          type: 'service',
          data: s,
        )).toList();

      case 'ads':
        final ads = context.watch<AdvProvider>().ads;
        final filtered = ids.isEmpty
            ? ads
            : ads.where((a) => ids.contains(a.id)).toList();
        return filtered.take(max).map((a) => _SectionItem(
          id: a.id,
          name: a.title,
          imageUrl: a.image,
          type: 'ad',
          data: a,
        )).toList();

      default:
        return [];
    }
  }

  Widget _buildItem(BuildContext context, _SectionItem item, bool isAr, bool isDark) {
    return GestureDetector(
      onTap: () => _handleTap(context, item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 56,
                height: 56,
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _placeholder(context),
                        placeholder: (_, __) => _placeholder(context),
                      )
                    : _placeholder(context),
              ),
            ),
            const SizedBox(width: 12),
            // Name
            Expanded(
              child: Text(
                item.name,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.08),
      child: Icon(
        HomeSectionIcons.decode(section.icon),
        color: Theme.of(context).primaryColor.withOpacity(0.4),
        size: 24,
      ),
    );
  }

  void _handleTap(BuildContext context, _SectionItem item) {
    switch (item.type) {
      case 'category':
        final cat = item.data as cat_model.Category;
        final isAr = context.read<LanguageProvider>().isArabic;
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ServicesScreen.fromCategory(
            categoryId: cat.id,
            categoryName: cat.localizedName(isAr),
          ),
        ));
        break;

      case 'subcategory':
        final sub = item.data as Subcategory;
        final isAr = context.read<LanguageProvider>().isArabic;
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ServicesScreen.fromSubcategory(
            subcategoryId: sub.id,
            subcategoryName: sub.localizedName(isAr),
            parentCategoryId: sub.catId,
          ),
        ));
        break;

      case 'service':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ServiceDetailsScreen(service: item.data as Service),
        ));
        break;

      case 'ad':
        // ads handled by banner; tapping here navigates to service if available
        final ad = item.data as AdvModel;
        if (ad.serviceId != null) {
          final svc = context.read<ServiceProvider>().services
              .where((s) => s.id == ad.serviceId).firstOrNull;
          if (svc != null) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => ServiceDetailsScreen(service: svc),
            ));
          }
        }
        break;
    }
  }
}

// ─── Section header row ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final HomeSection section;
  final bool isAr;

  const _SectionHeader({required this.section, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;

    return Row(
      children: [
        // Icon badge
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, primary.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            HomeSectionIcons.decode(section.icon),
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            section.localizedTitle(isAr),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Internal data class ──────────────────────────────────────────────────────

class _SectionItem {
  final int id;
  final String name;
  final String? imageUrl;
  final String type;
  final dynamic data;

  _SectionItem({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.type,
    required this.data,
  });
}

import 'package:flutter/material.dart';

class HomeSection {
  final int id;
  final String titleAr;
  final String titleEn;
  final String icon;
  final String contentType; // 'categories' | 'subcategories' | 'services' | 'ads'
  final List<int> itemIds;  // empty = show all
  final int maxItems;
  final int sortOrder;
  final bool active;

  HomeSection({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.icon,
    required this.contentType,
    required this.itemIds,
    required this.maxItems,
    required this.sortOrder,
    required this.active,
  });

  factory HomeSection.fromJson(Map<String, dynamic> json) {
    final rawIds = json['item_ids'];
    List<int> ids = [];
    if (rawIds is List) {
      ids = rawIds.map((e) => int.tryParse(e.toString()) ?? 0).where((e) => e > 0).toList();
    }

    return HomeSection(
      id: json['id'] as int,
      titleAr: json['title_ar'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      icon: json['icon'] as String? ?? 'star',
      contentType: json['content_type'] as String? ?? 'subcategories',
      itemIds: ids,
      maxItems: json['max_items'] as int? ?? 10,
      sortOrder: json['sort_order'] as int? ?? 0,
      active: json['active'] == true,
    );
  }

  String localizedTitle(bool isAr) =>
      isAr ? titleAr : (titleEn.isNotEmpty ? titleEn : titleAr);
}

/// Maps admin icon key strings → Flutter IconData
class HomeSectionIcons {
  static IconData decode(String key) {
    return _map[key] ?? Icons.star_rounded;
  }

  static const Map<String, IconData> _map = {
    'star':          Icons.star_rounded,
    'premium':       Icons.workspace_premium_rounded,
    'category':      Icons.category_rounded,
    'tag':           Icons.local_offer_rounded,
    'store':         Icons.storefront_rounded,
    'restaurant':    Icons.restaurant_rounded,
    'hotel':         Icons.hotel_rounded,
    'car':           Icons.directions_car_rounded,
    'hospital':      Icons.local_hospital_rounded,
    'school':        Icons.school_rounded,
    'shop':          Icons.shopping_bag_rounded,
    'museum':        Icons.museum_rounded,
    'park':          Icons.park_rounded,
    'business':      Icons.business_rounded,
    'verified':      Icons.verified_rounded,
    'explore':       Icons.explore_rounded,
    'favorite':      Icons.favorite_rounded,
    'flash':         Icons.flash_on_rounded,
    'trending':      Icons.trending_up_rounded,
    'new_release':   Icons.new_releases_rounded,
    'local_activity':Icons.local_activity_rounded,
    'sports':        Icons.sports_rounded,
    'fitness':       Icons.fitness_center_rounded,
    'spa':           Icons.spa_rounded,
    'home':          Icons.home_rounded,
    'layers':        Icons.layers_rounded,
  };

  static const List<Map<String, String>> options = [
    {'key': 'star',           'label': 'نجمة'},
    {'key': 'premium',        'label': 'متميز'},
    {'key': 'category',       'label': 'فئة'},
    {'key': 'tag',            'label': 'عرض'},
    {'key': 'store',          'label': 'متجر'},
    {'key': 'restaurant',     'label': 'مطعم'},
    {'key': 'hotel',          'label': 'فندق'},
    {'key': 'car',            'label': 'سيارة'},
    {'key': 'hospital',       'label': 'مستشفى'},
    {'key': 'school',         'label': 'تعليم'},
    {'key': 'shop',           'label': 'تسوق'},
    {'key': 'museum',         'label': 'متحف'},
    {'key': 'park',           'label': 'حديقة'},
    {'key': 'business',       'label': 'أعمال'},
    {'key': 'verified',       'label': 'موثوق'},
    {'key': 'explore',        'label': 'استكشاف'},
    {'key': 'favorite',       'label': 'مفضلة'},
    {'key': 'flash',          'label': 'عروض'},
    {'key': 'trending',       'label': 'رائج'},
    {'key': 'new_release',    'label': 'جديد'},
    {'key': 'local_activity', 'label': 'نشاط'},
    {'key': 'sports',         'label': 'رياضة'},
    {'key': 'fitness',        'label': 'لياقة'},
    {'key': 'spa',            'label': 'سبا'},
    {'key': 'home',           'label': 'منزل'},
    {'key': 'layers',         'label': 'متنوع'},
  ];
}

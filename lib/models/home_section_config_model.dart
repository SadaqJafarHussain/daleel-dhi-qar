class HomeSectionConfig {
  final String key;
  final String titleAr;
  final String titleEn;
  final bool visible;
  final int sortOrder;

  const HomeSectionConfig({
    required this.key,
    required this.titleAr,
    required this.titleEn,
    required this.visible,
    required this.sortOrder,
  });

  factory HomeSectionConfig.fromJson(Map<String, dynamic> json) {
    return HomeSectionConfig(
      key:       json['key']        as String,
      titleAr:   json['title_ar']   as String? ?? '',
      titleEn:   json['title_en']   as String? ?? '',
      visible:   json['visible']    as bool?   ?? true,
      sortOrder: json['sort_order'] as int?    ?? 0,
    );
  }

  String localizedTitle(bool isAr) =>
      isAr ? titleAr : (titleEn.isNotEmpty ? titleEn : titleAr);
}

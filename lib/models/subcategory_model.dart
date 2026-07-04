class Subcategory {
  final int id;
  final int catId;
  final String name;
  final String nameAr;
  final String nameEn;
  final bool active;
  final String image;

  Subcategory({
    required this.id,
    required this.catId,
    required this.name,
    required this.nameAr,
    required this.nameEn,
    required this.active,
    required this.image,
  });

  String localizedName(bool isAr) {
    if (isAr) return nameAr.isNotEmpty ? nameAr : name;
    return nameEn.isNotEmpty ? nameEn : name;
  }

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    // Handle active field - can be bool, String, or int
    bool parseActive(dynamic value) {
      if (value == null) return true;
      if (value is bool) return value;
      if (value is String) return value == '1' || value.toLowerCase() == 'true';
      if (value is int) return value == 1;
      return true;
    }

    final nameAr = (json['name_ar'] as String?)?.trim() ?? '';
    final nameEn = (json['name_en'] as String?)?.trim() ?? '';
    final name = (json['name'] as String?)?.trim() ?? '';

    return Subcategory(
      id: json['id'] ?? 0,
      catId: json['cat_id'] ?? 0,
      name: name,
      nameAr: nameAr.isNotEmpty ? nameAr : name,
      nameEn: nameEn.isNotEmpty ? nameEn : name,
      active: parseActive(json['active']),
      image: json['image'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cat_id': catId,
      'name': name,
      'name_ar': nameAr,
      'name_en': nameEn,
      'active': active,
      'image': image,
    };
  }
}
class Category {
  final int id;
  final String name;
  final String nameAr;
  final String nameEn;
  final String icon;
  final bool active;

  Category({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.nameEn,
    required this.icon,
    required this.active,
  });

  String localizedName(bool isAr) {
    if (isAr) return nameAr.isNotEmpty ? nameAr : name;
    return nameEn.isNotEmpty ? nameEn : name;
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    final nameAr = (json['name_ar'] as String?)?.trim() ?? '';
    final nameEn = (json['name_en'] as String?)?.trim() ?? '';
    final name = (json['name'] as String?)?.trim() ?? '';
    return Category(
      id: json['id'],
      name: name,
      nameAr: nameAr.isNotEmpty ? nameAr : name,
      nameEn: nameEn.isNotEmpty ? nameEn : name,
      icon: json['icon'] ?? '',
      active: json['active'] == true || json['active'] == 1 || json['active'] == '1',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'name_ar': nameAr,
    'name_en': nameEn,
    'icon': icon,
    'active': active ? '1' : '0',
  };
}
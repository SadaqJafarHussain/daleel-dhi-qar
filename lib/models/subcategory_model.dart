class Subcategory {
  final int id;
  final int catId;
  final String name;
  final bool active;
  final String image;

  Subcategory({
    required this.id,
    required this.catId,
    required this.name,
    required this.active,
    required this.image,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    // Handle active field - can be bool, String, or int
    bool parseActive(dynamic value) {
      if (value == null) return true;
      if (value is bool) return value;
      if (value is String) return value == '1' || value.toLowerCase() == 'true';
      if (value is int) return value == 1;
      return true;
    }

    return Subcategory(
      id: json['id'] ?? 0,
      catId: json['cat_id'] ?? 0,
      name: json['name'] ?? '',
      active: parseActive(json['active']),
      image: json['image'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cat_id': catId,
      'name': name,
      'active': active,
      'image': image,
    };
  }
}
class Category {
  final int id;
  final String name;
  final String image;
  final bool active;

  Category({
    required this.id,
    required this.name,
    required this.image,
    required this.active,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      active: json['active'] == '1',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'image': image,
    'active': active ? '1' : '0',
  };
}
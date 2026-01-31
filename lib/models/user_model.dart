// ============================================
// User Model
// Location: lib/models/user_model.dart
// ============================================

enum Gender { male, female}

enum AgeGroup {
  under18,      // أقل من 18
  age18to24,    // 18-24
  age25to34,    // 25-34
  age35to44,    // 35-44
  age45to54,    // 45-54
  age55plus,    // 55+
  notSpecified
}

class UserModel {
  final int id;
  final String name;
  final String phone;
  final String role;
  final String active;

  // New profile fields for ad targeting
  final Gender? gender;
  final DateTime? birthDate;
  final String? city;
  final List<String>? interests;  // e.g., ['restaurants', 'hotels', 'tourism']
  final String? occupation;
  final String? avatarUrl;
  final bool profileCompleted;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.active,
    this.gender,
    this.birthDate,
    this.city,
    this.interests,
    this.occupation,
    this.avatarUrl,
    this.profileCompleted = false,
  });

  // Calculate age from birthDate
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  // Get age group for ad targeting
  AgeGroup get ageGroup {
    final userAge = age;
    if (userAge == null) return AgeGroup.notSpecified;
    if (userAge < 18) return AgeGroup.under18;
    if (userAge <= 24) return AgeGroup.age18to24;
    if (userAge <= 34) return AgeGroup.age25to34;
    if (userAge <= 44) return AgeGroup.age35to44;
    if (userAge <= 54) return AgeGroup.age45to54;
    return AgeGroup.age55plus;
  }

  // Factory constructor to create User from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'user',
      active: json['active']?.toString() ?? '1',
      gender: _parseGender(json['gender']),
      birthDate: json['birth_date'] != null
          ? DateTime.tryParse(json['birth_date'].toString())
          : null,
      city: json['city'],
      interests: json['interests'] != null
          ? List<String>.from(json['interests'])
          : null,
      occupation: json['occupation'],
      avatarUrl: json['avatar_url'],
      profileCompleted: json['profile_completed'] == true ||
                        json['profile_completed'] == 1 ||
                        json['profile_completed'] == '1',
    );
  }

  // Parse gender from string/int
  static Gender? _parseGender(dynamic value) {
    if (value == null) return null;
    final str = value.toString().toLowerCase();
    switch (str) {
      case 'male':
      case '0':
        return Gender.male;
      case 'female':
      case '1':
        return Gender.female;
      case 'other':
      case '2':
      default:
        return Gender.male;
    }
  }

  // Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role,
      'active': active,
      'gender': gender?.name,
      'birth_date': birthDate?.toIso8601String().split('T').first,
      'city': city,
      'interests': interests,
      'occupation': occupation,
      'avatar_url': avatarUrl,
      'profile_completed': profileCompleted,
    };
  }

  // Check if user is active
  bool get isActive => active == '1' || active == 'true';

  // Check if user is admin
  bool get isAdmin => role.toLowerCase() == 'admin';

  // Check if profile needs completion
  bool get needsProfileCompletion => !profileCompleted;

  // Copy with method for updating user data
  UserModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? role,
    String? active,
    Gender? gender,
    DateTime? birthDate,
    String? city,
    List<String>? interests,
    String? occupation,
    String? avatarUrl,
    bool? profileCompleted,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      active: active ?? this.active,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      city: city ?? this.city,
      interests: interests ?? this.interests,
      occupation: occupation ?? this.occupation,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      profileCompleted: profileCompleted ?? this.profileCompleted,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, phone: $phone, role: $role, active: $active, gender: $gender, age: $age, city: $city, profileCompleted: $profileCompleted)';
  }
}

// Extension for Gender display names - use localization keys
extension GenderExtension on Gender {
  /// Returns the localization key for this gender
  String get localizationKey {
    switch (this) {
      case Gender.male:
        return 'male';
      case Gender.female:
        return 'female';
    }
  }
}

// Extension for AgeGroup display names - use localization keys
extension AgeGroupExtension on AgeGroup {
  /// Returns the localization key for this age group
  String get localizationKey {
    switch (this) {
      case AgeGroup.under18:
        return 'age_under_18';
      case AgeGroup.age18to24:
        return 'age_18_24';
      case AgeGroup.age25to34:
        return 'age_25_34';
      case AgeGroup.age35to44:
        return 'age_35_44';
      case AgeGroup.age45to54:
        return 'age_45_54';
      case AgeGroup.age55plus:
        return 'age_55_plus';
      case AgeGroup.notSpecified:
        return 'age_not_specified';
    }
  }
}

/// Simple User class for Supabase auth compatibility
class User {
  final int id;
  final String name;
  final String phone;
  final String? gender;
  final String? birthDate;
  final String? city;
  final List<String>? interests;
  final String? occupation;
  final String? avatarUrl;
  final String? createdAt;

  User({
    required this.id,
    required this.name,
    required this.phone,
    this.gender,
    this.birthDate,
    this.city,
    this.interests,
    this.occupation,
    this.avatarUrl,
    this.createdAt,
  });

  /// Convert to UserModel for app compatibility
  UserModel toUserModel() {
    return UserModel(
      id: id,
      name: name,
      phone: phone,
      role: 'user',
      active: '1',
      gender: gender != null ? (gender == 'male' ? Gender.male : Gender.female) : null,
      birthDate: birthDate != null ? DateTime.tryParse(birthDate!) : null,
      city: city,
      interests: interests,
      occupation: occupation,
      avatarUrl: avatarUrl,
      profileCompleted: gender != null && city != null && birthDate != null,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      gender: json['gender'],
      birthDate: json['birth_date'],
      city: json['city'],
      interests: json['interests'] != null ? List<String>.from(json['interests']) : null,
      occupation: json['occupation'],
      avatarUrl: json['avatar_url'],
      createdAt: json['created_at'],
    );
  }
}

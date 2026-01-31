class Service {
  final int id;
  final int userId;
  final String? supabaseUserId; // UUID from Supabase
  final String userName;
  final String? userAvatarUrl; // Owner's avatar URL from profiles
  final int catId;
  final String catName;
  final int subcatId;
  final String subcatName;
  final String title;
  final String description;
  final String phone;
  final String address;
  final double lat;
  final double lng;
  final String active;
  final String createdAt;
  List<ServiceFile> files;
  final String? facebook;
  final String? instagram;
  final String? whatsapp;
  final String? telegram;
  double? distance; // dynamically calculated for nearby services

  // Rating fields
  final double? averageRating;
  final int? totalReviews;

  // Working hours fields
  final String? openTime;      // Format: "HH:mm" (e.g., "09:00")
  final String? closeTime;     // Format: "HH:mm" (e.g., "22:00")
  final String? workDays;      // Format: comma-separated days "0,1,2,3,4,5,6" (0=Sunday)
  final bool? isManualOverride; // If true, use 'active' directly; if false, calculate
  final bool? isOpen24Hours;   // If true, always open

  // Owner verification status (from profiles table)
  final bool isOwnerVerified;

  // Favorites count
  final int favoritesCount;

  Service({
    required this.id,
    required this.userId,
    this.supabaseUserId,
    required this.userName,
    this.userAvatarUrl,
    required this.catId,
    required this.catName,
    required this.subcatId,
    required this.subcatName,
    required this.title,
    required this.description,
    required this.phone,
    required this.address,
    required this.lat,
    required this.lng,
    required this.active,
    required this.createdAt,
    required this.files,
    this.facebook,
    this.instagram,
    this.whatsapp,
    this.telegram,
    this.distance,
    this.averageRating,
    this.totalReviews,
    this.openTime,
    this.closeTime,
    this.workDays,
    this.isManualOverride,
    this.isOpen24Hours,
    this.isOwnerVerified = false,
    this.favoritesCount = 0,
  });

  /// Check if the service is currently open based on working hours
  bool get isCurrentlyOpen {
    // If manual override is enabled, use the active field directly
    if (isManualOverride == true) {
      return active == '1';
    }

    // If open 24 hours, always open
    if (isOpen24Hours == true) {
      return true;
    }

    // If no working hours set, default to active field
    if (openTime == null || closeTime == null || workDays == null) {
      return active == '1';
    }

    final now = DateTime.now();
    final currentDay = now.weekday % 7; // Convert to 0=Sunday format

    // Check if today is a work day
    final workDaysList = workDays!.split(',').map((d) => int.tryParse(d.trim()) ?? -1).toList();
    if (!workDaysList.contains(currentDay)) {
      return false;
    }

    // Parse open and close times
    final openParts = openTime!.split(':');
    final closeParts = closeTime!.split(':');

    if (openParts.length < 2 || closeParts.length < 2) {
      return active == '1';
    }

    final openHour = int.tryParse(openParts[0]) ?? 0;
    final openMinute = int.tryParse(openParts[1]) ?? 0;
    final closeHour = int.tryParse(closeParts[0]) ?? 23;
    final closeMinute = int.tryParse(closeParts[1]) ?? 59;

    final openDateTime = DateTime(now.year, now.month, now.day, openHour, openMinute);
    var closeDateTime = DateTime(now.year, now.month, now.day, closeHour, closeMinute);

    // Handle overnight hours (e.g., 22:00 - 02:00)
    if (closeDateTime.isBefore(openDateTime)) {
      closeDateTime = closeDateTime.add(const Duration(days: 1));
    }

    return now.isAfter(openDateTime) && now.isBefore(closeDateTime);
  }

  /// Get formatted working hours string
  String get workingHoursDisplay {
    if (isOpen24Hours == true) {
      return '24/7';
    }
    if (openTime == null || closeTime == null) {
      return '';
    }
    return '$openTime - $closeTime';
  }

  /// Get work days as list of day indices
  List<int> get workDaysList {
    if (workDays == null || workDays!.isEmpty) {
      return [];
    }
    return workDays!.split(',').map((d) => int.tryParse(d.trim()) ?? -1).where((d) => d >= 0 && d <= 6).toList();
  }

  factory Service.fromJson(Map<String, dynamic> json) {
    // Parse files from multiple sources
    List<ServiceFile> parsedFiles = [];

    // 1. Try 'file' array (from legacy API)
    if (json['file'] is List && (json['file'] as List).isNotEmpty) {
      parsedFiles = (json['file'] as List)
          .map((file) => ServiceFile.fromJson(file))
          .toList();
    }
    // 2. Try 'service_files' array (from Supabase join)
    else if (json['service_files'] is List && (json['service_files'] as List).isNotEmpty) {
      parsedFiles = (json['service_files'] as List)
          .map((file) => ServiceFile.fromJson(file))
          .toList();
    }
    // 3. Try direct 'image_url' field (simple Supabase column)
    else if (json['image_url'] != null && json['image_url'].toString().isNotEmpty) {
      parsedFiles = [
        ServiceFile(
          id: 0,
          file: '',
          url: json['image_url'].toString(),
          serviceId: int.tryParse(json['id'].toString()) ?? 0,
        ),
      ];
    }
    // 4. Try 'image' field (alternative naming)
    else if (json['image'] != null && json['image'].toString().isNotEmpty) {
      parsedFiles = [
        ServiceFile(
          id: 0,
          file: '',
          url: json['image'].toString(),
          serviceId: int.tryParse(json['id'].toString()) ?? 0,
        ),
      ];
    }

    // Store original user_id as string for UUID comparison
    final rawUserId = json['user_id']?.toString() ?? '';

    // Extract user name, avatar, and verification status from profiles join or direct field
    String userName = '';
    String? userAvatarUrl;
    bool isOwnerVerified = false;
    if (json['profiles'] != null && json['profiles'] is Map) {
      userName = json['profiles']['name'] ?? '';
      userAvatarUrl = json['profiles']['avatar_url'];
      isOwnerVerified = json['profiles']['is_verified'] == true || json['profiles']['is_verified'] == 1;
    } else if (json['user_name'] != null) {
      userName = json['user_name'];
      userAvatarUrl = json['user_avatar_url'];
      isOwnerVerified = json['is_owner_verified'] == true || json['is_owner_verified'] == 1;
    }

    return Service(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: int.tryParse(rawUserId) ?? 0,
      supabaseUserId: rawUserId.isNotEmpty ? rawUserId : null,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      catId: int.tryParse(json['cat_id'].toString()) ?? 0,
      catName: json['cat_name'] ?? '',
      subcatId: int.tryParse((json['subcat_id'] ?? json['sub_cat_id'] ?? '0').toString()) ?? 0,
      subcatName: json['subcat_name'] ?? '',
      title: json['title'] ?? json['name'] ?? '',
      description: json['description'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      lat: double.tryParse(json['lat'].toString()) ?? 0.0,
      lng: double.tryParse(json['lng'].toString()) ?? 0.0,
      active: (json['active'] == true || json['active'] == 1 || json['active'] == '1' || json['active'] == 'true') ? '1' : '0',
      createdAt: json['created_at'] ?? '',
      facebook: json['facebook'],
      instagram: json['instagram'],
      whatsapp: json['whatsapp'],
      telegram: json['telegram'],
      files: parsedFiles,
      averageRating: json['average_rating'] != null
          ? double.tryParse(json['average_rating'].toString())
          : null,
      totalReviews: json['total_reviews'] != null
          ? int.tryParse(json['total_reviews'].toString())
          : null,
      openTime: json['open_time'],
      closeTime: json['close_time'],
      workDays: json['work_days'] is List
          ? (json['work_days'] as List).map((e) => e.toString()).join(',')
          : json['work_days'],
      isManualOverride: json['is_manual_override'] == 1 || json['is_manual_override'] == true,
      isOpen24Hours: json['is_open_24_hours'] == 1 || json['is_open_24_hours'] == true,
      isOwnerVerified: isOwnerVerified,
      favoritesCount: int.tryParse((json['favorites_count'] ?? '0').toString()) ?? 0,
    );
  }

  /// ✅ Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': supabaseUserId ?? userId,
      'user_name': userName,
      if (userAvatarUrl != null) 'user_avatar_url': userAvatarUrl,
      'cat_id': catId,
      'cat_name': catName,
      'subcat_id': subcatId,
      'subcat_name': subcatName,
      'title': title,
      'description': description,
      'phone': phone,
      'address': address,
      'lat': lat,
      'lng': lng,
      'active': active,
      'created_at': createdAt,
      if (facebook != null) 'facebook': facebook,
      if (instagram != null) 'instagram': instagram,
      if (whatsapp != null) 'whatsapp': whatsapp,
      if (telegram != null) 'telegram': telegram,
      'file': files.map((f) => f.toJson()).toList(),
      if (distance != null) 'distance': distance,
      if (averageRating != null) 'average_rating': averageRating,
      if (totalReviews != null) 'total_reviews': totalReviews,
      if (openTime != null) 'open_time': openTime,
      if (closeTime != null) 'close_time': closeTime,
      if (workDays != null) 'work_days': workDays,
      'is_manual_override': isManualOverride == true ? 1 : 0,
      'is_open_24_hours': isOpen24Hours == true ? 1 : 0,
      'favorites_count': favoritesCount,
    };
  }

  /// Convenience getter
  String get imageUrl => files.isNotEmpty ? files.first.url : '';

  factory Service.empty() {
    return Service(
      id: 0,
      userId: 0,
      supabaseUserId: null,
      userName: '',
      userAvatarUrl: null,
      catId: 0,
      catName: '',
      subcatId: 0,
      subcatName: '',
      title: '',
      description: '',
      phone: '',
      address: '',
      lat: 0.0,
      lng: 0.0,
      active: '1',
      createdAt: '',
      files: [],
      facebook: null,
      instagram: null,
      whatsapp: null,
      telegram: null,
      distance: 0.0,
      openTime: null,
      closeTime: null,
      workDays: null,
      isManualOverride: false,
      isOpen24Hours: false,
      isOwnerVerified: false,
      favoritesCount: 0,
    );
  }

  /// Create a copy with updated fields
  Service copyWith({
    int? id,
    int? userId,
    String? supabaseUserId,
    String? userName,
    String? userAvatarUrl,
    int? catId,
    String? catName,
    int? subcatId,
    String? subcatName,
    String? title,
    String? description,
    String? phone,
    String? address,
    double? lat,
    double? lng,
    String? active,
    String? createdAt,
    List<ServiceFile>? files,
    String? facebook,
    String? instagram,
    String? whatsapp,
    String? telegram,
    double? distance,
    double? averageRating,
    int? totalReviews,
    String? openTime,
    String? closeTime,
    String? workDays,
    bool? isManualOverride,
    bool? isOpen24Hours,
    bool? isOwnerVerified,
    int? favoritesCount,
  }) {
    return Service(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      supabaseUserId: supabaseUserId ?? this.supabaseUserId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      catId: catId ?? this.catId,
      catName: catName ?? this.catName,
      subcatId: subcatId ?? this.subcatId,
      subcatName: subcatName ?? this.subcatName,
      title: title ?? this.title,
      description: description ?? this.description,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      files: files ?? this.files,
      facebook: facebook ?? this.facebook,
      instagram: instagram ?? this.instagram,
      whatsapp: whatsapp ?? this.whatsapp,
      telegram: telegram ?? this.telegram,
      distance: distance ?? this.distance,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      workDays: workDays ?? this.workDays,
      isManualOverride: isManualOverride ?? this.isManualOverride,
      isOpen24Hours: isOpen24Hours ?? this.isOpen24Hours,
      isOwnerVerified: isOwnerVerified ?? this.isOwnerVerified,
      favoritesCount: favoritesCount ?? this.favoritesCount,
    );
  }
}

class ServiceFile {
  final int id;
  final String file;
  final String url;
  final int serviceId;

  ServiceFile({
    required this.id,
    required this.file,
    required this.url,
    required this.serviceId,
  });

  factory ServiceFile.fromJson(Map<String, dynamic> json) {
    return ServiceFile(
      id: int.tryParse(json['id'].toString()) ?? 0,
      // Support both 'file' (from API/local) and 'file_path' (from Supabase)
      file: json['file'] ?? json['file_path'] ?? '',
      url: json['url'] ?? '',
      serviceId: int.tryParse(json['service_id'].toString()) ?? 0,
    );
  }

  /// ✅ Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file': file,
      'url': url,
      'service_id': serviceId,
    };
  }
}
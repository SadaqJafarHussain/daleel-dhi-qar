import 'package:tour_guid/models/service_model.dart';

/// Factory for creating Service instances for testing
class ServiceFixtures {
  /// Create a Service with sensible defaults and optional overrides
  static Service createService({
    int id = 1,
    int userId = 100,
    String? supabaseUserId = 'user-uuid-123',
    String userName = 'Test User',
    String? userAvatarUrl,
    int catId = 1,
    String catName = 'Test Category',
    int subcatId = 1,
    String subcatName = 'Test Subcategory',
    String title = 'Test Service',
    String description = 'Test Description',
    String phone = '+1234567890',
    String address = 'Test Address',
    double lat = 31.0439,
    double lng = 46.2576,
    String active = '1',
    String createdAt = '2024-01-01T00:00:00Z',
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
    bool isOwnerVerified = false,
    int favoritesCount = 0,
  }) {
    return Service(
      id: id,
      userId: userId,
      supabaseUserId: supabaseUserId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      catId: catId,
      catName: catName,
      subcatId: subcatId,
      subcatName: subcatName,
      title: title,
      description: description,
      phone: phone,
      address: address,
      lat: lat,
      lng: lng,
      active: active,
      createdAt: createdAt,
      files: files ?? [],
      facebook: facebook,
      instagram: instagram,
      whatsapp: whatsapp,
      telegram: telegram,
      distance: distance,
      averageRating: averageRating,
      totalReviews: totalReviews,
      openTime: openTime,
      closeTime: closeTime,
      workDays: workDays,
      isManualOverride: isManualOverride,
      isOpen24Hours: isOpen24Hours,
      isOwnerVerified: isOwnerVerified,
      favoritesCount: favoritesCount,
    );
  }

  /// Create a ServiceFile for testing
  static ServiceFile createServiceFile({
    int id = 1,
    String file = 'test_file.jpg',
    String url = 'https://example.com/images/test_file.jpg',
    int serviceId = 1,
  }) {
    return ServiceFile(
      id: id,
      file: file,
      url: url,
      serviceId: serviceId,
    );
  }

  /// Create complete JSON for Service.fromJson testing
  static Map<String, dynamic> createServiceJson({
    int id = 1,
    dynamic userId = 'user-uuid-123',
    String? userName,
    String? userAvatarUrl,
    int catId = 1,
    String catName = 'Test Category',
    int subcatId = 1,
    String subcatName = 'Test Subcategory',
    String title = 'Test Service',
    String description = 'Test Description',
    String phone = '+1234567890',
    String address = 'Test Address',
    double lat = 31.0439,
    double lng = 46.2576,
    String active = '1',
    String createdAt = '2024-01-01T00:00:00Z',
    List<Map<String, dynamic>>? files,
    List<Map<String, dynamic>>? serviceFiles,
    String? imageUrl,
    String? facebook,
    String? instagram,
    String? whatsapp,
    String? telegram,
    double? averageRating,
    int? totalReviews,
    String? openTime,
    String? closeTime,
    dynamic workDays,
    bool? isManualOverride,
    bool? isOpen24Hours,
    Map<String, dynamic>? profiles,
    int? favoritesCount,
  }) {
    final json = <String, dynamic>{
      'id': id,
      'user_id': userId,
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
    };

    if (userName != null) json['user_name'] = userName;
    if (userAvatarUrl != null) json['user_avatar_url'] = userAvatarUrl;
    if (files != null) json['file'] = files;
    if (serviceFiles != null) json['service_files'] = serviceFiles;
    if (imageUrl != null) json['image_url'] = imageUrl;
    if (facebook != null) json['facebook'] = facebook;
    if (instagram != null) json['instagram'] = instagram;
    if (whatsapp != null) json['whatsapp'] = whatsapp;
    if (telegram != null) json['telegram'] = telegram;
    if (averageRating != null) json['average_rating'] = averageRating;
    if (totalReviews != null) json['total_reviews'] = totalReviews;
    if (openTime != null) json['open_time'] = openTime;
    if (closeTime != null) json['close_time'] = closeTime;
    if (workDays != null) json['work_days'] = workDays;
    if (isManualOverride != null) json['is_manual_override'] = isManualOverride;
    if (isOpen24Hours != null) json['is_open_24_hours'] = isOpen24Hours;
    if (profiles != null) json['profiles'] = profiles;
    if (favoritesCount != null) json['favorites_count'] = favoritesCount;

    return json;
  }

  /// Create JSON for ServiceFile.fromJson testing
  static Map<String, dynamic> createServiceFileJson({
    int id = 1,
    String file = 'test_file.jpg',
    String url = 'https://example.com/images/test_file.jpg',
    int serviceId = 1,
  }) {
    return {
      'id': id,
      'file': file,
      'url': url,
      'service_id': serviceId,
    };
  }

  /// Create a service with working hours configured
  static Service createServiceWithWorkingHours({
    required String openTime,
    required String closeTime,
    required String workDays,
    bool isManualOverride = false,
    bool isOpen24Hours = false,
    String active = '1',
  }) {
    return createService(
      openTime: openTime,
      closeTime: closeTime,
      workDays: workDays,
      isManualOverride: isManualOverride,
      isOpen24Hours: isOpen24Hours,
      active: active,
    );
  }

  /// Create a 24/7 service
  static Service create24HourService() {
    return createService(isOpen24Hours: true);
  }

  /// Create a manually controlled service
  static Service createManualOverrideService({bool isActive = true}) {
    return createService(
      isManualOverride: true,
      active: isActive ? '1' : '0',
    );
  }

  /// Create a service with files
  static Service createServiceWithFiles({int fileCount = 2}) {
    final files = List.generate(
      fileCount,
      (index) => createServiceFile(
        id: index + 1,
        file: 'file_$index.jpg',
        url: 'https://example.com/images/file_$index.jpg',
      ),
    );
    return createService(files: files);
  }

  /// Create a verified owner service
  static Service createVerifiedService() {
    return createService(isOwnerVerified: true);
  }
}

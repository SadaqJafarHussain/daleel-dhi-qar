import 'package:flutter/material.dart';
import 'service_model.dart';

class FavoritesResponse {
  final String status;
  final String message;
  final List<Favorite> favorites;

  FavoritesResponse({
    required this.status,
    required this.message,
    required this.favorites,
  });

  factory FavoritesResponse.fromJson(
      Map<String, dynamic> json, {
        String? Function(int)? getCategoryName,
        String? Function(int)? getSubcategoryName,
      }) {
    final favorites = (json['data'] as List<dynamic>?)
        ?.map((item) {
      try {
        final favorite = Favorite.fromJson(item);

        // ✅ Enrich with category and subcategory names if providers available
        if (getCategoryName != null && getSubcategoryName != null) {
          final catName = getCategoryName(favorite.service.catId) ?? '';
          final subcatName =
              getSubcategoryName(favorite.service.subcatId) ?? '';

          favorite.enrichServiceNames(
            categoryName: catName,
            subcategoryName: subcatName,
          );
        }

        return favorite;
      } catch (e) {
        debugPrint('⚠️ Error parsing favorite: $e');
        return null;
      }
    })
        .whereType<Favorite>()
    // ✅ REMOVED: Don't filter by service.id
        .toList() ??
        [];

    debugPrint('✅ Parsed ${favorites.length} favorites from API');

    return FavoritesResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      favorites: favorites,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': favorites.map((f) => f.toJson()).toList(),
    };
  }
}

class Favorite {
  final int id;
  final int serviceId;
  Service service;

  Favorite({
    required this.id,
    required this.serviceId,
    required this.service,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    final serviceJson = json['services'];
    final serviceId = json['service_id'] ?? 0;
    final favoriteId = json['id'] ?? 0;

    final filesJson = (json['file'] as List<dynamic>?)
        ?.map((f) => ServiceFile.fromJson(f))
        .toList() ??
        [];

    Service service;

    // ✅ FIXED: Better check and use service_id as the actual id
    if (serviceJson is Map<String, dynamic> &&
        serviceJson['name'] != null &&
        serviceJson['name'].toString().isNotEmpty) {
      // Valid service object - parse it and set the correct id
      final serviceData = Map<String, dynamic>.from(serviceJson);

      // ✅ CRITICAL FIX: Use service_id as the id if services.id is missing
      if (serviceData['id'] == null || serviceData['id'] == 0) {
        serviceData['id'] = serviceId;
      }

      service = Service.fromJson(serviceData);
      service.files.addAll(filesJson);

      debugPrint('✅ Parsed service: id=${service.id}, serviceId=$serviceId, title=${service.title}');
    } else {
      // Create placeholder with correct id
      service = Service.empty();
      service = Service(
        id: serviceId, // Use service_id
        userId: service.userId,
        userName: service.userName,
        catId: service.catId,
        catName: service.catName,
        subcatId: service.subcatId,
        subcatName: service.subcatName,
        title: 'Service #$serviceId',
        description: service.description,
        phone: service.phone,
        address: service.address,
        lat: service.lat,
        lng: service.lng,
        active: service.active,
        createdAt: service.createdAt,
        files: filesJson,
        distance: service.distance,
      );

      debugPrint('⚠️ Created placeholder service: id=${service.id}, serviceId=$serviceId');
    }

    debugPrint('📦 Favorite: id=$favoriteId, serviceId=$serviceId, service.id=${service.id}');

    return Favorite(
      id: favoriteId,
      serviceId: serviceId,
      service: service,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_id': serviceId,
      'services': service.toJson(),
      'file': service.files.map((f) => f.toJson()).toList(),
    };
  }

  /// ✅ Enrich service with category and subcategory names from providers
  void enrichServiceNames({
    required String categoryName,
    required String subcategoryName,
  }) {
    // Create a new Service with updated names
    service = Service(
      id: service.id,
      userId: service.userId,
      userName: service.userName,
      catId: service.catId,
      catName: categoryName, // ✅ Update category name
      subcatId: service.subcatId,
      subcatName: subcategoryName, // ✅ Update subcategory name
      title: service.title,
      description: service.description,
      phone: service.phone,
      address: service.address,
      lat: service.lat,
      lng: service.lng,
      active: service.active,
      createdAt: service.createdAt,
      files: service.files,
      distance: service.distance,
    );
  }
}
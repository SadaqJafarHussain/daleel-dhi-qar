import 'package:tour_guid/models/favorite.dart';
import 'package:tour_guid/models/service_model.dart';

import 'service_fixtures.dart';

/// Factory for creating Favorite instances for testing
class FavoriteFixtures {
  /// Create a Favorite with sensible defaults
  static Favorite createFavorite({
    int id = 1,
    int serviceId = 1,
    Service? service,
  }) {
    return Favorite(
      id: id,
      serviceId: serviceId,
      service: service ?? ServiceFixtures.createService(id: serviceId),
    );
  }

  /// Create a list of favorites
  static List<Favorite> createFavorites({int count = 3}) {
    return List.generate(
      count,
      (index) => createFavorite(
        id: index + 1,
        serviceId: index + 100,
        service: ServiceFixtures.createService(
          id: index + 100,
          title: 'Favorite Service ${index + 1}',
        ),
      ),
    );
  }

  /// Create JSON for FavoritesResponse parsing
  static Map<String, dynamic> createFavoritesResponseJson({
    String status = 'success',
    String message = 'Favorites loaded',
    List<Map<String, dynamic>>? favorites,
    int favoriteCount = 3,
  }) {
    final favData = favorites ?? List.generate(
      favoriteCount,
      (index) => {
        'id': index + 1,
        'service_id': index + 100,
        'services': {
          'id': index + 100,
          'name': 'Favorite Service ${index + 1}',
          'title': 'Favorite Service ${index + 1}',
          'description': 'Description ${index + 1}',
          'cat_id': 1,
          'subcat_id': 1,
          'user_id': 'user-uuid',
          'phone': '+1234567890',
          'address': 'Address ${index + 1}',
          'lat': 31.0439,
          'lng': 46.2576,
          'active': '1',
          'created_at': '2024-01-01T00:00:00Z',
        },
      },
    );

    return {
      'status': status,
      'message': message,
      'data': favData,
    };
  }
}

import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tour_guid/services/cache_manager.dart';
import 'package:tour_guid/models/offline_operation.dart';

void main() {
  late String tempPath;

  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Create temp directory for Hive
    final tempDir = await Directory.systemTemp.createTemp('hive_cache_test_');
    tempPath = tempDir.path;
    Hive.init(tempPath);
  });

  tearDownAll(() async {
    await Hive.close();

    // Clean up temp directory
    final tempDir = Directory(tempPath);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('CacheManager', () {
    late CacheManager cacheManager;

    setUp(() async {
      cacheManager = CacheManager();

      // We need to open boxes manually for testing since init() uses initFlutter
      // which requires Flutter environment
      await Hive.openBox('categories_cache');
      await Hive.openBox('subcategories_cache');
      await Hive.openBox('services_cache');
      await Hive.openBox('favorites_cache');
      await Hive.openBox('reviews_cache');
      await Hive.openBox('ads_cache');
      await Hive.openBox('profile_cache');
      await Hive.openBox('offline_queue');
      await Hive.openBox('sync_metadata');
    });

    tearDown(() async {
      // Clear all boxes after each test
      for (final box in Hive.isBoxOpen('categories_cache') ? [Hive.box('categories_cache')] : <Box>[]) {
        await box.clear();
      }
      for (final box in Hive.isBoxOpen('services_cache') ? [Hive.box('services_cache')] : <Box>[]) {
        await box.clear();
      }
      for (final box in Hive.isBoxOpen('offline_queue') ? [Hive.box('offline_queue')] : <Box>[]) {
        await box.clear();
      }
    });

    group('set and get', () {
      test('round-trip for simple value', () async {
        await cacheManager.set('categories', 'test_key', 'test_value');
        final result = await cacheManager.get<String>('categories', 'test_key');

        expect(result, equals('test_value'));
      });

      test('returns null for missing key', () async {
        final result = await cacheManager.get<String>('categories', 'nonexistent');

        expect(result, isNull);
      });

      test('set with TTL wraps value in cache entry', () async {
        await cacheManager.set(
          'categories',
          'ttl_key',
          'ttl_value',
          ttl: const Duration(hours: 1),
        );

        final result = await cacheManager.get<String>('categories', 'ttl_key');
        expect(result, equals('ttl_value'));
      });
    });

    group('TTL expiration', () {
      test('expired cache entry returns null', () async {
        // Set with 0 duration TTL (immediately expired)
        final box = Hive.box('categories_cache');
        await box.put('expired_key', {
          'data': 'expired_value',
          'cached_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          'ttl_ms': const Duration(hours: 1).inMilliseconds,
        });

        final result = await cacheManager.get<String>('categories', 'expired_key');

        expect(result, isNull);
      });

      test('non-expired cache entry returns value', () async {
        final box = Hive.box('categories_cache');
        await box.put('fresh_key', {
          'data': 'fresh_value',
          'cached_at': DateTime.now().toIso8601String(),
          'ttl_ms': const Duration(hours: 1).inMilliseconds,
        });

        final result = await cacheManager.get<String>('categories', 'fresh_key');

        expect(result, equals('fresh_value'));
      });
    });

    group('getList', () {
      test('returns properly typed list data', () async {
        final testList = [
          {'id': 1, 'name': 'Item 1'},
          {'id': 2, 'name': 'Item 2'},
        ];

        await cacheManager.set(
          'categories',
          'list_key',
          testList,
          ttl: const Duration(hours: 1),
        );

        final result = await cacheManager.getList('categories', 'list_key');

        expect(result, isNotNull);
        expect(result!.length, equals(2));
        expect(result[0]['id'], equals(1));
        expect(result[0]['name'], equals('Item 1'));
        expect(result[1]['id'], equals(2));
      });

      test('returns null for missing key', () async {
        final result = await cacheManager.getList('categories', 'nonexistent_list');

        expect(result, isNull);
      });

      test('handles nested structures', () async {
        final testList = [
          {
            'id': 1,
            'nested': {'key': 'value'},
            'array': [1, 2, 3],
          },
        ];

        await cacheManager.set(
          'categories',
          'nested_list',
          testList,
          ttl: const Duration(hours: 1),
        );

        final result = await cacheManager.getList('categories', 'nested_list');

        expect(result, isNotNull);
        expect(result![0]['nested'], isA<Map<String, dynamic>>());
        expect(result[0]['nested']['key'], equals('value'));
        expect(result[0]['array'], isA<List>());
      });
    });

    group('getMap', () {
      test('returns properly typed map data', () async {
        final testMap = {'id': 1, 'name': 'Test', 'active': true};

        await cacheManager.set(
          'services',
          'map_key',
          testMap,
          ttl: const Duration(hours: 1),
        );

        final result = await cacheManager.getMap('services', 'map_key');

        expect(result, isNotNull);
        expect(result!['id'], equals(1));
        expect(result['name'], equals('Test'));
        expect(result['active'], isTrue);
      });

      test('returns null for expired map', () async {
        final box = Hive.box('services_cache');
        await box.put('expired_map', {
          'data': {'id': 1},
          'cached_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'ttl_ms': const Duration(hours: 1).inMilliseconds,
        });

        final result = await cacheManager.getMap('services', 'expired_map');

        expect(result, isNull);
      });
    });

    group('delete', () {
      test('removes entry from box', () async {
        await cacheManager.set('categories', 'to_delete', 'value');

        await cacheManager.delete('categories', 'to_delete');

        final result = await cacheManager.get<String>('categories', 'to_delete');
        expect(result, isNull);
      });

      test('does not throw for missing key', () async {
        // Should not throw
        await cacheManager.delete('categories', 'nonexistent');
        expect(true, isTrue);
      });
    });

    group('clearBox', () {
      test('clears all entries in a box', () async {
        await cacheManager.set('categories', 'key1', 'value1');
        await cacheManager.set('categories', 'key2', 'value2');
        await cacheManager.set('categories', 'key3', 'value3');

        await cacheManager.clearBox('categories');

        expect(await cacheManager.get<String>('categories', 'key1'), isNull);
        expect(await cacheManager.get<String>('categories', 'key2'), isNull);
        expect(await cacheManager.get<String>('categories', 'key3'), isNull);
      });
    });

    group('offline queue operations', () {
      test('addToOfflineQueue adds operation', () async {
        final operation = OfflineOperation(
          id: 'op-1',
          type: OperationType.insert,
          table: 'favorites',
          data: {'service_id': 1, 'user_id': 'user-123'},
        );

        await cacheManager.addToOfflineQueue(operation);

        final queue = await cacheManager.getOfflineQueue();
        expect(queue.length, equals(1));
        expect(queue[0].id, equals('op-1'));
        expect(queue[0].type, equals(OperationType.insert));
      });

      test('getOfflineQueue returns sorted by creation time', () async {
        final op1 = OfflineOperation(
          id: 'op-1',
          type: OperationType.insert,
          table: 'favorites',
          data: {},
          createdAt: DateTime(2024, 1, 1, 10, 0),
        );
        final op2 = OfflineOperation(
          id: 'op-2',
          type: OperationType.update,
          table: 'favorites',
          data: {},
          createdAt: DateTime(2024, 1, 1, 9, 0),
        );

        await cacheManager.addToOfflineQueue(op1);
        await cacheManager.addToOfflineQueue(op2);

        final queue = await cacheManager.getOfflineQueue();

        // Should be sorted by createdAt ascending
        expect(queue[0].id, equals('op-2')); // Earlier time first
        expect(queue[1].id, equals('op-1'));
      });

      test('removeFromOfflineQueue removes operation', () async {
        final operation = OfflineOperation(
          id: 'op-to-remove',
          type: OperationType.delete,
          table: 'favorites',
          data: {},
        );

        await cacheManager.addToOfflineQueue(operation);
        await cacheManager.removeFromOfflineQueue('op-to-remove');

        final queue = await cacheManager.getOfflineQueue();
        expect(queue.where((op) => op.id == 'op-to-remove'), isEmpty);
      });

      test('updateOfflineOperation updates operation', () async {
        final operation = OfflineOperation(
          id: 'op-update',
          type: OperationType.insert,
          table: 'reviews',
          data: {},
          retryCount: 0,
        );

        await cacheManager.addToOfflineQueue(operation);

        final updatedOp = operation.copyWith(retryCount: 3);
        await cacheManager.updateOfflineOperation(updatedOp);

        final queue = await cacheManager.getOfflineQueue();
        final found = queue.firstWhere((op) => op.id == 'op-update');
        expect(found.retryCount, equals(3));
      });

      test('getOfflineQueueSize returns correct count', () async {
        await cacheManager.addToOfflineQueue(OfflineOperation(
          id: 'op-1',
          type: OperationType.insert,
          table: 'test',
          data: {},
        ));
        await cacheManager.addToOfflineQueue(OfflineOperation(
          id: 'op-2',
          type: OperationType.insert,
          table: 'test',
          data: {},
        ));

        final size = await cacheManager.getOfflineQueueSize();
        expect(size, equals(2));
      });

      test('clearOfflineQueue removes all operations', () async {
        await cacheManager.addToOfflineQueue(OfflineOperation(
          id: 'op-1',
          type: OperationType.insert,
          table: 'test',
          data: {},
        ));
        await cacheManager.addToOfflineQueue(OfflineOperation(
          id: 'op-2',
          type: OperationType.insert,
          table: 'test',
          data: {},
        ));

        await cacheManager.clearOfflineQueue();

        final size = await cacheManager.getOfflineQueueSize();
        expect(size, equals(0));
      });
    });

    group('hasValidCache', () {
      test('returns true for valid cached data', () async {
        await cacheManager.set(
          'categories',
          'valid_cache',
          'value',
          ttl: const Duration(hours: 1),
        );

        final hasValid = await cacheManager.hasValidCache('categories', 'valid_cache');
        expect(hasValid, isTrue);
      });

      test('returns false for missing key', () async {
        final hasValid = await cacheManager.hasValidCache('categories', 'nonexistent');
        expect(hasValid, isFalse);
      });
    });

    group('entity-specific methods', () {
      test('setCategories and getCategories work correctly', () async {
        final categories = [
          {'id': 1, 'name': 'Category 1'},
          {'id': 2, 'name': 'Category 2'},
        ];

        await cacheManager.setCategories(categories);
        final result = await cacheManager.getCategories();

        expect(result, isNotNull);
        expect(result!.length, equals(2));
      });

      test('setService and getService work correctly', () async {
        final service = {'id': 42, 'title': 'Test Service'};

        await cacheManager.setService(42, service);
        final result = await cacheManager.getService(42);

        expect(result, isNotNull);
        expect(result!['id'], equals(42));
        expect(result['title'], equals('Test Service'));
      });

      test('setFavorites and getFavorites work with userId', () async {
        final favorites = [
          {'id': 1, 'service_id': 100},
          {'id': 2, 'service_id': 200},
        ];

        await cacheManager.setFavorites('user-123', favorites);
        final result = await cacheManager.getFavorites('user-123');

        expect(result, isNotNull);
        expect(result!.length, equals(2));
      });

      test('setReviews and getReviews work with serviceId', () async {
        final reviews = [
          {'id': 1, 'rating': 5.0},
          {'id': 2, 'rating': 4.0},
        ];

        await cacheManager.setReviews(42, reviews);
        final result = await cacheManager.getReviews(42);

        expect(result, isNotNull);
        expect(result!.length, equals(2));
      });

      test('setProfile and getProfile work with userId', () async {
        final profile = {'id': 'user-123', 'name': 'John Doe'};

        await cacheManager.setProfile('user-123', profile);
        final result = await cacheManager.getProfile('user-123');

        expect(result, isNotNull);
        expect(result!['name'], equals('John Doe'));
      });
    });

    group('box name mapping', () {
      test('maps simple names to full box names', () async {
        // Test that different naming conventions work
        await cacheManager.set('categories', 'key', 'value');
        final result = await cacheManager.get<String>('categories', 'key');
        expect(result, equals('value'));

        // Clear using same name
        await cacheManager.delete('categories', 'key');
        final deleted = await cacheManager.get<String>('categories', 'key');
        expect(deleted, isNull);
      });
    });
  });
}

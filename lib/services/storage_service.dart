import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import '../config/app_config.dart';
import 'supabase_service.dart';

/// Service for managing file storage in Supabase Storage
class StorageService {
  // Singleton instance
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final SupabaseService _supabase = SupabaseService();

  /// Get storage client
  SupabaseStorageClient get _storage => _supabase.client.storage;

  /// Sanitize file name to prevent path traversal attacks
  String _sanitizeFileName(String fileName) {
    // Remove path separators and parent directory references
    return fileName
        .replaceAll(RegExp(r'[/\\]'), '_')  // Replace path separators
        .replaceAll('..', '_')               // Remove parent directory reference
        .replaceAll(RegExp(r'[<>:"|?*]'), '_')  // Remove invalid characters
        .trim();
  }

  /// Validate file extension is allowed
  bool _isAllowedExtension(String extension) {
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic'];
    return allowedExtensions.contains(extension.toLowerCase());
  }

  // ========================================
  // SERVICE IMAGES
  // ========================================

  /// Upload a service image
  Future<String?> uploadServiceImage({
    required int serviceId,
    required File file,
    String? fileName,
  }) async {
    try {
      // Validate file size
      final fileSize = await file.length();
      if (fileSize > AppConfig.maxImageSize) {
        throw Exception('Image size exceeds ${AppConfig.maxImageSize ~/ (1024 * 1024)}MB limit');
      }

      // Validate and sanitize file name
      final extension = path.extension(file.path).toLowerCase();
      if (!_isAllowedExtension(extension)) {
        throw Exception('Invalid file type. Allowed: jpg, jpeg, png, gif, webp, heic');
      }

      // Sanitize file name to prevent path traversal
      final sanitizedName = fileName != null
          ? _sanitizeFileName(fileName)
          : '${DateTime.now().millisecondsSinceEpoch}$extension';
      final storagePath = 'services/$serviceId/$sanitizedName';

      // Upload file
      await _storage
          .from(AppConfig.serviceImagesBucket)
          .upload(storagePath, file);

      // Get public URL
      final url = _storage
          .from(AppConfig.serviceImagesBucket)
          .getPublicUrl(storagePath);

      debugPrint('StorageService: Uploaded service image: $url');
      return url;
    } catch (e) {
      debugPrint('StorageService: Error uploading service image: $e');
      return null;
    }
  }

  /// Upload multiple service images
  Future<List<String>> uploadServiceImages({
    required int serviceId,
    required List<File> files,
  }) async {
    final urls = <String>[];

    for (int i = 0; i < files.length; i++) {
      final url = await uploadServiceImage(
        serviceId: serviceId,
        file: files[i],
        fileName: '${DateTime.now().millisecondsSinceEpoch}_$i${path.extension(files[i].path)}',
      );
      if (url != null) {
        urls.add(url);
      }
    }

    return urls;
  }

  /// Delete a service image
  Future<bool> deleteServiceImage(String imageUrl) async {
    try {
      // Extract path from URL
      final storagePath = _extractPathFromUrl(imageUrl, AppConfig.serviceImagesBucket);
      if (storagePath == null) return false;

      await _storage
          .from(AppConfig.serviceImagesBucket)
          .remove([storagePath]);

      debugPrint('StorageService: Deleted service image: $storagePath');
      return true;
    } catch (e) {
      debugPrint('StorageService: Error deleting service image: $e');
      return false;
    }
  }

  /// Delete all images for a service
  Future<bool> deleteAllServiceImages(int serviceId) async {
    try {
      final folderPath = 'services/$serviceId';

      // List all files in the folder
      final files = await _storage
          .from(AppConfig.serviceImagesBucket)
          .list(path: folderPath);

      if (files.isEmpty) return true;

      // Delete all files
      final paths = files.map((f) => '$folderPath/${f.name}').toList();
      await _storage
          .from(AppConfig.serviceImagesBucket)
          .remove(paths);

      debugPrint('StorageService: Deleted all images for service $serviceId');
      return true;
    } catch (e) {
      debugPrint('StorageService: Error deleting service images: $e');
      return false;
    }
  }

  // ========================================
  // USER AVATARS
  // ========================================

  /// Upload user avatar
  Future<String?> uploadAvatar({
    required String odUserId,
    required File file,
  }) async {
    try {
      // Validate file size
      final fileSize = await file.length();
      if (fileSize > AppConfig.maxImageSize) {
        throw Exception('Image size exceeds limit');
      }

      final extension = path.extension(file.path).toLowerCase();
      final storagePath = 'avatars/$odUserId/avatar$extension';

      // Delete existing avatar first
      try {
        await _storage.from(AppConfig.avatarsBucket).remove([storagePath]);
      } catch (_) {
        // Ignore if doesn't exist
      }

      // Upload new avatar
      await _storage
          .from(AppConfig.avatarsBucket)
          .upload(storagePath, file);

      // Get public URL
      final url = _storage
          .from(AppConfig.avatarsBucket)
          .getPublicUrl(storagePath);

      debugPrint('StorageService: Uploaded avatar: $url');
      return url;
    } catch (e) {
      debugPrint('StorageService: Error uploading avatar: $e');
      return null;
    }
  }

  /// Delete user avatar
  Future<bool> deleteAvatar(String odUserId) async {
    try {
      final folderPath = 'avatars/$odUserId';

      final files = await _storage
          .from(AppConfig.avatarsBucket)
          .list(path: folderPath);

      if (files.isEmpty) return true;

      final paths = files.map((f) => '$folderPath/${f.name}').toList();
      await _storage
          .from(AppConfig.avatarsBucket)
          .remove(paths);

      debugPrint('StorageService: Deleted avatar for user $odUserId');
      return true;
    } catch (e) {
      debugPrint('StorageService: Error deleting avatar: $e');
      return false;
    }
  }

  // ========================================
  // GENERAL FILE OPERATIONS
  // ========================================

  /// Delete a file by its URL or path
  Future<bool> deleteFile(String fileUrlOrPath) async {
    try {
      // If it's a URL, try to extract path
      if (fileUrlOrPath.startsWith('http')) {
        // Try service images bucket first
        var storagePath = _extractPathFromUrl(fileUrlOrPath, AppConfig.serviceImagesBucket);
        if (storagePath != null) {
          await _storage.from(AppConfig.serviceImagesBucket).remove([storagePath]);
          debugPrint('StorageService: Deleted file from service-images: $storagePath');
          return true;
        }

        // Try avatars bucket
        storagePath = _extractPathFromUrl(fileUrlOrPath, AppConfig.avatarsBucket);
        if (storagePath != null) {
          await _storage.from(AppConfig.avatarsBucket).remove([storagePath]);
          debugPrint('StorageService: Deleted file from avatars: $storagePath');
          return true;
        }

        debugPrint('StorageService: Could not extract path from URL: $fileUrlOrPath');
        return false;
      } else {
        // Assume it's a path in service-images bucket
        await _storage.from(AppConfig.serviceImagesBucket).remove([fileUrlOrPath]);
        debugPrint('StorageService: Deleted file: $fileUrlOrPath');
        return true;
      }
    } catch (e) {
      debugPrint('StorageService: Error deleting file: $e');
      return false;
    }
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  /// Get signed URL for temporary access
  Future<String?> getSignedUrl({
    required String bucket,
    required String path,
    Duration expiry = const Duration(hours: 1),
  }) async {
    try {
      final url = await _storage
          .from(bucket)
          .createSignedUrl(path, expiry.inSeconds);

      return url;
    } catch (e) {
      debugPrint('StorageService: Error getting signed URL: $e');
      return null;
    }
  }

  /// Extract storage path from public URL
  String? _extractPathFromUrl(String url, String bucket) {
    try {
      // URL format: https://xxx.supabase.co/storage/v1/object/public/bucket/path
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;

      // Find bucket index and get path after it
      final bucketIndex = segments.indexOf(bucket);
      if (bucketIndex == -1 || bucketIndex >= segments.length - 1) {
        return null;
      }

      return segments.sublist(bucketIndex + 1).join('/');
    } catch (e) {
      debugPrint('StorageService: Error extracting path from URL: $e');
      return null;
    }
  }

  /// Check if file exists
  Future<bool> fileExists({
    required String bucket,
    required String path,
  }) async {
    try {
      final parentPath = path.substring(0, path.lastIndexOf('/'));
      final fileName = path.substring(path.lastIndexOf('/') + 1);

      final files = await _storage.from(bucket).list(path: parentPath);
      return files.any((f) => f.name == fileName);
    } catch (e) {
      return false;
    }
  }

  /// Get file metadata
  Future<FileObject?> getFileMetadata({
    required String bucket,
    required String path,
  }) async {
    try {
      final parentPath = path.substring(0, path.lastIndexOf('/'));
      final fileName = path.substring(path.lastIndexOf('/') + 1);

      final files = await _storage.from(bucket).list(path: parentPath);
      return files.firstWhere(
        (f) => f.name == fileName,
        orElse: () => throw Exception('File not found'),
      );
    } catch (e) {
      debugPrint('StorageService: Error getting file metadata: $e');
      return null;
    }
  }

  /// Download file to bytes
  Future<Uint8List?> downloadFile({
    required String bucket,
    required String path,
  }) async {
    try {
      final bytes = await _storage.from(bucket).download(path);
      return bytes;
    } catch (e) {
      debugPrint('StorageService: Error downloading file: $e');
      return null;
    }
  }
}

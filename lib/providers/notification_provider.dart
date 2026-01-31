import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

/// NotificationProvider - Manages notification state for the app
class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  // State
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;
  NotificationPreferences? _preferences;
  bool _isInitialized = false;
  bool _isPushEnabled = true; // Default to true

  // Subscriptions
  StreamSubscription<AppNotification>? _notificationSubscription;
  StreamSubscription<int>? _unreadCountSubscription;

  // Pagination
  static const int _pageSize = 20;
  int _currentPage = 0;

  // Getters
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  NotificationPreferences? get preferences => _preferences;
  bool get hasUnread => _unreadCount > 0;
  bool get isPushEnabled => _isPushEnabled;

  /// Get unread notifications
  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  /// Get notifications grouped by date
  Map<String, List<AppNotification>> get groupedNotifications {
    final Map<String, List<AppNotification>> grouped = {};

    for (final notification in _notifications) {
      final dateKey = _getDateKey(notification.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(notification);
    }

    return grouped;
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return 'today';
    } else if (notificationDate == yesterday) {
      return 'yesterday';
    } else if (now.difference(date).inDays < 7) {
      return 'this_week';
    } else {
      return 'older';
    }
  }

  /// Initialize the provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _notificationService.initialize();

      // Listen for new notifications
      _notificationSubscription =
          _notificationService.notificationStream.listen(
        _onNewNotification,
        onError: (e) {
          if (kDebugMode) {
            print('NotificationProvider: Notification stream error: $e');
          }
        },
      );

      // Listen for unread count changes
      _unreadCountSubscription =
          _notificationService.unreadCountStream.listen(
        _onUnreadCountChanged,
        onError: (e) {
          if (kDebugMode) {
            print('NotificationProvider: Unread count stream error: $e');
          }
        },
      );

      _isInitialized = true;
      if (kDebugMode) {
        print('NotificationProvider: Initialized');
      }
    } catch (e) {
      // Cancel any subscriptions created before the error
      _notificationSubscription?.cancel();
      _unreadCountSubscription?.cancel();
      _notificationSubscription = null;
      _unreadCountSubscription = null;
      if (kDebugMode) {
        print('NotificationProvider: Initialization error: $e');
      }
    }
  }

  /// Set current user (call after login)
  Future<void> setUser(String userId) async {
    await _notificationService.setUser(userId);
    await loadNotifications(refresh: true);
    await loadPreferences();
    await checkPushStatus(); // Check if push is enabled
    // Update unread count from loaded notifications
    _updateUnreadCountFromNotifications();
  }

  /// Update unread count from local notifications list
  void _updateUnreadCountFromNotifications() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    notifyListeners();
  }

  /// Clear user (call on logout)
  Future<void> clearUser() async {
    await _notificationService.clearUser();
    _notifications = [];
    _unreadCount = 0;
    _preferences = null;
    _currentPage = 0;
    _hasMore = true;
    notifyListeners();
  }

  /// Handle new notification from stream
  void _onNewNotification(AppNotification notification) {
    // Check for duplicates - prevent FCM + realtime double notifications
    final isDuplicate = _notifications.any((n) =>
      n.id == notification.id ||
      (n.title == notification.title &&
       n.body == notification.body &&
       n.createdAt.difference(notification.createdAt).inSeconds.abs() < 5)
    );

    if (isDuplicate) {
      if (kDebugMode) {
        print('NotificationProvider: Duplicate notification ignored: ${notification.title}');
      }
      return;
    }

    // Add to beginning of list
    _notifications.insert(0, notification);
    // Update unread count
    if (!notification.isRead) {
      _unreadCount++;
    }
    notifyListeners();

    if (kDebugMode) {
      print('NotificationProvider: New notification received: ${notification.title}');
    }
  }

  /// Handle unread count change
  void _onUnreadCountChanged(int count) {
    _unreadCount = count;
    notifyListeners();
  }

  /// Load notifications with pagination
  Future<void> loadNotifications({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 0;
      _hasMore = true;
      _notifications = [];
    }

    if (!_hasMore) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newNotifications = await _notificationService.fetchNotifications(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      // Fix #21: Only increment page if we got items
      if (newNotifications.isEmpty) {
        _hasMore = false;
      } else {
        if (newNotifications.length < _pageSize) {
          _hasMore = false;
        }

        if (refresh) {
          _notifications = newNotifications;
        } else {
          _notifications.addAll(newNotifications);
        }

        _currentPage++;
      }
    } catch (e) {
      _errorMessage = 'failed_to_load_notifications';
      if (kDebugMode) {
        print('NotificationProvider: Error loading notifications: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more notifications (for infinite scroll)
  Future<void> loadMoreNotifications() async {
    if (_isLoading || !_hasMore) return;
    await loadNotifications();
  }

  /// Refresh notifications
  Future<void> refreshNotifications() async {
    await loadNotifications(refresh: true);
  }

  /// Mark notification as read
  Future<bool> markAsRead(int notificationId) async {
    final success = await _notificationService.markAsRead(notificationId);

    if (success) {
      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    }

    return success;
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    final success = await _notificationService.markAllAsRead();

    if (success) {
      // Update local state
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _unreadCount = 0;
      notifyListeners();
    }

    return success;
  }

  /// Delete notification
  Future<bool> deleteNotification(int notificationId) async {
    final success = await _notificationService.deleteNotification(notificationId);

    if (success) {
      // Remove from local state
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    }

    return success;
  }

  /// Delete all notifications
  Future<bool> deleteAllNotifications() async {
    final success = await _notificationService.deleteAllNotifications();

    if (success) {
      _notifications = [];
      _unreadCount = 0;
      notifyListeners();
    }

    return success;
  }

  /// Load notification preferences
  Future<void> loadPreferences() async {
    _preferences = await _notificationService.fetchPreferences();
    notifyListeners();
  }

  /// Update notification preferences
  Future<bool> updatePreferences(NotificationPreferences newPreferences) async {
    final success = await _notificationService.updatePreferences(newPreferences);

    if (success) {
      _preferences = newPreferences;
      notifyListeners();
    }

    return success;
  }

  /// Toggle a specific preference
  Future<bool> togglePreference(String preferenceKey, bool value) async {
    if (_preferences == null) return false;

    NotificationPreferences updated;

    switch (preferenceKey) {
      case 'push_enabled':
        updated = _preferences!.copyWith(pushEnabled: value);
        break;
      case 'review_notifications':
        updated = _preferences!.copyWith(reviewNotifications: value);
        break;
      case 'favorite_notifications':
        updated = _preferences!.copyWith(favoriteNotifications: value);
        break;
      case 'service_update_notifications':
        updated = _preferences!.copyWith(serviceUpdateNotifications: value);
        break;
      case 'promotion_notifications':
        updated = _preferences!.copyWith(promotionNotifications: value);
        break;
      case 'ads_notifications':
        updated = _preferences!.copyWith(adsNotifications: value);
        break;
      case 'system_notifications':
        updated = _preferences!.copyWith(systemNotifications: value);
        break;
      case 'verification_notifications':
        updated = _preferences!.copyWith(verificationNotifications: value);
        break;
      default:
        return false;
    }

    return updatePreferences(updated);
  }

  /// Send test notification (for debugging)
  Future<void> sendTestNotification() async {
    await _notificationService.sendTestNotification();
  }

  /// Enable push notifications
  Future<bool> enablePushNotifications() async {
    final success = await _notificationService.enablePushNotifications();
    if (success) {
      _isPushEnabled = true;
      notifyListeners();
    }
    return success;
  }

  /// Disable push notifications
  Future<bool> disablePushNotifications() async {
    final success = await _notificationService.disablePushNotifications();
    if (success) {
      _isPushEnabled = false;
      notifyListeners();
    }
    return success;
  }

  /// Toggle push notifications
  Future<bool> togglePushNotifications(bool enable) async {
    if (enable) {
      return await enablePushNotifications();
    } else {
      return await disablePushNotifications();
    }
  }

  /// Check if push notifications are enabled
  Future<void> checkPushStatus() async {
    _isPushEnabled = await _notificationService.isPushEnabled();
    notifyListeners();
  }

  /// Get notification by ID
  AppNotification? getNotificationById(int id) {
    try {
      return _notifications.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Check if specific notification type is enabled
  bool isNotificationTypeEnabled(NotificationType type) {
    if (_preferences == null) return true; // Default to enabled
    return _preferences!.isTypeEnabled(type);
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    _notificationService.dispose();
    super.dispose();
  }
}

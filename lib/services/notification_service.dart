import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../screens/service_details_screen.dart';
import '../screens/main_screen.dart';
import 'navigation_service.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('NotificationService: Background message received: ${message.messageId}');
  }
}

/// Notification Service - Handles both FCM push and in-app notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  FirebaseMessaging? _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Stream controllers
  final StreamController<AppNotification> _notificationStreamController =
      StreamController<AppNotification>.broadcast();
  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();
  bool _isDisposed = false;

  Stream<AppNotification> get notificationStream => _notificationStreamController.stream;
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  RealtimeChannel? _realtimeChannel;
  bool _isInitialized = false;
  String? _currentUserId;
  NotificationPreferences? _cachedPreferences;

  /// Safely add notification to stream (checks if disposed)
  void _safeAddNotification(AppNotification notification) {
    if (!_isDisposed && !_notificationStreamController.isClosed) {
      _notificationStreamController.add(notification);
    }
  }

  /// Safely add unread count to stream (checks if disposed)
  void _safeAddUnreadCount(int count) {
    if (!_isDisposed && !_unreadCountController.isClosed) {
      _unreadCountController.add(count);
    }
  }

  /// Check if notification should be shown based on user preferences
  bool _shouldShowNotification(AppNotification notification) {
    if (kDebugMode) {
      print('NotificationService: Checking if should show notification');
      print('NotificationService: Cached preferences: $_cachedPreferences');
      print('NotificationService: Push enabled: ${_cachedPreferences?.pushEnabled}');
      print('NotificationService: Notification type: ${notification.type}');
    }

    // If no cached preferences, default to showing notifications
    if (_cachedPreferences == null) {
      if (kDebugMode) {
        print('NotificationService: No cached preferences, showing notification');
      }
      return true;
    }

    // Check if push is enabled globally
    if (!_cachedPreferences!.pushEnabled) {
      if (kDebugMode) {
        print('NotificationService: Push disabled, hiding notification');
      }
      return false;
    }

    // Check if specific notification type is enabled
    final typeEnabled = _cachedPreferences!.isTypeEnabled(notification.type);
    if (kDebugMode) {
      print('NotificationService: Type ${notification.type} enabled: $typeEnabled');
    }
    return typeEnabled;
  }

  /// Update cached preferences (call this when preferences change)
  void updateCachedPreferences(NotificationPreferences? preferences) {
    _cachedPreferences = preferences;
    if (kDebugMode) {
      print('NotificationService: Cached preferences updated - pushEnabled: ${preferences?.pushEnabled}');
    }
  }

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Try to initialize Firebase (will fail gracefully if not configured)
      await _initializeFirebase();

      _isInitialized = true;
      if (kDebugMode) {
        print('NotificationService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Initialization error: $e');
      }
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'tour_guid_notifications',
        'Tour Guide Notifications',
        description: 'Notifications for Tour Guide app',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Initialize Firebase Messaging
  Future<void> _initializeFirebase() async {
    try {
      // Check if Firebase is already initialized
      if (Firebase.apps.isEmpty) {
        if (kDebugMode) {
          print('NotificationService: Firebase not configured, skipping FCM');
        }
        return;
      }

      _firebaseMessaging = FirebaseMessaging.instance;

      // Request permission
      final settings = await _firebaseMessaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        print('NotificationService: Permission status: ${settings.authorizationStatus}');
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Set up message handlers (background handler is set in main.dart)
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        // Get and save FCM token
        final token = await _firebaseMessaging!.getToken();
        if (token != null) {
          await _saveFcmToken(token);
        }

        // Listen for token refresh
        _firebaseMessaging!.onTokenRefresh.listen(_saveFcmToken);
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Firebase init error (expected if not configured): $e');
      }
    }
  }

  /// Handle foreground FCM message
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('NotificationService: Foreground message: ${message.notification?.title}');
    }

    // Refresh notifications (always update the list)
    if (_currentUserId != null) {
      _fetchUnreadCount();
    }

    // Check if push is enabled before showing local notification
    if (_cachedPreferences != null && !_cachedPreferences!.pushEnabled) {
      if (kDebugMode) {
        print('NotificationService: FCM notification suppressed (push disabled)');
      }
      return;
    }

    // Check if specific notification type is enabled
    final type = message.data['type'] as String?;
    if (type != null && _cachedPreferences != null) {
      final notificationType = NotificationTypeExtension.fromString(type);
      if (!_cachedPreferences!.isTypeEnabled(notificationType)) {
        if (kDebugMode) {
          print('NotificationService: FCM notification suppressed (type $type disabled)');
        }
        return;
      }
    }

    // Show local notification
    _showLocalNotification(
      title: message.notification?.title ?? 'Tour Guide',
      body: message.notification?.body ?? '',
      payload: jsonEncode(message.data),
    );
  }

  /// Handle when user taps on notification (from background)
  void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      print('NotificationService: Message opened app: ${message.data}');
    }
    // Navigate based on notification data
    _handleNotificationNavigation(message.data);
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _handleNotificationNavigation(data);
      } catch (e) {
        if (kDebugMode) {
          print('NotificationService: Error parsing notification payload: $e');
        }
      }
    }
  }

  /// Handle notification navigation based on type
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    if (kDebugMode) {
      print('NotificationService: Navigate with data: $data');
    }

    final type = data['type'] as String?;
    final serviceId = data['service_id'];

    // Wait a moment to ensure the app is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      final navService = NavigationService();

      switch (type) {
        case 'review':
        case 'favorite':
          // Navigate to service details screen
          if (serviceId != null) {
            final id = int.tryParse(serviceId.toString());
            if (id != null) {
              navService.push(ServiceDetailsScreen(serviceId: id));
            }
          }
          break;
        case 'ads':
        case 'promotion':
          // Navigate to home screen (main screen)
          navService.pushAndRemoveUntil(const MainScreen());
          break;
        case 'service_update':
          // Navigate to service details if serviceId exists
          if (serviceId != null) {
            final id = int.tryParse(serviceId.toString());
            if (id != null) {
              navService.push(ServiceDetailsScreen(serviceId: id));
            }
          }
          break;
        default:
          // For unknown types, just go to home
          if (kDebugMode) {
            print('NotificationService: Unknown notification type: $type');
          }
          break;
      }
    });
  }

  /// Navigate to service details from notification data
  static void navigateFromNotification(AppNotification notification) {
    final navService = NavigationService();

    switch (notification.type) {
      case NotificationType.review:
      case NotificationType.favorite:
      case NotificationType.serviceUpdate:
        // Navigate to service details screen
        final serviceId = notification.serviceId;
        if (serviceId != null) {
          navService.push(ServiceDetailsScreen(serviceId: serviceId));
        }
        break;
      case NotificationType.ads:
      case NotificationType.promotion:
        // Navigate to home screen
        navService.pushAndRemoveUntil(const MainScreen());
        break;
      case NotificationType.system:
      case NotificationType.verification:
        // System/Verification notifications - no navigation needed
        break;
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'tour_guid_notifications',
      'Tour Guide Notifications',
      channelDescription: 'Notifications for Tour Guide app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Save FCM token to database
  Future<void> _saveFcmToken(String token) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'device_type': Platform.isAndroid ? 'android' : 'ios',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, token');

      if (kDebugMode) {
        print('NotificationService: FCM token saved');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Error saving FCM token: $e');
      }
    }
  }

  /// Set current user and start listening for notifications
  Future<void> setUser(String userId) async {
    _currentUserId = userId;

    // Subscribe to realtime notifications
    await _subscribeToNotifications(userId);

    // Fetch initial unread count
    await _fetchUnreadCount();

    // Load and cache preferences for notification filtering
    await fetchPreferences();
  }

  /// Clear user (on logout)
  Future<void> clearUser() async {
    _currentUserId = null;
    _cachedPreferences = null;
    await _unsubscribeFromNotifications();
    _safeAddUnreadCount(0);
  }

  /// Subscribe to realtime notifications
  Future<void> _subscribeToNotifications(String userId) async {
    await _unsubscribeFromNotifications();

    _realtimeChannel = _supabase.channel('notifications:$userId');

    _realtimeChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            if (kDebugMode) {
              print('NotificationService: New notification received');
            }

            final notification = AppNotification.fromJson(payload.newRecord);

            // Always add to notification list (for in-app viewing)
            _safeAddNotification(notification);

            // Update unread count
            _fetchUnreadCount();

            // Only show local notification if push is enabled and notification type is enabled
            if (_shouldShowNotification(notification)) {
              _showLocalNotification(
                title: notification.title,
                body: notification.body,
                payload: jsonEncode(notification.data),
              );
            } else {
              if (kDebugMode) {
                print('NotificationService: Notification suppressed (disabled in preferences)');
              }
            }
          },
        )
        .subscribe();

    if (kDebugMode) {
      print('NotificationService: Subscribed to notifications for user: $userId');
    }
  }

  /// Unsubscribe from realtime notifications
  Future<void> _unsubscribeFromNotifications() async {
    if (_realtimeChannel != null) {
      await _supabase.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
  }

  /// Fetch notifications from Supabase
  Future<List<AppNotification>> fetchNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    final userId = _currentUserId ?? _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Error fetching notifications: $e');
      }
      return [];
    }
  }

  /// Fetch unread count
  Future<int> _fetchUnreadCount() async {
    final userId = _currentUserId ?? _supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      final count = (response as List).length;
      _safeAddUnreadCount(count);
      return count;
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Error fetching unread count: $e');
      }
      return 0;
    }
  }

  /// Get current unread count
  Future<int> getUnreadCount() async {
    return _fetchUnreadCount();
  }

  /// Mark notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      await _fetchUnreadCount();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Error marking as read: $e');
      }
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    final userId = _currentUserId ?? _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      _safeAddUnreadCount(0);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Error marking all as read: $e');
      }
      return false;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(int notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);

      await _fetchUnreadCount();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Error deleting notification: $e');
      }
      return false;
    }
  }

  /// Delete all notifications
  Future<bool> deleteAllNotifications() async {
    final userId = _currentUserId ?? _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId);

      _safeAddUnreadCount(0);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Error deleting all notifications: $e');
      }
      return false;
    }
  }

  /// Fetch notification preferences
  Future<NotificationPreferences?> fetchPreferences() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('notification_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      NotificationPreferences? prefs;
      if (response != null) {
        prefs = NotificationPreferences.fromJson(response);
      } else {
        // Return default preferences if none exist
        prefs = NotificationPreferences(userId: userId);
      }

      // Cache the preferences for use in _shouldShowNotification
      _cachedPreferences = prefs;

      return prefs;
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Error fetching preferences: $e');
      }
      return null;
    }
  }

  /// Update notification preferences
  Future<bool> updatePreferences(NotificationPreferences preferences) async {
    try {
      await _supabase.from('notification_preferences').upsert(
        preferences.toJson(),
        onConflict: 'user_id',
      );

      // Update cached preferences
      _cachedPreferences = preferences;
      if (kDebugMode) {
        print('NotificationService: Preferences updated - pushEnabled: ${preferences.pushEnabled}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Error updating preferences: $e');
      }
      return false;
    }
  }

  /// Get FCM token (for debugging)
  Future<String?> getFcmToken() async {
    try {
      if (_firebaseMessaging != null) {
        return await _firebaseMessaging!.getToken();
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Error getting FCM token: $e');
      }
    }
    return null;
  }

  /// Enable push notifications - save FCM token to database
  Future<bool> enablePushNotifications() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      if (_firebaseMessaging == null) {
        if (kDebugMode) {
          print('NotificationService: Firebase not initialized');
        }
        return false;
      }

      // Get a fresh FCM token (will generate new one if deleted)
      final token = await _firebaseMessaging!.getToken();
      if (token == null) {
        if (kDebugMode) {
          print('NotificationService: No FCM token available');
        }
        return false;
      }

      if (kDebugMode) {
        print('NotificationService: Got FCM token: ${token.substring(0, 20)}...');
      }

      // Save token to database
      await _supabase.from('fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'device_type': Platform.isAndroid ? 'android' : 'ios',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, token');

      if (kDebugMode) {
        print('NotificationService: Push notifications enabled and token saved');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Error enabling push notifications: $e');
      }
      return false;
    }
  }

  /// Disable push notifications - remove FCM token from database and device
  Future<bool> disablePushNotifications() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      // Delete all tokens for this user from database
      await _supabase.from('fcm_tokens').delete().eq('user_id', userId);

      // Also delete the FCM token from the device to stop receiving background notifications
      if (_firebaseMessaging != null) {
        await _firebaseMessaging!.deleteToken();
        if (kDebugMode) {
          print('NotificationService: FCM token deleted from device');
        }
      }

      if (kDebugMode) {
        print('NotificationService: Push notifications disabled');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Error disabling push notifications: $e');
      }
      return false;
    }
  }

  /// Check if push notifications are enabled for current user
  Future<bool> isPushEnabled() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final result = await _supabase
          .from('fcm_tokens')
          .select('id')
          .eq('user_id', userId)
          .limit(1);

      return result.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Error checking push status: $e');
      }
      return false;
    }
  }

  /// Send a test notification (for debugging)
  Future<void> sendTestNotification() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'type': 'system',
        'title': 'اختبار الإشعارات',
        'body': 'هذا إشعار تجريبي للتأكد من عمل النظام',
        'data': {'test': true},
      });

      if (kDebugMode) {
        print('NotificationService: Test notification sent');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Error sending test notification: $e');
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _isDisposed = true;
    _unsubscribeFromNotifications();
    if (!_notificationStreamController.isClosed) {
      _notificationStreamController.close();
    }
    if (!_unreadCountController.isClosed) {
      _unreadCountController.close();
    }
    _isInitialized = false;
  }
}

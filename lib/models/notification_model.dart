/// Notification types
enum NotificationType {
  review,
  favorite,
  serviceUpdate,
  promotion,
  ads,
  system,
  verification,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.review:
        return 'review';
      case NotificationType.favorite:
        return 'favorite';
      case NotificationType.serviceUpdate:
        return 'service_update';
      case NotificationType.promotion:
        return 'promotion';
      case NotificationType.ads:
        return 'ads';
      case NotificationType.system:
        return 'system';
      case NotificationType.verification:
        return 'verification';
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'review':
        return NotificationType.review;
      case 'favorite':
        return NotificationType.favorite;
      case 'service_update':
        return NotificationType.serviceUpdate;
      case 'promotion':
        return NotificationType.promotion;
      case 'ads':
        return NotificationType.ads;
      case 'system':
        return NotificationType.system;
      case 'verification':
        return NotificationType.verification;
      default:
        return NotificationType.system;
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.review:
        return '⭐';
      case NotificationType.favorite:
        return '❤️';
      case NotificationType.serviceUpdate:
        return '🔄';
      case NotificationType.promotion:
        return '🎁';
      case NotificationType.ads:
        return '🎉';
      case NotificationType.system:
        return '📢';
      case NotificationType.verification:
        return '✓';
    }
  }

  String get titleAr {
    switch (this) {
      case NotificationType.review:
        return 'تقييم جديد';
      case NotificationType.favorite:
        return 'إضافة للمفضلة';
      case NotificationType.serviceUpdate:
        return 'تحديث الخدمة';
      case NotificationType.promotion:
        return 'ترويج';
      case NotificationType.ads:
        return 'عرض خاص';
      case NotificationType.system:
        return 'إشعار النظام';
      case NotificationType.verification:
        return 'حالة التوثيق';
    }
  }
}

/// Notification model
class AppNotification {
  final int id;
  final String odUser;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.odUser,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? 0,
      odUser: json['user_id'] ?? '',
      type: NotificationTypeExtension.fromString(json['type'] ?? 'system'),
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : {},
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': odUser,
      'type': type.value,
      'title': title,
      'body': body,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AppNotification copyWith({
    int? id,
    String? odUser,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      odUser: odUser ?? this.odUser,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get the service ID from data (if applicable)
  int? get serviceId => data['service_id'] as int?;

  /// Get the review ID from data (if applicable)
  int? get reviewId => data['review_id'] as int?;

  /// Get the rating from data (if applicable)
  int? get rating => data['rating'] as int?;

  /// Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'منذ $months ${months == 1 ? 'شهر' : 'أشهر'}';
    } else if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} ${difference.inDays == 1 ? 'يوم' : 'أيام'}';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'}';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
    } else {
      return 'الآن';
    }
  }
}

/// Notification preferences model
class NotificationPreferences {
  final int? id;
  final String userId;
  final bool pushEnabled;
  final bool reviewNotifications;
  final bool favoriteNotifications;
  final bool serviceUpdateNotifications;
  final bool promotionNotifications;
  final bool adsNotifications;
  final bool systemNotifications;
  final bool verificationNotifications;

  NotificationPreferences({
    this.id,
    required this.userId,
    this.pushEnabled = true,
    this.reviewNotifications = true,
    this.favoriteNotifications = true,
    this.serviceUpdateNotifications = true,
    this.promotionNotifications = true,
    this.adsNotifications = true,
    this.systemNotifications = true,
    this.verificationNotifications = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      id: json['id'],
      userId: json['user_id'] ?? '',
      pushEnabled: json['push_enabled'] ?? true,
      reviewNotifications: json['review_notifications'] ?? true,
      favoriteNotifications: json['favorite_notifications'] ?? true,
      serviceUpdateNotifications: json['service_update_notifications'] ?? true,
      promotionNotifications: json['promotion_notifications'] ?? true,
      adsNotifications: json['ads_notifications'] ?? true,
      systemNotifications: json['system_notifications'] ?? true,
      verificationNotifications: json['verification_notifications'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'push_enabled': pushEnabled,
      'review_notifications': reviewNotifications,
      'favorite_notifications': favoriteNotifications,
      'service_update_notifications': serviceUpdateNotifications,
      'promotion_notifications': promotionNotifications,
      'ads_notifications': adsNotifications,
      'system_notifications': systemNotifications,
      'verification_notifications': verificationNotifications,
    };
  }

  NotificationPreferences copyWith({
    int? id,
    String? userId,
    bool? pushEnabled,
    bool? reviewNotifications,
    bool? favoriteNotifications,
    bool? serviceUpdateNotifications,
    bool? promotionNotifications,
    bool? adsNotifications,
    bool? systemNotifications,
    bool? verificationNotifications,
  }) {
    return NotificationPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      reviewNotifications: reviewNotifications ?? this.reviewNotifications,
      favoriteNotifications: favoriteNotifications ?? this.favoriteNotifications,
      serviceUpdateNotifications: serviceUpdateNotifications ?? this.serviceUpdateNotifications,
      promotionNotifications: promotionNotifications ?? this.promotionNotifications,
      adsNotifications: adsNotifications ?? this.adsNotifications,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      verificationNotifications: verificationNotifications ?? this.verificationNotifications,
    );
  }

  /// Check if a specific notification type is enabled
  bool isTypeEnabled(NotificationType type) {
    if (!pushEnabled) return false;

    switch (type) {
      case NotificationType.review:
        return reviewNotifications;
      case NotificationType.favorite:
        return favoriteNotifications;
      case NotificationType.serviceUpdate:
        return serviceUpdateNotifications;
      case NotificationType.promotion:
        return promotionNotifications;
      case NotificationType.ads:
        return adsNotifications;
      case NotificationType.system:
        return systemNotifications;
      case NotificationType.verification:
        return verificationNotifications;
    }
  }
}

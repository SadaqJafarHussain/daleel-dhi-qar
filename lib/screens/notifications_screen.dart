import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../utils/app_localization.dart';
import '../utils/app_icons.dart';
import '../utils/app_texts_style.dart';
import 'service_details_screen.dart';
import 'main_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load notifications on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<NotificationProvider>(context, listen: false);
      provider.refreshNotifications();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<NotificationProvider>(context, listen: false);
      provider.loadMoreNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AppBackButton.light(),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_outlined,
                color: Theme.of(context).iconTheme.color),
            const SizedBox(width: 10),
            Text(
              loc.t('notifications'),
              style: TextStyle(
                color: Theme.of(context).textTheme.displayMedium!.color,
                fontWeight: FontWeight.bold,
                fontSize: AppTextSizes.h2,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.notifications.isEmpty) {
                return const SizedBox.shrink();
              }
              return PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    color: Theme.of(context).iconTheme.color),
                onSelected: (value) async {
                  if (value == 'mark_all_read') {
                    await provider.markAllAsRead();
                    HapticFeedback.lightImpact();
                  } else if (value == 'delete_all') {
                    _showDeleteAllDialog(context, provider);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        const Icon(Icons.done_all, size: 20),
                        const SizedBox(width: 12),
                        Text(loc.t('mark_all_read')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete_all',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 20, color: Colors.red.shade400),
                        const SizedBox(width: 12),
                        Text(loc.t('delete_all'),
                            style: TextStyle(color: Colors.red.shade400)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return _buildLoadingState(isDark);
          }

          if (provider.notifications.isEmpty) {
            return _buildEmptyState(context, loc, isDark, w, h);
          }

          return RefreshIndicator(
            onRefresh: provider.refreshNotifications,
            color: Theme.of(context).primaryColor,
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.04,
                vertical: h * 0.015,
              ),
              itemCount: provider.notifications.length +
                  (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.notifications.length) {
                  return _buildLoadMoreIndicator();
                }

                final notification = provider.notifications[index];
                final showDateHeader = _shouldShowDateHeader(
                  provider.notifications, index);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showDateHeader)
                      _buildDateHeader(context, notification.createdAt, loc),
                    _NotificationTile(
                      notification: notification,
                      onTap: () => _handleNotificationTap(
                          context, notification, provider),
                      onDismiss: () => provider.deleteNotification(notification.id),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  bool _shouldShowDateHeader(List<AppNotification> notifications, int index) {
    if (index == 0) return true;

    final current = notifications[index].createdAt;
    final previous = notifications[index - 1].createdAt;

    return !_isSameDay(current, previous);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateHeader(BuildContext context, DateTime date, AppLocalizations loc) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(date.year, date.month, date.day);

    String label;
    if (notificationDate == today) {
      label = loc.t('today');
    } else if (notificationDate == yesterday) {
      label = loc.t('yesterday');
    } else {
      label = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: CircularProgressIndicator(
        color: isDark ? Colors.white70 : Colors.grey.shade600,
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations loc,
      bool isDark, double w, double h) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade800.withOpacity(0.5)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: w * 0.15,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
          SizedBox(height: h * 0.03),
          Text(
            loc.t('no_notifications'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: h * 0.01),
          Text(
            loc.t('no_notifications_subtitle'),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(BuildContext context,
      AppNotification notification, NotificationProvider provider) {
    // Mark as read
    if (!notification.isRead) {
      provider.markAsRead(notification.id);
    }

    HapticFeedback.selectionClick();

    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.review:
      case NotificationType.favorite:
      case NotificationType.serviceUpdate:
        // Navigate to service details screen
        final serviceId = notification.serviceId;
        if (serviceId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServiceDetailsScreen(serviceId: serviceId),
            ),
          );
        } else {
          // Show details in bottom sheet if no service ID
          _showNotificationDetails(context, notification);
        }
        break;
      case NotificationType.ads:
      case NotificationType.promotion:
        // Navigate to home screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
        break;
      case NotificationType.system:
      case NotificationType.verification:
        // System/Verification notifications - show details in bottom sheet
        _showNotificationDetails(context, notification);
        break;
    }
  }

  void _showNotificationDetails(BuildContext context, AppNotification notification) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildNotificationIcon(notification.type, 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              notification.body,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type, double size) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.review:
        icon = Icons.star_rounded;
        color = const Color(0xFFFBBF24);
        break;
      case NotificationType.favorite:
        icon = Icons.favorite_rounded;
        color = const Color(0xFFEF4444);
        break;
      case NotificationType.serviceUpdate:
        icon = Icons.update_rounded;
        color = const Color(0xFF10B981);
        break;
      case NotificationType.promotion:
        icon = Icons.local_offer_rounded;
        color = const Color(0xFF8B5CF6);
        break;
      case NotificationType.ads:
        icon = Icons.campaign_rounded;
        color = const Color(0xFFEC4899);
        break;
      case NotificationType.system:
        icon = Icons.info_rounded;
        color = const Color(0xFF6B7280);
        break;
      case NotificationType.verification:
        icon = Icons.verified_rounded;
        color = const Color(0xFF3B82F6);
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }

  void _showDeleteAllDialog(BuildContext context, NotificationProvider provider) {
    final loc = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.t('delete_all_notifications')),
        content: Text(loc.t('delete_all_notifications_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.t('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.deleteAllNotifications();
              HapticFeedback.lightImpact();
            },
            child: Text(
              loc.t('delete'),
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual notification tile widget
class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Theme.of(context).cardColor
                : (isDark
                    ? const Color(0xFF1E3A5F).withOpacity(0.5)
                    : const Color(0xFFE0F2FE)),
            borderRadius: BorderRadius.circular(12),
            border: notification.isRead
                ? Border.all(
                    color: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(notification.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF3B82F6),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(NotificationType type) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.review:
        icon = Icons.star_rounded;
        color = const Color(0xFFFBBF24);
        break;
      case NotificationType.favorite:
        icon = Icons.favorite_rounded;
        color = const Color(0xFFEF4444);
        break;
      case NotificationType.serviceUpdate:
        icon = Icons.update_rounded;
        color = const Color(0xFF10B981);
        break;
      case NotificationType.promotion:
        icon = Icons.local_offer_rounded;
        color = const Color(0xFF8B5CF6);
        break;
      case NotificationType.ads:
        icon = Icons.campaign_rounded;
        color = const Color(0xFFEC4899);
        break;
      case NotificationType.system:
        icon = Icons.info_rounded;
        color = const Color(0xFF6B7280);
        break;
      case NotificationType.verification:
        icon = Icons.verified_rounded;
        color = const Color(0xFF3B82F6);
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

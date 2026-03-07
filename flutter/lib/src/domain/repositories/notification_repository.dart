import 'package:k_budget/src/domain/models/notification.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> getNotifications({int page = 0, int size = 20, bool? unreadOnly});
  Future<int> getUnreadCount();
  Future<NotificationModel> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String id);
  Future<void> deleteAll();
}

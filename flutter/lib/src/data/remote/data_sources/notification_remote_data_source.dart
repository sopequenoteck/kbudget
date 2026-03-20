import 'package:dio/dio.dart';
import 'package:k_budget/src/domain/models/notification.dart';

class NotificationRemoteDataSource {
  final Dio _dio;

  NotificationRemoteDataSource(this._dio);

  Future<List<NotificationModel>> getNotifications({int page = 0, int size = 20, bool? unreadOnly}) async {
    final queryParams = <String, dynamic>{'page': page, 'size': size};
    if (unreadOnly != null) queryParams['unread'] = unreadOnly;
    final response = await _dio.get<Map<String, dynamic>>(
      '/notifications',
      queryParameters: queryParams,
    );
    final content = response.data!['content'] as List<dynamic>;
    return content
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await _dio.get<Map<String, dynamic>>('/notifications/unread-count');
    return response.data!['count'] as int;
  }

  Future<NotificationModel> markAsRead(String id) async {
    final response = await _dio.put<Map<String, dynamic>>('/notifications/$id/read');
    return NotificationModel.fromJson(response.data!);
  }

  Future<void> markAllAsRead() async {
    await _dio.put<void>('/notifications/read-all');
  }

  Future<void> deleteNotification(String id) async {
    await _dio.delete<void>('/notifications/$id');
  }

  Future<void> deleteAll() async {
    await _dio.delete<void>('/notifications');
  }
}

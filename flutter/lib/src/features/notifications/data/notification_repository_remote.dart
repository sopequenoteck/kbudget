// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:k_budget/src/data/remote/data_sources/notification_remote_data_source.dart';
import 'package:k_budget/src/domain/models/notification.dart';
import 'package:k_budget/src/domain/repositories/notification_repository.dart';

class NotificationRepositoryRemote implements NotificationRepository {
  final NotificationRemoteDataSource _dataSource;

  NotificationRepositoryRemote(this._dataSource);

  @override
  Future<List<NotificationModel>> getNotifications({int page = 0, int size = 20, bool? unreadOnly}) =>
      _dataSource.getNotifications(page: page, size: size, unreadOnly: unreadOnly);

  @override
  Future<int> getUnreadCount() => _dataSource.getUnreadCount();

  @override
  Future<NotificationModel> markAsRead(String id) => _dataSource.markAsRead(id);

  @override
  Future<void> markAllAsRead() => _dataSource.markAllAsRead();

  @override
  Future<void> deleteNotification(String id) => _dataSource.deleteNotification(id);

  @override
  Future<void> deleteAll() => _dataSource.deleteAll();
}

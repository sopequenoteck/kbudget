// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:k_budget/src/domain/models/notification.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> getNotifications({int page = 0, int size = 20, bool? unreadOnly});
  Future<int> getUnreadCount();
  Future<NotificationModel> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String id);
  Future<void> deleteAll();
}

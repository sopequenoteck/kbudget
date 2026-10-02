// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/entity_type.dart';
import 'package:k_budget/src/domain/enums/notification_type.dart';
import 'package:k_budget/src/domain/models/notification.dart';

Map<String, dynamic> _json({
  String type = 'SUBSCRIPTION_DUE',
  String? entityType = 'SUBSCRIPTION',
  Map<String, dynamic>? params,
}) =>
    {
      'id': 'n-1',
      'type': type,
      'title': 'Subscription Netflix',
      'message': 'Netflix is due tomorrow',
      'entityType': entityType,
      'entityId': 'sub-1',
      'read': false,
      'readAt': null,
      'createdAt': '2026-09-30T08:00:00Z',
      'params': params,
    };

void main() {
  group('NotificationModel.fromJson', () {
    test('should_readParams_when_paramsArePresent', () {
      final model = NotificationModel.fromJson(
        _json(params: {'name': 'Netflix'}),
      );

      expect(model.params, {'name': 'Netflix'});
      expect(model.type, NotificationType.subscriptionDue);
      expect(model.entityType, EntityType.subscription);
    });

    test('should_leaveParamsNull_when_paramsAreAbsent', () {
      final model = NotificationModel.fromJson(_json()..remove('params'));

      expect(model.params, isNull);
    });

    test('should_setTypeNull_when_typeIsUnknown', () {
      final model = NotificationModel.fromJson(_json(type: 'NEW_TYPE'));

      expect(model.type, isNull);
      expect(model.title, 'Subscription Netflix');
    });

    test('should_setEntityTypeNull_when_entityTypeIsUnknown', () {
      final model = NotificationModel.fromJson(_json(entityType: 'WIDGET'));

      expect(model.entityType, isNull);
      expect(model.entityId, 'sub-1');
    });
  });
}

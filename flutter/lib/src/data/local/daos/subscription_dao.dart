// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/drift.dart';
import 'package:k_budget/src/data/local/database.dart';

part 'subscription_dao.g.dart';

@DriftAccessor(tables: [Subscriptions])
class SubscriptionDao extends DatabaseAccessor<AppDatabase>
    with _$SubscriptionDaoMixin {
  SubscriptionDao(super.db);

  Future<List<Subscription>> getAllSubscriptions() =>
      select(subscriptions).get();

  Stream<List<Subscription>> watchAllSubscriptions() =>
      select(subscriptions).watch();

  Future<Subscription> getSubscriptionById(String id) =>
      (select(subscriptions)..where((t) => t.id.equals(id))).getSingle();

  Future<int> insertSubscription(SubscriptionsCompanion subscription) =>
      into(subscriptions).insert(subscription);

  Future<bool> updateSubscription(SubscriptionsCompanion subscription) =>
      update(subscriptions).replace(subscription);

  Future<int> deleteSubscription(String id) =>
      (delete(subscriptions)..where((t) => t.id.equals(id))).go();
}

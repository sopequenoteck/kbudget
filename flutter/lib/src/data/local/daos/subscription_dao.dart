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

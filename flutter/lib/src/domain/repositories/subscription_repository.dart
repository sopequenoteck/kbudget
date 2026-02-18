import 'package:k_budget/src/domain/models/subscription.dart';

abstract class SubscriptionRepository {
  Future<List<Subscription>> getAll();
  Stream<List<Subscription>> watchAll();
  Future<Subscription> getById(String id);
  Future<Subscription> create(Subscription subscription);
  Future<Subscription> update(Subscription subscription);
  Future<void> delete(String id);
}

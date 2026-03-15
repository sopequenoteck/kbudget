import 'package:k_budget/src/domain/models/subscription.dart';
import 'package:k_budget/src/domain/models/subscription_payment.dart';
import 'package:k_budget/src/domain/models/subscription_total_paid.dart';

abstract class SubscriptionRepository {
  Future<List<Subscription>> getAll();
  Stream<List<Subscription>> watchAll();
  Future<Subscription> getById(String id);
  Future<Subscription> create(Subscription subscription);
  Future<Subscription> update(Subscription subscription);
  Future<void> delete(String id);
  Future<SubscriptionPayment> pay(String id);
  Future<List<SubscriptionPayment>> getPayments(String id);
  Future<SubscriptionTotalPaid> getTotalPaid(String id);
}

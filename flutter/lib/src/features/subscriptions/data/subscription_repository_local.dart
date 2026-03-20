import 'package:k_budget/src/data/local/daos/subscription_dao.dart';
import 'package:k_budget/src/data/local/mappers.dart';
import 'package:k_budget/src/domain/models/subscription.dart';
import 'package:k_budget/src/domain/models/subscription_payment.dart';
import 'package:k_budget/src/domain/models/subscription_total_paid.dart';
import 'package:k_budget/src/domain/repositories/subscription_repository.dart';

class SubscriptionRepositoryLocal implements SubscriptionRepository {
  final SubscriptionDao _dao;

  SubscriptionRepositoryLocal(this._dao);

  @override
  Future<List<Subscription>> getAll() async {
    final rows = await _dao.getAllSubscriptions();
    return rows.map(subscriptionFromDb).toList();
  }

  @override
  Stream<List<Subscription>> watchAll() {
    return _dao.watchAllSubscriptions().map(
          (rows) => rows.map(subscriptionFromDb).toList(),
        );
  }

  @override
  Future<Subscription> getById(String id) async {
    final row = await _dao.getSubscriptionById(id);
    return subscriptionFromDb(row);
  }

  @override
  Future<Subscription> create(Subscription subscription) async {
    await _dao.insertSubscription(subscriptionToDb(subscription));
    return subscription;
  }

  @override
  Future<Subscription> update(Subscription subscription) async {
    await _dao.updateSubscription(subscriptionToDb(subscription));
    return subscription;
  }

  @override
  Future<void> delete(String id) async {
    await _dao.deleteSubscription(id);
  }

  @override
  Future<SubscriptionPayment> pay(String id) async {
    // Server-only: paiements gérés uniquement via l'API
    throw UnsupportedError(
      'Subscription payments are only available in server mode',
    );
  }

  @override
  Future<List<SubscriptionPayment>> getPayments(String id) async {
    // Server-only: pas d'historique local
    return [];
  }

  @override
  Future<SubscriptionTotalPaid> getTotalPaid(String id) async {
    // Server-only: pas de total local
    return const SubscriptionTotalPaid(
      subscriptionId: '',
      totalPaid: 0,
      paymentCount: 0,
    );
  }
}

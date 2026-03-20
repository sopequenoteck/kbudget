import 'package:k_budget/src/data/remote/data_sources/subscription_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/subscription_dtos.dart';
import 'package:k_budget/src/data/remote/dtos/subscription_payment_dtos.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/utils/enum_utils.dart';
import 'package:k_budget/src/domain/models/subscription.dart';
import 'package:k_budget/src/domain/models/subscription_payment.dart';
import 'package:k_budget/src/domain/models/subscription_total_paid.dart';
import 'package:k_budget/src/domain/repositories/subscription_repository.dart';

class SubscriptionRepositoryRemote implements SubscriptionRepository {
  final SubscriptionRemoteDataSource _dataSource;

  SubscriptionRepositoryRemote(this._dataSource);

  @override
  Future<List<Subscription>> getAll() async {
    final responses = await _dataSource.getAll();
    return responses.map(_toDomain).toList();
  }

  @override
  Stream<List<Subscription>> watchAll() async* {
    yield await getAll();
  }

  @override
  Future<Subscription> getById(String id) async {
    final response = await _dataSource.getById(id);
    return _toDomain(response);
  }

  @override
  Future<Subscription> create(Subscription subscription) async {
    final request = _toRequest(subscription);
    final response = await _dataSource.create(request);
    return _toDomain(response);
  }

  @override
  Future<Subscription> update(Subscription subscription) async {
    final request = _toRequest(subscription);
    final response = await _dataSource.update(subscription.id, request);
    return _toDomain(response);
  }

  @override
  Future<void> delete(String id) => _dataSource.delete(id);

  @override
  Future<SubscriptionPayment> pay(String id) async {
    final response = await _dataSource.pay(id);
    return response.toDomain();
  }

  @override
  Future<List<SubscriptionPayment>> getPayments(String id) async {
    final responses = await _dataSource.getPayments(id);
    return responses.map((r) => r.toDomain()).toList();
  }

  @override
  Future<SubscriptionTotalPaid> getTotalPaid(String id) async {
    final response = await _dataSource.getTotalPaid(id);
    return response.toDomain();
  }

  Subscription _toDomain(SubscriptionResponse r) => Subscription(
        id: r.id,
        nom: r.nom,
        montant: r.montant,
        frequence: Frequency.values.byNameOrDefault(r.frequence.toLowerCase(), Frequency.mensuel),
        dateDebut: DateTime.parse(r.dateDebut),
        currency: Currency.values.byNameOrDefault(r.currency.toLowerCase(), Currency.eur),
        actif: r.actif,
        categoryId: r.categoryId,
        accountId: r.accountId,
        updatedAt: r.updatedAt != null ? DateTime.parse(r.updatedAt!) : null,
      );

  SubscriptionRequest _toRequest(Subscription s) => SubscriptionRequest(
        nom: s.nom,
        montant: s.montant,
        frequence: s.frequence.name.toUpperCase(),
        dateDebut: s.dateDebut.toIso8601String(),
        actif: s.actif,
        categoryId: s.categoryId,
        accountId: s.accountId,
      );
}

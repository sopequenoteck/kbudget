import 'package:k_budget/src/data/remote/data_sources/account_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/account_dtos.dart';
import 'package:k_budget/src/data/remote/dtos/adjust_balance_request.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/utils/enum_utils.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/repositories/account_repository.dart';

class AccountRepositoryRemote implements AccountRepository {
  final AccountRemoteDataSource _dataSource;

  AccountRepositoryRemote(this._dataSource);

  @override
  Future<List<Account>> getAll() async {
    final responses = await _dataSource.getAll();
    return responses.map(_toDomain).toList();
  }

  @override
  Stream<List<Account>> watchAll() async* {
    yield await getAll();
  }

  @override
  Future<Account> getById(String id) async {
    final response = await _dataSource.getById(id);
    return _toDomain(response);
  }

  @override
  Future<Account> create(Account account) async {
    final request = _toRequest(account);
    final response = await _dataSource.create(request);
    return _toDomain(response);
  }

  @override
  Future<Account> update(Account account) async {
    final request = _toRequest(account);
    final response = await _dataSource.update(account.id, request);
    return _toDomain(response);
  }

  @override
  Future<void> delete(String id) => _dataSource.delete(id);

  @override
  Future<Account> setDefault(String id) async {
    final response = await _dataSource.setDefault(id);
    return _toDomain(response);
  }

  @override
  Future<Account> adjustBalance(String id, double newBalance) async {
    final request = AdjustBalanceRequest(newBalance: newBalance);
    final response = await _dataSource.adjustBalance(id, request);
    return _toDomain(response);
  }

  Account _toDomain(AccountResponse r) => Account(
        id: r.id,
        nom: r.nom,
        type: AccountType.values.byNameOrDefault(r.type.toLowerCase(), AccountType.courant),
        soldeInitial: r.soldeInitial,
        icone: r.icone,
        couleur: r.couleur,
        isDefault: r.isDefault,
        currency: Currency.values.byNameOrDefault(r.currency.toLowerCase(), Currency.eur),
        actif: r.actif,
        solde: r.solde,
        updatedAt: r.updatedAt != null ? DateTime.parse(r.updatedAt!) : null,
        bankCode: r.bankCode ?? 'OTHER',
        bankName: r.bankName,
        bankCountry: r.bankCountry,
        bankBrandColor: r.bankBrandColor,
        bankLogoUrl: r.bankLogoUrl,
        bankCustomName: r.bankCustomName,
        bankCustomLogo: r.bankCustomLogo,
      );

  AccountRequest _toRequest(Account a) => AccountRequest(
        nom: a.nom,
        type: a.type.name.toUpperCase(),
        soldeInitial: a.soldeInitial,
        icone: a.icone,
        couleur: a.couleur,
        isDefault: a.isDefault,
        currency: a.currency.name.toUpperCase(),
        actif: a.actif,
        bankCode: a.bankCode,
        bankCustomName: a.bankCode == 'OTHER' ? a.bankCustomName : null,
        bankCustomLogo: a.bankCode == 'OTHER' ? a.bankCustomLogo : null,
      );
}

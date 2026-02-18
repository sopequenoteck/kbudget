import 'package:k_budget/src/data/local/daos/account_dao.dart';
import 'package:k_budget/src/data/local/mappers.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/repositories/account_repository.dart';

class AccountRepositoryLocal implements AccountRepository {
  final AccountDao _dao;

  AccountRepositoryLocal(this._dao);

  @override
  Future<List<Account>> getAll() async {
    final rows = await _dao.getAllAccounts();
    return rows.map(accountFromDb).toList();
  }

  @override
  Stream<List<Account>> watchAll() {
    return _dao.watchAllAccounts().map(
          (rows) => rows.map(accountFromDb).toList(),
        );
  }

  @override
  Future<Account> getById(String id) async {
    final row = await _dao.getAccountById(id);
    return accountFromDb(row);
  }

  @override
  Future<Account> create(Account account) async {
    await _dao.insertAccount(accountToDb(account));
    return account;
  }

  @override
  Future<Account> update(Account account) async {
    await _dao.updateAccount(accountToDb(account));
    return account;
  }

  @override
  Future<void> delete(String id) async {
    await _dao.deleteAccount(id);
  }

  @override
  Future<Account> setDefault(String id) async {
    await _dao.setDefault(id);
    return getById(id);
  }
}

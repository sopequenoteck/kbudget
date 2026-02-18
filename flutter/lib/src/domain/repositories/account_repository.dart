import 'package:k_budget/src/domain/models/account.dart';

abstract class AccountRepository {
  Future<List<Account>> getAll();
  Stream<List<Account>> watchAll();
  Future<Account> getById(String id);
  Future<Account> create(Account account);
  Future<Account> update(Account account);
  Future<void> delete(String id);
  Future<Account> setDefault(String id);
}

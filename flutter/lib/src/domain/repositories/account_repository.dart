import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/repositories/crud_repository.dart';

abstract class AccountRepository extends CrudRepository<Account> {
  Stream<List<Account>> watchAll();
  Future<Account> getById(String id);
  Future<Account> setDefault(String id);
  Future<Account> adjustBalance(String id, double newBalance);
}

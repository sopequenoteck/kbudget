import 'package:k_budget/src/domain/models/transaction.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getAll();
  Stream<List<Transaction>> watchAll();
  Future<Transaction> getById(String id);
  Future<Transaction> create(Transaction transaction);
  Future<Transaction> update(Transaction transaction);
  Future<void> delete(String id);
}

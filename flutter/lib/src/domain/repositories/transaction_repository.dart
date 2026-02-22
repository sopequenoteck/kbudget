import 'package:k_budget/src/domain/models/monthly_summary.dart';
import 'package:k_budget/src/domain/models/transaction.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getAll();
  Stream<List<Transaction>> watchAll();
  Future<Transaction> getById(String id);
  Future<Transaction> create(Transaction transaction);
  Future<Transaction> update(Transaction transaction);
  Future<void> delete(String id);
  Future<List<MonthlySummary>> getMonthlySummary(int month, int year);
}

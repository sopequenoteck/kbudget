import 'package:k_budget/src/domain/models/recurring_transaction.dart';

abstract class RecurringTransactionRepository {
  Future<List<RecurringTransaction>> listActive();
  Future<void> validate(String id);
  Future<RecurringTransaction> skip(String id);
  Future<RecurringTransaction> deactivate(String id);
}

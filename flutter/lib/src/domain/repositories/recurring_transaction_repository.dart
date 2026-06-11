import 'package:k_budget/src/data/remote/dtos/recurring_transaction_create_request.dart';
import 'package:k_budget/src/domain/models/recurring_transaction.dart';

abstract class RecurringTransactionRepository {
  Future<List<RecurringTransaction>> listActive();
  Future<RecurringTransaction> create(RecurringTransactionCreateRequest req);
  Future<void> validate(String id);
  Future<RecurringTransaction> skip(String id);
  Future<RecurringTransaction> deactivate(String id);
}

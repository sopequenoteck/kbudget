import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/data/remote/data_sources/recurring_transaction_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/recurring_transaction_dtos.dart';
import 'package:k_budget/src/domain/models/recurring_transaction.dart';
import 'package:k_budget/src/domain/repositories/recurring_transaction_repository.dart';

class RecurringTransactionRepositoryRemote
    implements RecurringTransactionRepository {
  final RecurringTransactionRemoteDataSource _dataSource;

  RecurringTransactionRepositoryRemote(this._dataSource);

  @override
  Future<List<RecurringTransaction>> listActive() async {
    final responses = await _dataSource.getActive();
    return responses.map((r) => r.toDomain()).toList();
  }

  @override
  Future<void> validate(String id) => _dataSource.validate(id);

  @override
  Future<RecurringTransaction> skip(String id) async {
    final response = await _dataSource.skip(id);
    return response.toDomain();
  }

  @override
  Future<RecurringTransaction> deactivate(String id) async {
    final response = await _dataSource.deactivate(id);
    return response.toDomain();
  }
}

// Provider server-only (pas de dataModeProvider — recurring transactions = server uniquement)
final recurringTransactionRepositoryProvider =
    FutureProvider<RecurringTransactionRepository>((ref) async {
  final dio = await ref.watch(authenticatedDioProvider.future);
  return RecurringTransactionRepositoryRemote(
    RecurringTransactionRemoteDataSource(dio),
  );
});

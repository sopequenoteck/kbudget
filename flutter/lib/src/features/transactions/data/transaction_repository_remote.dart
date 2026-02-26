import 'package:k_budget/src/data/remote/data_sources/transaction_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/transaction_dtos.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/utils/enum_utils.dart';
import 'package:k_budget/src/domain/models/monthly_summary.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/domain/repositories/transaction_repository.dart';

class TransactionRepositoryRemote implements TransactionRepository {
  final TransactionRemoteDataSource _dataSource;

  TransactionRepositoryRemote(this._dataSource);

  @override
  Future<List<Transaction>> getByMonth(int month, int year) async {
    final responses = await _dataSource.getByMonth(month, year);
    return responses.map(_toDomain).toList();
  }

  @override
  Future<List<Transaction>> getAll() async {
    final responses = await _dataSource.getAll();
    return responses.map(_toDomain).toList();
  }

  @override
  Stream<List<Transaction>> watchAll() async* {
    yield await getAll();
  }

  @override
  Future<Transaction> getById(String id) async {
    final response = await _dataSource.getById(id);
    return _toDomain(response);
  }

  @override
  Future<Transaction> create(Transaction transaction) async {
    final request = _toRequest(transaction);
    final response = await _dataSource.create(request);
    return _toDomain(response);
  }

  @override
  Future<Transaction> update(Transaction transaction) async {
    final request = _toRequest(transaction);
    final response = await _dataSource.update(transaction.id, request);
    return _toDomain(response);
  }

  @override
  Future<void> delete(String id) => _dataSource.delete(id);

  @override
  Future<List<MonthlySummary>> getMonthlySummary(int month, int year) async {
    final responses = await _dataSource.getMonthlySummary(month, year);
    return responses.map(_summaryToDomain).toList();
  }

  MonthlySummary _summaryToDomain(MonthlySummaryResponse r) => MonthlySummary(
        month: r.month,
        year: r.year,
        totalRecettes: r.totalRecettes,
        totalDepenses: r.totalDepenses,
        bilan: r.bilan,
        currency: Currency.values.byNameOrDefault(r.currency.toLowerCase(), Currency.eur),
      );

  Transaction _toDomain(TransactionResponse r) => Transaction(
        id: r.id,
        montant: r.montant,
        libelle: r.libelle,
        type: TransactionType.values.byNameOrDefault(r.type.toLowerCase(), TransactionType.depense),
        date: DateTime.parse(r.date),
        note: r.note,
        transferId: r.transferId,
        categoryId: r.categoryId,
        accountId: r.accountId,
        updatedAt: r.updatedAt != null ? DateTime.parse(r.updatedAt!) : null,
      );

  TransactionRequest _toRequest(Transaction t) => TransactionRequest(
        montant: t.montant,
        libelle: t.libelle,
        type: t.type.name.toUpperCase(),
        date: t.date.toIso8601String(),
        note: t.note,
        categoryId: t.categoryId,
        accountId: t.accountId,
      );
}

import 'package:k_budget/src/data/local/daos/transaction_dao.dart';
import 'package:k_budget/src/data/local/mappers.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/monthly_summary.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/domain/repositories/transaction_repository.dart';
import 'package:k_budget/src/utils/string_utils.dart';

class TransactionRepositoryLocal implements TransactionRepository {
  final TransactionDao _dao;

  TransactionRepositoryLocal(this._dao);

  @override
  Future<List<Transaction>> getByMonth(int month, int year) async {
    final rows = await _dao.getTransactionsByMonth(month, year);
    return rows.map(transactionFromDb).toList();
  }

  @override
  Future<List<Transaction>> getAll() async {
    final rows = await _dao.getAllTransactions();
    return rows.map(transactionFromDb).toList();
  }

  @override
  Stream<List<Transaction>> watchAll() {
    return _dao.watchAllTransactions().map(
          (rows) => rows.map(transactionFromDb).toList(),
        );
  }

  @override
  Future<Transaction> getById(String id) async {
    final row = await _dao.getTransactionById(id);
    return transactionFromDb(row);
  }

  @override
  Future<Transaction> create(Transaction transaction) async {
    await _dao.insertTransaction(transactionToDb(transaction));
    return transaction;
  }

  @override
  Future<Transaction> update(Transaction transaction) async {
    await _dao.updateTransaction(transactionToDb(transaction));
    return transaction;
  }

  @override
  Future<void> delete(String id) async {
    await _dao.deleteTransaction(id);
  }

  @override
  Future<List<String>> getLibelleSuggestions(
    String query, {
    int limit = 20,
  }) async {
    final libelles = await _dao.getLibelleSuggestions(limit: limit);

    if (query.isEmpty) return libelles;

    final normalizedQuery = normalizeForSearch(query);
    return libelles
        .where((l) => normalizeForSearch(l).contains(normalizedQuery))
        .toList();
  }

  @override
  Future<List<MonthlySummary>> getMonthlySummary(int month, int year) async {
    final rows = await _dao.getMonthlySummary(month, year);
    double totalRecettes = 0;
    double totalDepenses = 0;
    for (final row in rows) {
      final type = row['type'] as String;
      final total = row['total'] as double;
      if (type == 'recette') {
        totalRecettes = total;
      } else if (type == 'depense') {
        totalDepenses = total;
      }
    }
    final bilan = totalRecettes - totalDepenses;
    return [
      MonthlySummary(
        month: month,
        year: year,
        totalRecettes: totalRecettes,
        totalDepenses: totalDepenses,
        bilan: bilan,
        currency: Currency.eur,
      ),
    ];
  }
}

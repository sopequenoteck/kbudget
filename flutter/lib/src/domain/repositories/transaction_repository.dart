import 'package:k_budget/src/domain/models/monthly_summary.dart';
import 'package:k_budget/src/domain/models/transaction.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getAll();
  Future<List<Transaction>> getByMonth(int month, int year);
  Stream<List<Transaction>> watchAll();
  Future<Transaction> getById(String id);
  Future<Transaction> create(Transaction transaction);
  Future<Transaction> update(Transaction transaction);
  Future<void> delete(String id);
  Future<List<MonthlySummary>> getMonthlySummary(int month, int year);

  /// Retourne les libellés distincts de l'utilisateur triés par fréquence
  /// puis par date de dernière utilisation.
  ///
  /// [query] filtre contains case/accent-insensible. Si vide, pas de filtre.
  /// [limit] nombre max de résultats (clampé à [1, 50] côté backend).
  Future<List<String>> getLibelleSuggestions(String query, {int limit = 20});
}

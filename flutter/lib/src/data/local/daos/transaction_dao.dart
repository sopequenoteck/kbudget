import 'package:drift/drift.dart';
import 'package:k_budget/src/data/local/database.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Future<List<Transaction>> getAllTransactions() =>
      (select(transactions)
            ..orderBy([
              (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)
            ]))
          .get();

  Stream<List<Transaction>> watchAllTransactions() =>
      (select(transactions)
            ..orderBy([
              (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)
            ]))
          .watch();

  Future<Transaction> getTransactionById(String id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingle();

  Future<int> insertTransaction(TransactionsCompanion transaction) =>
      into(transactions).insert(transaction);

  Future<bool> updateTransaction(TransactionsCompanion transaction) =>
      update(transactions).replace(transaction);

  Future<int> deleteTransaction(String id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  /// Calcule le resume mensuel local : SUM(montant) GROUP BY type
  /// pour le mois/annee donne. Retourne une Map avec 'recette' et 'depense'.
  Future<List<Map<String, dynamic>>> getMonthlySummary(
      int month, int year) async {
    final startDate = DateTime(year, month);
    final endDate = DateTime(year, month + 1);

    final query = customSelect(
      'SELECT type, SUM(montant) as total FROM transactions '
      'WHERE date >= ? AND date < ? '
      'GROUP BY type',
      variables: [
        Variable.withDateTime(startDate),
        Variable.withDateTime(endDate),
      ],
      readsFrom: {transactions},
    );

    final rows = await query.get();
    return rows
        .map((row) => {
              'type': row.read<String>('type'),
              'total': row.read<double>('total'),
            })
        .toList();
  }
}

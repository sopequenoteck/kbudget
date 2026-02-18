import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/local/database.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/transaction.dart' as domain;
import 'package:k_budget/src/features/transactions/data/transaction_repository_local.dart';

void main() {
  late AppDatabase db;
  late TransactionRepositoryLocal repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = TransactionRepositoryLocal(db.transactionDao);
  });

  tearDown(() async {
    await db.close();
  });

  domain.Transaction createTestTransaction({
    String id = 'txn-001',
    double montant = 42.50,
    String libelle = 'Courses',
    TransactionType type = TransactionType.depense,
  }) {
    return domain.Transaction(
      id: id,
      montant: montant,
      libelle: libelle,
      type: type,
      date: DateTime(2026, 2, 1),
      updatedAt: DateTime(2026, 2, 1),
    );
  }

  group('TransactionRepositoryLocal', () {
    test('should_return_empty_list_when_no_transactions', () async {
      final result = await repo.getAll();
      expect(result, isEmpty);
    });

    test('should_insert_and_retrieve_transaction', () async {
      final txn = createTestTransaction();
      await repo.create(txn);

      final result = await repo.getAll();
      expect(result, hasLength(1));
      expect(result.first.id, 'txn-001');
      expect(result.first.montant, 42.50);
      expect(result.first.libelle, 'Courses');
      expect(result.first.type, TransactionType.depense);
    });

    test('should_get_transaction_by_id', () async {
      await repo.create(createTestTransaction());

      final result = await repo.getById('txn-001');
      expect(result.id, 'txn-001');
      expect(result.libelle, 'Courses');
    });

    test('should_update_transaction', () async {
      final txn = createTestTransaction();
      await repo.create(txn);

      final updated = txn.copyWith(montant: 99.99, libelle: 'Courses modifié');
      await repo.update(updated);

      final result = await repo.getById('txn-001');
      expect(result.montant, 99.99);
      expect(result.libelle, 'Courses modifié');
    });

    test('should_delete_transaction', () async {
      await repo.create(createTestTransaction());
      await repo.delete('txn-001');

      final result = await repo.getAll();
      expect(result, isEmpty);
    });

    test('should_watch_all_transactions', () async {
      final stream = repo.watchAll();

      await repo.create(createTestTransaction(id: 'txn-001'));

      await expectLater(
        stream,
        emits(isA<List<domain.Transaction>>()
            .having((l) => l.length, 'length', 1)),
      );
    });

    test('should_handle_multiple_transactions', () async {
      await repo.create(createTestTransaction(id: 'txn-001'));
      await repo.create(createTestTransaction(
        id: 'txn-002',
        montant: 2500,
        libelle: 'Salaire',
        type: TransactionType.recette,
      ));

      final result = await repo.getAll();
      expect(result, hasLength(2));
    });
  });
}

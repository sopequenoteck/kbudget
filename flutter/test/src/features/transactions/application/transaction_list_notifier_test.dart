import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/monthly_summary.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/features/transactions/application/transaction_list_notifier.dart';
import 'package:k_budget/src/features/transactions/application/transaction_list_state.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.mocks.dart';

void main() {
  late MockTransactionRepository mockRepo;
  late ProviderContainer container;

  final txDepense1 = Transaction(
    id: '1',
    montant: 50.0,
    libelle: 'Courses',
    type: TransactionType.depense,
    date: DateTime(2026, 2, 20),
  );
  final txRecette = Transaction(
    id: '2',
    montant: 2000.0,
    libelle: 'Salaire',
    type: TransactionType.recette,
    date: DateTime(2026, 2, 22),
  );
  final txAjustement = Transaction(
    id: '3',
    montant: 5.0,
    libelle: 'Ajustement solde',
    type: TransactionType.ajustement,
    date: DateTime(2026, 2, 21),
  );
  final txDepense2 = Transaction(
    id: '4',
    montant: 30.0,
    libelle: 'Restaurant',
    type: TransactionType.depense,
    date: DateTime(2026, 2, 21),
  );

  const summary = MonthlySummary(
    month: 2,
    year: 2026,
    totalRecettes: 2000.0,
    totalDepenses: 80.0,
    bilan: 1920.0,
    currency: Currency.eur,
  );

  setUp(() {
    mockRepo = MockTransactionRepository();
    container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  TransactionListNotifier notifier() =>
      container.read(transactionListNotifierProvider.notifier);

  TransactionListState state() =>
      container.read(transactionListNotifierProvider);

  group('TransactionListNotifier', () {
    test('should_load_transactions_and_summary_when_loadMonth_called',
        () async {
      when(mockRepo.getByMonth(2, 2026))
          .thenAnswer((_) async => [txDepense1, txRecette, txAjustement]);
      when(mockRepo.getMonthlySummary(2, 2026))
          .thenAnswer((_) async => [summary]);

      await notifier().loadMonth(2, 2026);

      final s = state();
      expect(s.allMonthTransactions, hasLength(3));
      expect(s.filteredTransactions, hasLength(3));
      expect(s.summary, isNotNull);
      expect(s.summary!.bilan, 1920.0);
      expect(s.isLoading, false);
      expect(s.error, isNull);
      expect(s.selectedMonth, 2);
      expect(s.selectedYear, 2026);
    });

    test('should_set_error_when_repository_throws', () async {
      when(mockRepo.getByMonth(2, 2026))
          .thenThrow(Exception('Network error'));

      await notifier().loadMonth(2, 2026);

      final s = state();
      expect(s.isLoading, false);
      expect(s.error, contains('Impossible de charger'));
    });

    test('should_filter_depenses_when_setFilter_depense', () async {
      when(mockRepo.getByMonth(2, 2026)).thenAnswer(
          (_) async => [txDepense1, txRecette, txAjustement, txDepense2]);
      when(mockRepo.getMonthlySummary(2, 2026))
          .thenAnswer((_) async => [summary]);

      await notifier().loadMonth(2, 2026);
      notifier().setFilter(TransactionTypeFilter.depense);

      final s = state();
      expect(s.filteredTransactions, hasLength(2));
      expect(
        s.filteredTransactions.every((t) => t.type == TransactionType.depense),
        true,
      );
      expect(s.activeFilter, TransactionTypeFilter.depense);
    });

    test('should_filter_recettes_when_setFilter_recette', () async {
      when(mockRepo.getByMonth(2, 2026)).thenAnswer(
          (_) async => [txDepense1, txRecette, txAjustement, txDepense2]);
      when(mockRepo.getMonthlySummary(2, 2026))
          .thenAnswer((_) async => [summary]);

      await notifier().loadMonth(2, 2026);
      notifier().setFilter(TransactionTypeFilter.recette);

      final s = state();
      expect(s.filteredTransactions, hasLength(1));
      expect(s.filteredTransactions.first.type, TransactionType.recette);
    });

    test('should_show_all_including_ajustements_when_setFilter_all', () async {
      when(mockRepo.getByMonth(2, 2026)).thenAnswer(
          (_) async => [txDepense1, txRecette, txAjustement, txDepense2]);
      when(mockRepo.getMonthlySummary(2, 2026))
          .thenAnswer((_) async => [summary]);

      await notifier().loadMonth(2, 2026);
      notifier().setFilter(TransactionTypeFilter.depense);
      notifier().setFilter(TransactionTypeFilter.all);

      final s = state();
      expect(s.filteredTransactions, hasLength(4));
      expect(s.activeFilter, TransactionTypeFilter.all);
    });

    test('should_reload_both_list_and_summary_when_refresh_called', () async {
      when(mockRepo.getByMonth(any, any))
          .thenAnswer((_) async => [txDepense1]);
      when(mockRepo.getMonthlySummary(any, any))
          .thenAnswer((_) async => [summary]);

      await notifier().loadMonth(2, 2026);
      await notifier().refresh();

      verify(mockRepo.getByMonth(2, 2026)).called(2);
      verify(mockRepo.getMonthlySummary(2, 2026)).called(2);
    });

    test('should_reapply_filter_after_month_change', () async {
      when(mockRepo.getByMonth(2, 2026)).thenAnswer(
          (_) async => [txDepense1, txRecette, txAjustement, txDepense2]);
      when(mockRepo.getMonthlySummary(2, 2026))
          .thenAnswer((_) async => [summary]);

      await notifier().loadMonth(2, 2026);
      notifier().setFilter(TransactionTypeFilter.depense);
      expect(state().filteredTransactions, hasLength(2));

      // Changer de mois avec des données différentes
      final janTx = Transaction(
        id: '10',
        montant: 20.0,
        libelle: 'Janvier depense',
        type: TransactionType.depense,
        date: DateTime(2026, 1, 15),
      );
      final janRecette = Transaction(
        id: '11',
        montant: 500.0,
        libelle: 'Janvier recette',
        type: TransactionType.recette,
        date: DateTime(2026, 1, 10),
      );

      when(mockRepo.getByMonth(1, 2026))
          .thenAnswer((_) async => [janTx, janRecette]);
      when(mockRepo.getMonthlySummary(1, 2026))
          .thenAnswer((_) async => [summary]);

      await notifier().loadMonth(1, 2026);

      // Le filtre depense doit être réappliqué
      final s = state();
      expect(s.activeFilter, TransactionTypeFilter.depense);
      expect(s.filteredTransactions, hasLength(1));
      expect(s.filteredTransactions.first.id, '10');
    });

    test('should_handle_empty_summary_list', () async {
      when(mockRepo.getByMonth(3, 2026)).thenAnswer((_) async => []);
      when(mockRepo.getMonthlySummary(3, 2026))
          .thenAnswer((_) async => []);

      await notifier().loadMonth(3, 2026);

      final s = state();
      expect(s.summary, isNull);
      expect(s.allMonthTransactions, isEmpty);
      expect(s.filteredTransactions, isEmpty);
      expect(s.isLoading, false);
    });
  });
}

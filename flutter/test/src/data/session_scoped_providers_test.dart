// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/repository_providers.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/debt_payment.dart';
import 'package:k_budget/src/domain/models/monthly_summary.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/features/budgets/application/budget_transactions_provider.dart';
import 'package:k_budget/src/features/debts/application/debt_notifier.dart';
import 'package:k_budget/src/features/transactions/application/libelle_suggestions_provider.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/mocks.mocks.dart';
import '../features/settings/application/language_notifier_test.dart'
    show FakeAuthNotifier;

/// Providers `family` qui portent des donnees d'un compte : leur cache ne
/// doit pas survivre a un changement de session (KKS-546).
void main() {
  late MockTransactionRepository repo;
  late ProviderContainer container;

  MonthlySummary summaryOf(double bilan) => MonthlySummary(
        month: 2,
        year: 2026,
        totalRecettes: bilan,
        totalDepenses: 0,
        bilan: bilan,
        currency: Currency.eur,
      );

  Transaction transactionOf(String id) => Transaction(
        id: id,
        montant: 10.0,
        libelle: 'Libelle $id',
        type: TransactionType.depense,
        date: DateTime(2026, 2, 20),
      );

  void changeSession() {
    final auth =
        container.read(authNotifierProvider.notifier) as FakeAuthNotifier;
    auth.emit(const AuthState.unauthenticated());
    auth.emit(const AuthState.authenticated());
  }

  setUp(() {
    repo = MockTransactionRepository();
    container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(repo),
        authNotifierProvider.overrideWith(
          () => FakeAuthNotifier(const AuthState.authenticated()),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  group('monthlySummaryProvider', () {
    test('should_refetch_when_sessionChanges_monthlySummaryProvider',
        () async {
      const key = (month: 2, year: 2026);
      when(repo.getMonthlySummary(2, 2026))
          .thenAnswer((_) async => [summaryOf(100)]);
      expect(
        (await container.read(monthlySummaryProvider(key).future)).single.bilan,
        100,
      );

      when(repo.getMonthlySummary(2, 2026))
          .thenAnswer((_) async => [summaryOf(200)]);
      expect(
        (await container.read(monthlySummaryProvider(key).future)).single.bilan,
        100,
      );

      changeSession();

      expect(
        (await container.read(monthlySummaryProvider(key).future)).single.bilan,
        200,
      );
      verify(repo.getMonthlySummary(2, 2026)).called(2);
    });
  });

  group('libelleSuggestionsProvider', () {
    test('should_refetch_when_sessionChanges_libelleSuggestionsProvider',
        () async {
      when(repo.getLibelleSuggestions('ca', limit: 20))
          .thenAnswer((_) async => ['Carrefour A']);
      expect(
        await container.read(libelleSuggestionsProvider('ca').future),
        ['Carrefour A'],
      );

      when(repo.getLibelleSuggestions('ca', limit: 20))
          .thenAnswer((_) async => ['Carrefour B']);
      expect(
        await container.read(libelleSuggestionsProvider('ca').future),
        ['Carrefour A'],
      );

      changeSession();

      expect(
        await container.read(libelleSuggestionsProvider('ca').future),
        ['Carrefour B'],
      );
      verify(repo.getLibelleSuggestions('ca', limit: 20)).called(2);
    });
  });

  group('budgetTransactionsProvider', () {
    test('should_refetch_when_sessionChanges_budgetTransactionsProvider',
        () async {
      const key = (month: 2, year: 2026);
      when(repo.getByMonth(2, 2026))
          .thenAnswer((_) async => [transactionOf('a')]);
      expect(
        (await container.read(budgetTransactionsProvider(key).future))
            .single
            .id,
        'a',
      );

      when(repo.getByMonth(2, 2026))
          .thenAnswer((_) async => [transactionOf('b')]);
      expect(
        (await container.read(budgetTransactionsProvider(key).future))
            .single
            .id,
        'a',
      );

      changeSession();

      expect(
        (await container.read(budgetTransactionsProvider(key).future))
            .single
            .id,
        'b',
      );
      verify(repo.getByMonth(2, 2026)).called(2);
    });
  });

  group('debtPaymentsProvider', () {
    test('should_refetch_when_sessionChanges_debtPayments', () async {
      final debtRepo = MockDebtRepository();
      container = ProviderContainer(
        overrides: [
          debtRepositoryProvider.overrideWithValue(debtRepo),
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(const AuthState.authenticated()),
          ),
        ],
      );
      addTearDown(container.dispose);
      DebtPayment paymentOf(String id) =>
          DebtPayment(id: id, montant: 5, date: DateTime(2026, 2, 20));
      when(debtRepo.getPayments('d1'))
          .thenAnswer((_) async => [paymentOf('a')]);
      expect(
        (await container.read(debtPaymentsProvider('d1').future)).single.id,
        'a',
      );

      when(debtRepo.getPayments('d1'))
          .thenAnswer((_) async => [paymentOf('b')]);
      expect(
        (await container.read(debtPaymentsProvider('d1').future)).single.id,
        'a',
      );

      changeSession();

      expect(
        (await container.read(debtPaymentsProvider('d1').future)).single.id,
        'b',
      );
      verify(debtRepo.getPayments('d1')).called(2);
    });
  });
}

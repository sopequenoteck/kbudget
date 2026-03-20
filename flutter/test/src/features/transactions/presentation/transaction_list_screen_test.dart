import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/domain/models/monthly_summary.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/features/transactions/presentation/transaction_list_screen.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.mocks.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  late MockTransactionRepository mockRepo;
  late MockCategoryRepository mockCatRepo;
  late MockExchangeRateRepository mockExchangeRateRepo;

  final tx1 = Transaction(
    id: '1',
    montant: 50.0,
    libelle: 'Courses',
    type: TransactionType.depense,
    date: DateTime(2026, 2, 20),
    categoryId: 'cat1',
  );
  final tx2 = Transaction(
    id: '2',
    montant: 2000.0,
    libelle: 'Salaire',
    type: TransactionType.recette,
    date: DateTime(2026, 2, 22),
    categoryId: 'cat2',
  );

  const category1 = Category(
    id: 'cat1',
    nom: 'Alimentation',
    icone: '\u{1F6D2}',
    couleur: '#FF5733',
  );
  const category2 = Category(
    id: 'cat2',
    nom: 'Revenus',
    icone: '\u{1F4B0}',
    couleur: '#33FF57',
  );

  const summary = MonthlySummary(
    month: 2,
    year: 2026,
    totalRecettes: 2000.0,
    totalDepenses: 50.0,
    bilan: 1950.0,
    currency: Currency.eur,
  );

  setUp(() {
    mockRepo = MockTransactionRepository();
    mockCatRepo = MockCategoryRepository();
    mockExchangeRateRepo = MockExchangeRateRepository();
    when(mockExchangeRateRepo.getAll()).thenAnswer((_) async => <ExchangeRate>[]);
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(mockRepo),
        categoryRepositoryProvider.overrideWithValue(mockCatRepo),
        exchangeRateRepositoryProvider.overrideWith((_) async => mockExchangeRateRepo),
      ],
      child: MaterialApp(
        theme: theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: TransactionListScreen(),
        ),
      ),
    );
  }

  group('TransactionListScreen', () {
    testWidgets('should_display_transactions_grouped_by_day_when_loaded',
        (tester) async {
      when(mockRepo.getByMonth(any, any))
          .thenAnswer((_) async => [tx1, tx2]);
      when(mockRepo.getMonthlySummary(any, any))
          .thenAnswer((_) async => [summary]);
      when(mockCatRepo.getAll())
          .thenAnswer((_) async => [category1, category2]);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Courses'), findsOneWidget);
      expect(find.text('Alimentation'), findsOneWidget);
    });

    testWidgets('should_display_empty_state_when_no_transactions',
        (tester) async {
      when(mockRepo.getByMonth(any, any)).thenAnswer((_) async => []);
      when(mockRepo.getMonthlySummary(any, any))
          .thenAnswer((_) async => []);
      when(mockCatRepo.getAll()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Aucune transaction ce mois-ci'), findsOneWidget);
    });

    testWidgets('should_display_error_with_retry_when_error',
        (tester) async {
      when(mockRepo.getByMonth(any, any))
          .thenThrow(Exception('Network error'));
      when(mockCatRepo.getAll()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Une erreur est survenue'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('should_display_summary_card_labels', (tester) async {
      when(mockRepo.getByMonth(any, any))
          .thenAnswer((_) async => [tx1, tx2]);
      when(mockRepo.getMonthlySummary(any, any))
          .thenAnswer((_) async => [summary]);
      when(mockCatRepo.getAll())
          .thenAnswer((_) async => [category1, category2]);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Les labels du summary card sont présents
      expect(find.text('Bilan'), findsOneWidget);
      // "Recettes" et "Dépenses" apparaissent dans le summary ET le filtre
      expect(find.text('Recettes'), findsWidgets);
      expect(find.text('Dépenses'), findsWidgets);
    });

    testWidgets('should_display_filter_segments', (tester) async {
      when(mockRepo.getByMonth(any, any))
          .thenAnswer((_) async => [tx1, tx2]);
      when(mockRepo.getMonthlySummary(any, any))
          .thenAnswer((_) async => [summary]);
      when(mockCatRepo.getAll())
          .thenAnswer((_) async => [category1, category2]);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Tous'), findsOneWidget);
    });
  });
}

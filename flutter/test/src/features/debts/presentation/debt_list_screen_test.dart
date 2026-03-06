import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/debt.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/features/debts/presentation/debt_list_screen.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.mocks.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  late MockDebtRepository mockDebtRepo;
  late MockCategoryRepository mockCatRepo;
  late MockAccountRepository mockAccountRepo;
  late MockExchangeRateRepository mockExchangeRateRepo;

  final debtPret = Debt(
    id: '1',
    personne: 'Alice',
    montant: 100.0,
    sens: DebtType.pret,
    date: DateTime(2026, 2, 10),
    categoryId: 'cat1',
  );
  final debtEmprunt = Debt(
    id: '2',
    personne: 'Bob',
    montant: 50.0,
    sens: DebtType.emprunt,
    date: DateTime(2026, 2, 20),
    categoryId: 'cat2',
  );
  final debtRepaid = Debt(
    id: '3',
    personne: 'Charlie',
    montant: 30.0,
    sens: DebtType.emprunt,
    date: DateTime(2026, 1, 5),
    rembourse: true,
  );

  const category1 = Category(
    id: 'cat1',
    nom: 'Amis',
    icone: '\u{1F91D}',
    couleur: '#4CAF50',
  );
  const category2 = Category(
    id: 'cat2',
    nom: 'Famille',
    icone: '\u{1F46A}',
    couleur: '#2196F3',
  );

  setUp(() {
    mockDebtRepo = MockDebtRepository();
    mockCatRepo = MockCategoryRepository();
    mockAccountRepo = MockAccountRepository();
    mockExchangeRateRepo = MockExchangeRateRepository();
    when(mockAccountRepo.getAll()).thenAnswer((_) async => []);
    when(mockExchangeRateRepo.getAll()).thenAnswer((_) async => <ExchangeRate>[]);
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        debtRepositoryProvider.overrideWithValue(mockDebtRepo),
        categoryRepositoryProvider.overrideWithValue(mockCatRepo),
        accountRepositoryProvider.overrideWithValue(mockAccountRepo),
        exchangeRateRepositoryProvider.overrideWithValue(mockExchangeRateRepo),
      ],
      child: MaterialApp(
        theme: theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: DebtListScreen(),
        ),
      ),
    );
  }

  group('DebtListScreen', () {
    testWidgets('should_displaySections_when_dataLoaded', (tester) async {
      when(mockDebtRepo.getAll())
          .thenAnswer((_) async => [debtPret, debtEmprunt]);
      when(mockCatRepo.getAll())
          .thenAnswer((_) async => [category1, category2]);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Prêts'), findsWidgets);
      expect(find.text('Emprunts'), findsWidgets);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('should_displayEmptyState_when_noDebts', (tester) async {
      when(mockDebtRepo.getAll()).thenAnswer((_) async => []);
      when(mockCatRepo.getAll()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Aucune dette'), findsOneWidget);
    });

    testWidgets('should_displayRepaidBadge_when_debtIsRepaid',
        (tester) async {
      when(mockDebtRepo.getAll())
          .thenAnswer((_) async => [debtPret, debtRepaid]);
      when(mockCatRepo.getAll()).thenAnswer((_) async => [category1]);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // "Remboursé" appears as badge + filter segment = 2 occurrences
      expect(find.text('Remboursé'), findsNWidgets(2));
    });

    testWidgets('should_displaySummaryCard_when_nonRepaidDebtsExist',
        (tester) async {
      when(mockDebtRepo.getAll())
          .thenAnswer((_) async => [debtPret, debtEmprunt]);
      when(mockCatRepo.getAll())
          .thenAnswer((_) async => [category1, category2]);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Emprunts'), findsWidgets);
      expect(find.text('Solde net'), findsOneWidget);
    });

    testWidgets('should_displayFilterSegments', (tester) async {
      when(mockDebtRepo.getAll())
          .thenAnswer((_) async => [debtPret, debtEmprunt]);
      when(mockCatRepo.getAll())
          .thenAnswer((_) async => [category1, category2]);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Tous'), findsOneWidget);
      expect(find.text('En cours'), findsOneWidget);
      expect(find.text('Remboursé'), findsOneWidget);
    });

    testWidgets('should_displayContextualEmptyMessage_when_filterActive',
        (tester) async {
      when(mockDebtRepo.getAll()).thenAnswer((_) async => [debtPret]);
      when(mockCatRepo.getAll()).thenAnswer((_) async => [category1]);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap "Remboursé" filter
      await tester.tap(find.text('Remboursé'));
      await tester.pumpAndSettle();

      expect(find.text('Aucune dette remboursée'), findsOneWidget);
    });

    testWidgets('should_displaySkeleton_when_loading', (tester) async {
      final completer = Completer<List<Debt>>();
      when(mockDebtRepo.getAll()).thenAnswer((_) => completer.future);
      when(mockCatRepo.getAll()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 100));

      // Should not show empty or data state
      expect(find.text('Aucune dette'), findsNothing);
      expect(find.text('Alice'), findsNothing);
    });
  });
}

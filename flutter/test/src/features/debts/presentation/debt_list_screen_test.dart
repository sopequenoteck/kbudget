import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:k_budget/src/common_widgets/section_header_sticky.dart';
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
        exchangeRateRepositoryProvider.overrideWith((_) async => mockExchangeRateRepo),
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
    testWidgets('should_displayEmptyState_when_noDebts', (tester) async {
      when(mockDebtRepo.getAll()).thenAnswer((_) async => []);
      when(mockCatRepo.getAll()).thenAnswer((_) async => []);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Aucune dette'), findsOneWidget);
    });

    testWidgets('should_display_temporal_groups_when_data_loaded',
        (tester) async {
      // debtPret : non remboursé → bucket temporel (sans échéance)
      // debtRepaid : remboursé → bucket 'Remboursées'
      when(mockDebtRepo.getAll())
          .thenAnswer((_) async => [debtPret, debtRepaid]);
      when(mockCatRepo.getAll()).thenAnswer((_) async => [category1]);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Remboursées'), findsOneWidget);
    });

    testWidgets('should_display_section_header_when_data_loaded',
        (tester) async {
      when(mockDebtRepo.getAll()).thenAnswer((_) async => [debtPret]);
      when(mockCatRepo.getAll()).thenAnswer((_) async => [category1]);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(SectionHeaderSticky), findsOneWidget);
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

  group('DebtListScreen navigation', () {
    late GoRouter router;
    late String lastPushedLocation;

    setUp(() {
      lastPushedLocation = '';
      router = GoRouter(
        initialLocation: '/debts',
        routes: [
          GoRoute(
            path: '/debts',
            builder: (_, __) => ProviderScope(
              overrides: [
                debtRepositoryProvider.overrideWithValue(mockDebtRepo),
                categoryRepositoryProvider
                    .overrideWithValue(mockCatRepo),
                accountRepositoryProvider
                    .overrideWithValue(mockAccountRepo),
                exchangeRateRepositoryProvider
                    .overrideWith((_) async => mockExchangeRateRepo),
              ],
              child: const Scaffold(
                body: DebtListScreen(),
                floatingActionButton: SizedBox.shrink(),
              ),
            ),
          ),
          GoRoute(
            path: '/debts/:id',
            builder: (context, state) {
              lastPushedLocation = '/debts/${state.pathParameters['id']}';
              return const Scaffold(body: Text('Detail'));
            },
          ),
        ],
      );
    });

    Widget buildAppWithRouter() => MaterialApp.router(
          routerConfig: router,
          theme: theme.AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        );

    testWidgets(
        'should_navigate_to_debt_detail_on_item_tap',
        (tester) async {
      when(mockDebtRepo.getAll()).thenAnswer((_) async => [debtPret]);
      when(mockCatRepo.getAll()).thenAnswer((_) async => [category1]);

      await tester.pumpWidget(buildAppWithRouter());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();

      expect(lastPushedLocation, '/debts/1');
    });
  });
}

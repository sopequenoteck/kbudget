import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:k_budget/src/data/repository_providers.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/debt.dart';
import 'package:k_budget/src/domain/models/debt_payment.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/features/debts/application/debt_notifier.dart';
import 'package:k_budget/src/features/debts/presentation/debt_detail_screen.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;
import 'package:mockito/mockito.dart';

import '../../../../helpers/display_locale.dart';
import '../../../../helpers/fixtures/test_fixtures.dart';
import '../../../../helpers/mocks.mocks.dart';

class _TestDebtNotifier extends DebtNotifier {
  _TestDebtNotifier({this.preloadedDebt});

  final Debt? preloadedDebt;

  @override
  Debt? getDebtById(String id) => preloadedDebt;
}

class _TestCategoryNotifier extends CategoryNotifier {
  _TestCategoryNotifier(this.preloadedItems);

  final List<Category> preloadedItems;

  @override
  ListState<Category> build() => ListState<Category>(items: preloadedItems);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  late MockDebtRepository mockDebtRepo;

  const testCategory = Category(
    id: 'cat1',
    nom: 'Amis',
    icone: '🤝',
    couleur: '#4CAF50',
  );

  final borrowedDebt = Debt(
    id: 'debt1',
    personne: 'Alice',
    montant: 250.0,
    sens: DebtType.emprunt,
    date: DateTime(2026, 1, 15),
    rembourse: false,
    categoryId: 'cat1',
    accountId: 'acc1',
    accountName: 'Compte courant',
    includeInBalance: true,
    remainingAmount: 100.0,
    reminderDate: DateTime(2026, 2, 1),
    reminderTime: '10:00',
    dueDate: DateTime(2026, 3, 1),
  );

  final repaidLentDebt = Debt(
    id: 'debt2',
    personne: 'Bob',
    montant: 80.0,
    sens: DebtType.pret,
    date: DateTime(2026, 1, 10),
    rembourse: true,
  );

  setUp(() {
    mockDebtRepo = MockDebtRepository();
  });

  Widget buildApp({
    required Debt debt,
    List<Category> categories = const [testCategory],
  }) {
    return ProviderScope(
      overrides: [
        displayLocaleOverride(),
        debtRepositoryProvider.overrideWithValue(mockDebtRepo),
        debtNotifierProvider.overrideWith(
          () => _TestDebtNotifier(preloadedDebt: debt),
        ),
        categoryNotifierProvider.overrideWith(
          () => _TestCategoryNotifier(categories),
        ),
      ],
      child: MaterialApp(
        theme: theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: DebtDetailScreen(debtId: debt.id),
      ),
    );
  }

  group('DebtDetailScreen', () {
    testWidgets(
        'should_displayErrorState_when_debtNotFoundAnywhere',
        (tester) async {
      when(mockDebtRepo.getById('unknown'))
          .thenThrow(Exception('not found'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            displayLocaleOverride(),
            debtRepositoryProvider.overrideWithValue(mockDebtRepo),
            debtNotifierProvider.overrideWith(
              () => _TestDebtNotifier(),
            ),
            categoryNotifierProvider.overrideWith(
              () => _TestCategoryNotifier(const []),
            ),
          ],
          child: MaterialApp(
            theme: theme.AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: const DebtDetailScreen(debtId: 'unknown'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Une erreur est survenue'), findsOneWidget);
    });

    testWidgets(
        'should_displayBorrowedDebtWithRepayButtonAndPayments_when_notRepaid',
        (tester) async {
      when(mockDebtRepo.getPayments(borrowedDebt.id)).thenAnswer(
        (_) async => [
          DebtPayment(
            id: 'p1',
            montant: 150.0,
            date: DateTime(2026, 1, 20),
            accountName: 'Livret A',
          ),
        ],
      );

      await tester.pumpWidget(buildApp(debt: borrowedDebt));
      await tester.pumpAndSettle();

      // Header + badge emprunt
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Emprunt'), findsOneWidget);

      // Bouton rembourser + bouton report rappel (reminderDate défini)
      expect(find.text('Rembourser'), findsOneWidget);
      expect(find.text('Reporter le rappel'), findsOneWidget);

      // Infos enrichies
      expect(find.text('Compte courant'), findsOneWidget);
      expect(find.text('Amis'), findsOneWidget);

      // Section paiements : total remboursé + montant du paiement
      expect(find.text('Total remboursé'), findsOneWidget);
      expect(find.textContaining('150,00'), findsWidgets);
    });

    testWidgets(
        'should_displayRepaidBadgeAndEmptyPayments_when_debtRepaidWithoutPayments',
        (tester) async {
      when(mockDebtRepo.getPayments(repaidLentDebt.id))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildApp(debt: repaidLentDebt, categories: const []));
      await tester.pumpAndSettle();

      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Prêt'), findsOneWidget);
      expect(find.text('Remboursé'), findsOneWidget);

      // Debt remboursée : pas de bouton rembourser
      expect(find.text('Rembourser'), findsNothing);

      // Aucun paiement enregistré
      expect(find.text('Aucun paiement enregistré'), findsOneWidget);
    });

    testWidgets('should_displayTranslatedCategory_when_categoryIsSystem',
        (tester) async {
      when(mockDebtRepo.getPayments(borrowedDebt.id))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        buildApp(
          debt: borrowedDebt.copyWith(categoryId: 'cat-sys'),
          categories: [TestFixtures.systemCategory],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Abonnement'), findsOneWidget);
      expect(find.text('Subscription'), findsNothing);
    });
  });
}

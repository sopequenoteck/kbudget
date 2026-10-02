import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/domain/models/transaction.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_state.dart';
import 'package:k_budget/src/features/dashboard/presentation/widgets/recent_transactions_section.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as theme;

import '../../../../../helpers/display_locale.dart';

class _TestDashboardNotifier extends DashboardNotifier {
  _TestDashboardNotifier(this.preloadedState);

  final DashboardState preloadedState;

  @override
  DashboardState build() => preloadedState;
}

class _TestCategoryNotifier extends CategoryNotifier {
  _TestCategoryNotifier(this.preloadedItems);

  final List<Category> preloadedItems;

  @override
  ListState<Category> build() => ListState<Category>(items: preloadedItems);
}

void main() {
  const accountEur = Account(
    id: 'acc-eur',
    nom: 'Compte courant',
    type: AccountType.courant,
    soldeInitial: 1000,
    icone: '🏦',
    couleur: '#4CAF50',
    actif: true,
    solde: 1000,
  );

  const accountUsd = Account(
    id: 'acc-usd',
    nom: 'Compte USD',
    type: AccountType.courant,
    soldeInitial: 500,
    icone: '🏦',
    couleur: '#2196F3',
    currency: Currency.usd,
    actif: true,
    solde: 500,
  );

  final normalTransaction = Transaction(
    id: 't1',
    montant: 20.0,
    libelle: 'Courses',
    type: TransactionType.depense,
    date: DateTime(2026, 3, 1),
    accountId: 'acc-eur',
  );

  final foreignTransaction = Transaction(
    id: 't2',
    montant: 15.0,
    libelle: 'Achat en ligne',
    type: TransactionType.depense,
    date: DateTime(2026, 3, 2),
    accountId: 'acc-usd',
  );

  Widget buildApp(
    DashboardState state, {
    List<Category> categories = const [],
  }) {
    return ProviderScope(
      overrides: [
        displayLocaleOverride(),
        categoryNotifierProvider.overrideWith(
          () => _TestCategoryNotifier(categories),
        ),
        dashboardNotifierProvider.overrideWith(
          () => _TestDashboardNotifier(state),
        ),
      ],
      child: MaterialApp(
        theme: theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: const Scaffold(
          body: RecentTransactionsSection(),
        ),
      ),
    );
  }

  group('RecentTransactionsSection', () {
    testWidgets(
        'should_displayAmountsAndRelativeDates_when_transactionsInSameCurrency',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          DashboardState(
            isLoading: false,
            recentTransactions: [normalTransaction],
            accounts: const [accountEur],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Courses'), findsOneWidget);
      expect(find.textContaining('20,00'), findsWidgets);
    });

    testWidgets(
        'should_displayConvertedAmountAndBadge_when_transactionInForeignCurrency',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          DashboardState(
            isLoading: false,
            recentTransactions: [foreignTransaction],
            accounts: const [accountUsd],
            activeCurrency: Currency.eur,
            exchangeRates: [
              const ExchangeRate(
                id: 'r1',
                baseCurrency: Currency.usd,
                targetCurrency: Currency.eur,
                rate: 0.9,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Achat en ligne'), findsOneWidget);
      expect(find.text('USD'), findsOneWidget);
      expect(find.textContaining('≈'), findsOneWidget);
    });

    testWidgets('should_showSectionTexts_when_noRecentTransactions',
        (tester) async {
      await tester.pumpWidget(
        buildApp(const DashboardState(isLoading: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dernières opérations'), findsOneWidget);
      expect(find.text('Voir tout'), findsOneWidget);
      expect(find.text('Aucune transaction'), findsOneWidget);
    });

    testWidgets(
        'should_showTranslatedCategoryAndAccount_when_categoryIsSystem',
        (tester) async {
      final systemTransaction = Transaction(
        id: 't3',
        montant: 9.99,
        libelle: 'Netflix',
        type: TransactionType.depense,
        date: DateTime(2026, 3, 3),
        accountId: 'acc-eur',
        categoryId: 'cat-sys',
      );

      await tester.pumpWidget(
        buildApp(
          DashboardState(
            isLoading: false,
            recentTransactions: [systemTransaction],
            accounts: const [accountEur],
          ),
          categories: const [
            Category(
              id: 'cat-sys',
              nom: 'Subscription',
              icone: '🔁',
              couleur: '#8B5CF6',
              isSystem: true,
              systemKey: 'SUBSCRIPTION',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Abonnement · Compte courant'), findsOneWidget);
      expect(find.textContaining('Subscription'), findsNothing);
    });
  });
}

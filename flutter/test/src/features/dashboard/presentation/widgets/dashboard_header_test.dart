import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/budget_overview.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/domain/models/monthly_summary.dart';
import 'package:k_budget/src/domain/models/recurring_transaction.dart';
import 'package:k_budget/src/features/budgets/application/budget_list_state.dart';
import 'package:k_budget/src/features/budgets/application/budget_notifier.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_state.dart';
import 'package:k_budget/src/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:k_budget/src/features/recurring/application/recurring_list_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme.dart' as app_theme;

/// DashboardNotifier factice : retourne un state pré-rempli sans appel réseau.
class _FakeDashboardNotifier extends DashboardNotifier {
  final String? _userName;
  final MonthlySummary? _summary;
  _FakeDashboardNotifier({String? userName, MonthlySummary? summary})
      : _userName = userName,
        _summary = summary;

  @override
  DashboardState build() => DashboardState(
        userName: _userName,
        currentSummary: _summary,
        isLoading: false,
      );

  @override
  Future<void> loadDashboard() async {
    // No-op
  }
}

/// RecurringListNotifier factice sans appel réseau.
class _FakeRecurringNotifier extends RecurringListNotifier {
  final List<RecurringTransaction> _items;
  _FakeRecurringNotifier(this._items);

  @override
  ListState<RecurringTransaction> build() =>
      ListState<RecurringTransaction>(items: _items);

  @override
  Future<void> loadItems() async {
    // No-op
  }
}

/// BudgetNotifier factice sans appel réseau.
class _FakeBudgetNotifier extends BudgetNotifier {
  final BudgetOverview? _overview;
  _FakeBudgetNotifier(this._overview);

  @override
  BudgetListState build() => BudgetListState(overview: _overview);

  @override
  Future<void> loadOverview() async {
    // No-op
  }
}

RecurringTransaction _overdue(String id) => RecurringTransaction(
      id: id,
      montant: 50,
      libelle: 'Loyer',
      type: TransactionType.depense,
      frequency: Frequency.mensuel,
      nextOccurrence: DateTime.now().subtract(const Duration(days: 3)),
      recurringActive: true,
    );

BudgetOverviewItem _budget(String id, double percentage) => BudgetOverviewItem(
      budgetId: id,
      categoryId: 'cat-$id',
      categoryNom: 'Courses',
      categoryIcone: '🛒',
      categoryCouleur: '#000000',
      montantBudget: 100,
      montantBudgetNormalise: 100,
      currency: 'EUR',
      montantDepense: percentage,
      percentage: percentage,
      frequence: 'MENSUEL',
    );

BudgetOverview _overview(List<BudgetOverviewItem> items) => BudgetOverview(
      month: '2026-09',
      totalBudget: 100,
      totalSpent: 0,
      percentage: 0,
      currency: 'EUR',
      items: items,
    );

MonthlySummary _summary(double recettes, double depenses) => MonthlySummary(
      month: 9,
      year: 2026,
      totalRecettes: recettes,
      totalDepenses: depenses,
      bilan: recettes - depenses,
      currency: Currency.eur,
    );

void main() {
  Widget buildWidget({
    String? userName,
    List<RecurringTransaction> recurring = const [],
    BudgetOverview? overview,
    MonthlySummary? summary,
  }) {
    return ProviderScope(
      overrides: [
        dashboardNotifierProvider.overrideWith(
          () => _FakeDashboardNotifier(userName: userName, summary: summary),
        ),
        recurringListNotifierProvider.overrideWith(
          () => _FakeRecurringNotifier(recurring),
        ),
        budgetNotifierProvider.overrideWith(
          () => _FakeBudgetNotifier(overview),
        ),
      ],
      child: MaterialApp(
        theme: app_theme.AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: const Scaffold(
          body: DashboardHeader(),
        ),
      ),
    );
  }

  String headerText(WidgetTester tester) =>
      tester.widget<Text>(find.byType(Text)).data!;

  group('DashboardHeader', () {
    testWidgets('should_displayGreetingWithUserName_when_userNameProvided',
        (tester) async {
      await tester.pumpWidget(buildWidget(userName: 'Kelly'));
      await tester.pumpAndSettle();

      // "<salutation> Kelly · <statut>"
      expect(
        headerText(tester),
        matches(RegExp(r'^(Bonjour|Bon après-midi|Bonsoir) Kelly · ')),
      );
    });

    testWidgets('should_displayGreetingAlone_when_noUserName', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(
        headerText(tester),
        matches(RegExp(r'^(Bonjour|Bon après-midi|Bonsoir) · ')),
      );
    });

    testWidgets('should_showQuietMonth_when_noActivity', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(headerText(tester), endsWith(' · Mois calme'));
    });

    testWidgets('should_showOverdueCount_when_recurringOverdue',
        (tester) async {
      await tester.pumpWidget(buildWidget(
        recurring: [_overdue('1'), _overdue('2')],
        overview: _overview([_budget('1', 120)]),
      ));
      await tester.pumpAndSettle();

      // Les charges en retard priment sur les budgets dépassés
      expect(headerText(tester), endsWith(' · 2 charges en retard'));
    });

    testWidgets('should_showExceededCount_when_budgetOver100',
        (tester) async {
      await tester.pumpWidget(buildWidget(
        overview: _overview([_budget('1', 120), _budget('2', 50)]),
      ));
      await tester.pumpAndSettle();

      expect(headerText(tester), endsWith(' · 1 budget dépassé'));
    });

    testWidgets('should_showPositiveMonth_when_incomeCoversExpenses',
        (tester) async {
      await tester.pumpWidget(buildWidget(summary: _summary(500, 200)));
      await tester.pumpAndSettle();

      expect(headerText(tester), endsWith(' · Mois positif'));
    });

    testWidgets('should_showNegativeMonth_when_expensesExceedIncome',
        (tester) async {
      await tester.pumpWidget(buildWidget(summary: _summary(100, 300)));
      await tester.pumpAndSettle();

      expect(headerText(tester), endsWith(' · Mois négatif'));
    });
  });
}

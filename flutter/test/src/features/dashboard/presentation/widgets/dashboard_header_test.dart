import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/features/budgets/application/budget_list_state.dart';
import 'package:k_budget/src/features/budgets/application/budget_notifier.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_state.dart';
import 'package:k_budget/src/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:k_budget/src/features/recurring/application/recurring_list_notifier.dart';
import 'package:k_budget/src/theme/app_theme.dart' as app_theme;

/// DashboardNotifier factice : retourne un state pré-rempli sans appel réseau.
class _FakeDashboardNotifier extends DashboardNotifier {
  final String? _userName;
  _FakeDashboardNotifier({String? userName}) : _userName = userName;

  @override
  DashboardState build() =>
      DashboardState(userName: _userName, isLoading: false);

  @override
  Future<void> loadDashboard() async {
    // No-op
  }
}

/// RecurringListNotifier factice sans appel réseau.
class _FakeRecurringNotifier extends RecurringListNotifier {
  @override
  Future<void> loadItems() async {
    // No-op
  }
}

/// BudgetNotifier factice sans appel réseau.
class _FakeBudgetNotifier extends BudgetNotifier {
  @override
  BudgetListState build() => const BudgetListState();

  @override
  Future<void> loadOverview() async {
    // No-op
  }
}

void main() {
  Widget buildWidget({String? userName}) {
    return ProviderScope(
      overrides: [
        dashboardNotifierProvider.overrideWith(
          () => _FakeDashboardNotifier(userName: userName),
        ),
        recurringListNotifierProvider.overrideWith(
          () => _FakeRecurringNotifier(),
        ),
        budgetNotifierProvider.overrideWith(
          () => _FakeBudgetNotifier(),
        ),
      ],
      child: MaterialApp(
        theme: app_theme.AppTheme.light,
        home: const Scaffold(
          body: DashboardHeader(),
        ),
      ),
    );
  }

  group('DashboardHeader', () {
    testWidgets('should_displayGreetingWithUserName_when_userNameProvided',
        (tester) async {
      await tester.pumpWidget(buildWidget(userName: 'Kelly'));
      await tester.pumpAndSettle();

      // Le widget affiche "<salutation> Kelly · <suffixe>"
      expect(find.textContaining('Kelly'), findsOneWidget);
    });

    testWidgets('should_displayGreeting_when_noUserName', (tester) async {
      await tester.pumpWidget(buildWidget(userName: null));
      await tester.pumpAndSettle();

      // Sans nom : le widget affiche une salutation temporelle + suffixe
      expect(find.byType(Text), findsOneWidget);
    });
  });
}

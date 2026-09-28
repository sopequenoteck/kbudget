// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/recurring_status.dart';
import 'package:k_budget/src/features/budgets/application/budget_notifier.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:k_budget/src/features/recurring/application/recurring_list_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  String _greeting(AppLocalizations l10n, String? userName) {
    final hour = DateTime.now().hour;
    final hasName = userName != null ? 'yes' : 'no';
    final name = userName ?? '';
    if (hour < 12) {
      return l10n.dashboardSummaryGreetingMorning(hasName, name);
    }
    if (hour < 18) {
      return l10n.dashboardSummaryGreetingAfternoon(hasName, name);
    }
    return l10n.dashboardSummaryGreetingEvening(hasName, name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final dashState = ref.watch(dashboardNotifierProvider);
    final recurringState = ref.watch(recurringListNotifierProvider);
    final budgetState = ref.watch(budgetNotifierProvider);

    final prefix = _greeting(l10n, dashState.userName);

    final overdueCount = recurringState.items
        .where((i) => i.status == RecurringStatus.overdue)
        .length;

    final exceededCount =
        budgetState.overview?.items.where((i) => i.percentage > 100).length ??
            0;

    final String status;

    if (overdueCount > 0) {
      status = l10n.recurringSummaryOverdueCount(overdueCount);
    } else if (exceededCount > 0) {
      status = l10n.budgetsSummaryExceededCount(exceededCount);
    } else {
      final summary = dashState.currentSummary;
      if (summary != null &&
          summary.totalRecettes + summary.totalDepenses > 0) {
        final isPositive = summary.totalRecettes >= summary.totalDepenses;
        status = isPositive
            ? l10n.dashboardSummaryMonthPositive
            : l10n.dashboardSummaryMonthNegative;
      } else {
        status = l10n.dashboardSummaryMonthQuiet;
      }
    }

    return Text(
      '$prefix · $status',
      style: TextStyle(
        fontSize: AppTypography.sizeSm,
        fontWeight: AppTypography.regular,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

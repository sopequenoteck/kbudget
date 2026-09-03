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

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  String _greeting(String? userName) {
    final hour = DateTime.now().hour;
    final String salut;
    if (hour < 12) {
      salut = 'Bonjour';
    } else if (hour < 18) {
      salut = 'Bon après-midi';
    } else {
      salut = 'Bonsoir';
    }
    return userName != null ? '$salut $userName' : salut;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final dashState = ref.watch(dashboardNotifierProvider);
    final recurringState = ref.watch(recurringListNotifierProvider);
    final budgetState = ref.watch(budgetNotifierProvider);

    final prefix = _greeting(dashState.userName);

    final overdueCount = recurringState.items
        .where((i) => i.status == RecurringStatus.overdue)
        .length;

    final exceededCount =
        budgetState.overview?.items.where((i) => i.percentage > 100).length ??
            0;

    final String suffix;

    if (overdueCount > 0) {
      suffix = ' · $overdueCount charge${overdueCount > 1 ? 's' : ''} en retard';
    } else if (exceededCount > 0) {
      suffix = ' · $exceededCount budget${exceededCount > 1 ? 's' : ''} dépassé${exceededCount > 1 ? 's' : ''}';
    } else {
      final summary = dashState.currentSummary;
      if (summary != null && summary.totalRecettes + summary.totalDepenses > 0) {
        final isPositive = summary.totalRecettes >= summary.totalDepenses;
        suffix = isPositive ? ' · Mois positif' : ' · Mois négatif';
      } else {
        suffix = ' · Mois calme';
      }
    }

    return Text(
      '$prefix$suffix',
      style: TextStyle(
        fontSize: AppTypography.sizeSm,
        fontWeight: AppTypography.regular,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

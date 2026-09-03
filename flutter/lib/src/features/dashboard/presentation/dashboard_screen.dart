// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/data/remote/data_sources/preference_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/user_preference_request.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:k_budget/src/features/dashboard/presentation/widgets/currency_pill_selector.dart';
import 'package:k_budget/src/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:k_budget/src/features/dashboard/presentation/widgets/dashboard_hero_widget.dart';
import 'package:k_budget/src/features/dashboard/presentation/widgets/budget_summary_section.dart';
import 'package:k_budget/src/features/dashboard/presentation/widgets/recent_transactions_section.dart';
import 'package:k_budget/src/features/exchange_rates/application/exchange_rate_notifier.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Charger les donnees au demarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardNotifierProvider.notifier).loadDashboard();
    });
  }

  @override
  void dispose() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
      // Persister immédiatement si changement en attente
      final currentState = ref.read(dashboardNotifierProvider);
      _persistCurrencyChange(currentState.currencies);
    }
    super.dispose();
  }

  void _onCurrencyPillTapped(Currency currency) {
    final notifier = ref.read(dashboardNotifierProvider.notifier);
    final currentState = ref.read(dashboardNotifierProvider);

    // Reorder currencies : la devise tapée devient la première
    final reordered = [
      currency,
      ...currentState.currencies.where((c) => c != currency),
    ];

    // Mise à jour instantanée
    notifier.setActiveCurrencyAndCurrencies(currency, reordered);

    // Debounce la persistance
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 2000), () {
      _persistCurrencyChange(reordered);
    });
  }

  Future<void> _persistCurrencyChange(List<Currency> currencies) async {
    try {
      final dataSource =
          await ref.read(preferenceRemoteDataSourceProvider.future);
      final prefs = await dataSource.getPreferences();
      await dataSource.updatePreferences(
        UserPreferenceRequest(
          enabledFeatures: prefs.enabledFeatures,
          navOrder: prefs.navOrder,
          currencies:
              currencies.map((c) => c.name.toUpperCase()).toList(),
        ),
      );
      // Re-fetch les taux inversés par le backend
      await ref.read(exchangeRateListProvider.notifier).loadItems();
      final newRates = ref.read(exchangeRateListProvider);
      ref
          .read(dashboardNotifierProvider.notifier)
          .updateExchangeRates(newRates.items);
    } catch (_) {
      // Silent failure
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(dashboardNotifierProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Etat vide global : aucun compte et pas en chargement
    if (!state.isLoading && state.accounts.isEmpty) {
      return _buildEmptyState(colorScheme);
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Ligne top : salutation contextuelle + pill selector devises
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(child: DashboardHeader()),
                    if (state.currencies.length > 1)
                      CurrencyPillSelector(
                        currencies: state.currencies,
                        activeCurrency: state.activeCurrency,
                        onCurrencyChanged: _onCurrencyPillTapped,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space4),

                // Hero patrimoine total + revenus/dépenses
                DashboardHeroWidget(
                  key: const Key('dashboard_hero'),
                  accounts: state.accounts,
                  activeCurrency: state.activeCurrency,
                  exchangeRates: state.exchangeRates,
                  currencies: state.currencies,
                  currentSummary: state.currentSummary,
                  isLoading: state.isLoading,
                ),
                const SizedBox(height: AppSpacing.space5),

                // Resume budgets (gère sa propre visibilité)
                const BudgetSummarySection(),
                const SizedBox(height: AppSpacing.space5),

                // Dernieres operations
                const RecentTransactionsSection(),
                const SizedBox(height: AppSpacing.space4),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(
              PhosphorIconsRegular.wallet,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              'Bienvenue !',
              style: TextStyle(
                fontSize: AppTypography.sizeXl,
                fontWeight: AppTypography.semiBold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              'Commencez par créer un compte\npour suivre vos finances.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTypography.sizeMd,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

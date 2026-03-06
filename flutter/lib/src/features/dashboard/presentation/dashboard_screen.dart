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
import 'package:k_budget/src/features/dashboard/presentation/widgets/hero_account_section.dart';
import 'package:k_budget/src/features/dashboard/presentation/widgets/mini_cards_section.dart';
import 'package:k_budget/src/features/dashboard/presentation/widgets/monthly_summary_section.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Etat vide global : aucun compte et pas en chargement
    if (!state.isLoading && state.accounts.isEmpty) {
      return _buildEmptyState(colorScheme);
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message de bienvenue
            Text(
              state.userName != null
                  ? 'Bonjour ${state.userName}'
                  : 'Bonjour',
              style: TextStyle(
                fontSize: AppTypography.sizeXl,
                fontWeight: AppTypography.semiBold,
                color: colorScheme.onSurface,
              ),
            ),
            // Pill selector multi-devises
            if (state.currencies.length > 1) ...[
              const SizedBox(height: AppSpacing.space3),
              CurrencyPillSelector(
                currencies: state.currencies,
                activeCurrency: state.activeCurrency,
                onCurrencyChanged: (c) {
                  _onCurrencyPillTapped(c);
                },
              ),
            ],
            const SizedBox(height: AppSpacing.space4),

            // US1 — Hero compte + liste comptes
            HeroAccountSection(
              activeCurrency: state.activeCurrency,
              exchangeRates: state.exchangeRates,
            ),
            const SizedBox(height: AppSpacing.space5),

            // US2 — Resume mensuel
            const MonthlySummarySection(),
            const SizedBox(height: AppSpacing.space5),

            // US4 — Mini-cards (avant les transactions pour le layout)
            MiniCardsSection(
              activeCurrency: state.activeCurrency,
              exchangeRates: state.exchangeRates,
            ),
            const SizedBox(height: AppSpacing.space5),

            // US3 — Dernieres operations
            const RecentTransactionsSection(),
            const SizedBox(height: AppSpacing.space4),
          ],
        ),
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

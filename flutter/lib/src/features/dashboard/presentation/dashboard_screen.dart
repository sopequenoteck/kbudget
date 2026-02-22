import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:k_budget/src/features/dashboard/presentation/widgets/hero_account_section.dart';
import 'package:k_budget/src/features/dashboard/presentation/widgets/mini_cards_section.dart';
import 'package:k_budget/src/features/dashboard/presentation/widgets/monthly_summary_section.dart';
import 'package:k_budget/src/features/dashboard/presentation/widgets/recent_transactions_section.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les donnees au demarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardNotifierProvider.notifier).loadDashboard();
    });
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
            const SizedBox(height: AppSpacing.space4),

            // US1 — Hero compte + liste comptes
            const HeroAccountSection(),
            const SizedBox(height: AppSpacing.space5),

            // US2 — Resume mensuel
            const MonthlySummarySection(),
            const SizedBox(height: AppSpacing.space5),

            // US4 — Mini-cards (avant les transactions pour le layout)
            const MiniCardsSection(),
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
            Icon(
              Icons.account_balance_wallet_outlined,
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

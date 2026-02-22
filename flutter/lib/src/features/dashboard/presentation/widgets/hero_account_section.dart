import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:shimmer/shimmer.dart';

class HeroAccountSection extends ConsumerWidget {
  const HeroAccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardNotifierProvider);

    if (state.isLoading) return const _HeroSkeleton();

    if (state.accounts.isEmpty) return const SizedBox.shrink();

    final defaultAccount = state.defaultAccount;
    if (defaultAccount == null) return const SizedBox.shrink();

    final otherAccounts =
        state.accounts.where((a) => a.id != defaultAccount.id).toList();
    final showSeeAll = state.accounts.length >= 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroCard(account: defaultAccount),
        if (otherAccounts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space3),
          ...otherAccounts.map(
            (account) => _AccountRow(account: account),
          ),
        ],
        if (showSeeAll) ...[
          const SizedBox(height: AppSpacing.space2),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go(RouteNames.settings),
              child: const Text('Voir tout'),
            ),
          ),
        ],
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final solde = account.solde;

    return GestureDetector(
      onTap: () => context.go(RouteNames.transactions),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.space5),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: AppSpacing.space12,
                  height: AppSpacing.space12,
                  decoration: BoxDecoration(
                    color: Color(
                        int.parse('0xFF${account.couleur.replaceAll('#', '')}')),
                    borderRadius: BorderRadius.circular(AppRadius.round),
                  ),
                  child: Center(
                    child: Text(
                      account.icone,
                      style:
                          const TextStyle(fontSize: AppTypography.sizeXl),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Text(
                    account.nom,
                    style: TextStyle(
                      fontSize: AppTypography.sizeLg,
                      fontWeight: AppTypography.semiBold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              AmountFormatter.format(solde, currency: account.currency),
              style: TextStyle(
                fontSize: AppTypography.size3xl,
                fontWeight: AppTypography.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => context.go(RouteNames.transactions),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space2,
          horizontal: AppSpacing.space1,
        ),
        child: Row(
          children: [
            Container(
              width: AppSpacing.space9,
              height: AppSpacing.space9,
              decoration: BoxDecoration(
                color: Color(
                    int.parse('0xFF${account.couleur.replaceAll('#', '')}')),
                borderRadius: BorderRadius.circular(AppRadius.round),
              ),
              child: Center(
                child: Text(
                  account.icone,
                  style: const TextStyle(fontSize: AppTypography.sizeMd),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text(
                account.nom,
                style: TextStyle(
                  fontSize: AppTypography.sizeMd,
                  fontWeight: AppTypography.medium,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              AmountFormatter.format(
                account.solde,
                currency: account.currency,
              ),
              style: TextStyle(
                fontSize: AppTypography.sizeMd,
                fontWeight: AppTypography.semiBold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surface;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          ...List.generate(
            2,
            (_) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
              child: Container(
                width: double.infinity,
                height: AppSpacing.space9,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/common_widgets/account_bank_icon.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/currency_converter.dart';
import 'package:shimmer/shimmer.dart';

class HeroAccountSection extends ConsumerWidget {
  final Currency activeCurrency;
  final List<ExchangeRate> exchangeRates;

  const HeroAccountSection({
    super.key,
    required this.activeCurrency,
    required this.exchangeRates,
  });

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

    // Total patrimoine dans activeCurrency
    final totalBalance = state.accounts.fold<double>(0, (sum, a) {
      if (a.currency == activeCurrency) return sum + a.solde;
      final converted = CurrencyConverter.convert(
        amount: a.solde,
        fromCurrency: a.currency,
        toCurrency: activeCurrency,
        rates: exchangeRates,
      );
      return sum + (converted ?? 0);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroCard(
          account: defaultAccount,
          activeCurrency: activeCurrency,
          exchangeRates: exchangeRates,
          totalBalance: state.accounts.length > 1 ? totalBalance : null,
        ),
        if (otherAccounts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space3),
          ...otherAccounts.map(
            (account) => _AccountRow(
              account: account,
              activeCurrency: activeCurrency,
              exchangeRates: exchangeRates,
            ),
          ),
        ],
        if (showSeeAll) ...[
          const SizedBox(height: AppSpacing.space2),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/settings/accounts'),
              child: const Text('Voir tout'),
            ),
          ),
        ],
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.account,
    required this.activeCurrency,
    required this.exchangeRates,
    this.totalBalance,
  });

  final Account account;
  final Currency activeCurrency;
  final List<ExchangeRate> exchangeRates;
  final double? totalBalance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final solde = account.solde;

    // Montant converti si la devise du compte diffère de activeCurrency
    final converted = account.currency != activeCurrency
        ? CurrencyConverter.convert(
            amount: solde,
            fromCurrency: account.currency,
            toCurrency: activeCurrency,
            rates: exchangeRates,
          )
        : null;

    return Container(
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
              AccountBankIcon(account: account, size: AppSpacing.space12),
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
          if (converted != null) ...[
            const SizedBox(height: AppSpacing.space1),
            Text(
              '~ ${AmountFormatter.format(converted, currency: activeCurrency)}',
              style: TextStyle(
                fontSize: AppTypography.sizeLg,
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
              ),
            ),
          ],
          if (totalBalance != null) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              'Total : ${AmountFormatter.format(totalBalance!, currency: activeCurrency)}',
              style: TextStyle(
                fontSize: AppTypography.sizeSm,
                fontWeight: AppTypography.medium,
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.activeCurrency,
    required this.exchangeRates,
  });

  final Account account;
  final Currency activeCurrency;
  final List<ExchangeRate> exchangeRates;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final converted = account.currency != activeCurrency
        ? CurrencyConverter.convert(
            amount: account.solde,
            fromCurrency: account.currency,
            toCurrency: activeCurrency,
            rates: exchangeRates,
          )
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.space2,
        horizontal: AppSpacing.space1,
      ),
      child: Row(
        children: [
          AccountBankIcon(account: account, size: AppSpacing.space9),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
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
              if (converted != null)
                Text(
                  '~ ${AmountFormatter.format(converted, currency: activeCurrency)}',
                  style: TextStyle(
                    fontSize: AppTypography.sizeXs,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
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

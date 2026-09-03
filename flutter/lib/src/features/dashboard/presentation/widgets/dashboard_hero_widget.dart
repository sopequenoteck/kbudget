// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_colors.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/domain/models/monthly_summary.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/currency_converter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';

class DashboardHeroWidget extends StatelessWidget {
  const DashboardHeroWidget({
    super.key,
    required this.accounts,
    required this.activeCurrency,
    required this.exchangeRates,
    required this.currencies,
    required this.isLoading,
    this.currentSummary,
  });

  final List<Account> accounts;
  final Currency activeCurrency;
  final List<ExchangeRate> exchangeRates;
  final List<Currency> currencies;
  final bool isLoading;
  final MonthlySummary? currentSummary;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _DashboardHeroSkeleton(key: Key('dashboard_hero_skeleton'));
    }

    final colorScheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<AppThemeExtension>()!;

    // Calcul du patrimoine total + détection taux manquants
    bool hasMissingRate = false;
    final patrimoineTotal = accounts.fold<double>(0, (sum, a) {
      if (a.currency == activeCurrency) return sum + a.solde;
      final converted = CurrencyConverter.convert(
        amount: a.solde,
        fromCurrency: a.currency,
        toCurrency: activeCurrency,
        rates: exchangeRates,
      );
      if (converted == null) hasMissingRate = true;
      return sum + (converted ?? 0);
    });

    final patrimoineColor =
        patrimoineTotal >= 0 ? colors.incomeColor : colors.expenseColor;

    // Devise secondaire
    Currency? secondaryCurrency;
    if (currencies.length >= 2) {
      secondaryCurrency =
          activeCurrency != currencies[0] ? currencies[0] : currencies[1];
    }

    double? patrimoineSecondaire;
    if (secondaryCurrency != null) {
      patrimoineSecondaire = CurrencyConverter.convert(
        amount: patrimoineTotal,
        fromCurrency: activeCurrency,
        toCurrency: secondaryCurrency,
        rates: exchangeRates,
      );
    }

    return Column(
      key: const Key('dashboard_hero'),
      crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Label
          Text(
            'PATRIMOINE TOTAL',
            style: TextStyle(
              fontSize: AppTypography.sizeXs,
              fontWeight: AppTypography.medium,
              letterSpacing: AppTypography.labelLetterSpacingForSize12,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),

          // 2. Espacement
          const SizedBox(height: AppSpacing.space2),

          // 3. Montant patrimoine
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  AmountFormatter.format(
                    patrimoineTotal,
                    currency: activeCurrency,
                  ),
                  style: TextStyle(
                    fontSize: AppTypography.size3xl,
                    fontWeight: AppTypography.bold,
                    color: patrimoineColor,
                  ),
                ),
              ),
              if (hasMissingRate)
                const Tooltip(
                  message: 'Certains montants n\'ont pas pu être convertis',
                  child: PhosphorIcon(
                    PhosphorIconsRegular.warningCircle,
                    size: 18,
                    color: AppColors.warning,
                  ),
                ),
            ],
          ),

          // 4. Badge variation mensuelle
          if (currentSummary != null) ...[
            const SizedBox(height: AppSpacing.space2),
            _buildVariationBadge(colors, patrimoineTotal),
          ],

          // 5. Devise secondaire — avant les meta-lines (ordre Angular)
          if (patrimoineSecondaire != null && secondaryCurrency != null) ...[
            const SizedBox(height: AppSpacing.space1),
            Text(
              '≈ ${AmountFormatter.format(patrimoineSecondaire, currency: secondaryCurrency)}',
              style: TextStyle(
                fontSize: AppTypography.sizeXs,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],

          // 6. Meta-lines revenus/dépenses — côte à côte (flex row Angular)
          if (currentSummary != null) ...[
            const SizedBox(height: AppSpacing.space2),
            Row(
              spacing: AppSpacing.space4,
              children: [
                Row(
                  spacing: AppSpacing.space2,
                  children: [
                    PhosphorIcon(
                      PhosphorIconsRegular.trendUp,
                      size: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    Text(
                      AmountFormatter.format(
                        currentSummary!.totalRecettes,
                        type: 'recette',
                        currency: activeCurrency,
                      ),
                      style: TextStyle(
                        fontSize: AppTypography.sizeXs,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: AppSpacing.space2,
                  children: [
                    PhosphorIcon(
                      PhosphorIconsRegular.trendDown,
                      size: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    Text(
                      AmountFormatter.format(
                        currentSummary!.totalDepenses,
                        type: 'depense',
                        currency: activeCurrency,
                      ),
                      style: TextStyle(
                        fontSize: AppTypography.sizeXs,
                        color: colors.expenseColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
    );
  }

  Widget _buildVariationBadge(
    AppThemeExtension colors,
    double patrimoineTotal,
  ) {
    final netDuMois =
        currentSummary!.totalRecettes - currentSummary!.totalDepenses;
    final patrimoineDebutMois = patrimoineTotal - netDuMois;
    final sign = netDuMois >= 0 ? '+' : '';
    final montantFormate =
        AmountFormatter.format(netDuMois, currency: activeCurrency);

    final String variationLabel;
    if (patrimoineDebutMois != 0) {
      final pct = (netDuMois / patrimoineDebutMois) * 100;
      final pctFormate = pct.toStringAsFixed(1).replaceAll('.', ',');
      variationLabel = '$sign$montantFormate ce mois ($sign$pctFormate%)';
    } else {
      variationLabel = '$sign$montantFormate ce mois';
    }

    final variationColor =
        netDuMois >= 0 ? colors.incomeColor : colors.expenseColor;

    return Text(
      variationLabel,
      style: TextStyle(
        fontSize: AppTypography.sizeXs,
        fontWeight: AppTypography.medium,
        color: variationColor,
      ),
    );
  }
}

class _DashboardHeroSkeleton extends StatelessWidget {
  const _DashboardHeroSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surface,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space2,
        ),
        height: 96,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/constants/app_colors.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_shadows.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/domain/models/monthly_summary.dart';
import 'package:k_budget/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/currency_converter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';

class PatrimoineCard extends ConsumerWidget {
  final List<Account> accounts;
  final Currency activeCurrency;
  final List<ExchangeRate> exchangeRates;
  final List<Currency> currencies;
  final MonthlySummary? currentSummary;

  const PatrimoineCard({
    super.key,
    required this.accounts,
    required this.activeCurrency,
    required this.exchangeRates,
    required this.currencies,
    this.currentSummary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardNotifierProvider);

    if (state.isLoading) return const _PatrimoineCardSkeleton();

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

    // Calcul de la variation mensuelle
    String? variationLabel;
    Color? variationColor;
    if (currentSummary != null) {
      final netDuMois =
          currentSummary!.totalRecettes - currentSummary!.totalDepenses;
      final patrimoineDebutMois = patrimoineTotal - netDuMois;

      final sign = netDuMois >= 0 ? '+' : '';
      final montantFormate =
          AmountFormatter.format(netDuMois, currency: activeCurrency);

      if (patrimoineDebutMois != 0) {
        final pct = (netDuMois / patrimoineDebutMois) * 100;
        final pctFormate = pct.toStringAsFixed(1).replaceAll('.', ',');
        variationLabel = '$sign$montantFormate ce mois ($sign$pctFormate%)';
      } else {
        variationLabel = '$sign$montantFormate ce mois';
      }

      variationColor =
          netDuMois >= 0 ? AppColors.textSuccess : AppColors.textError;
    }

    // Devise secondaire — logique identique Angular
    Currency? secondaryCurrency;
    if (currencies.length >= 2) {
      if (activeCurrency != currencies[0]) {
        secondaryCurrency = currencies[0];
      } else {
        secondaryCurrency = currencies[1];
      }
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

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.amber900, AppColors.indigo900]
              : [AppColors.amber50, AppColors.indigo50],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PATRIMOINE TOTAL',
            style: TextStyle(
              fontSize: AppTypography.sizeXs,
              fontWeight: AppTypography.medium,
              letterSpacing: 0.8,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
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
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (hasMissingRate)
                const Tooltip(
                  message: 'Certains montants n\'ont pas pu être convertis',
                  child: Icon(
                    PhosphorIconsRegular.warningCircle,
                    size: 18,
                    color: AppColors.warning,
                  ),
                ),
            ],
          ),
          if (variationLabel != null) ...[
            const SizedBox(height: AppSpacing.space2),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
                vertical: AppSpacing.space1,
              ),
              decoration: BoxDecoration(
                color: variationColor?.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.round),
              ),
              child: Text(
                variationLabel,
                style: TextStyle(
                  fontSize: AppTypography.sizeSm,
                  fontWeight: AppTypography.medium,
                  color: variationColor,
                ),
              ),
            ),
          ],
          if (patrimoineSecondaire != null && secondaryCurrency != null) ...[
            const SizedBox(height: AppSpacing.space1),
            Text(
              '≈ ${AmountFormatter.format(patrimoineSecondaire, currency: secondaryCurrency)}',
              style: TextStyle(
                fontSize: AppTypography.sizeSm,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PatrimoineCardSkeleton extends StatelessWidget {
  const _PatrimoineCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surface;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: double.infinity,
        height: 110,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    );
  }
}

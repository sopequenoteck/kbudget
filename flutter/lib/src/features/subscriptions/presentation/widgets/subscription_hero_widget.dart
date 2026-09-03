// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';

class SubscriptionHeroWidget extends StatelessWidget {
  const SubscriptionHeroWidget({
    super.key,
    required this.monthlyTotals,
    required this.activeCount,
    required this.isLoading,
  });

  final Map<Currency, double> monthlyTotals;
  final int activeCount;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (monthlyTotals.isEmpty && !isLoading) return const SizedBox.shrink();

    if (isLoading) {
      return const _SubscriptionHeroSkeleton(
        key: Key('subscription_hero_skeleton'),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<AppThemeExtension>()!;

    final firstEntry = monthlyTotals.entries.first;
    final totalMensuel = firstEntry.value;
    final currency = firstEntry.key;
    final totalAnnuel = totalMensuel * 12;

    return Padding(
      key: const Key('subscription_hero'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ABONNEMENTS',
            style: TextStyle(
              fontSize: AppTypography.sizeXs,
              fontWeight: AppTypography.medium,
              letterSpacing: 0.8,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            AmountFormatter.format(totalMensuel, currency: currency),
            style: TextStyle(
              fontSize: AppTypography.size3xl,
              fontWeight: AppTypography.bold,
              color: colors.expenseColor,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              PhosphorIcon(
                PhosphorIconsRegular.repeat,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '$activeCount actifs',
                style: TextStyle(
                  fontSize: AppTypography.sizeSm,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          Row(
            children: [
              PhosphorIcon(
                PhosphorIconsRegular.calendarBlank,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '≈ ${AmountFormatter.format(totalAnnuel, currency: currency)}/an',
                style: TextStyle(
                  fontSize: AppTypography.sizeSm,
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

class _SubscriptionHeroSkeleton extends StatelessWidget {
  const _SubscriptionHeroSkeleton({super.key});

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

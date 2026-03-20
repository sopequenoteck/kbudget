import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';

class CurrencyPillSelector extends StatelessWidget {
  final List<Currency> currencies;
  final Currency activeCurrency;
  final ValueChanged<Currency> onCurrencyChanged;

  const CurrencyPillSelector({
    super.key,
    required this.currencies,
    required this.activeCurrency,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (currencies.length <= 1) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: currencies.map((c) {
          final isActive = c == activeCurrency;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.space2),
            child: GestureDetector(
              onTap: () => onCurrencyChanged(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space4,
                  vertical: AppSpacing.space2,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.round),
                ),
                child: Text(
                  c.symbol,
                  style: TextStyle(
                    fontSize: AppTypography.sizeSm,
                    fontWeight:
                        isActive ? AppTypography.semiBold : AppTypography.medium,
                    color: isActive
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

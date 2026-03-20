import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/subscriptions/application/subscription_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PaymentHistorySection extends ConsumerWidget {
  final String subscriptionId;
  final Currency currency;

  const PaymentHistorySection({
    super.key,
    required this.subscriptionId,
    required this.currency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final paymentsAsync = ref.watch(subscriptionPaymentsProvider(subscriptionId));
    final totalAsync = ref.watch(subscriptionTotalPaidProvider(subscriptionId));
    final dateFormat = DateFormat('d MMM yyyy', 'fr_FR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.subscriptionPaymentHistory,
              style: TextStyle(
                fontSize: AppTypography.sizeMd,
                fontWeight: AppTypography.semiBold,
                color: colorScheme.onSurface,
              ),
            ),
            totalAsync.when(
              loading: () => const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (e, s) => const SizedBox.shrink(),
              data: (total) => Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AmountFormatter.format(total.totalPaid, currency: currency),
                    style: TextStyle(
                      fontSize: AppTypography.sizeSm,
                      fontWeight: AppTypography.semiBold,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    l10n.subscriptionPayments(total.paymentCount),
                    style: TextStyle(
                      fontSize: AppTypography.sizeXs,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        paymentsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.space4),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, s) => Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Text(
              l10n.errorGeneric,
              style: TextStyle(
                fontSize: AppTypography.sizeSm,
                color: colorScheme.error,
              ),
            ),
          ),
          data: (payments) {
            if (payments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
                child: Center(
                  child: Column(
                    children: [
                      PhosphorIcon(
                        PhosphorIconsRegular.receipt,
                        size: 36,
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      Text(
                        l10n.subscriptionNoPayments,
                        style: TextStyle(
                          fontSize: AppTypography.sizeSm,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: payments.map((payment) {
                  final isLast = payment == payments.last;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space4,
                          vertical: AppSpacing.space3,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dateFormat.format(payment.date),
                                    style: TextStyle(
                                      fontSize: AppTypography.sizeSm,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  if (payment.accountName != null)
                                    Text(
                                      payment.accountName!,
                                      style: TextStyle(
                                        fontSize: AppTypography.sizeXs,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              AmountFormatter.format(
                                payment.montant,
                                currency: currency,
                              ),
                              style: TextStyle(
                                fontSize: AppTypography.sizeSm,
                                fontWeight: AppTypography.medium,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast) const Divider(height: 1),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

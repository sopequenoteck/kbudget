// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:k_budget/src/common_widgets/app_modal.dart';
import 'package:k_budget/src/common_widgets/confirm_dialog_custom.dart';
import 'package:k_budget/src/common_widgets/page_header.dart';
import 'package:k_budget/src/common_widgets/select_picker.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/features/accounts/application/account_notifier.dart';
import 'package:k_budget/src/features/exchange_rates/application/currency_config_notifier.dart';
import 'package:k_budget/src/features/exchange_rates/application/exchange_rate_notifier.dart';
import 'package:k_budget/src/features/exchange_rates/presentation/widgets/rate_form.dart';
import 'package:k_budget/src/features/exchange_rates/presentation/widgets/rate_calculator.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:go_router/go_router.dart';

class CurrencySettingsScreen extends ConsumerStatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  ConsumerState<CurrencySettingsScreen> createState() =>
      _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState
    extends ConsumerState<CurrencySettingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(exchangeRateListProvider.notifier).loadItems();
      ref.read(currencyConfigNotifierProvider.notifier).loadCurrencies();
    });
  }

  Future<void> _openRateForm({ExchangeRate? existingRate}) async {
    final currencies = ref.read(currencyConfigNotifierProvider);
    final baseCurrency = currencies.isNotEmpty ? currencies.first : Currency.eur;

    await AppModal.show(
      context,
      title: existingRate == null ? 'Ajouter un taux' : 'Modifier le taux',
      onClose: () {},
      child: RateForm(
        baseCurrency: baseCurrency,
        existingRate: existingRate,
        onSaved: () => Navigator.of(context).pop(),
      ),
    );
  }

  Future<void> _confirmDelete(ExchangeRate rate) async {
    final confirmed = await ConfirmDialogCustom.show(
      context: context,
      icon: PhosphorIconsRegular.trash,
      title: '${rate.baseCurrency.name.toUpperCase()} → ${rate.targetCurrency.name.toUpperCase()}',
      message: 'Ce taux de conversion sera définitivement supprimé.',
      confirmLabel: 'Supprimer',
      variant: ConfirmVariant.danger,
    ) ?? false;

    if (!confirmed || !mounted) return;
    await ref
        .read(exchangeRateListProvider.notifier)
        .delete(rate.baseCurrency, rate.targetCurrency);
  }

  Future<void> _confirmRemoveCurrency(Currency currency) async {
    final accounts = ref.read(accountNotifierProvider).items;
    final hasAccounts =
        accounts.any((a) => a.currency == currency && a.actif);

    final message = hasAccounts
        ? 'Cette devise est utilisée par des comptes existants. Voulez-vous la retirer ?'
        : 'Retirer ${currency.name.toUpperCase()} de vos devises ?';

    final confirmed = await ConfirmDialogCustom.show(
      context: context,
      icon: PhosphorIconsRegular.warning,
      title: 'Retirer ${currency.name.toUpperCase()} ?',
      message: message,
      confirmLabel: 'Retirer',
      variant: ConfirmVariant.danger,
    ) ?? false;

    if (confirmed && mounted) {
      await ref
          .read(currencyConfigNotifierProvider.notifier)
          .removeCurrency(currency);
    }
  }

  void _addCurrency() {
    final currencies = ref.read(currencyConfigNotifierProvider);
    final available =
        Currency.values.where((c) => !currencies.contains(c)).toList();
    if (available.isEmpty) return;

    final items = available
        .map((c) => SelectPickerItem(
              id: c.name,
              label: c.name.toUpperCase(),
              secondaryText: c.symbol,
            ))
        .toList();

    AppModal.show(
      context,
      title: 'Ajouter une devise',
      onClose: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items
            .map(
              (item) => ListTile(
                leading: Text(
                  Currency.values.byName(item.id).symbol,
                  style: const TextStyle(fontSize: 20),
                ),
                title: Text(item.label),
                subtitle: Text(Currency.values.byName(item.id).name),
                onTap: () {
                  Navigator.of(context).pop();
                  ref
                      .read(currencyConfigNotifierProvider.notifier)
                      .addCurrency(Currency.values.byName(item.id));
                },
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exchangeRateListProvider);
    final currencies = ref.watch(currencyConfigNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final sectionLabelStyle = TextStyle(
      fontSize: AppTypography.sizeXs,
      fontWeight: AppTypography.medium,
      letterSpacing: AppTypography.labelLetterSpacingForSize12,
      color: colorScheme.onSurfaceVariant,
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.space4),
          children: [
            PageHeader(
              title: 'Devises & Taux',
              onBack: () => context.pop(),
              icon: const PhosphorIcon(PhosphorIconsRegular.bank, size: 16),
            ),

            // Section "Mes devises"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('MES DEVISES', style: sectionLabelStyle),
                _AddButton(onTap: _addCurrency),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),

            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: currencies.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
                final reordered = [...currencies];
                final item = reordered.removeAt(oldIndex);
                reordered.insert(newIndex, item);
                ref
                    .read(currencyConfigNotifierProvider.notifier)
                    .reorderCurrencies(reordered);
              },
              itemBuilder: (context, index) {
                final currency = currencies[index];
                final isPrimary = index == 0;
                return ListTile(
                  key: ValueKey(currency.name),
                  leading: Text(
                    currency.symbol,
                    style: const TextStyle(fontSize: 20),
                  ),
                  title: Text(currency.name.toUpperCase()),
                  subtitle: Text(
                    isPrimary ? 'Principale • ${currency.displayName}' : currency.displayName,
                    style: TextStyle(
                      fontSize: AppTypography.sizeSm,
                      color: isPrimary
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight:
                          isPrimary ? AppTypography.medium : AppTypography.regular,
                    ),
                  ),
                  trailing: isPrimary
                      ? Chip(
                          label: const Text('Principale'),
                          labelStyle: TextStyle(
                            fontSize: AppTypography.sizeXs,
                            color: colorScheme.primary,
                          ),
                          backgroundColor:
                              colorScheme.primary.withValues(alpha: 0.1),
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        )
                      : IconButton(
                          icon: PhosphorIcon(
                            PhosphorIconsRegular.trash,
                            size: 20,
                            color: colorScheme.error,
                          ),
                          onPressed: () => _confirmRemoveCurrency(currency),
                          tooltip: 'Retirer cette devise',
                        ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.space6),
            const Divider(),
            const SizedBox(height: AppSpacing.space4),

            // Section taux de conversion
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TAUX DE CONVERSION', style: sectionLabelStyle),
                _AddButton(onTap: () => _openRateForm()),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),

            if (state.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.space8),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (state.error != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.space4),
                child: Text(
                  'Erreur : ${state.error}',
                  style: TextStyle(color: colorScheme.error),
                ),
              )
            else if (state.items.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.space6),
                child: Text(
                  'Aucun taux de conversion enregistré.',
                  style: TextStyle(
                    fontSize: AppTypography.sizeSm,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < state.items.length; i++) ...[
                      _RateTile(
                        rate: state.items[i],
                        onEdit: () => _openRateForm(existingRate: state.items[i]),
                        onDelete: () => _confirmDelete(state.items[i]),
                      ),
                      if (i < state.items.length - 1)
                        Divider(height: 1, color: colorScheme.outline),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: AppSpacing.space6),
            const Divider(),
            const SizedBox(height: AppSpacing.space4),

            // Section calculateur
            Text('CALCULATEUR', style: sectionLabelStyle),
            const SizedBox(height: AppSpacing.space3),
            const RateCalculator(),
            const SizedBox(height: AppSpacing.space8),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.outline),
        ),
        child: Center(
          child: PhosphorIcon(
            PhosphorIconsRegular.plus,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _RateTile extends StatelessWidget {
  final ExchangeRate rate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RateTile({
    required this.rate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${rate.baseCurrency.name.toUpperCase()} → ${rate.targetCurrency.name.toUpperCase()}',
              style: TextStyle(
                fontSize: AppTypography.sizeSm,
                fontWeight: AppTypography.medium,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            rate.rate.toStringAsFixed(
              rate.rate < 1 ? 6 : (rate.rate < 10 ? 4 : 3),
            ),
            style: TextStyle(
              fontSize: AppTypography.sizeSm,
              fontWeight: AppTypography.semiBold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          IconButton(
            icon: PhosphorIcon(
              PhosphorIconsRegular.pencil,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: onEdit,
            tooltip: 'Modifier',
          ),
          IconButton(
            icon: PhosphorIcon(
              PhosphorIconsRegular.trash,
              size: 20,
              color: colorScheme.error,
            ),
            onPressed: onDelete,
            tooltip: 'Supprimer',
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:k_budget/src/common_widgets/app_modal.dart';
import 'package:k_budget/src/common_widgets/select_picker.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/features/accounts/application/account_notifier.dart';
import 'package:k_budget/src/features/exchange_rates/application/currency_config_notifier.dart';
import 'package:k_budget/src/features/exchange_rates/application/exchange_rate_notifier.dart';
import 'package:k_budget/src/features/exchange_rates/presentation/widgets/rate_form.dart';
import 'package:k_budget/src/features/exchange_rates/presentation/widgets/rate_calculator.dart';
import 'package:k_budget/src/domain/enums/enums.dart';

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce taux ?'),
        content: Text(
          '${rate.baseCurrency.symbol} → ${rate.targetCurrency.symbol} : ${rate.rate}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer cette devise ?'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Devises & Taux')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.space4),
        children: [
          // Section "Mes devises"
          Text(
            'Mes devises',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
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
                  isPrimary ? 'Principale • ${currency.name}' : currency.name,
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

          const SizedBox(height: AppSpacing.space3),

          OutlinedButton.icon(
            onPressed: _addCurrency,
            icon: const PhosphorIcon(PhosphorIconsRegular.plus, size: 20),
            label: const Text('Ajouter une devise'),
          ),

          const SizedBox(height: AppSpacing.space6),
          const Divider(),
          const SizedBox(height: AppSpacing.space4),

          // Section taux de conversion
          Text(
            'Taux de conversion',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
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
            ...state.items.map((rate) => _RateTile(
                  rate: rate,
                  onEdit: () => _openRateForm(existingRate: rate),
                  onDelete: () => _confirmDelete(rate),
                )),

          const SizedBox(height: AppSpacing.space4),

          // Bouton ajouter
          OutlinedButton.icon(
            onPressed: () => _openRateForm(),
            icon: const PhosphorIcon(PhosphorIconsRegular.plus, size: 20),
            label: const Text('Ajouter un taux'),
          ),

          const SizedBox(height: AppSpacing.space6),
          const Divider(),
          const SizedBox(height: AppSpacing.space4),

          // Section calculateur
          Text(
            'Calculateur',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          const RateCalculator(),
          const SizedBox(height: AppSpacing.space8),
        ],
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

    return Card(
      color: colorScheme.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: AppSpacing.space2),
      elevation: 0,
      child: ListTile(
        leading: PhosphorIcon(
          PhosphorIconsRegular.currencyCircleDollar,
          size: 24,
          color: colorScheme.primary,
        ),
        title: Text(
          '${rate.baseCurrency.name.toUpperCase()} → ${rate.targetCurrency.name.toUpperCase()}',
          style: TextStyle(
            fontSize: AppTypography.sizeMd,
            fontWeight: AppTypography.medium,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          rate.rate.toStringAsFixed(
            rate.rate < 1 ? 6 : (rate.rate < 10 ? 4 : 3),
          ),
          style: TextStyle(
            fontSize: AppTypography.sizeSm,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
      ),
    );
  }
}

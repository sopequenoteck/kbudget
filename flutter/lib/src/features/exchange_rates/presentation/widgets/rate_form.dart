// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/common_widgets/app_form_field.dart';
import 'package:k_budget/src/common_widgets/select_picker.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/domain/models/exchange_rate.dart';
import 'package:k_budget/src/features/exchange_rates/application/exchange_rate_notifier.dart';
import 'package:k_budget/src/utils/currency_converter.dart';

class RateForm extends ConsumerStatefulWidget {
  final Currency baseCurrency;
  final ExchangeRate? existingRate;
  final VoidCallback onSaved;

  const RateForm({
    super.key,
    required this.baseCurrency,
    this.existingRate,
    required this.onSaved,
  });

  @override
  ConsumerState<RateForm> createState() => _RateFormState();
}

class _RateFormState extends ConsumerState<RateForm> {
  late Currency _selectedTarget;
  late final TextEditingController _rateController;
  bool _showErrors = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRate != null) {
      _selectedTarget = widget.existingRate!.targetCurrency;
      _rateController = TextEditingController(
        text: widget.existingRate!.rate.toString(),
      );
    } else {
      final available = Currency.values
          .where((c) => c != widget.baseCurrency)
          .toList();
      _selectedTarget = available.first;
      _rateController = TextEditingController();
      _autofillFixedParity(_selectedTarget);
    }
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  void _autofillFixedParity(Currency target) {
    final direct = CurrencyConverter.fixedParityRates[(widget.baseCurrency, target)];
    if (direct != null) {
      _rateController.text = direct.toString();
      return;
    }
    final inverse = CurrencyConverter.fixedParityRates[(target, widget.baseCurrency)];
    if (inverse != null) {
      _rateController.text = CurrencyConverter.invertRate(inverse).toString();
    }
  }

  String? _validateRate(String value) {
    if (value.trim().isEmpty) return 'Le taux est requis';
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return 'Entrez un taux valide (> 0)';
    return null;
  }

  Future<void> _onSubmit() async {
    setState(() => _showErrors = true);
    final rateError = _validateRate(_rateController.text);
    if (rateError != null) return;

    setState(() => _isSubmitting = true);
    try {
      final rate = double.parse(_rateController.text.replaceAll(',', '.'));
      await ref.read(exchangeRateListProvider.notifier).upsert(
            widget.baseCurrency,
            _selectedTarget,
            rate,
          );
      if (mounted) widget.onSaved();
    } on Exception {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'enregistrement")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final rateError = _showErrors ? _validateRate(_rateController.text) : null;

    final targetItems = Currency.values
        .where((c) => c != widget.baseCurrency)
        .map((c) => SelectPickerItem(id: c.name, label: '${c.symbol} — ${c.name}'))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Devise de base (read-only)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Devise de base',
              style: TextStyle(
                fontSize: AppTypography.sizeSm,
                fontWeight: AppTypography.medium,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.space3,
                horizontal: AppSpacing.space4,
              ),
              child: Text(
                '${widget.baseCurrency.symbol} — ${widget.baseCurrency.displayName}',
                style: TextStyle(
                  fontSize: AppTypography.sizeMd,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space6),

        // Devise cible
        SelectPicker(
          label: 'Devise cible',
          items: targetItems,
          selectedId: _selectedTarget.name,
          onChanged: (id) {
            if (id == null) return;
            final target = Currency.values.byName(id);
            setState(() {
              _selectedTarget = target;
              _rateController.clear();
            });
            _autofillFixedParity(target);
          },
          enabled: widget.existingRate == null,
        ),
        const SizedBox(height: AppSpacing.space6),

        // Taux
        AppFormField(
          label:
              'Taux (1 ${widget.baseCurrency.symbol} = X ${_selectedTarget.symbol})',
          showError: rateError != null,
          errorMessage: rateError ?? '',
          child: TextField(
            controller: _rateController,
            decoration: InputDecoration.collapsed(
              hintText: '0.000000',
              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            style: TextStyle(
              fontSize: AppTypography.sizeMd,
              color: colorScheme.onSurface,
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: AppSpacing.space8),

        // Bouton Enregistrer
        FilledButton(
          onPressed: _isSubmitting ? null : _onSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enregistrer'),
        ),
        const SizedBox(height: AppSpacing.space4),
      ],
    );
  }
}

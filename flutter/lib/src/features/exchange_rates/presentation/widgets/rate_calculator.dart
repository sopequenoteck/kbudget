// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_budget/src/common_widgets/app_form_field.dart';
import 'package:k_budget/src/common_widgets/select_picker.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';

class RateCalculator extends StatefulWidget {
  const RateCalculator({super.key});

  @override
  State<RateCalculator> createState() => _RateCalculatorState();
}

class _RateCalculatorState extends State<RateCalculator> {
  Currency _fromCurrency = Currency.eur;
  Currency _toCurrency = Currency.xof;

  final _fromController = TextEditingController();
  final _toController = TextEditingController();

  double? _computedRate;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _compute() {
    final fromVal = double.tryParse(_fromController.text.replaceAll(',', '.'));
    final toVal = double.tryParse(_toController.text.replaceAll(',', '.'));
    if (fromVal != null && fromVal > 0 && toVal != null && toVal > 0) {
      setState(() => _computedRate = toVal / fromVal);
    } else {
      setState(() => _computedRate = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currencyItems = Currency.values
        .map((c) => SelectPickerItem(id: c.name, label: '${c.symbol} — ${c.name}'))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ligne "J'ai X [devise]"
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 3,
              child: AppFormField(
                label: "J'ai",
                child: TextField(
                  controller: _fromController,
                  decoration: InputDecoration.collapsed(
                    hintText: '1',
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
                  onChanged: (_) => _compute(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              flex: 4,
              child: SelectPicker(
                label: 'Devise',
                items: currencyItems,
                selectedId: _fromCurrency.name,
                onChanged: (id) {
                  if (id == null) return;
                  setState(() {
                    _fromCurrency = Currency.values.byName(id);
                    _computedRate = null;
                  });
                  _compute();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),

        // Ligne "= Y [devise]"
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 3,
              child: AppFormField(
                label: '=',
                child: TextField(
                  controller: _toController,
                  decoration: InputDecoration.collapsed(
                    hintText: '655.957',
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
                  onChanged: (_) => _compute(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              flex: 4,
              child: SelectPicker(
                label: 'Devise',
                items: currencyItems,
                selectedId: _toCurrency.name,
                onChanged: (id) {
                  if (id == null) return;
                  setState(() {
                    _toCurrency = Currency.values.byName(id);
                    _computedRate = null;
                  });
                  _compute();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),

        // Résultat
        if (_computedRate != null)
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.space3),
            ),
            child: Text(
              'Taux : 1 ${_fromCurrency.symbol} = ${_computedRate!.toStringAsFixed(6)} ${_toCurrency.symbol}',
              style: TextStyle(
                fontSize: AppTypography.sizeSm,
                fontWeight: AppTypography.medium,
                color: colorScheme.onPrimaryContainer,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.space3),
            ),
            child: Text(
              'Saisissez deux montants pour calculer le taux',
              style: TextStyle(
                fontSize: AppTypography.sizeSm,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

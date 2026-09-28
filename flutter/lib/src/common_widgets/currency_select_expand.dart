// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart'
    show
        DiagnosticPropertiesBuilder,
        EnumProperty,
        ObjectFlagProperty,
        StringProperty;
import 'package:flutter/material.dart';
import 'package:k_budget/src/common_widgets/select_picker.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/domain/enums/currency.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/utils/currency_name.dart';

/// Section depliable de choix de la devise, dans les formulaires de dette
/// et d'abonnement : chaque devise par son nom traduit et son symbole.
class CurrencySelectExpand extends StatelessWidget {
  /// Cree la section, [selected] etant la devise choisie s'il y en a une.
  const CurrencySelectExpand({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// Libelle du champ.
  final String label;

  /// Devise choisie, `null` tant que l'utilisateur n'en a pas choisi.
  final Currency? selected;

  /// Appele avec la devise choisie.
  final ValueChanged<Currency> onSelected;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(EnumProperty<Currency>('selected', selected))
      ..add(
        ObjectFlagProperty<ValueChanged<Currency>>.has(
          'onSelected',
          onSelected,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      child: SelectPicker(
        items: [
          for (final c in Currency.values)
            SelectPickerItem(
              id: c.name,
              label: '${currencyName(c, l10n)} (${c.symbol})',
            ),
        ],
        selectedId: selected?.name,
        onChanged: (id) {
          if (id != null) {
            onSelected(Currency.values.byName(id));
          }
        },
        label: label,
      ),
    );
  }
}

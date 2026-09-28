// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart'
    show
        DiagnosticPropertiesBuilder,
        IterableProperty,
        ObjectFlagProperty,
        StringProperty;
import 'package:flutter/material.dart';
import 'package:k_budget/src/common_widgets/account_bank_icon.dart';
import 'package:k_budget/src/common_widgets/select_picker.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/domain/models/account.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/color_utils.dart';
import 'package:k_budget/src/utils/locale_format.dart';

/// Section depliable de choix du compte, dans les formulaires de
/// transaction, de dette et d'abonnement : les comptes actifs, avec leur
/// solde et le logo de leur banque.
class AccountSelectExpand extends StatelessWidget {
  /// Cree la section parmi [accounts].
  const AccountSelectExpand({
    required this.accounts,
    required this.selectedId,
    required this.label,
    required this.onChanged,
    this.keptAccountId,
    super.key,
  });

  /// Comptes de l'utilisateur, actifs ou non.
  final List<Account> accounts;

  /// Identifiant du compte choisi, `null` si aucun.
  final String? selectedId;

  /// Compte propose meme s'il est inactif : celui de l'element modifie.
  final String? keptAccountId;

  /// Libelle du champ.
  final String label;

  /// Appele avec l'identifiant du compte choisi, `null` s'il est retire.
  final ValueChanged<String?> onChanged;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Account>('accounts', accounts))
      ..add(StringProperty('selectedId', selectedId))
      ..add(StringProperty('keptAccountId', keptAccountId))
      ..add(StringProperty('label', label))
      ..add(
        ObjectFlagProperty<ValueChanged<String?>>.has('onChanged', onChanged),
      );
  }

  @override
  Widget build(BuildContext context) {
    final locale = intlLocaleFor(Localizations.localeOf(context));
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      child: SelectPicker(
        items: [
          for (final a in accounts)
            if (a.actif || a.id == keptAccountId)
              SelectPickerItem(
                id: a.id,
                label: a.nom,
                icon: a.icone,
                color: parseHexColor(a.couleur),
                secondaryText: AmountFormatter.format(a.solde, locale: locale),
                imageUrl: resolveBankAssetPath(a),
              ),
        ],
        selectedId: selectedId,
        onChanged: onChanged,
        label: label,
      ),
    );
  }
}

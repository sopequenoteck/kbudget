// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:k_budget/src/localization/app_localizations.dart';

/// Nom affiche d'une categorie : une categorie systeme est traduite par sa
/// [systemKey] (cle `categoriesValue*`), toute autre garde son [nom] saisi.
/// Une cle nulle, vide ou inconnue retombe sur [nom] (docs/i18n.md).
String categoryDisplayName(
  String nom,
  String? systemKey,
  AppLocalizations l10n,
) =>
    switch (systemKey) {
      'SUBSCRIPTION' => l10n.categoriesValueSubscription,
      'DEBT' => l10n.categoriesValueDebt,
      'TRANSFER' => l10n.categoriesValueTransfer,
      'ADJUSTMENT' => l10n.categoriesValueAdjustment,
      _ => nom,
    };

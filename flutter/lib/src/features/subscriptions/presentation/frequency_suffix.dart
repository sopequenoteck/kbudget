// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/localization/app_localizations.dart';

/// Suffixe de periodicite accole au montant d'un abonnement (`/sem`,
/// `/mois`, `/an`), partage par la liste et le detail (KKS-401).
String frequencySuffix(Frequency frequency, AppLocalizations l10n) =>
    switch (frequency) {
      Frequency.hebdomadaire => l10n.subscriptionsValuePerWeek,
      Frequency.mensuel => l10n.subscriptionsValuePerMonth,
      Frequency.annuel => l10n.subscriptionsValuePerYear,
    };

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:k_budget/src/domain/enums/currency.dart';
import 'package:k_budget/src/localization/app_localizations.dart';

/// Nom de [currency] dans la langue d'affichage : une cle
/// `exchangeRatesValue*` par code (docs/i18n.md).
String currencyName(Currency currency, AppLocalizations l10n) =>
    switch (currency) {
      Currency.eur => l10n.exchangeRatesValueEur,
      Currency.xof => l10n.exchangeRatesValueXof,
      Currency.usd => l10n.exchangeRatesValueUsd,
      Currency.gbp => l10n.exchangeRatesValueGbp,
      Currency.chf => l10n.exchangeRatesValueChf,
      Currency.cad => l10n.exchangeRatesValueCad,
      Currency.mad => l10n.exchangeRatesValueMad,
    };

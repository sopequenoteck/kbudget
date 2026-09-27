// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:k_budget/src/domain/enums/currency.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';

const _positiveTypes = {'recette', 'pret'};
const _negativeTypes = {'depense', 'emprunt'};

class AmountFormatter {
  AmountFormatter._();

  static final _cache = <String, NumberFormat>{};

  static NumberFormat _getFormatter(Currency currency, String locale) {
    return _cache.putIfAbsent(
      '$locale-${currency.displayName}',
      () => NumberFormat.currency(
        locale: locale,
        symbol: currency.symbol,
        decimalDigits: currency.decimalPlaces,
      ),
    );
  }

  /// Formate un montant avec devise et signe optionnel.
  ///
  /// [type] : nom de lenum (`TransactionType.depense.name`,
  /// `DebtType.pret.name`) pour determiner le signe +/-.
  /// Sans [type], le signe est deduit de la valeur.
  /// [locale] : identifiant `intl` (`fr_FR`, `en_GB`), independant de la
  /// devise affichee.
  static String format(
    double? value, {
    required String locale,
    String? type,
    Currency currency = Currency.eur,
  }) {
    if (value == null) return '';

    final formatter = _getFormatter(currency, locale);
    final formatted = formatter.format(value.abs());

    if (value == 0) return formatted;

    if (type != null && _positiveTypes.contains(type)) {
      return '+$formatted';
    }

    if (type != null && _negativeTypes.contains(type)) {
      return '-$formatted';
    }

    if (value < 0) return '-$formatted';

    return formatted;
  }

  /// Retourne la couleur semantique pour un type de montant.
  ///
  /// Retourne `null` pour les types inconnus (le caller decide du fallback).
  static Color? amountColor(String? type, AppThemeExtension colors) {
    return switch (type) {
      'recette' || 'pret' => colors.incomeColor,
      'depense' || 'emprunt' => colors.expenseColor,
      _ => null,
    };
  }
}

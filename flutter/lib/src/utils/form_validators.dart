// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:k_budget/src/localization/app_localizations.dart';

// Validateurs de champs partages par les formulaires : chacun retourne le
// message traduit de la premiere regle violee, ou `null` si la valeur est
// valide. Les formulaires de transaction, d'abonnement et de dette, comme
// les ecrans d'authentification, en portaient chacun une copie (KKS-399).

/// Texte obligatoire d'au plus [maxLength] caracteres, espaces de bord
/// ignores.
String? validateRequiredText(
  String? value,
  AppLocalizations l10n, {
  required int maxLength,
}) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return l10n.commonValidationRequired;
  }
  if (trimmed.length > maxLength) {
    return l10n.commonValidationMaxLength(maxLength);
  }
  return null;
}

/// Montant obligatoire et strictement positif ; la virgule decimale est
/// acceptee.
String? validatePositiveAmount(String? value, AppLocalizations l10n) {
  final trimmed = value?.trim() ?? '';
  final parsed = double.tryParse(trimmed.replaceAll(',', '.'));
  if (parsed == null) {
    return l10n.commonValidationRequired;
  }
  if (parsed <= 0) {
    return l10n.commonValidationAmountPositive;
  }
  return null;
}

/// Adresse email obligatoire, contenant au moins un `@`.
String? validateEmail(String? value, AppLocalizations l10n) {
  if (value == null || value.trim().isEmpty) {
    return l10n.authFormEmailRequired;
  }
  if (!value.contains('@')) {
    return l10n.authFormEmailInvalid;
  }
  return null;
}

/// Nom d'affichage obligatoire d'au plus 100 caracteres, la limite de
/// l'API.
String? validateDisplayName(String? value, AppLocalizations l10n) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty || trimmed.length > 100) {
    return l10n.authFormDisplayNameRequired;
  }
  return null;
}

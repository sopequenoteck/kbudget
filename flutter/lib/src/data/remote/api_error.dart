// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:k_budget/src/localization/app_localizations.dart';

/// Niveau `INFO` au sens de `package:logging`.
///
/// Un code inconnu est un fonctionnement nominal — un client ancien face a un
/// serveur recent — et ne doit donc pas remonter comme une erreur.
const int _logLevelInfo = 800;

/// Lit le code d'erreur porte par le corps d'une reponse d'erreur.
///
/// Retourne `null` des que le corps n'est pas exploitable : un 502 de reverse
/// proxy renvoie du HTML, une coupure ne renvoie rien, et `response.data` peut
/// valoir n'importe quoi. Aucune exception n'est levee.
///
/// `error` est le seul champ contractuel du corps d'erreur. Le champ `message`
/// est un champ de diagnostic (KKS-324) : il n'est jamais lu ici.
String? apiErrorCode(DioException e) {
  final data = e.response?.data;
  if (data is! Map) {
    return null;
  }
  final code = data['error'];
  return code is String && code.isNotEmpty ? code : null;
}

/// Traduit un code d'erreur API en libelle affichable.
///
/// [fallback] est le libelle contextuel du site appelant (« Erreur lors du
/// changement de mot de passe »…), servi quand aucun code exploitable n'est
/// disponible ou que le code est hors catalogue. Sans lui, tous les sites
/// convergeraient vers un libelle indifferencie.
///
/// [overrides] porte les libelles propres au site appelant, consultes avant le
/// catalogue. `BAD_REQUEST` couvre des dizaines de `throw` heterogenes cote
/// serveur et recoit donc un libelle general — mais sur `/auth/login` il n'a
/// qu'un sens possible.
///
/// Un `switch` exhaustif plutot qu'une table de closures : les getters de
/// [AppLocalizations] sont generes, l'analyseur signale ici un getter disparu
/// la ou une table repousserait l'erreur a l'execution.
String errorLabel(
  AppLocalizations l10n,
  String? code, {
  String? fallback,
  Map<String, String>? overrides,
}) {
  if (code == null) {
    return fallback ?? l10n.errorGeneric;
  }
  final override = overrides?[code];
  if (override != null) {
    return override;
  }
  switch (code) {
    case 'BAD_REQUEST':
      return l10n.errorCodeBadRequest;
    case 'VALIDATION_ERROR':
      return l10n.errorCodeValidation;
    case 'MALFORMED_REQUEST':
      return l10n.errorCodeMalformedRequest;
    case 'PASSWORD_INCORRECT':
      return l10n.errorCodePasswordIncorrect;
    case 'PASSWORD_UNCHANGED':
      return l10n.errorCodePasswordUnchanged;
    case 'CONFIRMATION_REQUIRED':
      return l10n.errorCodeConfirmationRequired;
    case 'UNAUTHENTICATED':
      return l10n.errorCodeUnauthenticated;
    case 'TOKEN_EXPIRED':
      return l10n.errorCodeTokenExpired;
    case 'TOKEN_REVOKED':
      return l10n.errorCodeTokenRevoked;
    case 'TOKEN_REUSE_DETECTED':
      return l10n.errorCodeTokenReuseDetected;
    case 'TOKEN_INVALID':
      return l10n.errorCodeTokenInvalid;
    case 'ACCESS_DENIED':
      return l10n.errorCodeAccessDenied;
    case 'PASSWORD_RESET_REQUIRED':
      return l10n.errorCodePasswordResetRequired;
    case 'PASSWORD_RESET_NOT_REQUIRED':
      return l10n.errorCodePasswordResetNotRequired;
    case 'FEATURE_DISABLED':
      return l10n.errorCodeFeatureDisabled;
    case 'LAST_ADMIN_DELETION_FORBIDDEN':
      return l10n.errorCodeLastAdminDeletionForbidden;
    case 'NOT_FOUND':
      return l10n.errorCodeNotFound;
    case 'CONFLICT':
      return l10n.errorCodeConflict;
    case 'LAST_ADMIN_CANNOT_BE_DISABLED':
      return l10n.errorCodeLastAdminCannotBeDisabled;
    case 'EMAIL_ALREADY_EXISTS':
      return l10n.errorCodeEmailAlreadyExists;
    case 'TOO_MANY_REQUESTS':
      return l10n.errorCodeTooManyRequests;
    case 'INTERNAL_ERROR':
      return l10n.errorCodeInternal;
    default:
      developer.log(
        'Unknown API error code: $code',
        name: 'api_error',
        level: _logLevelInfo,
      );
      return fallback ?? l10n.errorGeneric;
  }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:k_budget/src/localization/app_localizations.dart';

/// Politique de mot de passe, alignee sur `PasswordPolicy` cote API (KKS-351).
///
/// Une longueur ecrite en dur dans un validateur se desynchronise du serveur
/// sans qu'aucun test ne devienne rouge : c'est ce qui avait laisse l'ecran
/// d'acceptation d'invitation exiger 8 caracteres face a un serveur qui en
/// exige desormais 12.
///
/// L'ecran de connexion n'utilise pas ces constantes : il verifie un mot de
/// passe existant, lui imposer une longueur minimale bloquerait un compte cree
/// avant un durcissement.
class PasswordPolicy {
  PasswordPolicy._();

  /// Longueur minimale a la creation ou au changement de mot de passe.
  static const int minLength = 12;

  /// Longueur maximale acceptee, alignee sur la capacite de BCrypt.
  static const int maxLength = 100;

  /// Message affiche quand la saisie est trop courte.
  ///
  /// Reutilise la meme cle que [helperText] (`authFormPasswordMinLength`),
  /// alignee sur `auth.form.passwordMinLength` cote Angular, qui sert aussi
  /// bien d'indication que de message d'erreur.
  static String tooShortMessage(AppLocalizations l10n) =>
      l10n.authFormPasswordMinLength(minLength);

  /// Indication affichee sous le champ, avant toute saisie.
  static String helperText(AppLocalizations l10n) =>
      l10n.authFormPasswordMinLength(minLength);
}

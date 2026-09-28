// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart'
    show DiagnosticPropertiesBuilder, DiagnosticsProperty;
import 'package:flutter/material.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/utils/form_validators.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Champ email des ecrans de connexion et de premier acces, valide par
/// [validateEmail].
class AuthEmailField extends StatelessWidget {
  /// Cree le champ lie a [controller].
  const AuthEmailField({required this.controller, super.key});

  /// Texte saisi.
  final TextEditingController controller;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<TextEditingController>('controller', controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      decoration: InputDecoration(
        labelText: l10n.authFormEmail,
        prefixIcon: const PhosphorIcon(PhosphorIconsRegular.envelope, size: 20),
      ),
      validator: (value) => validateEmail(value, l10n),
    );
  }
}

/// Champ nom d'affichage des ecrans de premier acces et d'acceptation
/// d'invitation, valide par [validateDisplayName].
class AuthDisplayNameField extends StatelessWidget {
  /// Cree le champ lie a [controller].
  const AuthDisplayNameField({required this.controller, super.key});

  /// Texte saisi.
  final TextEditingController controller;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<TextEditingController>('controller', controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.name],
      decoration: InputDecoration(
        labelText: l10n.authFormDisplayName,
        prefixIcon: const PhosphorIcon(PhosphorIconsRegular.user, size: 20),
      ),
      validator: (value) => validateDisplayName(value, l10n),
    );
  }
}

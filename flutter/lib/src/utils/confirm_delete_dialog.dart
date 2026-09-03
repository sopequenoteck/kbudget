// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:k_budget/src/localization/app_localizations.dart';

/// Affiche un dialog de confirmation de suppression.
///
/// Retourne `true` si l'utilisateur confirme, `false` ou `null` sinon.
Future<bool?> showDeleteConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(ctx).colorScheme.error,
          ),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
}

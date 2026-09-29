// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/utils/form_validators.dart';

class InviteDialog extends StatefulWidget {
  final void Function(String email) onSubmit;
  final bool isLoading;

  const InviteDialog({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<InviteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(_emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.space4,
        right: AppSpacing.space4,
        top: AppSpacing.space4,
        bottom: AppSpacing.space4 +
            MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.usersActionInvite,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.space4),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: l10n.authFormEmailAddress,
                hintText: l10n.usersFormEmailPlaceholder,
              ),
              validator: (value) => validateEmail(value, l10n),
              onFieldSubmitted: (_) => _handleSubmit(),
            ),
            const SizedBox(height: AppSpacing.space6),
            FilledButton(
              onPressed: widget.isLoading ? null : _handleSubmit,
              child: widget.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.usersActionCreateInvite),
            ),
            const SizedBox(height: AppSpacing.space2),
            TextButton(
              onPressed: widget.isLoading
                  ? null
                  : () => Navigator.of(context).pop(),
              child: Text(l10n.commonActionCancel),
            ),
          ],
        ),
      ),
    );
  }
}

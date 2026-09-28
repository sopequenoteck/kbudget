// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/password_policy.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/features/auth/presentation/widgets/auth_form_fields.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Ecran de premiere connexion (KKS-309).
///
/// Un compte provisionne par un admin — ou l'admin seed cree par
/// `BootstrapSeedRunner` au premier demarrage d'une instance self-hostee —
/// arrive ici apres son premier login reussi : le serveur exige un reset
/// email/mot de passe/nom avant tout appel metier
/// (`PasswordResetRequiredFilter`). Sans cet ecran, l'utilisateur atteint le
/// dashboard puis voit chaque requete rejetee en 403, sans issue.
class FirstLoginResetScreen extends ConsumerStatefulWidget {
  /// Crée l'écran de réinitialisation forcée.
  const FirstLoginResetScreen({super.key});

  @override
  ConsumerState<FirstLoginResetScreen> createState() =>
      _FirstLoginResetScreenState();
}

class _FirstLoginResetScreenState
    extends ConsumerState<FirstLoginResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void dispose() {
    _emailController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).completeFirstLoginReset(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _displayNameController.text.trim(),
          );
    } on DioException catch (e) {
      setState(() {
        _isSubmitting = false;
        _submitError = e.response?.statusCode == 400
            ? l10n.errorsApiValidationError
            : l10n.authFeedbackResetError;
      });
    } on Exception catch (_) {
      setState(() {
        _isSubmitting = false;
        _submitError = l10n.errorsClientUnknown;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        context.go(RouteNames.dashboard);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.space6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PhosphorIcon(
                      PhosphorIconsRegular.shieldCheck,
                      size: 56,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      l10n.authPageFirstLoginTitle,
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      l10n.authPageFirstLoginNotice,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    AuthEmailField(controller: _emailController),
                    const SizedBox(height: AppSpacing.space4),
                    AuthDisplayNameField(controller: _displayNameController),
                    const SizedBox(height: AppSpacing.space4),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: l10n.authFormPassword,
                        helperText: PasswordPolicy.helperText(l10n),
                        prefixIcon: const PhosphorIcon(
                          PhosphorIconsRegular.lock,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: PhosphorIcon(
                            _obscurePassword
                                ? PhosphorIconsRegular.eye
                                : PhosphorIconsRegular.eyeSlash,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.authFormPasswordRequired;
                        }
                        if (value.length < PasswordPolicy.minLength) {
                          return PasswordPolicy.tooShortMessage(l10n);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: l10n.authFormConfirmPassword,
                        prefixIcon: const PhosphorIcon(
                          PhosphorIconsRegular.lock,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: PhosphorIcon(
                            _obscureConfirmPassword
                                ? PhosphorIconsRegular.eye
                                : PhosphorIconsRegular.eyeSlash,
                            size: 20,
                          ),
                          onPressed: () => setState(() =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.authFormPasswordConfirmRequired;
                        }
                        if (value != _passwordController.text) {
                          return l10n.authFormPasswordMismatch;
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _handleSubmit(),
                    ),
                    const SizedBox(height: AppSpacing.space6),
                    if (_submitError != null)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.space4),
                        child: Text(
                          _submitError!,
                          style: TextStyle(color: theme.colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(l10n.commonActionConfirm),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

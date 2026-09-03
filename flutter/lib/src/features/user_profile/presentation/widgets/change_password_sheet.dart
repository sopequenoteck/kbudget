// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/password_policy.dart';
import 'package:k_budget/src/data/remote/dtos/auth_dtos.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/user_profile/application/user_profile_repository_provider.dart';
import 'package:k_budget/src/features/user_profile/domain/models/change_password_request.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Bottom sheet de changement de mot de passe.
///
/// Retourne [AuthResponse] si succès (nouveaux tokens), null si annulé.
class ChangePasswordSheet extends ConsumerStatefulWidget {
  const ChangePasswordSheet({super.key});

  @override
  ConsumerState<ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();

  static Future<AuthResponse?> show(BuildContext context) {
    return showModalBottomSheet<AuthResponse>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const ChangePasswordSheet(),
    );
  }
}

class _ChangePasswordSheetState extends ConsumerState<ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = await ref.read(userProfileRepositoryProvider.future);
      final authResponse = await repo.changePassword(
        ChangePasswordRequest(
          currentPassword: _currentCtrl.text,
          newPassword: _newCtrl.text,
        ),
      );

      // Mettre à jour les tokens dans le state Auth
      final authRepo = await ref.read(authRepositoryProvider.future);
      await authRepo.saveTokens(
        authResponse.accessToken,
        authResponse.refreshToken,
      );

      if (mounted) {
        Navigator.of(context).pop(authResponse);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mot de passe modifié avec succès')),
        );
      }
    } on DioException catch (e) {
      final code = e.response?.data?['error'] as String?;
      if (mounted) {
        setState(() {
          _errorMessage = switch (code) {
            'PASSWORD_INCORRECT' => 'Mot de passe actuel incorrect',
            'PASSWORD_UNCHANGED' =>
              'Le nouveau mot de passe doit être différent de l\'actuel',
            _ => 'Erreur lors du changement de mot de passe',
          };
        });
      }
    } on Exception {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur réseau, veuillez réessayer';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Changer le mot de passe',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.space6),

              // Mot de passe actuel
              TextFormField(
                controller: _currentCtrl,
                obscureText: !_showCurrent,
                decoration: InputDecoration(
                  labelText: 'Mot de passe actuel',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: PhosphorIcon(
                      _showCurrent
                          ? PhosphorIconsRegular.eye
                          : PhosphorIconsRegular.eyeSlash,
                    ),
                    onPressed: () =>
                        setState(() => _showCurrent = !_showCurrent),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: AppSpacing.space4),

              // Nouveau mot de passe
              TextFormField(
                controller: _newCtrl,
                obscureText: !_showNew,
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  helperText: PasswordPolicy.helperText,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: PhosphorIcon(
                      _showNew
                          ? PhosphorIconsRegular.eye
                          : PhosphorIconsRegular.eyeSlash,
                    ),
                    onPressed: () => setState(() => _showNew = !_showNew),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Champ requis';
                  if (v.length < PasswordPolicy.minLength) {
                    return PasswordPolicy.tooShortMessage;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.space4),

              // Confirmation
              TextFormField(
                controller: _confirmCtrl,
                obscureText: !_showConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirmer le nouveau mot de passe',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: PhosphorIcon(
                      _showConfirm
                          ? PhosphorIconsRegular.eye
                          : PhosphorIconsRegular.eyeSlash,
                    ),
                    onPressed: () =>
                        setState(() => _showConfirm = !_showConfirm),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Champ requis';
                  if (v != _newCtrl.text) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.space3),
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.space6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Modifier'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

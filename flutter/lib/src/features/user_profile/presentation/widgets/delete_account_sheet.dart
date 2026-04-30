import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/constants/app_colors.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/user_profile/application/user_profile_repository_provider.dart';
import 'package:k_budget/src/features/user_profile/domain/models/delete_account_request.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Bottom sheet de confirmation de suppression de compte.
///
/// Retourne [true] si la suppression a été confirmée et exécutée avec succès,
/// [false] ou [null] si annulé.
class DeleteAccountSheet extends ConsumerStatefulWidget {
  const DeleteAccountSheet({super.key});

  @override
  ConsumerState<DeleteAccountSheet> createState() => _DeleteAccountSheetState();

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const DeleteAccountSheet(),
    );
  }
}

class _DeleteAccountSheetState extends ConsumerState<DeleteAccountSheet> {
  final _passwordCtrl = TextEditingController();
  bool _showPassword = false;
  bool _confirmed = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _passwordCtrl.text.isNotEmpty && _confirmed && !_isSubmitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = await ref.read(userProfileRepositoryProvider.future);
      await repo.deleteAccount(
        DeleteAccountRequest(
          currentPassword: _passwordCtrl.text,
          confirmed: true,
        ),
      );

      // Purge auth state
      await ref.read(authNotifierProvider.notifier).logout();

      if (mounted) {
        Navigator.of(context).pop(true);
        context.go(RouteNames.login);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.data?['error'] as String?;
      final message = switch (code) {
        'PASSWORD_INCORRECT' => 'Mot de passe incorrect',
        'LAST_ADMIN_DELETION_FORBIDDEN' =>
          'Vous êtes le dernier administrateur. Veuillez nommer un autre administrateur avant de supprimer votre compte.',
        _ => 'Erreur lors de la suppression',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la suppression')),
      );
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Supprimer mon compte',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              'Cette action est irréversible. Toutes vos données seront supprimées.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.space6),

            // Champ mot de passe
            TextFormField(
              controller: _passwordCtrl,
              obscureText: !_showPassword,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Mot de passe actuel',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: PhosphorIcon(
                    _showPassword
                        ? PhosphorIconsRegular.eye
                        : PhosphorIconsRegular.eyeSlash,
                  ),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space4),

            // Checkbox de confirmation
            CheckboxListTile(
              value: _confirmed,
              onChanged: (value) =>
                  setState(() => _confirmed = value ?? false),
              title: const Text(
                'Je comprends que cette action est définitive',
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: AppSpacing.space6),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: AppSpacing.space3),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.error.withValues(alpha: 0.4),
                  ),
                  onPressed: _canSubmit ? _submit : null,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Supprimer mon compte'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/password_policy.dart';
import 'package:k_budget/src/data/remote/api_client.dart';
import 'package:k_budget/src/domain/enums/currency.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/data/auth_remote_data_source.dart';
import 'package:k_budget/src/features/auth/data/auth_repository_impl.dart';
import 'package:k_budget/src/features/auth/presentation/widgets/auth_form_fields.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// Provider public (sans intercepteur auth) pour le lookup invitation
final _invitationLookupProvider =
    FutureProvider.family<String, String>((ref, token) async {
  final dio = await ref.watch(apiClientProvider.future);
  final response =
      await dio.get<Map<String, dynamic>>('/auth/invitations/$token');
  return response.data!['email'] as String;
});

class AcceptInviteScreen extends ConsumerStatefulWidget {
  final String token;

  const AcceptInviteScreen({super.key, required this.token});

  @override
  ConsumerState<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends ConsumerState<AcceptInviteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _submitError;
  String _selectedCurrency = 'EUR';

  @override
  void dispose() {
    _displayNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(String email) async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final dio = await ref.read(apiClientProvider.future);
      final dataSource = AuthRemoteDataSource(dio);
      final repo = AuthRepositoryImpl(dataSource);

      final timezone = DateTime.now().timeZoneName;

      // Appeler le endpoint accept-invite directement
      final response = await dio.post<Map<String, dynamic>>(
        '/auth/accept-invite',
        data: {
          'token': widget.token,
          'password': _passwordController.text,
          'displayName': _displayNameController.text.trim(),
          'currency': _selectedCurrency,
          'timezone': timezone,
        },
      );

      final accessToken = response.data!['token'] as String;
      final refreshToken = response.data!['refreshToken'] as String;

      // Sauvegarder les tokens
      await repo.saveTokens(accessToken, refreshToken);

      // Marquer comme authentifié
      ref.read(authNotifierProvider.notifier).forceUnauthenticated();
      // Re-vérifier l'auth pour mettre à jour l'état
      await ref.read(authNotifierProvider.notifier).checkAuth();

      if (mounted) {
        context.go(RouteNames.dashboard);
      }
    } on DioException catch (e) {
      setState(() {
        _isSubmitting = false;
        _submitError = e.response?.statusCode == 404
            ? l10n.authFeedbackInvalidLink
            : l10n.authFeedbackCreateAccountError;
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
    final lookupAsync = ref.watch(_invitationLookupProvider(widget.token));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.space6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: lookupAsync.when(
                loading: () => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: AppSpacing.space4),
                    Text(l10n.authFeedbackCheckingLink),
                  ],
                ),
                error: (_, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PhosphorIcon(
                      PhosphorIconsRegular.warning,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      l10n.authPageInvalidLinkTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      l10n.authFeedbackInvalidLink,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.space6),
                    FilledButton(
                      onPressed: () => context.go(RouteNames.login),
                      child: Text(l10n.authActionBackToLogin),
                    ),
                  ],
                ),
                data: (email) => _buildForm(context, email, l10n),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    String email,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PhosphorIcon(
            PhosphorIconsRegular.sealCheck,
            size: 56,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            l10n.authPageAcceptInviteTitle,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            l10n.authPageAcceptInviteTagline,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.space8),
          // Email lecture seule
          TextFormField(
            initialValue: email,
            enabled: false,
            decoration: InputDecoration(
              labelText: l10n.authFormEmail,
              prefixIcon: const PhosphorIcon(
                PhosphorIconsRegular.envelope,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          AuthDisplayNameField(controller: _displayNameController),
          const SizedBox(height: AppSpacing.space4),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: l10n.authFormPassword,
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
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              helperText: PasswordPolicy.helperText(l10n),
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
            onFieldSubmitted: (_) => _handleSubmit(email),
          ),
          const SizedBox(height: AppSpacing.space4),
          DropdownButtonFormField<String>(
            initialValue: _selectedCurrency,
            decoration: InputDecoration(
              labelText: l10n.authFormCurrency,
              prefixIcon: const PhosphorIcon(
                PhosphorIconsRegular.currencyCircleDollar,
                size: 20,
              ),
            ),
            items: Currency.values.map((currency) {
              return DropdownMenuItem<String>(
                value: currency.name.toUpperCase(),
                child: Text('${currency.symbol} - ${currency.displayName}'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCurrency = value);
              }
            },
          ),
          const SizedBox(height: AppSpacing.space6),
          if (_submitError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space4),
              child: Text(
                _submitError!,
                style: TextStyle(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          FilledButton(
            onPressed: _isSubmitting ? null : () => _handleSubmit(email),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.authActionCreateAccount),
          ),
          const SizedBox(height: AppSpacing.space4),
          TextButton(
            onPressed:
                _isSubmitting ? null : () => context.go(RouteNames.login),
            child: Text(l10n.authActionBackToLogin),
          ),
        ],
      ),
    );
  }
}

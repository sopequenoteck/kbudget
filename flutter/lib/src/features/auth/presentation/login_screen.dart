// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/data/remote/api_error.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/features/auth/presentation/widgets/auth_form_fields.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authNotifierProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthAuthenticating;

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
                      PhosphorIconsRegular.wallet,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      'K-Budget',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      l10n.authPageLoginTagline,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    AuthEmailField(controller: _emailController),
                    const SizedBox(height: AppSpacing.space4),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: l10n.authFormPassword,
                        prefixIcon: const PhosphorIcon(PhosphorIconsRegular.lock, size: 20),
                        suffixIcon: IconButton(
                          icon: PhosphorIcon(
                            _obscurePassword
                                ? PhosphorIconsRegular.eye
                                : PhosphorIconsRegular.eyeSlash,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.authFormPasswordRequired;
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: AppSpacing.space6),
                    if (authState is AuthLoginFailed)
                      Padding(
                        padding: const EdgeInsets.only(
                            bottom: AppSpacing.space4),
                        child: Text(
                          // Le serveur refuse des identifiants par un
                          // BAD_REQUEST, code partage par des dizaines de
                          // causes ailleurs : sur cet ecran il n'en a qu'une.
                          // Un code absent signale un corps de reponse non
                          // exploitable (serveur injoignable, timeout, 502
                          // de proxy) : le libelle reseau est alors plus
                          // pertinent qu'« identifiants invalides ».
                          errorLabel(
                            l10n,
                            authState.errorCode,
                            fallback: authState.errorCode == null
                                ? l10n.errorsClientNetwork
                                : l10n.authFeedbackInvalidCredentials,
                            overrides: {
                              'BAD_REQUEST':
                                  l10n.authFeedbackInvalidCredentials,
                            },
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    FilledButton(
                      onPressed: isLoading ? null : _handleLogin,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(l10n.authActionSignIn),
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
